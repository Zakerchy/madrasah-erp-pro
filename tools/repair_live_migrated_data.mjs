import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import {
  buildBeneficiaryRecords,
  buildFundTransactionRecords,
  buildScholarshipPaymentRecords,
  isAlignedBeneficiaryRow,
  isAlignedScholarshipRow,
  isAlignedTransactionRow,
  parseCsvFile,
  readCsvObjects,
  rowsForHeaders,
} from './migrated_sheet_utils.mjs';

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

function rowsToObjects(headers, rows) {
  return rows.map((row) =>
    Object.fromEntries(headers.map((header, idx) => [header, row[idx] ?? '']))
  );
}

const env = loadEnv(ENV_PATH);
const spreadsheetId = process.argv[2] || env.GOOGLE_SHEET_ID;
const svcEmail = env.GOOGLE_SERVICE_ACCOUNT_EMAIL;
let privateKey = env.GOOGLE_PRIVATE_KEY || '';
privateKey = privateKey.replace(/\\n/g, '\n');

if (!spreadsheetId || !svcEmail || !privateKey) {
  throw new Error('Missing GOOGLE_SHEET_ID / GOOGLE_SERVICE_ACCOUNT_EMAIL / GOOGLE_PRIVATE_KEY');
}

const auth = new google.auth.JWT({
  email: svcEmail,
  key: privateKey,
  scopes: ['https://www.googleapis.com/auth/spreadsheets'],
});
const sheets = google.sheets({ version: 'v4', auth });

const txnHeaders = parseCsvFile(path.join(SHEETS_DIR, 'fund_transactions.csv')).headers;
const beneficiaryHeaders = parseCsvFile(path.join(SHEETS_DIR, 'beneficiaries.csv')).headers;
const scholarshipHeaders = parseCsvFile(path.join(SHEETS_DIR, 'scholarship_payments.csv')).headers;

const [txnRaw, beneficiaryRaw, scholarshipRaw] = await Promise.all([
  sheets.spreadsheets.values.get({ spreadsheetId, range: 'fund_transactions!A1:ZZ' }),
  sheets.spreadsheets.values.get({ spreadsheetId, range: 'beneficiaries!A1:ZZ' }),
  sheets.spreadsheets.values.get({ spreadsheetId, range: 'scholarship_payments!A1:ZZ' }),
]);

const txnValues = txnRaw.data.values || [];
const beneficiaryValues = beneficiaryRaw.data.values || [];
const scholarshipValues = scholarshipRaw.data.values || [];

const liveTxnHeaders = txnValues[0] || txnHeaders;
const liveBeneficiaryHeaders = beneficiaryValues[0] || beneficiaryHeaders;
const liveScholarshipHeaders = scholarshipValues[0] || scholarshipHeaders;

const liveTxnRows = rowsToObjects(liveTxnHeaders, txnValues.slice(1));
const liveBeneficiaryRows = rowsToObjects(liveBeneficiaryHeaders, beneficiaryValues.slice(1));
const liveScholarshipRows = rowsToObjects(liveScholarshipHeaders, scholarshipValues.slice(1));

const preservedTxnRows = liveTxnRows.filter(
  (row) => isAlignedTransactionRow(row) && !String(row.id || '').startsWith('txn_mig_')
);
const preservedBeneficiaryRows = liveBeneficiaryRows.filter(
  (row) => isAlignedBeneficiaryRow(row) && !String(row.id || '').startsWith('ben_mig_')
);
const preservedScholarshipRows = liveScholarshipRows.filter(
  (row) => isAlignedScholarshipRow(row) && !String(row.id || '').startsWith('sp_mig_')
);

const migratedTransactions = readCsvObjects(path.join(OUT_DIR, 'migrated_fund_transactions.csv'));
const migratedBeneficiaries = readCsvObjects(path.join(OUT_DIR, 'migrated_beneficiaries.csv'));
const migratedScholarship = readCsvObjects(path.join(OUT_DIR, 'migrated_scholarship_payments.csv'));

const repairedBeneficiaries = buildBeneficiaryRecords(
  migratedBeneficiaries,
  preservedBeneficiaryRows
);
const repairedTransactions = buildFundTransactionRecords(
  migratedTransactions,
  preservedTxnRows
);
const repairedScholarship = buildScholarshipPaymentRecords(
  migratedScholarship,
  repairedBeneficiaries,
  preservedScholarshipRows
);

const backup = {
  createdAt: new Date().toISOString(),
  spreadsheetId,
  liveCounts: {
    fund_transactions: liveTxnRows.length,
    beneficiaries: liveBeneficiaryRows.length,
    scholarship_payments: liveScholarshipRows.length,
  },
  preservedCounts: {
    fund_transactions: preservedTxnRows.length,
    beneficiaries: preservedBeneficiaryRows.length,
    scholarship_payments: preservedScholarshipRows.length,
  },
  raw: {
    fund_transactions: txnValues,
    beneficiaries: beneficiaryValues,
    scholarship_payments: scholarshipValues,
  },
};

const backupFile = path.join(
  OUT_DIR,
  `live_repair_backup_${new Date().toISOString().replace(/[:.]/g, '-')}.json`
);
fs.writeFileSync(backupFile, JSON.stringify(backup, null, 2), 'utf8');

const writes = [
  {
    tab: 'fund_transactions',
    values: rowsForHeaders(txnHeaders, repairedTransactions),
  },
  {
    tab: 'beneficiaries',
    values: rowsForHeaders(beneficiaryHeaders, repairedBeneficiaries),
  },
  {
    tab: 'scholarship_payments',
    values: rowsForHeaders(scholarshipHeaders, repairedScholarship),
  },
];

for (const write of writes) {
  await sheets.spreadsheets.values.clear({
    spreadsheetId,
    range: `${write.tab}!A2:ZZ`,
  });
  if (!write.values.length) continue;
  await sheets.spreadsheets.values.update({
    spreadsheetId,
    range: `${write.tab}!A2`,
    valueInputOption: 'RAW',
    requestBody: { values: write.values },
  });
}

console.log(
  JSON.stringify(
    {
      ok: true,
      spreadsheetId,
      backupFile,
      repairedCounts: {
        fund_transactions: repairedTransactions.length,
        beneficiaries: repairedBeneficiaries.length,
        scholarship_payments: repairedScholarship.length,
      },
      preservedCounts: {
        fund_transactions: preservedTxnRows.length,
        beneficiaries: preservedBeneficiaryRows.length,
        scholarship_payments: preservedScholarshipRows.length,
      },
    },
    null,
    2
  )
);
