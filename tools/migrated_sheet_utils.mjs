import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export function parseCsvLine(line) {
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

export function parseCsvFile(filePath) {
  const txt = fs.readFileSync(filePath, 'utf8').trim();
  if (!txt) return { headers: [], rows: [] };
  const lines = txt.split(/\r?\n/);
  const headers = parseCsvLine(lines[0]);
  const rows = lines.slice(1).filter(Boolean).map(parseCsvLine);
  return { headers, rows };
}

export function readCsvObjects(filePath) {
  const { headers, rows } = parseCsvFile(filePath);
  return rows.map((row) =>
    Object.fromEntries(headers.map((header, idx) => [header, row[idx] ?? '']))
  );
}

export function hashPin(pin) {
  return crypto.createHash('sha256').update(String(pin), 'utf8').digest('hex');
}

function stableId(prefix, record) {
  const src = JSON.stringify(record);
  const digest = crypto.createHash('sha1').update(src, 'utf8').digest('hex');
  return `${prefix}_${digest.slice(0, 16)}`;
}

function toNumber(value) {
  const cleaned = String(value ?? '')
    .replace(/,/g, '')
    .replace(/[^\d.-]/g, '')
    .trim();
  return cleaned ? Number(cleaned) : 0;
}

function isoNow() {
  return new Date().toISOString();
}

function isIsoDate(value) {
  return /^\d{4}-\d{2}-\d{2}$/.test(String(value ?? '').trim());
}

function isMonthKey(value) {
  return /^\d{4}-\d{2}$/.test(String(value ?? '').trim());
}

export function isAlignedTransactionRow(row) {
  return (
    String(row.id || '').startsWith('txn_') &&
    isIsoDate(row.txn_date) &&
    ['IN', 'OUT'].includes(String(row.direction || '').trim().toUpperCase()) &&
    String(row.fund_type || '').trim().length > 0 &&
    Number.isFinite(toNumber(row.amount))
  );
}

export function isAlignedBeneficiaryRow(row) {
  return (
    String(row.id || '').startsWith('ben_') &&
    String(row.name_bn || '').trim().length > 0
  );
}

export function isAlignedScholarshipRow(row) {
  return (
    String(row.id || '').startsWith('sp_') &&
    isMonthKey(row.month_key) &&
    Number.isFinite(toNumber(row.total_paid))
  );
}

export function buildFundTransactionRecords(migratedRows, existingAlignedRows = []) {
  const now = isoNow();
  const output = [];

  existingAlignedRows.forEach((row) => {
    output.push({
      id: String(row.id || stableId('txn_keep', row)),
      txn_date: String(row.txn_date || '').trim(),
      direction: String(row.direction || '').trim().toUpperCase(),
      fund_type: String(row.fund_type || '').trim(),
      amount: toNumber(row.amount),
      source_or_vendor: String(row.source_or_vendor || '').trim(),
      category: String(row.category || '').trim(),
      reference: String(row.reference || '').trim(),
      notes: String(row.notes || '').trim(),
      related_entity_type: String(row.related_entity_type || '').trim(),
      related_entity_id: String(row.related_entity_id || '').trim(),
      status: String(row.status || 'ACTIVE').trim() || 'ACTIVE',
      created_by: String(row.created_by || 'migration').trim(),
      created_at: String(row.created_at || now).trim() || now,
      updated_at: String(row.updated_at || now).trim() || now,
    });
  });

  migratedRows.forEach((row, index) => {
    const record = {
      txn_date: String(row.txn_date || '').trim(),
      direction: String(row.direction || 'IN').trim().toUpperCase(),
      fund_type: String(row.fund_type || 'GENERAL').trim(),
      amount: toNumber(row.amount),
      source_or_vendor: String(row.source_or_vendor || '').trim(),
      category: String(row.category || '').trim(),
      notes: String(row.notes || 'migrated').trim() || 'migrated',
    };
    if (!isIsoDate(record.txn_date) || record.amount <= 0) return;
    output.push({
      id: stableId('txn_mig', { ...record, index }),
      txn_date: record.txn_date,
      direction: record.direction,
      fund_type: record.fund_type,
      amount: record.amount,
      source_or_vendor: record.source_or_vendor,
      category: record.category,
      reference: '',
      notes: record.notes,
      related_entity_type: '',
      related_entity_id: '',
      status: 'ACTIVE',
      created_by: 'migration',
      created_at: now,
      updated_at: now,
    });
  });

  output.sort((a, b) => {
    const dateCmp = String(a.txn_date).localeCompare(String(b.txn_date));
    if (dateCmp !== 0) return dateCmp;
    return String(a.id).localeCompare(String(b.id));
  });
  return output;
}

export function buildBeneficiaryRecords(migratedRows, existingAlignedRows = []) {
  const now = isoNow();
  const output = [];

  existingAlignedRows.forEach((row) => {
    output.push({
      id: String(row.id || stableId('ben_keep', row)),
      serial_no: String(row.serial_no || '').trim(),
      name_bn: String(row.name_bn || '').trim(),
      age: String(row.age || '').trim(),
      guardian_status: String(row.guardian_status || '').trim(),
      class_name: String(row.class_name || '').trim(),
      primary_need: String(row.primary_need || '').trim(),
      monthly_need: String(row.monthly_need || '').trim(),
      monthly_need_amount: toNumber(row.monthly_need_amount),
      active: String(row.active || 'TRUE').trim().toUpperCase() === 'FALSE' ? 'FALSE' : 'TRUE',
      created_at: String(row.created_at || now).trim() || now,
      updated_at: String(row.updated_at || now).trim() || now,
    });
  });

  migratedRows.forEach((row, index) => {
    const record = {
      serial_no: String(row.serial_no || '').trim(),
      name_bn: String(row.name_bn || '').trim(),
      age: String(row.age || '').trim(),
      guardian_status: String(row.guardian_status || '').trim(),
      class_name: String(row.class_name || '').trim(),
      primary_need: String(row.primary_need || '').trim(),
      monthly_need: String(row.monthly_need || '').trim(),
      monthly_need_amount: toNumber(row.monthly_need_amount),
      active: String(row.active || 'TRUE').trim().toUpperCase() === 'FALSE' ? 'FALSE' : 'TRUE',
    };
    if (!record.name_bn) return;
    output.push({
      id: stableId('ben_mig', { ...record, index }),
      ...record,
      created_at: now,
      updated_at: now,
    });
  });

  output.sort((a, b) => {
    const serialCmp = String(a.serial_no).localeCompare(String(b.serial_no), undefined, {
      numeric: true,
    });
    if (serialCmp !== 0) return serialCmp;
    return String(a.name_bn).localeCompare(String(b.name_bn));
  });
  return output;
}

export function buildScholarshipPaymentRecords(
  migratedRows,
  beneficiaryRows,
  existingAlignedRows = []
) {
  const now = isoNow();
  const output = [];
  const beneficiaryIdByName = new Map(
    beneficiaryRows.map((row) => [String(row.name_bn || '').trim(), String(row.id || '').trim()])
  );

  existingAlignedRows.forEach((row) => {
    output.push({
      id: String(row.id || stableId('sp_keep', row)),
      month_key: String(row.month_key || '').trim(),
      beneficiary_id: String(row.beneficiary_id || '').trim(),
      school_fee: toNumber(row.school_fee),
      bangla_tutor: toNumber(row.bangla_tutor),
      arabi_tutor: toNumber(row.arabi_tutor),
      materials: toNumber(row.materials),
      other: toNumber(row.other),
      total_paid: toNumber(row.total_paid),
      remaining_amount: toNumber(row.remaining_amount),
      payment_date: String(row.payment_date || '').trim(),
      payment_status: String(row.payment_status || 'PAID').trim() || 'PAID',
      txn_id: String(row.txn_id || '').trim(),
      notes: String(row.notes || '').trim(),
    });
  });

  migratedRows.forEach((row, index) => {
    const monthKey = String(row.month_key || '').trim();
    const beneficiaryName = String(row.beneficiary_name || '').trim();
    const beneficiaryId = beneficiaryIdByName.get(beneficiaryName) || '';
    const record = {
      month_key: monthKey,
      beneficiary_id: beneficiaryId,
      school_fee: toNumber(row.school_fee),
      bangla_tutor: toNumber(row.bangla_tutor),
      arabi_tutor: toNumber(row.arabi_tutor),
      materials: toNumber(row.materials),
      other: toNumber(row.other),
      total_paid: toNumber(row.total_paid),
      remaining_amount: toNumber(row.remaining_amount),
      payment_date: isMonthKey(monthKey) ? `${monthKey}-01` : '',
      payment_status: String(row.payment_status || 'PAID').trim() || 'PAID',
      txn_id: '',
      notes: beneficiaryName ? `migrated:${beneficiaryName}` : 'migrated',
    };
    if (!record.month_key || !record.beneficiary_id) return;
    output.push({
      id: stableId('sp_mig', { ...record, index }),
      ...record,
    });
  });

  output.sort((a, b) => {
    const monthCmp = String(a.month_key).localeCompare(String(b.month_key));
    if (monthCmp !== 0) return monthCmp;
    return String(a.id).localeCompare(String(b.id));
  });
  return output;
}

export function rowsForHeaders(headers, records) {
  return records.map((record) => headers.map((header) => record[header] ?? ''));
}

export function readOfficialHeaders(rootDir, sheetCsvName) {
  const filePath = path.join(rootDir, 'sheets', sheetCsvName);
  return parseCsvFile(filePath).headers;
}
