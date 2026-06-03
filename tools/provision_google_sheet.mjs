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

const ROOT = '/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-pro';
const ENV_PATH = '/Users/zakerchy/Desktop/TravERPPro2/.env.local';
const SHEETS_DIR = path.join(ROOT, 'sheets');
const OUT_DIR = path.join(ROOT, 'tools', 'output');

function loadEnv(filePath) {
  const txt = fs.readFileSync(filePath, 'utf8');
  const out = {};
  txt.split(/\r?\n/).forEach((line) => {
    const m = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
    if (!m) return;
    let v = m[2] ?? '';
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.slice(1, -1);
    }
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
      if (q && nx === '"') {
        cur += '"';
        i++;
      } else {
        q = !q;
      }
      continue;
    }
    if (ch === ',' && !q) {
      out.push(cur);
      cur = '';
      continue;
    }
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
const svcEmail = env.GOOGLE_SERVICE_ACCOUNT_EMAIL;
let privateKey = env.GOOGLE_PRIVATE_KEY || '';
privateKey = privateKey.replace(/\\n/g, '\n');

if (!svcEmail || !privateKey) {
  throw new Error('Missing GOOGLE_SERVICE_ACCOUNT_EMAIL or GOOGLE_PRIVATE_KEY in .env.local');
}

const auth = new google.auth.JWT({
  email: svcEmail,
  key: privateKey,
  scopes: [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive',
  ],
});

const sheets = google.sheets({ version: 'v4', auth });
const drive = google.drive({ version: 'v3', auth });

const tabCsvFiles = [
  'users_roles.csv',
  'fund_transactions.csv',
  'expense_details.csv',
  'salary_staff.csv',
  'salary_payments.csv',
  'beneficiaries.csv',
  'scholarship_monthly_plan.csv',
  'scholarship_payments.csv',
  'audit_log.csv',
  'settings.csv',
];

const tabNames = tabCsvFiles.map((f) => path.basename(f, '.csv'));

const title = `Madrasah ERP Pro DB ${new Date().toISOString().slice(0, 10)}`;
const createRes = await sheets.spreadsheets.create({
  requestBody: { properties: { title } },
});

const spreadsheetId = createRes.data.spreadsheetId;
const spreadsheetUrl = createRes.data.spreadsheetUrl;
if (!spreadsheetId) throw new Error('Failed to create spreadsheet');

// Rename default Sheet1 to first tab name
await sheets.spreadsheets.batchUpdate({
  spreadsheetId,
  requestBody: {
    requests: [
      {
        updateSheetProperties: {
          properties: { sheetId: 0, title: tabNames[0] },
          fields: 'title',
        },
      },
      ...tabNames.slice(1).map((name) => ({ addSheet: { properties: { title: name } } })),
    ],
  },
});

// Write headers for each tab
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

// Import migrated rows
const imports = [
  { src: 'migrated_fund_transactions.csv', tab: 'fund_transactions' },
  { src: 'migrated_beneficiaries.csv', tab: 'beneficiaries' },
  { src: 'migrated_scholarship_payments.csv', tab: 'scholarship_payments' },
];

for (const item of imports) {
  const p = path.join(OUT_DIR, item.src);
  if (!fs.existsSync(p)) continue;
  const { rows } = parseCsvFile(p);
  if (!rows.length) continue;
  await sheets.spreadsheets.values.append({
    spreadsheetId,
    range: `${item.tab}!A2`,
    valueInputOption: 'RAW',
    insertDataOption: 'INSERT_ROWS',
    requestBody: { values: rows },
  });
}

// Seed admin user (PIN 1234)
const userSeed = [
  'u_admin_1',
  'Admin',
  '01700000000',
  'zakerchy@gmail.com',
  'ADMIN',
  'TRUE',
  hashPin('1234'),
  new Date().toISOString(),
  new Date().toISOString(),
];
await sheets.spreadsheets.values.append({
  spreadsheetId,
  range: 'users_roles!A2',
  valueInputOption: 'RAW',
  insertDataOption: 'INSERT_ROWS',
  requestBody: { values: [userSeed] },
});

// share with your main email
try {
  await drive.permissions.create({
    fileId: spreadsheetId,
    requestBody: {
      type: 'user',
      role: 'writer',
      emailAddress: 'zakerchy@gmail.com',
    },
    sendNotificationEmail: false,
  });
} catch (e) {
  // non-fatal for non-workspace/service-account limitations
}

const summary = {
  createdAt: new Date().toISOString(),
  spreadsheetId,
  spreadsheetUrl,
  title,
  seededAdminPhone: '01700000000',
  seededAdminPin: '1234',
};

const outFile = path.join(ROOT, 'tools', 'output', 'provisioned_sheet.json');
fs.writeFileSync(outFile, JSON.stringify(summary, null, 2), 'utf8');

console.log('Provision done');
console.log(JSON.stringify(summary, null, 2));
