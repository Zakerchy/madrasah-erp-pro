/**
 * Madrasah ERP Lite - Apps Script Backend
 * Deploy as Web App (Execute as Me)
 */

const CONFIG = {
  SHEET_ID_FALLBACK: '1oDjX_FS0F0_4ZjZM0YBS-TLHFRmYwbNRCPKhcTUxr3Y',
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

// Route both GET and POST through a single handler so the Flutter app
// can use HTTP POST for all requests (simpler client code).
function doGet(e) {
  try {
    const params = (e && e.parameter) || {};
    if (params.action === 'resetPinForm') return servePinResetForm_(params);
    if (params.action === 'confirmPinReset') {
      const r = confirmPinReset_(params);
      const msg = r.ok
        ? '<h2 style="color:#166534">✅ পিন রিসেট সফল হয়েছে</h2><p>ব্যবহারকারীকে নতুন পিন জানিয়ে দিন।</p>'
        : '<h2 style="color:#991b1b">❌ ত্রুটি</h2><p>' + (r.message || 'অজানা ত্রুটি') + '</p>';
      return HtmlService.createHtmlOutput('<html><body style="font-family:sans-serif;text-align:center;padding:40px">' + msg + '</body></html>');
    }
    return handleRequest_(params);
  } catch (err) {
    return json({ ok: false, error: String(err) });
  }
}

function doPost(e) {
  try {
    const body = JSON.parse((e && e.postData && e.postData.contents) || '{}');
    return handleRequest_(body);
  } catch (err) {
    return json({ ok: false, error: String(err) });
  }
}

function handleRequest_(params) {
  params = params || {};
  const action = params.action || 'health';

  try {
    if (action === 'health') {
      return json({
        ok: true,
        message: 'Madrasah ERP API চালু আছে',
        ts: nowIso(),
        sheetId: getSheetId_(),
      });
    }

    // Helper: generate PIN hash for admin to fill in users_roles sheet
    if (action === 'hashPin') {
      const pin = params.pin || '';
      if (!pin) return json({ ok: false, message: 'pin required' });
      return json({ ok: true, pin_hash: pinHash_(pin) });
    }

    // Read actions (also allowed via POST body)
    if (action === 'dashboardSummary') return json(dashboardSummary_(params));
    if (action === 'listTransactions') return json(listTransactions_(params));
    if (action === 'listBeneficiaries') return json(listBeneficiaries_(params));
    if (action === 'listStaff') return json(listStaff_(params));
    if (action === 'listSalaryPayments') return json(listSalaryPayments_(params));
    if (action === 'listScholarshipByMonth') return json(listScholarshipByMonth_(params));
    if (action === 'monthlyReport') return json(monthlyReport_(params));

    // Write actions
    if (action === 'login') return json(login_(params));
    if (action === 'requestPinReset') return json(requestPinReset_(params));
    if (action === 'confirmPinReset') return json(confirmPinReset_(params));

    if (action === 'createTransaction') {
      assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT', 'FIELD_USER']);
      return json(createTransaction_(params.payload));
    }

    if (action === 'updateTransaction') {
      assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(updateTransaction_(params.id, params.payload));
    }

    if (action === 'upsertBeneficiary') {
      assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(upsertById_(CONFIG.SHEETS.BENEFICIARIES, params.payload));
    }

    if (action === 'upsertStaff') {
      assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(upsertById_(CONFIG.SHEETS.STAFF, params.payload));
    }

    if (action === 'recordSalaryPayment') {
      assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(recordSalaryPayment_(params.payload));
    }

    if (action === 'saveScholarshipPayment') {
      assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT']);
      return json(saveScholarshipPayment_(params.payload));
    }

    if (action === 'listUsers') return json(listUsers_(params));

    if (action === 'upsertUser') {
      assertRole_(params.user_role, ['ADMIN']);
      return json(upsertById_(CONFIG.SHEETS.USERS, params.payload));
    }

    if (action === 'setUserApprovalStatus') {
      assertRole_(params.user_role, ['ADMIN']);
      return json(setUserApprovalStatus_(params.payload));
    }

    if (action === 'generateTempResetToken') {
      assertRole_(params.user_role, ['ADMIN']);
      return json(generateTempResetToken_(params.payload));
    }

    if (action === 'importMigratedData') {
      const secret = String(params.import_secret || '');
      if (secret !== 'MADRASAH_IMPORT_2025') return json({ ok: false, message: 'unauthorized' });
      return json(importMigratedData_(String(params.sheet_name || ''), params.rows || []));
    }

    return json({ ok: false, message: 'Unknown action: ' + action });
  } catch (err) {
    return json({ ok: false, error: String(err) });
  }
}

function login_(payload) {
  validateRequired_(payload, ['email']);

  const email = String(payload.email || '').trim().toLowerCase();
  const pinHash = String(payload.pin_hash || '').trim();
  const users = listSheetRows_(CONFIG.SHEETS.USERS).data || [];

  // Bootstrap: if sheet is empty, create first admin from hardcoded email
  const bootstrapEmail = 'zakerchy@gmail.com';
  if (users.length === 0 && email === bootstrapEmail) {
    const boot = {
      id: 'u_admin_bootstrap',
      name: 'Admin',
      phone: '',
      email: bootstrapEmail,
      role: 'ADMIN',
      active: 'TRUE',
      approval_status: 'APPROVED',
      pin_hash: '',
      created_at: nowIso(),
      updated_at: nowIso(),
    };
    appendRow_(CONFIG.SHEETS.USERS, boot);
    return { ok: true, data: { id: boot.id, name: boot.name, role: boot.role, phone: '', email: boot.email, approval_status: 'APPROVED' } };
  }

  const anyUser = users.find(u => String(u.email || '').trim().toLowerCase() === email);
  if (!anyUser) {
    return { ok: false, message: 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই' };
  }

  const status = String(anyUser.approval_status || 'APPROVED').toUpperCase();
  if (status === 'PENDING') return { ok: false, message: 'অনুমোদনের অপেক্ষায় আছেন। Admin-এর সাথে যোগাযোগ করুন।' };
  if (status === 'REJECTED') return { ok: false, message: 'অ্যাকাউন্ট রিজেক্ট করা হয়েছে।' };
  if (status === 'BLOCKED') return { ok: false, message: 'অ্যাকাউন্ট ব্লক করা হয়েছে।' };

  const active = String(anyUser.active || '').toUpperCase() === 'TRUE';
  if (!active) return { ok: false, message: 'অ্যাকাউন্ট নিষ্ক্রিয় করা হয়েছে।' };

  // PIN verification: if stored pin_hash is set, client must provide matching hash
  const storedPinHash = String(anyUser.pin_hash || '').trim();
  if (storedPinHash && pinHash && storedPinHash !== pinHash) {
    return { ok: false, message: 'পিন ভুল। আবার চেষ্টা করুন।' };
  }

  return {
    ok: true,
    data: {
      id: anyUser.id,
      name: anyUser.name,
      role: anyUser.role || 'VIEWER',
      phone: anyUser.phone || '',
      email: anyUser.email || '',
      approval_status: status,
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
  params = params || {};
  assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT', 'FIELD_USER', 'VIEWER']);
  const role = String(params.user_role || '');
  const userId = String(params.user_id || '');
  requireUserIdIfFieldRole_(role, userId);

  const txns = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const from = params.from || '';
  const to = params.to || '';

  const filtered = txns.filter((t) => {
    if (!t.txn_date) return false;
    if (from && t.txn_date < from) return false;
    if (to && t.txn_date > to) return false;
    return String(t.status || 'ACTIVE') !== 'VOID';
  });

  const scoped = role === 'FIELD_USER'
    ? filtered.filter((r) => String(r.created_by || '') === userId)
    : filtered;

  const summary = { totalIn: 0, totalOut: 0, balance: 0, byFund: {} };

  scoped.forEach((t) => {
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

  // Separation calculations (mirrors Excel dashboard top rows)
  const zakatIn = (summary.byFund['JAKAT'] || { in: 0 }).in;
  const scholarshipIn = (summary.byFund['SCHOLARSHIP'] || { in: 0 }).in;
  summary.totalFound = summary.totalIn;
  summary.balanceExclZakat = summary.totalIn - zakatIn;
  summary.balanceExclZakatScholarship = summary.balanceExclZakat - scholarshipIn;

  return { ok: true, data: summary };
}

function monthlyReport_(params) {
  params = params || {};
  assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT', 'FIELD_USER', 'VIEWER']);
  const role = String(params.user_role || '');
  const userId = String(params.user_id || '');
  requireUserIdIfFieldRole_(role, userId);

  const monthKey = params.monthKey;
  if (!monthKey) return { ok: false, message: 'monthKey required' };

  const txns = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const monthly = txns.filter((t) => String(t.txn_date || '').slice(0, 7) === monthKey && String(t.status || 'ACTIVE') !== 'VOID');

  const scoped = role === 'FIELD_USER'
    ? monthly.filter((r) => String(r.created_by || '') === userId)
    : monthly;

  let totalIn = 0;
  let totalOut = 0;
  scoped.forEach((t) => {
    const amt = Number(t.amount || 0);
    if (t.direction === 'IN') totalIn += amt;
    else totalOut += amt;
  });

  const rows = role === 'VIEWER' ? [] : scoped;
  return { ok: true, data: { monthKey, totalIn, totalOut, balance: totalIn - totalOut, rows } };
}

function listTransactions_(params) {
  params = params || {};
  assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT', 'FIELD_USER', 'VIEWER']);
  const role = String(params.user_role || '');
  const userId = String(params.user_id || '');
  requireUserIdIfFieldRole_(role, userId);

  if (role === 'VIEWER') return { ok: true, data: [] };

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
    if (String(r.status || 'ACTIVE') === 'VOID') return false;
    if (role === 'FIELD_USER' && String(r.created_by || '') !== userId) return false;
    return true;
  });

  filtered.sort((a, b) => String(b.txn_date || '').localeCompare(String(a.txn_date || '')));
  return { ok: true, data: filtered };
}

function listBeneficiaries_(params) {
  params = params || {};
  assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT', 'VIEWER']);
  return listSheetRows_(CONFIG.SHEETS.BENEFICIARIES);
}

function listStaff_(params) {
  params = params || {};
  assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT', 'VIEWER']);
  return listSheetRows_(CONFIG.SHEETS.STAFF);
}

function listSalaryPayments_(params) {
  params = params || {};
  assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT', 'VIEWER']);

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
  params = params || {};
  assertRole_(params.user_role, ['ADMIN', 'ACCOUNTANT', 'VIEWER']);

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

function requireUserIdIfFieldRole_(role, userId) {
  if (role === 'FIELD_USER' && !userId) {
    throw new Error('user_id is required for FIELD_USER scope');
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
  const ss = SpreadsheetApp.openById(getSheetId_());
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) throw new Error('Sheet not found: ' + sheetName);
  return sheet;
}

function getSheetId_() {
  const fromProp = PropertiesService.getScriptProperties().getProperty('SHEET_ID');
  if (fromProp && String(fromProp).trim()) return String(fromProp).trim();
  return CONFIG.SHEET_ID_FALLBACK;
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

function requestPinReset_(params) {
  const email = String(params.email || '').trim().toLowerCase();
  if (!email) return { ok: false, message: 'ইমেইল প্রয়োজন' };

  const users = listSheetRows_(CONFIG.SHEETS.USERS).data || [];
  const user = users.find(u => String(u.email || '').trim().toLowerCase() === email);
  if (!user) return { ok: false, message: 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই' };

  const token = String(Math.floor(100000 + Math.random() * 900000));
  const expiry = Date.now() + 30 * 60 * 1000;
  PropertiesService.getScriptProperties().setProperty('reset_' + email, token + '_' + expiry);

  const webAppUrl = ScriptApp.getService().getUrl();
  const resetUrl = webAppUrl + '?action=resetPinForm&token=' + token + '&email=' + encodeURIComponent(email);

  const adminEmail = 'zakerchy@gmail.com';
  GmailApp.sendEmail(
    adminEmail,
    'পিন রিসেট অনুরোধ — ' + user.name,
    'ব্যবহারকারী: ' + user.name + '\nইমেইল: ' + email + '\n\nপিন রিসেট লিংক:\n' + resetUrl + '\n\n৩০ মিনিটের মধ্যে করতে হবে।',
    {
      name: 'মাদ্রাসা ERP',
      htmlBody: '<p><b>ব্যবহারকারী:</b> ' + user.name + '<br><b>ইমেইল:</b> ' + email + '</p>' +
        '<p><a href="' + resetUrl + '" style="background:#166534;color:white;padding:10px 20px;text-decoration:none;border-radius:6px">পিন রিসেট করুন</a></p>' +
        '<p style="color:#666;font-size:12px">লিংকটি ৩০ মিনিটের মধ্যে ব্যবহার করুন।</p>'
    }
  );

  return { ok: true, message: 'Admin-এর ইমেইলে রিসেট লিংক পাঠানো হয়েছে। কিছুক্ষণ অপেক্ষা করুন।' };
}

function servePinResetForm_(params) {
  const token = String(params.token || '');
  const email = String(params.email || '');
  const webAppUrl = ScriptApp.getService().getUrl();
  const confirmUrl = webAppUrl + '?action=confirmPinReset&token=' + encodeURIComponent(token) + '&email=' + encodeURIComponent(email);

  const html = '<!DOCTYPE html><html lang="bn"><head><meta charset="UTF-8">' +
    '<meta name="viewport" content="width=device-width,initial-scale=1">' +
    '<title>পিন রিসেট — মাদ্রাসা ERP</title>' +
    '<style>body{font-family:sans-serif;max-width:380px;margin:40px auto;padding:20px;background:#f0fdf4}' +
    'h2{color:#166534}label{font-size:14px;color:#374151}' +
    'input{width:100%;padding:10px;margin:8px 0 16px;border:1px solid #d1d5db;border-radius:8px;font-size:18px;box-sizing:border-box}' +
    'button{background:#166534;color:white;padding:12px;border:none;border-radius:8px;cursor:pointer;font-size:16px;width:100%}' +
    'p.info{color:#6b7280;font-size:13px}</style></head>' +
    '<body><h2>🔑 পিন রিসেট</h2>' +
    '<p>ব্যবহারকারীর ইমেইল: <b>' + email + '</b></p>' +
    '<form id="f"><label>নতুন পিন (৪-৬ সংখ্যা):</label>' +
    '<input type="password" inputmode="numeric" id="pin" maxlength="6" placeholder="নতুন পিন" required>' +
    '<button type="submit">পিন সেট করুন</button></form>' +
    '<p class="info">পিন সেট হওয়ার পর ব্যবহারকারীকে জানিয়ে দিন।</p>' +
    '<script>document.getElementById("f").onsubmit=async function(e){' +
    'e.preventDefault();const p=document.getElementById("pin").value.trim();' +
    'if(p.length<4){alert("পিন কমপক্ষে ৪ সংখ্যার হতে হবে");return;}' +
    'const buf=await crypto.subtle.digest("SHA-256",new TextEncoder().encode(p));' +
    'const hash=Array.from(new Uint8Array(buf)).map(x=>x.toString(16).padStart(2,"0")).join("");' +
    'window.location.href="' + confirmUrl + '&new_pin_hash="+hash;' +
    '};</script></body></html>';

  return HtmlService.createHtmlOutput(html).setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function confirmPinReset_(params) {
  const token = String(params.token || '').trim();
  const email = String(params.email || '').trim().toLowerCase();
  const newPinHash = String(params.new_pin_hash || '').trim();

  if (!token || !email || !newPinHash) return { ok: false, message: 'অসম্পূর্ণ তথ্য' };

  const stored = PropertiesService.getScriptProperties().getProperty('reset_' + email);
  if (!stored) return { ok: false, message: 'রিসেট টোকেন পাওয়া যায়নি বা মেয়াদ শেষ' };

  const parts = stored.split('_');
  if (parts[0] !== token) return { ok: false, message: 'টোকেন অবৈধ' };
  if (Date.now() > parseInt(parts[1])) return { ok: false, message: 'রিসেট লিংকের মেয়াদ ৩০ মিনিট পার হয়ে গেছে' };

  const ss = SpreadsheetApp.openById(getSheetId_());
  const sheet = ss.getSheetByName(CONFIG.SHEETS.USERS);
  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const emailIdx = headers.indexOf('email');
  const pinHashIdx = headers.indexOf('pin_hash');
  const updatedAtIdx = headers.indexOf('updated_at');

  let updated = false;
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][emailIdx] || '').trim().toLowerCase() === email) {
      sheet.getRange(i + 1, pinHashIdx + 1).setValue(newPinHash);
      if (updatedAtIdx >= 0) sheet.getRange(i + 1, updatedAtIdx + 1).setValue(nowIso());
      updated = true;
      break;
    }
  }

  if (!updated) return { ok: false, message: 'ব্যবহারকারী খুঁজে পাওয়া যায়নি' };
  PropertiesService.getScriptProperties().deleteProperty('reset_' + email);
  return { ok: true, message: 'পিন সফলভাবে রিসেট হয়েছে' };
}

function listUsers_(params) {
  params = params || {};
  assertRole_(params.user_role, ['ADMIN']);
  const users = listSheetRows_(CONFIG.SHEETS.USERS).data || [];
  return {
    ok: true,
    data: users.map(function(u) {
      return {
        id: u.id, name: u.name, email: u.email, phone: u.phone,
        role: u.role, active: u.active, approval_status: u.approval_status,
      };
    }),
  };
}

function setUserApprovalStatus_(payload) {
  validateRequired_(payload, ['id', 'approval_status']);
  const validStatuses = ['APPROVED', 'PENDING', 'REJECTED', 'BLOCKED'];
  if (validStatuses.indexOf(String(payload.approval_status)) === -1) {
    throw new Error('Invalid approval_status: ' + payload.approval_status);
  }
  const res = updateById_(CONFIG.SHEETS.USERS, payload.id, { approval_status: payload.approval_status });
  return { ok: true, data: res.after };
}

function generateTempResetToken_(payload) {
  validateRequired_(payload, ['id']);
  const users = listSheetRows_(CONFIG.SHEETS.USERS).data || [];
  const user = users.find(function(u) { return String(u.id || '') === String(payload.id); });
  if (!user) return { ok: false, message: 'User not found' };

  const token = String(Math.floor(100000 + Math.random() * 900000));
  const expiresInMinutes = Number(payload.expires_in_minutes || 30);
  const expiry = Date.now() + expiresInMinutes * 60 * 1000;
  PropertiesService.getScriptProperties().setProperty('reset_' + String(user.email || '').toLowerCase(), token + '_' + expiry);

  const webAppUrl = ScriptApp.getService().getUrl();
  const resetUrl = webAppUrl + '?action=resetPinForm&token=' + token + '&email=' + encodeURIComponent(String(user.email || '').toLowerCase());

  return { ok: true, data: { token: token, expires_at: new Date(expiry).toISOString(), reset_url: resetUrl } };
}

function importMigratedData_(sheetName, rows) {
  if (!sheetName || !Array.isArray(rows)) return { ok: false, message: 'sheet_name and rows array required' };
  const now = nowIso();
  const today = todayIso_();
  let count = 0;

  if (sheetName === 'fund_transactions') {
    const existing = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
    if (existing.length > 0) return { ok: false, message: 'fund_transactions already has ' + existing.length + ' rows. Clear first.' };
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      appendRow_(CONFIG.SHEETS.TXN, {
        id: uid_('txn'),
        txn_date: String(r.txn_date || today),
        direction: String(r.direction || 'IN'),
        fund_type: String(r.fund_type || 'GENERAL'),
        amount: Number(r.amount || 0),
        source_or_vendor: String(r.source_or_vendor || ''),
        category: String(r.category || ''),
        reference: '',
        notes: String(r.notes || 'migrated'),
        related_entity_type: '',
        related_entity_id: '',
        status: 'ACTIVE',
        created_by: 'migration',
        created_at: now,
        updated_at: now,
      });
      count++;
    }
    return { ok: true, imported: count };
  }

  if (sheetName === 'beneficiaries') {
    const existing = listSheetRows_(CONFIG.SHEETS.BENEFICIARIES).data || [];
    if (existing.length > 0) return { ok: false, message: 'beneficiaries already has ' + existing.length + ' rows.' };
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      appendRow_(CONFIG.SHEETS.BENEFICIARIES, {
        id: uid_('ben'),
        serial_no: String(r.serial_no || ''),
        name_bn: String(r.name_bn || ''),
        age: String(r.age || ''),
        guardian_status: String(r.guardian_status || ''),
        class_name: String(r.class_name || ''),
        primary_need: String(r.primary_need || ''),
        monthly_need: String(r.monthly_need || ''),
        monthly_need_amount: Number(r.monthly_need_amount || 0),
        active: String(r.active || 'TRUE').toString().toUpperCase() === 'FALSE' ? 'FALSE' : 'TRUE',
        created_at: now,
        updated_at: now,
      });
      count++;
    }
    return { ok: true, imported: count };
  }

  if (sheetName === 'scholarship_payments') {
    const existing = listSheetRows_(CONFIG.SHEETS.SCHOLAR_PAY).data || [];
    if (existing.length > 0) return { ok: false, message: 'scholarship_payments already has ' + existing.length + ' rows.' };
    const bens = listSheetRows_(CONFIG.SHEETS.BENEFICIARIES).data || [];
    const nameToId = {};
    for (let i = 0; i < bens.length; i++) {
      nameToId[String(bens[i].name_bn || '').trim()] = String(bens[i].id || '');
    }
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const benName = String(r.beneficiary_name || '').trim();
      appendRow_(CONFIG.SHEETS.SCHOLAR_PAY, {
        id: uid_('sp'),
        month_key: String(r.month_key || ''),
        beneficiary_id: nameToId[benName] || '',
        school_fee: Number(r.school_fee || 0),
        bangla_tutor: Number(r.bangla_tutor || 0),
        arabi_tutor: Number(r.arabi_tutor || 0),
        materials: Number(r.materials || 0),
        other: Number(r.other || 0),
        total_paid: Number(r.total_paid || 0),
        remaining_amount: Number(r.remaining_amount || 0),
        payment_date: r.month_key ? String(r.month_key) + '-01' : today,
        payment_status: String(r.payment_status || 'PAID'),
        txn_id: '',
        notes: benName,
      });
      count++;
    }
    return { ok: true, imported: count };
  }

  return { ok: false, message: 'Unknown sheet_name: ' + sheetName };
}

// One-time setup: call this once from Apps Script editor to set Sheet ID property
function setupSheetId() {
  PropertiesService.getScriptProperties().setProperty('SHEET_ID', '1oDjX_FS0F0_4ZjZM0YBS-TLHFRmYwbNRCPKhcTUxr3Y');
  Logger.log('SHEET_ID set: ' + PropertiesService.getScriptProperties().getProperty('SHEET_ID'));
}
