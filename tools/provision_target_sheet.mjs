import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
let google;
try {
  ({ google } = require('googleapis'));
} catch {
  ({ google } = require('/Users/zakerchy/Desktop/TravERPPro2/node_modules/googleapis'));
}

const ROOT = '/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-lite';
const ENV_PATH = '/Users/zakerchy/Desktop/TravERPPro2/.env.local';
const SHEETS_DIR = path.join(ROOT, 'sheets');
const OUT_DIR = path.join(ROOT, 'tools', 'output');

const argId = process.argv[2];
if (!argId) {
  console.error('Usage: node tools/provision_target_sheet.mjs <GOOGLE_SHEET_ID>');
  process.exit(1);
}

function loadEnv(filePath) {
  const txt = fs.readFileSync(filePath, 'utf8');
  const out = {};
  txt.split(/\r?\n/).forEach((line) => {
    const m = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (!m) return;
    let v = m[2] ?? '';
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
    out[m[1]] = v;
  });
  return out;
}

function parseCsvLine(line) {
  const out = [];
  let cur = '';
  let q = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    const nx = line[i + 1];
    if (ch === '"') {
      if (q && nx === '"') { cur += '"'; i++; } else { q = !q; }
      continue;
    }
    if (ch === ',' && !q) { out.push(cur); cur = ''; continue; }
    cur += ch;
  }
  out.push(cur);
  return out;
}

function parseCsvFile(filePath) {
  const txt = fs.readFileSync(filePath, 'utf8').trim();
  if (!txt) return { headers: [], rows: [] };
  const lines = txt.split(/\r?\n/);
  const headers = parseCsvLine(lines[0]);
  const rows = lines.slice(1).filter(Boolean).map(parseCsvLine);
  return { headers, rows };
}

function hashPin(pin) {
  return crypto.createHash('sha256').update(String(pin), 'utf8').digest('hex');
}

const env = loadEnv(ENV_PATH);
const spreadsheetId = argId.trim();
const svcEmail = env.GOOGLE_SERVICE_ACCOUNT_EMAIL;
let privateKey = env.GOOGLE_PRIVATE_KEY || '';
privateKey = privateKey.replace(/\\n/g, '\n');
if (!svcEmail || !privateKey) throw new Error('Missing service account env keys');

const auth = new google.auth.JWT({
  email: svcEmail,
  key: privateKey,
  scopes: ['https://www.googleapis.com/auth/spreadsheets'],
});
const sheets = google.sheets({ version: 'v4', auth });

const tabCsvFiles = [
  'users_roles.csv','fund_transactions.csv','expense_details.csv','salary_staff.csv','salary_payments.csv',
  'beneficiaries.csv','scholarship_monthly_plan.csv','scholarship_payments.csv','audit_log.csv','settings.csv'
];
const tabNames = tabCsvFiles.map((f) => path.basename(f, '.csv'));

const ss = await sheets.spreadsheets.get({ spreadsheetId });
const existing = new Set((ss.data.sheets || []).map((s) => s.properties?.title).filter(Boolean));

const addRequests = tabNames.filter((name) => !existing.has(name)).map((name) => ({ addSheet: { properties: { title: name } } }));
if (addRequests.length) {
  await sheets.spreadsheets.batchUpdate({ spreadsheetId, requestBody: { requests: addRequests } });
}

for (const f of tabCsvFiles) {
  const tab = path.basename(f, '.csv');
  const { headers } = parseCsvFile(path.join(SHEETS_DIR, f));
  if (!headers.length) continue;
  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: `${tab}!A1`,
    valueInputOption: 'RAW',
    requestBody: { values: [headers] },
  });
}

const imports = [
  { src: 'migrated_fund_transactions.csv', tab: 'fund_transactions' },
  { src: 'migrated_beneficiaries.csv', tab: 'beneficiaries' },
  { src: 'migrated_scholarship_payments.csv', tab: 'scholarship_payments' },
];

for (const item of imports) {
  const p = path.join(OUT_DIR, item.src);
  if (!fs.existsSync(p)) continue;
  const { rows } = parseCsvFile(p);
  await sheets.spreadsheets.values.clear({ spreadsheetId, range: `${item.tab}!A2:ZZ` });
  if (rows.length) {
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: `${item.tab}!A2`,
      valueInputOption: 'RAW',
      requestBody: { values: rows },
    });
  }
}

const usersRead = await sheets.spreadsheets.values.get({ spreadsheetId, range: 'users_roles!A1:Z' });
const vals = usersRead.data.values || [];
const headers = vals[0] || [];
const rows = vals.slice(1);
const phoneIdx = headers.indexOf('phone');
const hasAdmin = rows.some((r) => String(r[phoneIdx] || '') === '01700000000');
if (!hasAdmin && headers.length) {
  const record = {
    id: 'u_admin_1',
    name: 'Admin',
    phone: '01700000000',
    email: 'zakerchy@gmail.com',
    role: 'ADMIN',
    active: 'TRUE',
    pin_hash: hashPin('1234'),
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };
  const row = headers.map((h) => record[h] ?? '');
  await sheets.spreadsheets.values.append({
    spreadsheetId,
    range: 'users_roles!A2',
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: [row] },
  });
}

const out = {
  appliedAt: new Date().toISOString(),
  spreadsheetId,
  sheetTitle: ss.data.properties?.title || '',
  addedTabs: addRequests.length,
  importedTabs: imports.map((i) => i.tab),
  adminSeedPhone: '01700000000',
  adminSeedPin: '1234',
};

const outFile = path.join(OUT_DIR, 'provisioned_target_sheet.json');
fs.writeFileSync(outFile, JSON.stringify(out, null, 2), 'utf8');

console.log('Provision target sheet done');
console.log(JSON.stringify(out, null, 2));
