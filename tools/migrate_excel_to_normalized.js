import fs from 'fs';
import path from 'path';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
let XLSX;
try {
  XLSX = require('xlsx');
} catch (_) {
  XLSX = require('/Users/zakerchy/Desktop/TravERPPro2/node_modules/xlsx');
}

const ROOT = '/Users/zakerchy/Desktop/MadrasahApp';
const PROJECT = '/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-lite';
const DONATION_FILE = path.join(ROOT, 'কম_প্লে_ক্সের দা_নের হিসাব.xlsx');
const SCHOLAR_FILE = path.join(ROOT, 'Helpless girls students.xlsx');
const OUT_DIR = path.join(PROJECT, 'tools/output');

const bnDigits = {
  '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
  '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
};

const monthAlias = {
  '01': ['জানুয়ারি', 'জানুয়ারি', 'জানুয়া‌রি', 'jan'],
  '02': ['ফেব্রুয়ারি', 'ফেব্রুয়ারি', 'ফেব্রুয়া‌রি', 'feb'],
  '03': ['মার্চ', 'march', 'mar'],
  '04': ['এপ্রিল', 'april', 'apr'],
  '05': ['মে', 'may'],
  '06': ['জুন', 'june', 'jun'],
  '07': ['জুলাই', 'july', 'jul'],
  '08': ['আগস্ট', 'august', 'aug'],
  '09': ['সেপ্টেম্বর', 'september', 'sep'],
  '10': ['অক্টোবর', 'অক্টোবর', 'অ‌ক্টোবর', 'october', 'oct'],
  '11': ['নভেম্বর', 'ন‌ভেম্বর', 'november', 'nov'],
  '12': ['ডিসেম্বর', 'ডি‌সেম্বর', 'december', 'dec'],
};

function bnToEn(str = '') {
  return String(str).replace(/[০-৯]/g, (d) => bnDigits[d] || d);
}

function cleanText(str = '') {
  return bnToEn(String(str))
    .replace(/[\u200B-\u200D\uFEFF\u00A0]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function normalizeAmount(v) {
  if (v === null || v === undefined || v === '') return 0;
  if (typeof v === 'number') return v;
  const s = cleanText(v).replace(/[^0-9.-]/g, '');
  return s ? Number(s) : 0;
}

function excelDateToIso(value) {
  if (typeof value === 'number') {
    const d = XLSX.SSF.parse_date_code(value);
    if (!d) return '';
    const mm = String(d.m).padStart(2, '0');
    const dd = String(d.d).padStart(2, '0');
    return `${d.y}-${mm}-${dd}`;
  }

  const raw = cleanText(value);
  if (!raw) return '';

  const m = raw.match(/^(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})$/);
  if (m) {
    let y = Number(m[3]);
    if (y < 100) y += 2000;
    const mm = String(Number(m[2])).padStart(2, '0');
    const dd = String(Number(m[1])).padStart(2, '0');
    return `${y}-${mm}-${dd}`;
  }

  return '';
}

function parseMonthKey(raw) {
  const txt = cleanText(raw).toLowerCase();
  if (!txt) return '';

  const yearMatch = txt.match(/(\d{2,4})/);
  if (!yearMatch) return '';

  let year = Number(yearMatch[1]);
  if (year < 100) year += 2000;

  let mm = '';
  Object.keys(monthAlias).forEach((k) => {
    if (mm) return;
    if (monthAlias[k].some((m) => txt.includes(m.toLowerCase()))) mm = k;
  });

  return mm ? `${year}-${mm}` : '';
}

function csvEscape(v) {
  const s = String(v ?? '');
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function writeCsv(filename, headers, rows) {
  const lines = [headers.join(',')];
  rows.forEach((r) => {
    lines.push(headers.map((h) => csvEscape(r[h])).join(','));
  });
  fs.writeFileSync(path.join(OUT_DIR, filename), lines.join('\n'), 'utf8');
}

function migrateDonationWorkbook() {
  const wb = XLSX.readFile(DONATION_FILE);
  const ws = wb.Sheets[wb.SheetNames[0]];
  const rows = XLSX.utils.sheet_to_json(ws, { header: 1, defval: '' });

  const out = [];
  let runningDate = '';

  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    if (!r || !r.length) continue;

    const rowDate = excelDateToIso(r[1]);
    if (rowDate) runningDate = rowDate;
    const baseDate = rowDate || runningDate;

    const donor = cleanText(r[2]);
    const constructionIn = normalizeAmount(r[3]);
    const jakatIn = normalizeAmount(r[4]);
    const scholarshipIn = normalizeAmount(r[5]);

    const constructionExpenseDate = excelDateToIso(r[6]) || baseDate;
    const constructionExpenseHead = cleanText(r[7]);
    const constructionExpenseAmount = normalizeAmount(r[8]);

    const jakatExpenseDate = excelDateToIso(r[10]) || baseDate;
    const jakatExpenseHead = cleanText(r[11]);
    const jakatExpenseAmount = normalizeAmount(r[12]);

    const scholarshipExpenseDate = excelDateToIso(r[14]) || baseDate;
    const scholarshipExpenseHead = cleanText(r[15]);
    const scholarshipExpenseAmount = normalizeAmount(r[16]);

    if (donor && constructionIn > 0 && baseDate) {
      out.push({ txn_date: baseDate, direction: 'IN', fund_type: 'CONSTRUCTION', amount: constructionIn, source_or_vendor: donor, category: 'DONATION', notes: 'migrated' });
    }
    if (donor && jakatIn > 0 && baseDate) {
      out.push({ txn_date: baseDate, direction: 'IN', fund_type: 'JAKAT', amount: jakatIn, source_or_vendor: donor, category: 'DONATION', notes: 'migrated' });
    }
    if (donor && scholarshipIn > 0 && baseDate) {
      out.push({ txn_date: baseDate, direction: 'IN', fund_type: 'SCHOLARSHIP', amount: scholarshipIn, source_or_vendor: donor, category: 'DONATION', notes: 'migrated' });
    }

    if (constructionExpenseHead && constructionExpenseAmount > 0 && constructionExpenseDate) {
      out.push({ txn_date: constructionExpenseDate, direction: 'OUT', fund_type: 'CONSTRUCTION', amount: constructionExpenseAmount, source_or_vendor: 'Expense', category: constructionExpenseHead, notes: 'migrated' });
    }
    if (jakatExpenseHead && jakatExpenseAmount > 0 && jakatExpenseDate) {
      out.push({ txn_date: jakatExpenseDate, direction: 'OUT', fund_type: 'JAKAT', amount: jakatExpenseAmount, source_or_vendor: 'Expense', category: jakatExpenseHead, notes: 'migrated' });
    }
    if (scholarshipExpenseHead && scholarshipExpenseAmount > 0 && scholarshipExpenseDate) {
      out.push({ txn_date: scholarshipExpenseDate, direction: 'OUT', fund_type: 'SCHOLARSHIP', amount: scholarshipExpenseAmount, source_or_vendor: 'Expense', category: scholarshipExpenseHead, notes: 'migrated' });
    }
  }

  return out.filter((r) => r.txn_date && r.amount > 0);
}

function migrateBeneficiariesAndScholarship() {
  const wb = XLSX.readFile(SCHOLAR_FILE);

  const benSheet = wb.Sheets['Copy of Sheet1'];
  const benRows = XLSX.utils.sheet_to_json(benSheet, { header: 1, defval: '' });
  const beneficiaries = [];

  benRows.forEach((r) => {
    if (!r || typeof r[0] !== 'number') return;
    beneficiaries.push({
      serial_no: r[0],
      name_bn: cleanText(r[1]),
      age: normalizeAmount(r[2]),
      guardian_status: cleanText(r[3]),
      class_name: cleanText(r[4]),
      primary_need: cleanText(r[5]),
      monthly_need: cleanText(r[6]),
      monthly_need_amount: normalizeAmount(r[7]),
      active: 'TRUE',
    });
  });

  const schSheet = wb.Sheets['Monthly Hishab of scholarship'];
  const schRows = XLSX.utils.sheet_to_json(schSheet, { header: 1, defval: '' });

  const scholarshipPayments = [];
  let currentMonthKey = '';

  schRows.forEach((r) => {
    const first = cleanText(r[0]);
    if (first.startsWith('মাস:') || first.startsWith('মাস')) {
      const label = first.replace(/^মাস:?/i, '').trim();
      currentMonthKey = parseMonthKey(label);
      return;
    }

    if (typeof r[0] === 'number' && r[1] && currentMonthKey) {
      scholarshipPayments.push({
        month_key: currentMonthKey,
        beneficiary_name: cleanText(r[1]),
        school_fee: normalizeAmount(r[7]),
        bangla_tutor: normalizeAmount(r[9]),
        arabi_tutor: normalizeAmount(r[10]),
        materials: normalizeAmount(r[11]),
        other: normalizeAmount(r[12]),
        total_paid: normalizeAmount(r[13]),
        remaining_amount: normalizeAmount(r[14]),
        payment_status: cleanText(r[6]).toUpperCase() === 'CANCELLED' ? 'CANCELLED' : 'PAID',
      });
    }
  });

  return { beneficiaries, scholarshipPayments };
}

function main() {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

  const txns = migrateDonationWorkbook();
  const { beneficiaries, scholarshipPayments } = migrateBeneficiariesAndScholarship();

  writeCsv('migrated_fund_transactions.csv', ['txn_date', 'direction', 'fund_type', 'amount', 'source_or_vendor', 'category', 'notes'], txns);
  writeCsv('migrated_beneficiaries.csv', ['serial_no', 'name_bn', 'age', 'guardian_status', 'class_name', 'primary_need', 'monthly_need', 'monthly_need_amount', 'active'], beneficiaries);
  writeCsv('migrated_scholarship_payments.csv', ['month_key', 'beneficiary_name', 'school_fee', 'bangla_tutor', 'arabi_tutor', 'materials', 'other', 'total_paid', 'remaining_amount', 'payment_status'], scholarshipPayments);

  console.log('Migration complete. Output files written to:', OUT_DIR);
  console.log('Transactions:', txns.length, 'Beneficiaries:', beneficiaries.length, 'Scholarship rows:', scholarshipPayments.length);
}

main();
