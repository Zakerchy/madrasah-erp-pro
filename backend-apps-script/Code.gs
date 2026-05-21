/**
 * Madrasah ERP Lite - Apps Script Backend
 * Deploy as Web App (Execute as Me)
 */

const CONFIG = {
  SHEET_ID: 'PUT_YOUR_GOOGLE_SHEET_ID_HERE',
  SHEETS: {
    USERS: 'users_roles',
    TXN: 'fund_transactions',
    EXPENSE: 'expense_details',
    STAFF: 'salary_staff',
    SALARY: 'salary_payments',
    BENEFICIARIES: 'beneficiaries',
    SCHOLAR_PLAN: 'scholarship_monthly_plan',
    SCHOLAR_PAY: 'scholarship_payments',
    AUDIT: 'audit_log',
    SETTINGS: 'settings',
  },
  ENUMS: {
    ROLE: ['ADMIN', 'ACCOUNTANT', 'FIELD_USER', 'VIEWER'],
    DIRECTION: ['IN', 'OUT'],
    FUND: ['CONSTRUCTION', 'JAKAT', 'SCHOLARSHIP', 'GENERAL'],
    STATUS: ['ACTIVE', 'VOID'],
    SCHOLAR_STATUS: ['PAID', 'PARTIAL', 'CANCELLED'],
    SALARY_STATUS: ['PAID', 'PARTIAL', 'UNPAID'],
  },
};

function doGet(e) {
  try {
    const action = (e && e.parameter && e.parameter.action) || 'health';

    if (action === 'health') return json({ ok: true, message: 'Madrasah ERP API running', ts: nowIso() });
    if (action === 'listTransactions') return json(listTransactions_(e.parameter));
    if (action === 'dashboardSummary') return json(dashboardSummary_(e.parameter));
    if (action === 'listBeneficiaries') return json(listSheetRows_(CONFIG.SHEETS.BENEFICIARIES));
    if (action === 'listStaff') return json(listSheetRows_(CONFIG.SHEETS.STAFF));
    if (action === 'listSalaryPayments') return json(listSalaryPayments_(e.parameter));
    if (action === 'listScholarshipByMonth') return json(listScholarshipByMonth_(e.parameter));
    if (action === 'monthlyReport') return json(monthlyReport_(e.parameter));

    // Setup helper: generate hash from query pin for users_roles.pin_hash
    if (action === 'hashPin') {
      const pin = (e.parameter && e.parameter.pin) || '';
      if (!pin) return json({ ok: false, message: 'pin required' });
      return json({ ok: true, pin_hash: pinHash_(pin) });
    }

    return json({ ok: false, message: 'Unknown action' });
  } catch (err) {
    return json({ ok: false, error: String(err) });
  }
}

function doPost(e) {
  try {
    const body = JSON.parse((e && e.postData && e.postData.contents) || '{}');
    const action = body.action;

    if (action === 'login') return json(login_(body));

    if (action === 'createTransaction') {
      assertRole_(body.user_role, ['ADMIN', 'ACCOUNTANT', 'FIELD_USER']);
      return json(createTransaction_(body.payload));
    }

    if (action === 'updateTransaction') {
      assertRole_(body.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(updateTransaction_(body.id, body.payload));
    }

    if (action === 'upsertBeneficiary') {
      assertRole_(body.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(upsertById_(CONFIG.SHEETS.BENEFICIARIES, body.payload));
    }

    if (action === 'upsertStaff') {
      assertRole_(body.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(upsertById_(CONFIG.SHEETS.STAFF, body.payload));
    }

    if (action === 'recordSalaryPayment') {
      assertRole_(body.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(recordSalaryPayment_(body.payload));
    }

    if (action === 'saveScholarshipPayment') {
      assertRole_(body.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(saveScholarshipPayment_(body.payload));
    }

    return json({ ok: false, message: 'Unknown action' });
  } catch (err) {
    return json({ ok: false, error: String(err) });
  }
}

function login_(payload) {
  validateRequired_(payload, ['phone', 'pin']);
  const users = listSheetRows_(CONFIG.SHEETS.USERS).data || [];
  const user = users.find((u) => String(u.phone) === String(payload.phone) && String(u.active).toUpperCase() === 'TRUE');

  if (!user) return { ok: false, message: 'User not found or inactive' };

  const givenPin = String(payload.pin || '');
  const stored = String(user.pin_hash || '');
  const hashed = pinHash_(givenPin);

  // Backward compatibility:
  // If existing data has plain pin in pin_hash cell, login still works.
  const matched = stored && (stored === hashed || stored === givenPin);
  if (!matched) return { ok: false, message: 'Invalid PIN' };

  return {
    ok: true,
    data: {
      id: user.id,
      name: user.name,
      role: user.role,
      phone: user.phone,
    },
  };
}

function createTransaction_(payload) {
  validateTransactionPayload_(payload);

  const row = {
    id: payload.id || uid_('txn'),
    txn_date: payload.txn_date,
    direction: payload.direction,
    fund_type: payload.fund_type,
    amount: Number(payload.amount || 0),
    source_or_vendor: payload.source_or_vendor || '',
    category: payload.category || '',
    reference: payload.reference || '',
    notes: payload.notes || '',
    related_entity_type: payload.related_entity_type || '',
    related_entity_id: payload.related_entity_id || '',
    status: payload.status || 'ACTIVE',
    created_by: payload.created_by || '',
    created_at: nowIso(),
    updated_at: nowIso(),
  };

  appendRow_(CONFIG.SHEETS.TXN, row);
  addAudit_('fund_transactions', 'CREATE', row.id, '', JSON.stringify(row), row.created_by || 'system');

  return { ok: true, data: row };
}

function updateTransaction_(id, payload) {
  if (!id) throw new Error('id is required');
  if (payload.direction) validateEnum_(payload.direction, CONFIG.ENUMS.DIRECTION, 'direction');
  if (payload.fund_type) validateEnum_(payload.fund_type, CONFIG.ENUMS.FUND, 'fund_type');
  if (payload.status) validateEnum_(payload.status, CONFIG.ENUMS.STATUS, 'status');
  if (payload.amount !== undefined && Number(payload.amount) <= 0) throw new Error('amount must be > 0');

  const res = updateById_(CONFIG.SHEETS.TXN, id, payload || {});
  addAudit_('fund_transactions', 'UPDATE', id, JSON.stringify(res.before || {}), JSON.stringify(res.after || {}), payload.updated_by || 'system');
  return { ok: true, data: res.after };
}

function recordSalaryPayment_(payload) {
  validateRequired_(payload, ['staff_id', 'month_key', 'paid_amount', 'fund_type']);
  validateEnum_(payload.fund_type, CONFIG.ENUMS.FUND, 'fund_type');

  const salaryRow = {
    id: payload.id || uid_('salpay'),
    staff_id: payload.staff_id,
    month_key: payload.month_key,
    payable_amount: Number(payload.payable_amount || payload.paid_amount || 0),
    paid_amount: Number(payload.paid_amount || 0),
    due_amount: Number(payload.due_amount || 0),
    payment_date: payload.payment_date || todayIso_(),
    txn_id: payload.txn_id || '',
    status: payload.status || 'PAID',
    notes: payload.notes || '',
  };

  validateEnum_(salaryRow.status, CONFIG.ENUMS.SALARY_STATUS, 'salary.status');

  appendRow_(CONFIG.SHEETS.SALARY, salaryRow);

  const txn = createTransaction_({
    txn_date: salaryRow.payment_date,
    direction: 'OUT',
    fund_type: payload.fund_type,
    amount: salaryRow.paid_amount,
    source_or_vendor: payload.staff_name || 'Salary Payment',
    category: 'SALARY',
    notes: payload.notes || '',
    related_entity_type: 'SALARY',
    related_entity_id: salaryRow.id,
    created_by: payload.created_by || 'system',
  });

  return { ok: true, salary: salaryRow, transaction: txn.data };
}

function saveScholarshipPayment_(payload) {
  validateRequired_(payload, ['month_key', 'beneficiary_id', 'total_paid', 'fund_type']);
  validateEnum_(payload.fund_type, CONFIG.ENUMS.FUND, 'fund_type');

  const row = {
    id: payload.id || uid_('schpay'),
    month_key: payload.month_key,
    beneficiary_id: payload.beneficiary_id,
    school_fee: Number(payload.school_fee || 0),
    bangla_tutor: Number(payload.bangla_tutor || 0),
    arabi_tutor: Number(payload.arabi_tutor || 0),
    materials: Number(payload.materials || 0),
    other: Number(payload.other || 0),
    total_paid: Number(payload.total_paid || 0),
    remaining_amount: Number(payload.remaining_amount || 0),
    payment_date: payload.payment_date || todayIso_(),
    payment_status: payload.payment_status || 'PAID',
    txn_id: payload.txn_id || '',
    notes: payload.notes || '',
  };

  validateEnum_(row.payment_status, CONFIG.ENUMS.SCHOLAR_STATUS, 'payment_status');

  appendRow_(CONFIG.SHEETS.SCHOLAR_PAY, row);

  const txn = createTransaction_({
    txn_date: row.payment_date,
    direction: 'OUT',
    fund_type: payload.fund_type,
    amount: row.total_paid,
    source_or_vendor: payload.beneficiary_name || 'Scholarship Payment',
    category: 'SCHOLARSHIP_PAYMENT',
    notes: row.notes,
    related_entity_type: 'SCHOLARSHIP_PAYMENT',
    related_entity_id: row.id,
    created_by: payload.created_by || 'system',
  });

  return { ok: true, scholarshipPayment: row, transaction: txn.data };
}

function dashboardSummary_(params) {
  const txns = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const from = params.from || '';
  const to = params.to || '';

  const filtered = txns.filter((t) => {
    if (!t.txn_date) return false;
    if (from && t.txn_date < from) return false;
    if (to && t.txn_date > to) return false;
    return t.status !== 'VOID';
  });

  const summary = { totalIn: 0, totalOut: 0, balance: 0, byFund: {} };

  filtered.forEach((t) => {
    const amt = Number(t.amount || 0);
    const fund = t.fund_type || 'UNKNOWN';
    if (!summary.byFund[fund]) summary.byFund[fund] = { in: 0, out: 0, balance: 0 };

    if (t.direction === 'IN') {
      summary.totalIn += amt;
      summary.byFund[fund].in += amt;
    } else {
      summary.totalOut += amt;
      summary.byFund[fund].out += amt;
    }
  });

  Object.keys(summary.byFund).forEach((k) => {
    summary.byFund[k].balance = summary.byFund[k].in - summary.byFund[k].out;
  });

  summary.balance = summary.totalIn - summary.totalOut;
  return { ok: true, data: summary };
}

function monthlyReport_(params) {
  const monthKey = params.monthKey;
  if (!monthKey) return { ok: false, message: 'monthKey required' };

  const txns = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const monthly = txns.filter((t) => String(t.txn_date || '').slice(0, 7) === monthKey && t.status !== 'VOID');

  let totalIn = 0;
  let totalOut = 0;
  monthly.forEach((t) => {
    const amt = Number(t.amount || 0);
    if (t.direction === 'IN') totalIn += amt;
    else totalOut += amt;
  });

  return { ok: true, data: { monthKey, totalIn, totalOut, balance: totalIn - totalOut, rows: monthly } };
}

function listTransactions_(params) {
  const rows = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const fundType = params.fundType || '';
  const direction = params.direction || '';
  const from = params.from || '';
  const to = params.to || '';

  const filtered = rows.filter((r) => {
    if (fundType && r.fund_type !== fundType) return false;
    if (direction && r.direction !== direction) return false;
    if (from && r.txn_date < from) return false;
    if (to && r.txn_date > to) return false;
    return String(r.status || 'ACTIVE') !== 'VOID';
  });

  filtered.sort((a, b) => String(b.txn_date || '').localeCompare(String(a.txn_date || '')));
  return { ok: true, data: filtered };
}

function listSalaryPayments_(params) {
  const rows = listSheetRows_(CONFIG.SHEETS.SALARY).data || [];
  const monthKey = params.monthKey || '';
  const staffId = params.staffId || '';

  const filtered = rows.filter((r) => {
    if (monthKey && String(r.month_key || '') !== monthKey) return false;
    if (staffId && String(r.staff_id || '') !== staffId) return false;
    return true;
  });

  filtered.sort((a, b) => String(b.payment_date || '').localeCompare(String(a.payment_date || '')));
  return { ok: true, data: filtered };
}

function listScholarshipByMonth_(params) {
  const rows = listSheetRows_(CONFIG.SHEETS.SCHOLAR_PAY).data || [];
  const monthKey = params.monthKey || '';
  const beneficiaryId = params.beneficiaryId || '';

  const filtered = rows.filter((r) => {
    if (monthKey && String(r.month_key || '') !== monthKey) return false;
    if (beneficiaryId && String(r.beneficiary_id || '') !== beneficiaryId) return false;
    return true;
  });

  filtered.sort((a, b) => String(b.payment_date || '').localeCompare(String(a.payment_date || '')));
  return { ok: true, data: filtered };
}

function listSheetRows_(sheetName) {
  const sheet = getSheet_(sheetName);
  const values = sheet.getDataRange().getValues();
  if (!values.length) return { ok: true, data: [] };

  const headers = values[0].map(String);
  const rows = [];
  for (let i = 1; i < values.length; i++) {
    const row = values[i];
    if (!row.join('').trim()) continue;
    const obj = {};
    headers.forEach((h, idx) => (obj[h] = row[idx]));
    rows.push(obj);
  }
  return { ok: true, data: rows };
}

function appendRow_(sheetName, obj) {
  const sheet = getSheet_(sheetName);
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0].map(String);
  const row = headers.map((h) => (obj[h] !== undefined ? obj[h] : ''));
  sheet.appendRow(row);
}

function upsertById_(sheetName, payload) {
  validateRequired_(payload, ['id']);
  const found = findRowById_(sheetName, payload.id);
  if (!found) {
    const newObj = Object.assign({}, payload);
    if (!newObj.created_at) newObj.created_at = nowIso();
    newObj.updated_at = nowIso();
    appendRow_(sheetName, newObj);
    addAudit_(sheetName, 'CREATE', newObj.id, '', JSON.stringify(newObj), payload.updated_by || 'system');
    return { ok: true, mode: 'create', data: newObj };
  }

  const result = updateById_(sheetName, payload.id, payload);
  addAudit_(sheetName, 'UPDATE', payload.id, JSON.stringify(result.before), JSON.stringify(result.after), payload.updated_by || 'system');
  return { ok: true, mode: 'update', data: result.after };
}

function updateById_(sheetName, id, patch) {
  const found = findRowById_(sheetName, id);
  if (!found) throw new Error('Row not found: ' + id);

  const headers = found.headers;
  const before = Object.assign({}, found.rowObj);
  const after = Object.assign({}, found.rowObj, patch, { updated_at: nowIso() });
  const writeRow = headers.map((h) => (after[h] !== undefined ? after[h] : ''));

  found.sheet.getRange(found.rowIndex, 1, 1, writeRow.length).setValues([writeRow]);
  return { before, after };
}

function findRowById_(sheetName, id) {
  const sheet = getSheet_(sheetName);
  const values = sheet.getDataRange().getValues();
  if (values.length < 2) return null;
  const headers = values[0].map(String);
  const idIdx = headers.indexOf('id');
  if (idIdx === -1) throw new Error('No id column in ' + sheetName);

  for (let i = 1; i < values.length; i++) {
    const row = values[i];
    if (String(row[idIdx]) === String(id)) {
      const rowObj = {};
      headers.forEach((h, idx) => (rowObj[h] = row[idx]));
      return { sheet, headers, rowIndex: i + 1, rowObj };
    }
  }
  return null;
}

function addAudit_(module, action, entityId, beforeJson, afterJson, doneBy) {
  const row = {
    id: uid_('audit'),
    module,
    action,
    entity_id: entityId,
    before_json: beforeJson || '',
    after_json: afterJson || '',
    done_by: doneBy || 'system',
    done_at: nowIso(),
  };
  appendRow_(CONFIG.SHEETS.AUDIT, row);
}

function assertRole_(currentRole, allowedRoles) {
  if (!currentRole) throw new Error('user_role is required');
  validateEnum_(currentRole, CONFIG.ENUMS.ROLE, 'user_role');
  if (allowedRoles.indexOf(currentRole) === -1) {
    throw new Error('Permission denied for role: ' + currentRole);
  }
}

function validateTransactionPayload_(payload) {
  validateRequired_(payload, ['txn_date', 'direction', 'fund_type', 'amount']);
  validateEnum_(payload.direction, CONFIG.ENUMS.DIRECTION, 'direction');
  validateEnum_(payload.fund_type, CONFIG.ENUMS.FUND, 'fund_type');
  if (Number(payload.amount || 0) <= 0) throw new Error('amount must be > 0');
}

function validateRequired_(obj, fields) {
  fields.forEach((f) => {
    if (obj[f] === undefined || obj[f] === null || obj[f] === '') {
      throw new Error('Missing required field: ' + f);
    }
  });
}

function validateEnum_(value, allowed, fieldName) {
  if (allowed.indexOf(value) === -1) {
    throw new Error(fieldName + ' invalid value: ' + value + '. Allowed: ' + allowed.join(','));
  }
}

function getSheet_(sheetName) {
  const ss = SpreadsheetApp.openById(CONFIG.SHEET_ID);
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) throw new Error('Sheet not found: ' + sheetName);
  return sheet;
}

function uid_(prefix) {
  return prefix + '_' + Utilities.getUuid().slice(0, 8);
}

function nowIso() {
  return new Date().toISOString();
}

function todayIso_() {
  return Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyy-MM-dd');
}

function pinHash_(pin) {
  const bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, String(pin), Utilities.Charset.UTF_8);
  return bytes.map(function (b) {
    const v = (b + 256) % 256;
    return (v < 16 ? '0' : '') + v.toString(16);
  }).join('');
}

function json(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
