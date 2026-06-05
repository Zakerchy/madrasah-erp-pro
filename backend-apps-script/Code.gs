/**
 * Madrasah ERP Pro - Apps Script Backend
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
    STUDENTS: 'students',
    GUARDIANS: 'student_guardians',
    CLASSES: 'classes',
    SECTIONS: 'sections',
    SUBJECTS: 'subjects',
    ATTENDANCE: 'student_attendance',
    EXAM_TERMS: 'exam_terms',
    EXAM_MARKS: 'exam_marks',
    FEE_PLANS: 'fee_plans',
    FEE_PAYMENTS: 'fee_payments',
    FEE_WAIVERS: 'fee_waivers',
    BUDGETS: 'finance_budgets',
    APPROVAL_RULES: 'approval_rules',
    APPROVAL_REQUESTS: 'approval_requests',
    RECONCILIATION: 'reconciliation_snapshots',
    NOTICES: 'notices',
    NOTICE_READS: 'notice_reads',
    DOCUMENTS: 'document_vault',
    AUDIT: 'audit_log',
    SETTINGS: 'settings',
    NOTIFICATIONS: 'notifications',
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

const MAX_REPORT_RANGE_DAYS = 3653;
const ROLE_DEFINITIONS_SETTING_KEY = 'roles.definitions';

const APP_PERMISSIONS = [
  'dashboard.view',
  'donations.view',
  'donations.write',
  'transactions.manage',
  'expenses.view',
  'expenses.write',
  'beneficiaries.view',
  'beneficiaries.write',
  'salary.view',
  'salary.write',
  'scholarship.view',
  'scholarship.write',
  'academic.foundation.view',
  'academic.foundation.write',
  'academic.core.view',
  'academic.core.write',
  'academic.attendance.write',
  'fees.view',
  'fees.write',
  'finance.view',
  'finance.write',
  'finance.approval_rules.manage',
  'finance.approval_requests.create',
  'finance.approval_requests.decide',
  'communication.view',
  'communication.write',
  'reports.view',
  'settings.view',
  'users.manage',
  'roles.view',
  'roles.manage',
  'notifications.view',
  'notifications.manage',
  'app_ui.manage',
  'audit.view',
];

const ACTION_PERMISSIONS = {
  dashboardSummary: 'dashboard.view',
  listTransactions: 'donations.view',
  listBeneficiaries: 'beneficiaries.view',
  listStaff: 'salary.view',
  listSalaryPayments: 'salary.view',
  listScholarshipByMonth: 'scholarship.view',
  listStudents: 'academic.foundation.view',
  listStudentGuardians: 'academic.foundation.view',
  listClasses: 'academic.foundation.view',
  listSections: 'academic.foundation.view',
  listSubjects: 'academic.foundation.view',
  listAttendance: 'academic.core.view',
  listExamTerms: 'academic.core.view',
  listExamMarks: 'academic.core.view',
  resultSummary: 'academic.core.view',
  listFeePlans: 'fees.view',
  listFeePayments: 'fees.view',
  listFeeWaivers: 'fees.view',
  listFeeDues: 'fees.view',
  listBudgets: 'finance.view',
  financeControlSummary: 'finance.view',
  listApprovalRules: 'finance.view',
  listApprovalRequests: 'finance.view',
  listNotices: 'communication.view',
  listDocuments: 'communication.view',
  monthlyReport: 'reports.view',
  rangeReport: 'reports.view',
  datasetStats: 'reports.view',
  getAppUiSettings: 'reports.view',
  listAuditLog: 'audit.view',
  getNotificationSettings: 'notifications.manage',
  listInAppNotifications: 'notifications.view',
  listRoleDefinitions: 'roles.view',
  createTransaction: 'donations.write',
  updateTransaction: 'transactions.manage',
  upsertBeneficiary: 'beneficiaries.write',
  upsertStaff: 'salary.write',
  recordSalaryPayment: 'salary.write',
  saveScholarshipPayment: 'scholarship.write',
  upsertStudent: 'academic.foundation.write',
  upsertStudentGuardian: 'academic.foundation.write',
  upsertClass: 'academic.foundation.write',
  upsertSection: 'academic.foundation.write',
  upsertSubject: 'academic.foundation.write',
  saveAttendance: 'academic.attendance.write',
  upsertExamTerm: 'academic.core.write',
  saveExamMark: 'academic.core.write',
  upsertFeePlan: 'fees.write',
  recordFeePayment: 'fees.write',
  upsertFeeWaiver: 'fees.write',
  upsertBudget: 'finance.write',
  upsertApprovalRule: 'finance.approval_rules.manage',
  createApprovalRequest: 'finance.approval_requests.create',
  decideApprovalRequest: 'finance.approval_requests.decide',
  publishNotice: 'communication.write',
  markNoticeRead: 'communication.view',
  upsertDocument: 'communication.write',
  listUsers: 'users.manage',
  upsertUser: 'users.manage',
  setUserApprovalStatus: 'users.manage',
  generateTempResetToken: 'users.manage',
  upsertNotificationSettings: 'notifications.manage',
  upsertAppUiSettings: 'app_ui.manage',
  createNotificationEvent: 'notifications.view',
  upsertRoleDefinition: 'roles.manage',
  logClientGuard: 'notifications.view',
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

    params.action = action;
    assertActionPermission_(params, action);

    // Read actions (also allowed via POST body)
    if (action === 'dashboardSummary') return json(dashboardSummary_(params));
    if (action === 'listTransactions') return json(listTransactions_(params));
    if (action === 'listBeneficiaries') return json(listBeneficiaries_(params));
    if (action === 'listStaff') return json(listStaff_(params));
    if (action === 'listSalaryPayments') return json(listSalaryPayments_(params));
    if (action === 'listScholarshipByMonth') return json(listScholarshipByMonth_(params));
    if (action === 'listStudents') return json(listStudents_(params));
    if (action === 'listStudentGuardians') return json(listStudentGuardians_(params));
    if (action === 'listClasses') return json(listClasses_(params));
    if (action === 'listSections') return json(listSections_(params));
    if (action === 'listSubjects') return json(listSubjects_(params));
    if (action === 'listAttendance') return json(listAttendance_(params));
    if (action === 'listExamTerms') return json(listExamTerms_(params));
    if (action === 'listExamMarks') return json(listExamMarks_(params));
    if (action === 'resultSummary') return json(resultSummary_(params));
    if (action === 'listFeePlans') return json(listFeePlans_(params));
    if (action === 'listFeePayments') return json(listFeePayments_(params));
    if (action === 'listFeeWaivers') return json(listFeeWaivers_(params));
    if (action === 'listFeeDues') return json(listFeeDues_(params));
    if (action === 'listBudgets') return json(listBudgets_(params));
    if (action === 'financeControlSummary') return json(financeControlSummary_(params));
    if (action === 'listApprovalRules') return json(listApprovalRules_(params));
    if (action === 'listApprovalRequests') return json(listApprovalRequests_(params));
    if (action === 'listNotices') return json(listNotices_(params));
    if (action === 'listDocuments') return json(listDocuments_(params));
    if (action === 'monthlyReport') return json(monthlyReport_(params));
    if (action === 'rangeReport') return json(rangeReport_(params));
    if (action === 'datasetStats') return json(datasetStats_(params));
    if (action === 'getAppUiSettings') return json(getAppUiSettings_(params));
    if (action === 'listAuditLog') return json(listAuditLog_(params));
    if (action === 'getNotificationSettings') return json(getNotificationSettings_(params));
    if (action === 'listInAppNotifications') return json(listInAppNotifications_(params));
    if (action === 'listRoleDefinitions') return json(listRoleDefinitions_(params));

    // Write actions
    if (action === 'login') return json(login_(params));
    if (action === 'requestPinReset') return json(requestPinReset_(params));
    if (action === 'confirmPinReset') return json(confirmPinReset_(params));

    if (action === 'createTransaction') {
      return json(createTransaction_(params.payload));
    }

    if (action === 'updateTransaction') {
      return json(updateTransaction_(params.id, params.payload));
    }

    if (action === 'upsertBeneficiary') {
      return json(upsertById_(CONFIG.SHEETS.BENEFICIARIES, params.payload));
    }

    if (action === 'upsertStaff') {
      return json(upsertById_(CONFIG.SHEETS.STAFF, params.payload));
    }

    if (action === 'recordSalaryPayment') {
      return json(recordSalaryPayment_(params.payload));
    }

    if (action === 'saveScholarshipPayment') {
      return json(saveScholarshipPayment_(params.payload));
    }

    if (action === 'upsertStudent') {
      return json(upsertStudent_(params.payload, params));
    }

    if (action === 'upsertStudentGuardian') {
      return json(upsertStudentGuardian_(params.payload, params));
    }

    if (action === 'upsertClass') {
      return json(upsertClass_(params.payload, params));
    }

    if (action === 'upsertSection') {
      return json(upsertSection_(params.payload, params));
    }

    if (action === 'upsertSubject') {
      return json(upsertSubject_(params.payload, params));
    }

    if (action === 'saveAttendance') {
      return json(saveAttendance_(params.payload, params));
    }

    if (action === 'upsertExamTerm') {
      return json(upsertExamTerm_(params.payload, params));
    }

    if (action === 'saveExamMark') {
      return json(saveExamMark_(params.payload, params));
    }

    if (action === 'upsertFeePlan') {
      return json(upsertFeePlan_(params.payload, params));
    }

    if (action === 'recordFeePayment') {
      return json(recordFeePayment_(params.payload, params));
    }

    if (action === 'upsertFeeWaiver') {
      return json(upsertFeeWaiver_(params.payload, params));
    }

    if (action === 'upsertBudget') {
      return json(upsertBudget_(params.payload, params));
    }

    if (action === 'upsertApprovalRule') {
      return json(upsertApprovalRule_(params.payload, params));
    }

    if (action === 'createApprovalRequest') {
      return json(createApprovalRequest_(params.payload, params));
    }

    if (action === 'decideApprovalRequest') {
      return json(decideApprovalRequest_(params.payload, params));
    }

    if (action === 'publishNotice') {
      return json(publishNotice_(params.payload, params));
    }

    if (action === 'markNoticeRead') {
      return json(markNoticeRead_(params.payload, params));
    }

    if (action === 'upsertDocument') {
      return json(upsertDocument_(params.payload, params));
    }

    if (action === 'listUsers') return json(listUsers_(params));

    if (action === 'upsertUser') {
      return json(upsertUser_(params.payload, params));
    }

    if (action === 'setUserApprovalStatus') {
      return json(setUserApprovalStatus_(params.payload, params));
    }

    if (action === 'generateTempResetToken') {
      return json(generateTempResetToken_(params.payload, params));
    }

    if (action === 'upsertNotificationSettings') {
      return json(upsertNotificationSettings_(params.payload, params));
    }

    if (action === 'upsertAppUiSettings') {
      return json(upsertAppUiSettings_(params.payload, params));
    }

    if (action === 'createNotificationEvent') {
      return json(createNotificationEvent_(params.payload, params));
    }

    if (action === 'upsertRoleDefinition') {
      return json(upsertRoleDefinition_(params.payload, params));
    }

    if (action === 'logClientGuard') {
      return json(logClientGuard_(params.payload, params));
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
    return {
      ok: true,
      data: {
        id: boot.id,
        name: boot.name,
        role: boot.role,
        phone: '',
        email: boot.email,
        approval_status: 'APPROVED',
        permissions: (getRoleDefinition_(boot.role) || { permissions: [] }).permissions || [],
      },
    };
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
      permissions: (getRoleDefinition_(anyUser.role || 'VIEWER') || { permissions: [] }).permissions || [],
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
  assertPermission_(params, 'dashboard.view');
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
    ? filtered.filter((r) => isVisibleToFieldUser_(r, userId))
    : filtered;

  const summary = { totalIn: 0, totalOut: 0, balance: 0, byFund: {} };

  scoped.forEach((t) => {
    const amt = normalizeNumber_(t.amount);
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
  assertPermission_(params, 'reports.view');
  const role = String(params.user_role || '');
  const userId = String(params.user_id || '');
  requireUserIdIfFieldRole_(role, userId);

  const monthKey = params.monthKey;
  if (!monthKey) return { ok: false, message: 'monthKey required' };

  const txns = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const monthly = txns.filter((t) => String(t.txn_date || '').slice(0, 7) === monthKey && String(t.status || 'ACTIVE') !== 'VOID');

  const scoped = role === 'FIELD_USER'
    ? monthly.filter((r) => isVisibleToFieldUser_(r, userId))
    : monthly;

  let totalIn = 0;
  let totalOut = 0;
  scoped.forEach((t) => {
    const amt = normalizeNumber_(t.amount);
    if (t.direction === 'IN') totalIn += amt;
    else totalOut += amt;
  });

  const rows = scoped;
  return { ok: true, data: { monthKey, totalIn, totalOut, balance: totalIn - totalOut, rows } };
}

function rangeReport_(params) {
  params = params || {};
  assertPermission_(params, 'reports.view');
  const role = String(params.user_role || '');
  const userId = String(params.user_id || '');
  requireUserIdIfFieldRole_(role, userId);

  const from = normalizeIsoDate_(params.from || '');
  const to = normalizeIsoDate_(params.to || '');
  if (!isIsoDateText_(from) || !isIsoDateText_(to)) {
    return { ok: false, message: 'from/to must be valid YYYY-MM-DD' };
  }
  if (from > to) return { ok: false, message: 'from date cannot be after to date' };

  const maxDays = MAX_REPORT_RANGE_DAYS;
  const days = rangeDaysInclusive_(from, to);
  if (days > maxDays) {
    return { ok: false, message: 'Maximum report range is ' + maxDays + ' days', max_range_days: maxDays };
  }

  const txns = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const filtered = txns.filter(function (t) {
    if (!String(t.txn_date || '')) return false;
    if (String(t.status || 'ACTIVE') === 'VOID') return false;
    if (String(t.txn_date || '') < from) return false;
    if (String(t.txn_date || '') > to) return false;
    if (role === 'FIELD_USER' && !isVisibleToFieldUser_(t, userId)) return false;
    return true;
  });

  filtered.sort(function (a, b) {
    return String(b.txn_date || '').localeCompare(String(a.txn_date || ''));
  });

  let totalIn = 0;
  let totalOut = 0;
  const byFund = {};
  const byMonth = {};

  filtered.forEach(function (t) {
    const amt = normalizeNumber_(t.amount);
    const dir = String(t.direction || '');
    const fund = String(t.fund_type || 'UNKNOWN');
    const monthKey = String(t.txn_date || '').slice(0, 7);
    if (!byFund[fund]) byFund[fund] = { in: 0, out: 0, balance: 0 };
    if (!byMonth[monthKey]) byMonth[monthKey] = { in: 0, out: 0, balance: 0 };

    if (dir === 'IN') {
      totalIn += amt;
      byFund[fund].in += amt;
      byMonth[monthKey].in += amt;
    } else {
      totalOut += amt;
      byFund[fund].out += amt;
      byMonth[monthKey].out += amt;
    }
  });

  Object.keys(byFund).forEach(function (k) {
    byFund[k].balance = byFund[k].in - byFund[k].out;
  });
  Object.keys(byMonth).forEach(function (k) {
    byMonth[k].balance = byMonth[k].in - byMonth[k].out;
  });

  return {
    ok: true,
    data: {
      from: from,
      to: to,
      range_days: days,
      max_range_days: maxDays,
      totalIn: totalIn,
      totalOut: totalOut,
      balance: totalIn - totalOut,
      rows: filtered,
      byFund: byFund,
      byMonth: byMonth,
    },
  };
}

function listTransactions_(params) {
  params = params || {};
  assertPermission_(params, 'donations.view');
  const role = String(params.user_role || '');
  const userId = String(params.user_id || '');
  requireUserIdIfFieldRole_(role, userId);

  const rows = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const fundType = params.fundType || '';
  const direction = params.direction || '';
  const from = params.from || '';
  const to = params.to || '';
  const limit = Math.max(1, Math.min(500, Number(params.limit || 120)));

  const filtered = rows.filter((r) => {
    if (fundType && r.fund_type !== fundType) return false;
    if (direction && r.direction !== direction) return false;
    if (from && r.txn_date < from) return false;
    if (to && r.txn_date > to) return false;
    if (String(r.status || 'ACTIVE') === 'VOID') return false;
    if (role === 'FIELD_USER' && !isVisibleToFieldUser_(r, userId)) return false;
    return true;
  });

  filtered.sort((a, b) => String(b.txn_date || '').localeCompare(String(a.txn_date || '')));
  return { ok: true, data: filtered.slice(0, limit) };
}

function datasetStats_(params) {
  params = params || {};
  assertPermission_(params, 'reports.view');
  const role = String(params.user_role || '');
  const userId = String(params.user_id || '');
  requireUserIdIfFieldRole_(role, userId);

  const rows = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const active = rows.filter(function (r) {
    if (String(r.status || 'ACTIVE') === 'VOID') return false;
    if (!String(r.txn_date || '').trim()) return false;
    if (role === 'FIELD_USER' && !isVisibleToFieldUser_(r, userId)) return false;
    return true;
  });

  const sortedDates = active
    .map(function (r) { return String(r.txn_date || '').trim(); })
    .filter(function (d) { return /^\d{4}-\d{2}-\d{2}$/.test(d); })
    .sort();

  let totalIn = 0;
  let totalOut = 0;
  active.forEach(function (r) {
    const amt = normalizeNumber_(r.amount);
    if (String(r.direction || '') === 'IN') totalIn += amt;
    else totalOut += amt;
  });

  return {
    ok: true,
    data: {
      txns_total_rows: rows.length,
      txns_active_rows: active.length,
      first_txn_date: sortedDates.length ? sortedDates[0] : '',
      last_txn_date: sortedDates.length ? sortedDates[sortedDates.length - 1] : '',
      total_in: totalIn,
      total_out: totalOut,
      balance: totalIn - totalOut,
    },
  };
}

function listBeneficiaries_(params) {
  params = params || {};
  assertPermission_(params, 'beneficiaries.view');
  return listSheetRows_(CONFIG.SHEETS.BENEFICIARIES);
}

function listStaff_(params) {
  params = params || {};
  assertPermission_(params, 'salary.view');
  return listSheetRows_(CONFIG.SHEETS.STAFF);
}

function listSalaryPayments_(params) {
  params = params || {};
  assertPermission_(params, 'salary.view');

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
  assertPermission_(params, 'scholarship.view');

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

function listStudents_(params) {
  params = params || {};
  assertPermission_(params, 'academic.foundation.view');
  ensurePhase1Sheet_(CONFIG.SHEETS.STUDENTS);
  const classId = String(params.class_id || '').trim();
  const sectionId = String(params.section_id || '').trim();
  const status = String(params.status || '').trim().toUpperCase();
  const search = String(params.search || '').trim().toLowerCase();
  const limit = Math.max(1, Math.min(1000, Number(params.limit || 300)));

  const rows = listSheetRows_(CONFIG.SHEETS.STUDENTS).data || [];
  const filtered = rows.filter(function (r) {
    if (classId && String(r.class_id || '') !== classId) return false;
    if (sectionId && String(r.section_id || '') !== sectionId) return false;
    if (status && String(r.status || '').toUpperCase() !== status) return false;
    if (search) {
      const hay = [
        r.student_code,
        r.name_bn,
        r.name_en,
        r.roll_no,
        r.phone,
      ].join(' ').toLowerCase();
      if (hay.indexOf(search) === -1) return false;
    }
    return true;
  });

  filtered.sort(function (a, b) {
    const classSort = String(a.class_id || '').localeCompare(String(b.class_id || ''));
    if (classSort !== 0) return classSort;
    const sectionSort = String(a.section_id || '').localeCompare(String(b.section_id || ''));
    if (sectionSort !== 0) return sectionSort;
    return Number(a.roll_no || 999999) - Number(b.roll_no || 999999);
  });
  return { ok: true, data: filtered.slice(0, limit) };
}

function listStudentGuardians_(params) {
  params = params || {};
  assertPermission_(params, 'academic.foundation.view');
  ensurePhase1Sheet_(CONFIG.SHEETS.GUARDIANS);
  const studentId = String(params.student_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.GUARDIANS).data || [];
  const filtered = rows.filter(function (r) {
    if (studentId && String(r.student_id || '') !== studentId) return false;
    return true;
  });
  filtered.sort(function (a, b) {
    return String(a.student_id || '').localeCompare(String(b.student_id || '')) ||
      String(a.name || '').localeCompare(String(b.name || ''));
  });
  return { ok: true, data: filtered };
}

function listClasses_(params) {
  params = params || {};
  assertPermission_(params, 'academic.foundation.view');
  ensurePhase1Sheet_(CONFIG.SHEETS.CLASSES);
  const rows = listSheetRows_(CONFIG.SHEETS.CLASSES).data || [];
  rows.sort(function (a, b) {
    return Number(a.sort_order || 9999) - Number(b.sort_order || 9999) ||
      String(a.name || '').localeCompare(String(b.name || ''));
  });
  return { ok: true, data: rows };
}

function listSections_(params) {
  params = params || {};
  assertPermission_(params, 'academic.foundation.view');
  ensurePhase1Sheet_(CONFIG.SHEETS.SECTIONS);
  const classId = String(params.class_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.SECTIONS).data || [];
  const filtered = rows.filter(function (r) {
    if (classId && String(r.class_id || '') !== classId) return false;
    return true;
  });
  filtered.sort(function (a, b) {
    return String(a.class_id || '').localeCompare(String(b.class_id || '')) ||
      String(a.name || '').localeCompare(String(b.name || ''));
  });
  return { ok: true, data: filtered };
}

function listSubjects_(params) {
  params = params || {};
  assertPermission_(params, 'academic.foundation.view');
  ensurePhase1Sheet_(CONFIG.SHEETS.SUBJECTS);
  const classId = String(params.class_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.SUBJECTS).data || [];
  const filtered = rows.filter(function (r) {
    if (classId && String(r.class_id || '') !== classId) return false;
    return true;
  });
  filtered.sort(function (a, b) {
    return String(a.class_id || '').localeCompare(String(b.class_id || '')) ||
      Number(a.sort_order || 9999) - Number(b.sort_order || 9999) ||
      String(a.name || '').localeCompare(String(b.name || ''));
  });
  return { ok: true, data: filtered };
}

function upsertStudent_(payload, params) {
  payload = payload || {};
  validateRequired_(payload, ['name_bn', 'class_id']);
  ensurePhase1Sheet_(CONFIG.SHEETS.STUDENTS);
  ensurePhase1Sheet_(CONFIG.SHEETS.CLASSES);
  ensurePhase1Sheet_(CONFIG.SHEETS.SECTIONS);

  const row = Object.assign({}, payload);
  row.id = row.id || uid_('stu');
  row.student_code = String(row.student_code || row.id).trim();
  row.name_bn = String(row.name_bn || '').trim();
  row.name_en = String(row.name_en || '').trim();
  row.gender = String(row.gender || '').trim();
  row.date_of_birth = normalizeIsoDate_(row.date_of_birth || '');
  row.admission_date = normalizeIsoDate_(row.admission_date || todayIso_());
  row.class_id = String(row.class_id || '').trim();
  row.section_id = String(row.section_id || '').trim();
  row.roll_no = String(row.roll_no || '').trim();
  row.status = normalizeActiveStatus_(row.status || 'ACTIVE');
  row.phone = String(row.phone || '').trim();
  row.address = String(row.address || '').trim();
  row.notes = String(row.notes || '').trim();
  row.updated_by = String(row.updated_by || params.user_id || params.user_role || 'system');

  const klass = findRowByIdSafe_(CONFIG.SHEETS.CLASSES, row.class_id);
  if (!klass) return { ok: false, message: 'class_id not found: ' + row.class_id };
  if (row.section_id) {
    const section = findRowByIdSafe_(CONFIG.SHEETS.SECTIONS, row.section_id);
    if (!section) return { ok: false, message: 'section_id not found: ' + row.section_id };
  }

  return upsertById_(CONFIG.SHEETS.STUDENTS, row);
}

function upsertStudentGuardian_(payload, params) {
  payload = payload || {};
  validateRequired_(payload, ['student_id', 'name', 'relation', 'phone']);
  ensurePhase1Sheet_(CONFIG.SHEETS.GUARDIANS);

  const row = Object.assign({}, payload);
  row.id = row.id || uid_('guard');
  row.student_id = String(row.student_id || '').trim();
  row.name = String(row.name || '').trim();
  row.relation = String(row.relation || '').trim();
  row.phone = String(row.phone || '').trim();
  row.email = String(row.email || '').trim();
  row.address = String(row.address || '').trim();
  row.occupation = String(row.occupation || '').trim();
  row.primary_contact = boolToSheet_(parseBool_(row.primary_contact, false));
  row.status = normalizeActiveStatus_(row.status || 'ACTIVE');
  row.notes = String(row.notes || '').trim();
  row.updated_by = String(row.updated_by || params.user_id || params.user_role || 'system');

  const student = findRowByIdSafe_(CONFIG.SHEETS.STUDENTS, row.student_id);
  if (!student) return { ok: false, message: 'student_id not found: ' + row.student_id };
  return upsertById_(CONFIG.SHEETS.GUARDIANS, row);
}

function upsertClass_(payload, params) {
  payload = payload || {};
  validateRequired_(payload, ['name']);
  ensurePhase1Sheet_(CONFIG.SHEETS.CLASSES);

  const row = Object.assign({}, payload);
  row.id = row.id || uid_('class');
  row.name = String(row.name || '').trim();
  row.level = String(row.level || '').trim();
  row.sort_order = Number(row.sort_order || 0);
  row.status = normalizeActiveStatus_(row.status || 'ACTIVE');
  row.notes = String(row.notes || '').trim();
  row.updated_by = String(row.updated_by || params.user_id || params.user_role || 'system');
  return upsertById_(CONFIG.SHEETS.CLASSES, row);
}

function upsertSection_(payload, params) {
  payload = payload || {};
  validateRequired_(payload, ['class_id', 'name']);
  ensurePhase1Sheet_(CONFIG.SHEETS.SECTIONS);
  ensurePhase1Sheet_(CONFIG.SHEETS.CLASSES);

  const row = Object.assign({}, payload);
  row.id = row.id || uid_('sec');
  row.class_id = String(row.class_id || '').trim();
  row.name = String(row.name || '').trim();
  row.capacity = Number(row.capacity || 0);
  row.status = normalizeActiveStatus_(row.status || 'ACTIVE');
  row.notes = String(row.notes || '').trim();
  row.updated_by = String(row.updated_by || params.user_id || params.user_role || 'system');

  const klass = findRowByIdSafe_(CONFIG.SHEETS.CLASSES, row.class_id);
  if (!klass) return { ok: false, message: 'class_id not found: ' + row.class_id };
  return upsertById_(CONFIG.SHEETS.SECTIONS, row);
}

function upsertSubject_(payload, params) {
  payload = payload || {};
  validateRequired_(payload, ['class_id', 'name']);
  ensurePhase1Sheet_(CONFIG.SHEETS.SUBJECTS);
  ensurePhase1Sheet_(CONFIG.SHEETS.CLASSES);

  const row = Object.assign({}, payload);
  row.id = row.id || uid_('subj');
  row.class_id = String(row.class_id || '').trim();
  row.name = String(row.name || '').trim();
  row.code = String(row.code || '').trim();
  row.sort_order = Number(row.sort_order || 0);
  row.status = normalizeActiveStatus_(row.status || 'ACTIVE');
  row.notes = String(row.notes || '').trim();
  row.updated_by = String(row.updated_by || params.user_id || params.user_role || 'system');

  const klass = findRowByIdSafe_(CONFIG.SHEETS.CLASSES, row.class_id);
  if (!klass) return { ok: false, message: 'class_id not found: ' + row.class_id };
  return upsertById_(CONFIG.SHEETS.SUBJECTS, row);
}

function listAttendance_(params) {
  params = params || {};
  assertPermission_(params, 'academic.core.view');
  ensurePhase2Sheet_(CONFIG.SHEETS.ATTENDANCE);

  const date = normalizeIsoDate_(params.attendance_date || params.date || '');
  const classId = String(params.class_id || '').trim();
  const sectionId = String(params.section_id || '').trim();
  const studentId = String(params.student_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.ATTENDANCE).data || [];
  const filtered = rows.filter(function (r) {
    if (date && normalizeIsoDate_(r.attendance_date || '') !== date) return false;
    if (classId && String(r.class_id || '') !== classId) return false;
    if (sectionId && String(r.section_id || '') !== sectionId) return false;
    if (studentId && String(r.student_id || '') !== studentId) return false;
    return true;
  });
  filtered.sort(function (a, b) {
    return String(b.attendance_date || '').localeCompare(String(a.attendance_date || '')) ||
      String(a.class_id || '').localeCompare(String(b.class_id || '')) ||
      String(a.student_id || '').localeCompare(String(b.student_id || ''));
  });
  return { ok: true, data: filtered };
}

function saveAttendance_(payload, params) {
  payload = payload || {};
  params = params || {};
  ensurePhase2Sheet_(CONFIG.SHEETS.ATTENDANCE);
  ensurePhase1Sheet_(CONFIG.SHEETS.STUDENTS);
  ensurePhase1Sheet_(CONFIG.SHEETS.CLASSES);
  ensurePhase1Sheet_(CONFIG.SHEETS.SECTIONS);

  const attendanceDate = normalizeIsoDate_(payload.attendance_date || payload.date || todayIso_());
  const classId = String(payload.class_id || '').trim();
  const sectionId = String(payload.section_id || '').trim();
  const rows = Array.isArray(payload.rows) ? payload.rows : [payload];
  if (!isIsoDateText_(attendanceDate)) return { ok: false, message: 'attendance_date must be YYYY-MM-DD' };
  if (!classId) return { ok: false, message: 'class_id is required' };
  if (!rows.length) return { ok: false, message: 'attendance rows are required' };

  const klass = findRowByIdSafe_(CONFIG.SHEETS.CLASSES, classId);
  if (!klass) return { ok: false, message: 'class_id not found: ' + classId };
  if (sectionId && !findRowByIdSafe_(CONFIG.SHEETS.SECTIONS, sectionId)) {
    return { ok: false, message: 'section_id not found: ' + sectionId };
  }

  const saved = [];
  rows.forEach(function (item) {
    const studentId = String(item.student_id || '').trim();
    if (!studentId) throw new Error('student_id is required');
    const student = findRowByIdSafe_(CONFIG.SHEETS.STUDENTS, studentId);
    if (!student) throw new Error('student_id not found: ' + studentId);

    const studentClassId = String(student.rowObj.class_id || classId);
    const studentSectionId = String(student.rowObj.section_id || sectionId);
    const status = normalizeAttendanceStatus_(item.status || 'PRESENT');
    const row = {
      id: item.id || stableAcademicId_('att', [attendanceDate, studentId]),
      attendance_date: attendanceDate,
      student_id: studentId,
      class_id: classId || studentClassId,
      section_id: sectionId || studentSectionId,
      status: status,
      notes: String(item.notes || '').trim(),
      recorded_by: String(params.user_id || item.recorded_by || params.user_role || 'system'),
      updated_by: String(params.user_id || item.updated_by || params.user_role || 'system'),
    };
    saved.push(upsertById_(CONFIG.SHEETS.ATTENDANCE, row).data);
  });

  return { ok: true, data: saved };
}

function listExamTerms_(params) {
  params = params || {};
  assertPermission_(params, 'academic.core.view');
  ensurePhase2Sheet_(CONFIG.SHEETS.EXAM_TERMS);
  const classId = String(params.class_id || '').trim();
  const sectionId = String(params.section_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.EXAM_TERMS).data || [];
  const filtered = rows.filter(function (r) {
    if (classId && String(r.class_id || '') !== classId) return false;
    if (sectionId && String(r.section_id || '') !== sectionId) return false;
    return true;
  });
  filtered.sort(function (a, b) {
    return String(b.start_date || '').localeCompare(String(a.start_date || '')) ||
      String(a.name || '').localeCompare(String(b.name || ''));
  });
  return { ok: true, data: filtered };
}

function upsertExamTerm_(payload, params) {
  payload = payload || {};
  validateRequired_(payload, ['name', 'class_id']);
  ensurePhase2Sheet_(CONFIG.SHEETS.EXAM_TERMS);
  ensurePhase1Sheet_(CONFIG.SHEETS.CLASSES);
  ensurePhase1Sheet_(CONFIG.SHEETS.SECTIONS);

  const row = Object.assign({}, payload);
  row.id = row.id || uid_('exam');
  row.name = String(row.name || '').trim();
  row.class_id = String(row.class_id || '').trim();
  row.section_id = String(row.section_id || '').trim();
  row.start_date = normalizeIsoDate_(row.start_date || todayIso_());
  row.end_date = normalizeIsoDate_(row.end_date || row.start_date);
  row.status = normalizeActiveStatus_(row.status || 'ACTIVE');
  row.notes = String(row.notes || '').trim();
  row.updated_by = String(row.updated_by || params.user_id || params.user_role || 'system');

  if (!findRowByIdSafe_(CONFIG.SHEETS.CLASSES, row.class_id)) {
    return { ok: false, message: 'class_id not found: ' + row.class_id };
  }
  if (row.section_id && !findRowByIdSafe_(CONFIG.SHEETS.SECTIONS, row.section_id)) {
    return { ok: false, message: 'section_id not found: ' + row.section_id };
  }
  if (!isIsoDateText_(row.start_date) || !isIsoDateText_(row.end_date)) {
    return { ok: false, message: 'start/end date must be YYYY-MM-DD' };
  }
  if (row.start_date > row.end_date) return { ok: false, message: 'start_date cannot be after end_date' };
  return upsertById_(CONFIG.SHEETS.EXAM_TERMS, row);
}

function listExamMarks_(params) {
  params = params || {};
  assertPermission_(params, 'academic.core.view');
  ensurePhase2Sheet_(CONFIG.SHEETS.EXAM_MARKS);
  const examTermId = String(params.exam_term_id || '').trim();
  const studentId = String(params.student_id || '').trim();
  const subjectId = String(params.subject_id || '').trim();
  const classId = String(params.class_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.EXAM_MARKS).data || [];
  const filtered = rows.filter(function (r) {
    if (examTermId && String(r.exam_term_id || '') !== examTermId) return false;
    if (studentId && String(r.student_id || '') !== studentId) return false;
    if (subjectId && String(r.subject_id || '') !== subjectId) return false;
    if (classId && String(r.class_id || '') !== classId) return false;
    return true;
  });
  filtered.sort(function (a, b) {
    return String(a.student_id || '').localeCompare(String(b.student_id || '')) ||
      String(a.subject_id || '').localeCompare(String(b.subject_id || ''));
  });
  return { ok: true, data: filtered };
}

function saveExamMark_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['exam_term_id', 'student_id', 'subject_id', 'marks_obtained', 'max_marks']);
  ensurePhase2Sheet_(CONFIG.SHEETS.EXAM_MARKS);
  ensurePhase2Sheet_(CONFIG.SHEETS.EXAM_TERMS);
  ensurePhase1Sheet_(CONFIG.SHEETS.STUDENTS);
  ensurePhase1Sheet_(CONFIG.SHEETS.SUBJECTS);

  const exam = findRowByIdSafe_(CONFIG.SHEETS.EXAM_TERMS, payload.exam_term_id);
  if (!exam) return { ok: false, message: 'exam_term_id not found: ' + payload.exam_term_id };
  const student = findRowByIdSafe_(CONFIG.SHEETS.STUDENTS, payload.student_id);
  if (!student) return { ok: false, message: 'student_id not found: ' + payload.student_id };
  const subject = findRowByIdSafe_(CONFIG.SHEETS.SUBJECTS, payload.subject_id);
  if (!subject) return { ok: false, message: 'subject_id not found: ' + payload.subject_id };

  const maxMarks = Math.max(1, normalizeNumber_(payload.max_marks));
  const marks = Math.max(0, normalizeNumber_(payload.marks_obtained));
  const row = {
    id: payload.id || stableAcademicId_('mark', [payload.exam_term_id, payload.student_id, payload.subject_id]),
    exam_term_id: String(payload.exam_term_id || '').trim(),
    student_id: String(payload.student_id || '').trim(),
    subject_id: String(payload.subject_id || '').trim(),
    class_id: String(payload.class_id || student.rowObj.class_id || exam.rowObj.class_id || ''),
    marks_obtained: marks,
    max_marks: maxMarks,
    grade: String(payload.grade || gradeFromPercent_((marks / maxMarks) * 100)),
    status: String(payload.status || 'RECORDED').trim().toUpperCase(),
    notes: String(payload.notes || '').trim(),
    updated_by: String(payload.updated_by || params.user_id || params.user_role || 'system'),
  };
  return upsertById_(CONFIG.SHEETS.EXAM_MARKS, row);
}

function resultSummary_(params) {
  params = params || {};
  assertPermission_(params, 'academic.core.view');
  ensurePhase1Sheet_(CONFIG.SHEETS.STUDENTS);
  ensurePhase1Sheet_(CONFIG.SHEETS.SUBJECTS);
  ensurePhase2Sheet_(CONFIG.SHEETS.EXAM_TERMS);
  ensurePhase2Sheet_(CONFIG.SHEETS.EXAM_MARKS);

  const examTermId = String(params.exam_term_id || '').trim();
  const classId = String(params.class_id || '').trim();
  if (!examTermId) return { ok: false, message: 'exam_term_id is required' };

  const students = (listStudents_({
    user_role: params.user_role,
    class_id: classId,
    section_id: params.section_id || '',
    status: 'ACTIVE',
    limit: 1000,
  }).data || []);
  const marks = listExamMarks_({
    user_role: params.user_role,
    exam_term_id: examTermId,
    class_id: classId,
  }).data || [];
  const subjects = listSubjects_({ user_role: params.user_role, class_id: classId }).data || [];
  const subjectById = {};
  subjects.forEach(function (s) { subjectById[String(s.id || '')] = s; });

  const markByStudent = {};
  marks.forEach(function (m) {
    const sid = String(m.student_id || '');
    if (!markByStudent[sid]) markByStudent[sid] = [];
    markByStudent[sid].push(m);
  });

  const rows = students.map(function (student) {
    const studentMarks = markByStudent[String(student.id || '')] || [];
    let obtained = 0;
    let max = 0;
    studentMarks.forEach(function (m) {
      obtained += normalizeNumber_(m.marks_obtained);
      max += normalizeNumber_(m.max_marks);
    });
    const percent = max > 0 ? (obtained / max) * 100 : 0;
    return {
      student_id: student.id,
      student_name: student.name_bn || student.name_en || student.id,
      class_id: student.class_id || classId,
      section_id: student.section_id || '',
      total_obtained: obtained,
      total_max: max,
      percent: Math.round(percent * 100) / 100,
      grade: max > 0 ? gradeFromPercent_(percent) : '',
      subjects_recorded: studentMarks.length,
      marks: studentMarks.map(function (m) {
        return Object.assign({}, m, {
          subject_name: (subjectById[String(m.subject_id || '')] || {}).name || m.subject_id,
        });
      }),
    };
  });

  rows.sort(function (a, b) {
    return b.percent - a.percent || String(a.student_name || '').localeCompare(String(b.student_name || ''));
  });
  return { ok: true, data: { exam_term_id: examTermId, class_id: classId, rows: rows } };
}

function listFeePlans_(params) {
  params = params || {};
  assertPermission_(params, 'fees.view');
  ensurePhase3Sheet_(CONFIG.SHEETS.FEE_PLANS);
  const classId = String(params.class_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.FEE_PLANS).data || [];
  const filtered = rows.filter(function (r) {
    if (classId && String(r.class_id || '') && String(r.class_id || '') !== classId) return false;
    return true;
  });
  filtered.sort(function (a, b) {
    return String(a.class_id || '').localeCompare(String(b.class_id || '')) ||
      String(a.name || '').localeCompare(String(b.name || ''));
  });
  return { ok: true, data: filtered };
}

function upsertFeePlan_(payload, params) {
  payload = payload || {};
  validateRequired_(payload, ['name', 'amount']);
  ensurePhase3Sheet_(CONFIG.SHEETS.FEE_PLANS);
  ensurePhase1Sheet_(CONFIG.SHEETS.CLASSES);

  const row = Object.assign({}, payload);
  row.id = row.id || uid_('feeplan');
  row.name = String(row.name || '').trim();
  row.class_id = String(row.class_id || '').trim();
  row.month_from = normalizeMonthKey_(row.month_from || '');
  row.month_to = normalizeMonthKey_(row.month_to || '');
  row.amount = Math.max(0, normalizeNumber_(row.amount));
  row.frequency = String(row.frequency || 'MONTHLY').trim().toUpperCase();
  row.status = normalizeActiveStatus_(row.status || 'ACTIVE');
  row.notes = String(row.notes || '').trim();
  row.updated_by = String(row.updated_by || params.user_id || params.user_role || 'system');

  if (row.class_id && !findRowByIdSafe_(CONFIG.SHEETS.CLASSES, row.class_id)) {
    return { ok: false, message: 'class_id not found: ' + row.class_id };
  }
  if (row.month_from && !isMonthKey_(row.month_from)) return { ok: false, message: 'month_from must be YYYY-MM' };
  if (row.month_to && !isMonthKey_(row.month_to)) return { ok: false, message: 'month_to must be YYYY-MM' };
  if (row.month_from && row.month_to && row.month_from > row.month_to) {
    return { ok: false, message: 'month_from cannot be after month_to' };
  }
  return upsertById_(CONFIG.SHEETS.FEE_PLANS, row);
}

function listFeePayments_(params) {
  params = params || {};
  assertPermission_(params, 'fees.view');
  ensurePhase3Sheet_(CONFIG.SHEETS.FEE_PAYMENTS);
  const monthKey = normalizeMonthKey_(params.month_key || '');
  const studentId = String(params.student_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.FEE_PAYMENTS).data || [];
  const filtered = rows.filter(function (r) {
    if (monthKey && String(r.month_key || '') !== monthKey) return false;
    if (studentId && String(r.student_id || '') !== studentId) return false;
    return String(r.status || 'ACTIVE') !== 'VOID';
  });
  filtered.sort(function (a, b) {
    return String(b.payment_date || '').localeCompare(String(a.payment_date || ''));
  });
  return { ok: true, data: filtered };
}

function recordFeePayment_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['student_id', 'month_key', 'amount']);
  ensurePhase3Sheet_(CONFIG.SHEETS.FEE_PAYMENTS);
  ensurePhase1Sheet_(CONFIG.SHEETS.STUDENTS);

  const student = findRowByIdSafe_(CONFIG.SHEETS.STUDENTS, payload.student_id);
  if (!student) return { ok: false, message: 'student_id not found: ' + payload.student_id };
  const monthKey = normalizeMonthKey_(payload.month_key || '');
  if (!isMonthKey_(monthKey)) return { ok: false, message: 'month_key must be YYYY-MM' };
  const amount = Math.max(0, normalizeNumber_(payload.amount));
  if (amount <= 0) return { ok: false, message: 'amount must be > 0' };

  const row = {
    id: payload.id || uid_('feepay'),
    student_id: String(payload.student_id || '').trim(),
    month_key: monthKey,
    amount: amount,
    payment_date: normalizeIsoDate_(payload.payment_date || todayIso_()),
    method: String(payload.method || '').trim(),
    reference: String(payload.reference || '').trim(),
    fund_type: String(payload.fund_type || 'GENERAL').trim().toUpperCase(),
    txn_id: String(payload.txn_id || '').trim(),
    status: String(payload.status || 'ACTIVE').trim().toUpperCase(),
    notes: String(payload.notes || '').trim(),
    updated_by: String(payload.updated_by || params.user_id || params.user_role || 'system'),
  };
  validateEnum_(row.fund_type, CONFIG.ENUMS.FUND, 'fund_type');

  const saved = upsertById_(CONFIG.SHEETS.FEE_PAYMENTS, row);
  let transaction = null;
  if (!row.txn_id && saved.mode === 'create') {
    transaction = createTransaction_({
      txn_date: row.payment_date,
      direction: 'IN',
      fund_type: row.fund_type,
      amount: row.amount,
      source_or_vendor: String(student.rowObj.name_bn || student.rowObj.name_en || row.student_id),
      category: 'STUDENT_FEE',
      reference: row.reference,
      notes: row.notes,
      related_entity_type: 'FEE_PAYMENT',
      related_entity_id: row.id,
      created_by: row.updated_by,
    });
    updateById_(CONFIG.SHEETS.FEE_PAYMENTS, row.id, { txn_id: transaction.data.id });
    saved.data.txn_id = transaction.data.id;
  }
  return { ok: true, data: saved.data, transaction: transaction ? transaction.data : null };
}

function listFeeWaivers_(params) {
  params = params || {};
  assertPermission_(params, 'fees.view');
  ensurePhase3Sheet_(CONFIG.SHEETS.FEE_WAIVERS);
  const monthKey = normalizeMonthKey_(params.month_key || '');
  const studentId = String(params.student_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.FEE_WAIVERS).data || [];
  const filtered = rows.filter(function (r) {
    if (monthKey && String(r.month_key || '') !== monthKey) return false;
    if (studentId && String(r.student_id || '') !== studentId) return false;
    return String(r.status || 'ACTIVE') !== 'VOID';
  });
  filtered.sort(function (a, b) {
    return String(b.updated_at || '').localeCompare(String(a.updated_at || ''));
  });
  return { ok: true, data: filtered };
}

function upsertFeeWaiver_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['student_id', 'month_key', 'amount', 'reason']);
  ensurePhase3Sheet_(CONFIG.SHEETS.FEE_WAIVERS);
  ensurePhase1Sheet_(CONFIG.SHEETS.STUDENTS);

  if (!findRowByIdSafe_(CONFIG.SHEETS.STUDENTS, payload.student_id)) {
    return { ok: false, message: 'student_id not found: ' + payload.student_id };
  }
  const monthKey = normalizeMonthKey_(payload.month_key || '');
  if (!isMonthKey_(monthKey)) return { ok: false, message: 'month_key must be YYYY-MM' };
  const amount = Math.max(0, normalizeNumber_(payload.amount));
  if (amount <= 0) return { ok: false, message: 'amount must be > 0' };

  const row = {
    id: payload.id || uid_('feewaive'),
    student_id: String(payload.student_id || '').trim(),
    month_key: monthKey,
    amount: amount,
    reason: String(payload.reason || '').trim(),
    approved_by: String(payload.approved_by || params.user_id || params.user_role || 'system'),
    status: String(payload.status || 'ACTIVE').trim().toUpperCase(),
    notes: String(payload.notes || '').trim(),
    updated_by: String(payload.updated_by || params.user_id || params.user_role || 'system'),
  };
  return upsertById_(CONFIG.SHEETS.FEE_WAIVERS, row);
}

function listFeeDues_(params) {
  params = params || {};
  assertPermission_(params, 'fees.view');
  ensurePhase1Sheet_(CONFIG.SHEETS.STUDENTS);
  ensurePhase3Sheet_(CONFIG.SHEETS.FEE_PLANS);
  ensurePhase3Sheet_(CONFIG.SHEETS.FEE_PAYMENTS);
  ensurePhase3Sheet_(CONFIG.SHEETS.FEE_WAIVERS);

  const monthKey = normalizeMonthKey_(params.month_key || params.monthKey || '');
  if (!isMonthKey_(monthKey)) return { ok: false, message: 'month_key must be YYYY-MM' };
  const classId = String(params.class_id || '').trim();
  const studentId = String(params.student_id || '').trim();

  const students = listStudents_({
    user_role: params.user_role,
    class_id: classId,
    student_id: studentId,
    status: 'ACTIVE',
    limit: 1000,
  }).data || [];
  const scopedStudents = students.filter(function (s) {
    if (studentId && String(s.id || '') !== studentId) return false;
    return true;
  });
  const plans = (listFeePlans_({ user_role: params.user_role, class_id: classId }).data || [])
    .filter(function (p) {
      if (String(p.status || 'ACTIVE') !== 'ACTIVE') return false;
      if (p.month_from && String(p.month_from) > monthKey) return false;
      if (p.month_to && String(p.month_to) < monthKey) return false;
      return true;
    });
  const payments = listFeePayments_({ user_role: params.user_role, month_key: monthKey }).data || [];
  const waivers = listFeeWaivers_({ user_role: params.user_role, month_key: monthKey }).data || [];

  const rows = scopedStudents.map(function (student) {
    const applicable = plans.filter(function (p) {
      const planClass = String(p.class_id || '').trim();
      return !planClass || planClass === String(student.class_id || '');
    });
    const planned = applicable.reduce(function (sum, p) { return sum + normalizeNumber_(p.amount); }, 0);
    const paid = payments
      .filter(function (p) { return String(p.student_id || '') === String(student.id || ''); })
      .reduce(function (sum, p) { return sum + normalizeNumber_(p.amount); }, 0);
    const waived = waivers
      .filter(function (w) { return String(w.student_id || '') === String(student.id || ''); })
      .reduce(function (sum, w) { return sum + normalizeNumber_(w.amount); }, 0);
    const due = Math.max(0, planned - paid - waived);
    const scholarshipState = due <= 0 ? 'PAID' : (paid > 0 || waived > 0 ? 'PARTIAL' : 'UNPAID');
    return {
      student_id: student.id,
      student_name: student.name_bn || student.name_en || student.id,
      class_id: student.class_id || '',
      section_id: student.section_id || '',
      month_key: monthKey,
      planned_amount: planned,
      paid_amount: paid,
      waived_amount: waived,
      due_amount: due,
      scholarship_due_state: scholarshipState,
      fee_plan_count: applicable.length,
    };
  });
  rows.sort(function (a, b) {
    return String(a.class_id || '').localeCompare(String(b.class_id || '')) ||
      String(a.student_name || '').localeCompare(String(b.student_name || ''));
  });
  const totals = rows.reduce(function (acc, r) {
    acc.planned_amount += normalizeNumber_(r.planned_amount);
    acc.paid_amount += normalizeNumber_(r.paid_amount);
    acc.waived_amount += normalizeNumber_(r.waived_amount);
    acc.due_amount += normalizeNumber_(r.due_amount);
    return acc;
  }, { planned_amount: 0, paid_amount: 0, waived_amount: 0, due_amount: 0 });
  return { ok: true, data: { month_key: monthKey, rows: rows, totals: totals } };
}

function listBudgets_(params) {
  params = params || {};
  assertPermission_(params, 'finance.view');
  ensurePhase4Sheet_(CONFIG.SHEETS.BUDGETS);
  const monthKey = normalizeMonthKey_(params.month_key || '');
  const fundType = String(params.fund_type || '').trim().toUpperCase();
  const rows = listSheetRows_(CONFIG.SHEETS.BUDGETS).data || [];
  const filtered = rows.filter(function (r) {
    if (monthKey && String(r.month_key || '') !== monthKey) return false;
    if (fundType && String(r.fund_type || '').toUpperCase() !== fundType) return false;
    return String(r.status || 'ACTIVE') !== 'VOID';
  });
  filtered.sort(function (a, b) {
    return String(b.month_key || '').localeCompare(String(a.month_key || '')) ||
      String(a.fund_type || '').localeCompare(String(b.fund_type || ''));
  });
  return { ok: true, data: filtered };
}

function upsertBudget_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['month_key', 'fund_type', 'planned_in', 'planned_out']);
  ensurePhase4Sheet_(CONFIG.SHEETS.BUDGETS);
  const monthKey = normalizeMonthKey_(payload.month_key || '');
  if (!isMonthKey_(monthKey)) return { ok: false, message: 'month_key must be YYYY-MM' };
  const row = {
    id: payload.id || stableAcademicId_('budget', [monthKey, payload.fund_type]),
    month_key: monthKey,
    fund_type: String(payload.fund_type || '').trim().toUpperCase(),
    planned_in: Math.max(0, normalizeNumber_(payload.planned_in)),
    planned_out: Math.max(0, normalizeNumber_(payload.planned_out)),
    notes: String(payload.notes || '').trim(),
    status: String(payload.status || 'ACTIVE').trim().toUpperCase(),
    updated_by: String(payload.updated_by || params.user_id || params.user_role || 'system'),
  };
  validateEnum_(row.fund_type, CONFIG.ENUMS.FUND, 'fund_type');
  return upsertById_(CONFIG.SHEETS.BUDGETS, row);
}

function financeControlSummary_(params) {
  params = params || {};
  assertPermission_(params, 'finance.view');
  ensurePhase4Sheet_(CONFIG.SHEETS.BUDGETS);
  const monthKey = normalizeMonthKey_(params.month_key || '');
  if (!isMonthKey_(monthKey)) return { ok: false, message: 'month_key must be YYYY-MM' };
  const from = monthKey + '-01';
  const to = lastDayOfMonthIso_(monthKey);
  const txns = listSheetRows_(CONFIG.SHEETS.TXN).data || [];
  const active = txns.filter(function (t) { return String(t.status || 'ACTIVE') !== 'VOID'; });
  const budgets = listBudgets_({ user_role: params.user_role, month_key: monthKey }).data || [];
  const byFund = {};
  CONFIG.ENUMS.FUND.forEach(function (fund) {
    byFund[fund] = {
      fund_type: fund,
      planned_in: 0,
      planned_out: 0,
      actual_in: 0,
      actual_out: 0,
      opening_balance: 0,
      closing_balance: 0,
      variance_in: 0,
      variance_out: 0,
    };
  });
  budgets.forEach(function (b) {
    const fund = String(b.fund_type || 'GENERAL').toUpperCase();
    if (!byFund[fund]) byFund[fund] = { fund_type: fund, planned_in: 0, planned_out: 0, actual_in: 0, actual_out: 0, opening_balance: 0, closing_balance: 0, variance_in: 0, variance_out: 0 };
    byFund[fund].planned_in += normalizeNumber_(b.planned_in);
    byFund[fund].planned_out += normalizeNumber_(b.planned_out);
  });
  active.forEach(function (t) {
    const fund = String(t.fund_type || 'GENERAL').toUpperCase();
    if (!byFund[fund]) byFund[fund] = { fund_type: fund, planned_in: 0, planned_out: 0, actual_in: 0, actual_out: 0, opening_balance: 0, closing_balance: 0, variance_in: 0, variance_out: 0 };
    const date = normalizeIsoDate_(t.txn_date || '');
    const amount = normalizeNumber_(t.amount);
    const signed = String(t.direction || '') === 'IN' ? amount : -amount;
    if (date && date < from) byFund[fund].opening_balance += signed;
    if (date && date >= from && date <= to) {
      if (String(t.direction || '') === 'IN') byFund[fund].actual_in += amount;
      else byFund[fund].actual_out += amount;
    }
  });
  Object.keys(byFund).forEach(function (fund) {
    const r = byFund[fund];
    r.closing_balance = r.opening_balance + r.actual_in - r.actual_out;
    r.variance_in = r.actual_in - r.planned_in;
    r.variance_out = r.planned_out - r.actual_out;
  });
  const rows = Object.keys(byFund).map(function (k) { return byFund[k]; });
  const totals = rows.reduce(function (acc, r) {
    ['planned_in', 'planned_out', 'actual_in', 'actual_out', 'opening_balance', 'closing_balance'].forEach(function (k) {
      acc[k] += normalizeNumber_(r[k]);
    });
    return acc;
  }, { planned_in: 0, planned_out: 0, actual_in: 0, actual_out: 0, opening_balance: 0, closing_balance: 0 });
  const dashboard = dashboardSummary_({ user_role: params.user_role, from: from, to: to, user_id: params.user_id || '' }).data || {};
  const reconciliation = {
    month_key: monthKey,
    dashboard_total_in: normalizeNumber_(dashboard.totalIn),
    dashboard_total_out: normalizeNumber_(dashboard.totalOut),
    summary_total_in: totals.actual_in,
    summary_total_out: totals.actual_out,
    pass: normalizeNumber_(dashboard.totalIn) === totals.actual_in && normalizeNumber_(dashboard.totalOut) === totals.actual_out,
  };
  return { ok: true, data: { month_key: monthKey, from: from, to: to, rows: rows, totals: totals, reconciliation: reconciliation } };
}

function listApprovalRules_(params) {
  params = params || {};
  assertPermission_(params, 'finance.view');
  ensurePhase4Sheet_(CONFIG.SHEETS.APPROVAL_RULES);
  return listSheetRows_(CONFIG.SHEETS.APPROVAL_RULES);
}

function upsertApprovalRule_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['action_type', 'threshold_amount']);
  ensurePhase4Sheet_(CONFIG.SHEETS.APPROVAL_RULES);
  const row = {
    id: payload.id || stableAcademicId_('rule', [payload.action_type]),
    action_type: String(payload.action_type || '').trim().toUpperCase(),
    threshold_amount: Math.max(0, normalizeNumber_(payload.threshold_amount)),
    approver_role: String(payload.approver_role || 'ADMIN').trim().toUpperCase(),
    active: boolToSheet_(parseBool_(payload.active, true)),
    notes: String(payload.notes || '').trim(),
    updated_by: String(payload.updated_by || params.user_id || params.user_role || 'system'),
  };
  validateRoleKey_(row.approver_role, 'approver_role');
  return upsertById_(CONFIG.SHEETS.APPROVAL_RULES, row);
}

function listApprovalRequests_(params) {
  params = params || {};
  assertPermission_(params, 'finance.view');
  ensurePhase4Sheet_(CONFIG.SHEETS.APPROVAL_REQUESTS);
  const status = String(params.status || '').trim().toUpperCase();
  const rows = listSheetRows_(CONFIG.SHEETS.APPROVAL_REQUESTS).data || [];
  const filtered = rows.filter(function (r) {
    if (status && String(r.status || '').toUpperCase() !== status) return false;
    return true;
  });
  filtered.sort(function (a, b) {
    return String(b.requested_at || '').localeCompare(String(a.requested_at || ''));
  });
  return { ok: true, data: filtered };
}

function createApprovalRequest_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['action_type', 'amount', 'summary']);
  ensurePhase4Sheet_(CONFIG.SHEETS.APPROVAL_REQUESTS);
  const row = {
    id: payload.id || uid_('approval'),
    action_type: String(payload.action_type || '').trim().toUpperCase(),
    amount: normalizeNumber_(payload.amount),
    entity_type: String(payload.entity_type || '').trim(),
    entity_id: String(payload.entity_id || '').trim(),
    summary: String(payload.summary || '').trim(),
    status: 'PENDING',
    requested_by: String(params.user_id || payload.requested_by || params.user_role || 'system'),
    requested_at: nowIso(),
    decided_by: '',
    decided_at: '',
    decision_notes: '',
    payload_json: JSON.stringify(payload.payload || {}),
    updated_by: String(params.user_id || params.user_role || 'system'),
  };
  return upsertById_(CONFIG.SHEETS.APPROVAL_REQUESTS, row);
}

function decideApprovalRequest_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['id', 'decision']);
  ensurePhase4Sheet_(CONFIG.SHEETS.APPROVAL_REQUESTS);
  const decision = String(payload.decision || '').trim().toUpperCase();
  if (['APPROVED', 'REJECTED'].indexOf(decision) === -1) return { ok: false, message: 'decision must be APPROVED or REJECTED' };
  const res = updateById_(CONFIG.SHEETS.APPROVAL_REQUESTS, payload.id, {
    status: decision,
    decided_by: String(params.user_id || params.user_role || 'admin'),
    decided_at: nowIso(),
    decision_notes: String(payload.decision_notes || '').trim(),
    updated_by: String(params.user_id || params.user_role || 'admin'),
  });
  addAudit_('approval_requests', decision, payload.id, JSON.stringify(res.before), JSON.stringify(res.after), String(params.user_id || params.user_role || 'admin'));
  return { ok: true, data: res.after };
}

function listNotices_(params) {
  params = params || {};
  assertPermission_(params, 'communication.view');
  ensurePhase5Sheet_(CONFIG.SHEETS.NOTICES);
  ensurePhase5Sheet_(CONFIG.SHEETS.NOTICE_READS);
  const role = String(params.user_role || '');
  const userId = String(params.user_id || '');
  const classId = String(params.class_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.NOTICES).data || [];
  const reads = listSheetRows_(CONFIG.SHEETS.NOTICE_READS).data || [];
  const readMap = {};
  reads.forEach(function (r) {
    if (String(r.user_id || '') === userId) readMap[String(r.notice_id || '')] = true;
  });
  const filtered = rows.filter(function (n) {
    if (String(n.status || 'PUBLISHED') !== 'PUBLISHED') return false;
    const targetRole = String(n.target_role || '').trim();
    const targetUser = String(n.target_user_id || '').trim();
    const targetClass = String(n.target_class_id || '').trim();
    if (!targetRole && !targetUser && !targetClass) return true;
    if (targetUser && targetUser === userId) return true;
    if (targetRole && targetRole === role) return true;
    if (targetClass && targetClass === classId) return true;
    return false;
  });
  filtered.sort(function (a, b) {
    return String(b.published_at || '').localeCompare(String(a.published_at || ''));
  });
  return { ok: true, data: filtered.map(function (n) { return Object.assign({}, n, { read: !!readMap[String(n.id || '')] }); }) };
}

function publishNotice_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['title', 'message']);
  ensurePhase5Sheet_(CONFIG.SHEETS.NOTICES);
  const row = {
    id: payload.id || uid_('notice'),
    title: String(payload.title || '').trim(),
    message: String(payload.message || '').trim(),
    target_role: String(payload.target_role || '').trim().toUpperCase(),
    target_user_id: String(payload.target_user_id || '').trim(),
    target_class_id: String(payload.target_class_id || '').trim(),
    priority: String(payload.priority || 'NORMAL').trim().toUpperCase(),
    status: String(payload.status || 'PUBLISHED').trim().toUpperCase(),
    published_by: String(params.user_id || params.user_role || 'system'),
    published_at: payload.published_at || nowIso(),
    expires_at: normalizeIsoDate_(payload.expires_at || ''),
    updated_by: String(payload.updated_by || params.user_id || params.user_role || 'system'),
  };
  if (row.target_role) validateRoleKey_(row.target_role, 'target_role');
  return upsertById_(CONFIG.SHEETS.NOTICES, row);
}

function markNoticeRead_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['notice_id']);
  ensurePhase5Sheet_(CONFIG.SHEETS.NOTICE_READS);
  const userId = String(params.user_id || payload.user_id || params.user_role || 'anonymous');
  const row = {
    id: stableAcademicId_('read', [payload.notice_id, userId]),
    notice_id: String(payload.notice_id || '').trim(),
    user_id: userId,
    read_at: nowIso(),
    updated_by: userId,
  };
  return upsertById_(CONFIG.SHEETS.NOTICE_READS, row);
}

function listDocuments_(params) {
  params = params || {};
  assertPermission_(params, 'communication.view');
  ensurePhase5Sheet_(CONFIG.SHEETS.DOCUMENTS);
  const entityType = String(params.entity_type || '').trim();
  const entityId = String(params.entity_id || '').trim();
  const rows = listSheetRows_(CONFIG.SHEETS.DOCUMENTS).data || [];
  const filtered = rows.filter(function (d) {
    if (entityType && String(d.entity_type || '') !== entityType) return false;
    if (entityId && String(d.entity_id || '') !== entityId) return false;
    return String(d.status || 'ACTIVE') !== 'VOID';
  });
  filtered.sort(function (a, b) {
    return String(b.updated_at || '').localeCompare(String(a.updated_at || ''));
  });
  return { ok: true, data: filtered };
}

function upsertDocument_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['title', 'url', 'entity_type', 'entity_id']);
  ensurePhase5Sheet_(CONFIG.SHEETS.DOCUMENTS);
  const row = {
    id: payload.id || uid_('doc'),
    title: String(payload.title || '').trim(),
    doc_type: String(payload.doc_type || 'DOCUMENT').trim().toUpperCase(),
    url: String(payload.url || '').trim(),
    entity_type: String(payload.entity_type || '').trim(),
    entity_id: String(payload.entity_id || '').trim(),
    notes: String(payload.notes || '').trim(),
    status: String(payload.status || 'ACTIVE').trim().toUpperCase(),
    uploaded_by: String(params.user_id || params.user_role || 'system'),
    updated_by: String(payload.updated_by || params.user_id || params.user_role || 'system'),
  };
  return upsertById_(CONFIG.SHEETS.DOCUMENTS, row);
}

function phase1SheetHeaders_() {
  const headers = {};
  headers[CONFIG.SHEETS.STUDENTS] = [
    'id', 'student_code', 'name_bn', 'name_en', 'gender', 'date_of_birth',
    'admission_date', 'class_id', 'section_id', 'roll_no', 'status', 'phone',
    'address', 'notes', 'created_at', 'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.GUARDIANS] = [
    'id', 'student_id', 'name', 'relation', 'phone', 'email', 'address',
    'occupation', 'primary_contact', 'status', 'notes', 'created_at',
    'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.CLASSES] = [
    'id', 'name', 'level', 'sort_order', 'status', 'notes', 'created_at',
    'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.SECTIONS] = [
    'id', 'class_id', 'name', 'capacity', 'status', 'notes', 'created_at',
    'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.SUBJECTS] = [
    'id', 'class_id', 'name', 'code', 'sort_order', 'status', 'notes',
    'created_at', 'updated_at', 'updated_by',
  ];
  return headers;
}

function phase2SheetHeaders_() {
  const headers = {};
  headers[CONFIG.SHEETS.ATTENDANCE] = [
    'id', 'attendance_date', 'student_id', 'class_id', 'section_id', 'status',
    'notes', 'recorded_by', 'created_at', 'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.EXAM_TERMS] = [
    'id', 'name', 'class_id', 'section_id', 'start_date', 'end_date', 'status',
    'notes', 'created_at', 'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.EXAM_MARKS] = [
    'id', 'exam_term_id', 'student_id', 'subject_id', 'class_id',
    'marks_obtained', 'max_marks', 'grade', 'status', 'notes', 'created_at',
    'updated_at', 'updated_by',
  ];
  return headers;
}

function phase3SheetHeaders_() {
  const headers = {};
  headers[CONFIG.SHEETS.FEE_PLANS] = [
    'id', 'name', 'class_id', 'month_from', 'month_to', 'amount', 'frequency',
    'status', 'notes', 'created_at', 'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.FEE_PAYMENTS] = [
    'id', 'student_id', 'month_key', 'amount', 'payment_date', 'method',
    'reference', 'fund_type', 'txn_id', 'status', 'notes', 'created_at',
    'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.FEE_WAIVERS] = [
    'id', 'student_id', 'month_key', 'amount', 'reason', 'approved_by',
    'status', 'notes', 'created_at', 'updated_at', 'updated_by',
  ];
  return headers;
}

function phase4SheetHeaders_() {
  const headers = {};
  headers[CONFIG.SHEETS.BUDGETS] = [
    'id', 'month_key', 'fund_type', 'planned_in', 'planned_out', 'notes',
    'status', 'created_at', 'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.APPROVAL_RULES] = [
    'id', 'action_type', 'threshold_amount', 'approver_role', 'active',
    'notes', 'created_at', 'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.APPROVAL_REQUESTS] = [
    'id', 'action_type', 'amount', 'entity_type', 'entity_id', 'summary',
    'status', 'requested_by', 'requested_at', 'decided_by', 'decided_at',
    'decision_notes', 'payload_json', 'created_at', 'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.RECONCILIATION] = [
    'id', 'month_key', 'summary_json', 'pass', 'created_at', 'updated_at',
    'updated_by',
  ];
  return headers;
}

function phase5SheetHeaders_() {
  const headers = {};
  headers[CONFIG.SHEETS.NOTICES] = [
    'id', 'title', 'message', 'target_role', 'target_user_id',
    'target_class_id', 'priority', 'status', 'published_by', 'published_at',
    'expires_at', 'created_at', 'updated_at', 'updated_by',
  ];
  headers[CONFIG.SHEETS.NOTICE_READS] = [
    'id', 'notice_id', 'user_id', 'read_at', 'created_at', 'updated_at',
    'updated_by',
  ];
  headers[CONFIG.SHEETS.DOCUMENTS] = [
    'id', 'title', 'doc_type', 'url', 'entity_type', 'entity_id', 'notes',
    'status', 'uploaded_by', 'created_at', 'updated_at', 'updated_by',
  ];
  return headers;
}

function ensurePhase1Sheet_(sheetName) {
  const headers = phase1SheetHeaders_()[sheetName];
  if (!headers) throw new Error('Unknown Phase 1 sheet: ' + sheetName);
  ensureSheetWithHeaders_(sheetName, headers);
}

function ensurePhase2Sheet_(sheetName) {
  const headers = phase2SheetHeaders_()[sheetName];
  if (!headers) throw new Error('Unknown Phase 2 sheet: ' + sheetName);
  ensureSheetWithHeaders_(sheetName, headers);
}

function ensurePhase3Sheet_(sheetName) {
  const headers = phase3SheetHeaders_()[sheetName];
  if (!headers) throw new Error('Unknown Phase 3 sheet: ' + sheetName);
  ensureSheetWithHeaders_(sheetName, headers);
}

function ensurePhase4Sheet_(sheetName) {
  const headers = phase4SheetHeaders_()[sheetName];
  if (!headers) throw new Error('Unknown Phase 4 sheet: ' + sheetName);
  ensureSheetWithHeaders_(sheetName, headers);
}

function ensurePhase5Sheet_(sheetName) {
  const headers = phase5SheetHeaders_()[sheetName];
  if (!headers) throw new Error('Unknown Phase 5 sheet: ' + sheetName);
  ensureSheetWithHeaders_(sheetName, headers);
}

function ensureSheetWithHeaders_(sheetName, headers) {
  const ss = SpreadsheetApp.openById(getSheetId_());
  let sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.setFrozenRows(1);
    return sheet;
  }

  if (sheet.getLastRow() === 0 || sheet.getLastColumn() === 0) {
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
    sheet.setFrozenRows(1);
    return sheet;
  }

  const existing = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0].map(String);
  const missing = headers.filter(function (h) { return existing.indexOf(h) === -1; });
  if (missing.length) {
    sheet.getRange(1, existing.length + 1, 1, missing.length).setValues([missing]);
  }
  sheet.setFrozenRows(1);
  return sheet;
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
    if (sheetName === CONFIG.SHEETS.TXN) {
      rows.push(normalizeTransactionRow_(obj));
    } else {
      rows.push(obj);
    }
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

function findRowByIdSafe_(sheetName, id) {
  try {
    if (!id) return null;
    return findRowById_(sheetName, id);
  } catch (err) {
    return null;
  }
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

function listAuditLog_(params) {
  params = params || {};
  assertPermission_(params, 'audit.view');

  const rows = listSheetRows_(CONFIG.SHEETS.AUDIT).data || [];
  const moduleFilter = String(params.module || '').trim();
  const actionFilter = String(params.audit_action || '').trim();
  const from = normalizeIsoDate_(params.from || '');
  const to = normalizeIsoDate_(params.to || '');
  const limit = Math.max(1, Math.min(200, Number(params.limit || 80)));

  const filtered = rows.filter(function (r) {
    if (moduleFilter && String(r.module || '') !== moduleFilter) return false;
    if (actionFilter && String(r.action || '') !== actionFilter) return false;
    const doneDay = normalizeIsoDate_(r.done_at || '');
    if (from && doneDay < from) return false;
    if (to && doneDay > to) return false;
    return true;
  });

  filtered.sort(function (a, b) {
    return String(b.done_at || '').localeCompare(String(a.done_at || ''));
  });
  return { ok: true, data: filtered.slice(0, limit) };
}

function notificationSettingDefs_() {
  return [
    { key: 'notify.in_app.enabled', defaultValue: 'TRUE', notes: 'In-app notifications always enabled' },
    { key: 'notify.email.approval', defaultValue: 'FALSE', notes: 'Email on approval-status events' },
    { key: 'notify.email.failed_sync', defaultValue: 'FALSE', notes: 'Email on sync-failed events' },
    { key: 'notify.email.daily_summary', defaultValue: 'FALSE', notes: 'Email daily summary alerts' },
    { key: 'notify.email.due_reminder', defaultValue: 'FALSE', notes: 'Email due reminders' },
    { key: 'notify.email.security_alert', defaultValue: 'FALSE', notes: 'Email security alerts' },
  ];
}

function defaultRoleDefinitions_() {
  const admin = APP_PERMISSIONS.slice();
  const accountant = [
    'dashboard.view',
    'donations.view',
    'donations.write',
    'transactions.manage',
    'expenses.view',
    'expenses.write',
    'beneficiaries.view',
    'beneficiaries.write',
    'salary.view',
    'salary.write',
    'scholarship.view',
    'scholarship.write',
    'academic.foundation.view',
    'academic.foundation.write',
    'academic.core.view',
    'academic.core.write',
    'academic.attendance.write',
    'fees.view',
    'fees.write',
    'finance.view',
    'finance.write',
    'finance.approval_requests.create',
    'communication.view',
    'communication.write',
    'reports.view',
    'roles.view',
    'notifications.view',
    'audit.view',
  ];
  const fieldUser = [
    'dashboard.view',
    'donations.view',
    'donations.write',
    'academic.foundation.view',
    'academic.core.view',
    'academic.attendance.write',
    'communication.view',
    'reports.view',
    'roles.view',
    'notifications.view',
    'finance.approval_requests.create',
  ];
  const viewer = [
    'dashboard.view',
    'donations.view',
    'academic.foundation.view',
    'academic.core.view',
    'communication.view',
    'reports.view',
    'roles.view',
    'notifications.view',
  ];
  return [
    {
      key: 'ADMIN',
      name_bn: 'অ্যাডমিন',
      name_en: 'Admin',
      description: 'Full platform access',
      permissions: admin,
      is_builtin: true,
      active: true,
    },
    {
      key: 'ACCOUNTANT',
      name_bn: 'অ্যাকাউন্ট্যান্ট',
      name_en: 'Accountant',
      description: 'Operations, finance and reports',
      permissions: accountant,
      is_builtin: true,
      active: true,
    },
    {
      key: 'FIELD_USER',
      name_bn: 'ফিল্ড ইউজার',
      name_en: 'Field User',
      description: 'Field collection and attendance tasks',
      permissions: fieldUser,
      is_builtin: true,
      active: true,
    },
    {
      key: 'VIEWER',
      name_bn: 'ভিউয়ার',
      name_en: 'Viewer',
      description: 'Read-only dashboard, academic and reports access',
      permissions: viewer,
      is_builtin: true,
      active: true,
    },
  ];
}

function sanitizePermissionList_(permissions) {
  if (!Array.isArray(permissions)) return [];
  const seen = {};
  return permissions
    .map(function (p) { return String(p || '').trim(); })
    .filter(function (p) {
      if (!p || APP_PERMISSIONS.indexOf(p) === -1 || seen[p]) return false;
      seen[p] = true;
      return true;
    })
    .sort();
}

function validateRoleKey_(value, fieldName) {
  const key = String(value || '').trim().toUpperCase();
  if (!key) throw new Error((fieldName || 'role') + ' is required');
  if (!/^[A-Z][A-Z0-9_]{1,39}$/.test(key)) {
    throw new Error((fieldName || 'role') + ' invalid value: ' + key);
  }
  const defs = readRoleDefinitions_();
  const found = defs.find(function (r) {
    return String(r.key || '').trim().toUpperCase() === key && !!r.active;
  });
  if (!found) throw new Error((fieldName || 'role') + ' invalid value: ' + key);
  return key;
}

function ensureRoleDefinitionDefaults_() {
  const byKey = getSettingsMapByKey_();
  if (byKey[ROLE_DEFINITIONS_SETTING_KEY]) return;
  upsertSettingTextByKey_(
    ROLE_DEFINITIONS_SETTING_KEY,
    JSON.stringify(defaultRoleDefinitions_()),
    'Centralized role definitions and permissions'
  );
}

function readRoleDefinitions_() {
  ensureRoleDefinitionDefaults_();
  const byKey = getSettingsMapByKey_();
  const raw = String((byKey[ROLE_DEFINITIONS_SETTING_KEY] || {}).value || '').trim();
  const defaults = defaultRoleDefinitions_();
  if (!raw) return defaults;

  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return defaults;
    const merged = {};
    defaults.forEach(function (def) {
      merged[def.key] = Object.assign({}, def, {
        permissions: sanitizePermissionList_(def.permissions),
      });
    });
    parsed.forEach(function (item) {
      const key = String((item && item.key) || '').trim().toUpperCase();
      if (!key) return;
      merged[key] = {
        key: key,
        name_bn: String((item && item.name_bn) || key).trim(),
        name_en: String((item && item.name_en) || key).trim(),
        description: String((item && item.description) || '').trim(),
        permissions: sanitizePermissionList_((item && item.permissions) || []),
        is_builtin: !!(item && item.is_builtin),
        active: item && item.active !== false,
      };
    });
    return Object.keys(merged)
      .sort()
      .map(function (key) { return merged[key]; });
  } catch (err) {
    return defaults;
  }
}

function getRoleDefinition_(roleKey) {
  const key = String(roleKey || '').trim().toUpperCase();
  if (!key) return null;
  const defs = readRoleDefinitions_();
  for (let i = 0; i < defs.length; i++) {
    if (String(defs[i].key || '').trim().toUpperCase() === key) return defs[i];
  }
  return null;
}

function roleHasPermission_(roleKey, permission) {
  const def = getRoleDefinition_(roleKey);
  if (!def || !def.active) return false;
  return (def.permissions || []).indexOf(String(permission || '').trim()) !== -1;
}

function assertPermission_(params, permission) {
  const role = validateRoleKey_(params && params.user_role, 'user_role');
  if (!permission) return role;
  if (!roleHasPermission_(role, permission)) {
    addAudit_(
      'security',
      'PERMISSION_DENIED',
      String(permission),
      '',
      JSON.stringify({
        permission: permission,
        action: String((params && params.action) || ''),
        user_id: String((params && params.user_id) || ''),
        role: role,
      }),
      String((params && params.user_id) || role)
    );
    throw new Error('Permission denied for role: ' + role + ' (' + permission + ')');
  }
  return role;
}

function assertActionPermission_(params, action) {
  const permission = ACTION_PERMISSIONS[String(action || '').trim()];
  if (!permission) return;
  assertPermission_(params || {}, permission);
}

function listRoleDefinitions_(params) {
  params = params || {};
  assertPermission_(params, 'roles.view');
  return {
    ok: true,
    data: readRoleDefinitions_().map(function (def) {
      return {
        key: def.key,
        name_bn: def.name_bn,
        name_en: def.name_en,
        description: def.description,
        permissions: sanitizePermissionList_(def.permissions),
        is_builtin: !!def.is_builtin,
        active: def.active !== false,
      };
    }),
  };
}

function upsertRoleDefinition_(payload, params) {
  payload = payload || {};
  params = params || {};
  const key = String(payload.key || '').trim().toUpperCase();
  if (!/^[A-Z][A-Z0-9_]{1,39}$/.test(key)) {
    return { ok: false, message: 'Role key must be uppercase letters, numbers or underscore' };
  }

  const permissions = sanitizePermissionList_(payload.permissions || []);
  if (!permissions.length) {
    return { ok: false, message: 'At least one permission is required' };
  }

  const defs = readRoleDefinitions_();
  const existing = defs.find(function (def) {
    return String(def.key || '').trim().toUpperCase() === key;
  });
  if (existing && existing.is_builtin) {
    return { ok: false, message: 'Built-in roles cannot be edited from here' };
  }

  const nextDef = {
    key: key,
    name_bn: String(payload.name_bn || key).trim(),
    name_en: String(payload.name_en || key).trim(),
    description: String(payload.description || '').trim(),
    permissions: permissions,
    is_builtin: false,
    active: payload.active !== false,
  };
  const before = existing ? JSON.stringify(existing) : '';
  const nextDefs = defs.filter(function (def) {
    return String(def.key || '').trim().toUpperCase() !== key;
  });
  nextDefs.push(nextDef);
  nextDefs.sort(function (a, b) {
    return String(a.key || '').localeCompare(String(b.key || ''));
  });
  upsertSettingTextByKey_(
    ROLE_DEFINITIONS_SETTING_KEY,
    JSON.stringify(nextDefs),
    'Centralized role definitions and permissions'
  );
  addAudit_(
    'roles',
    existing ? 'UPDATE' : 'CREATE',
    key,
    before,
    JSON.stringify(nextDef),
    String(params.user_id || params.user_role || 'admin')
  );
  return { ok: true, data: nextDef };
}

function parseBool_(raw, defaultValue) {
  const v = String(raw === undefined || raw === null ? '' : raw).trim().toUpperCase();
  if (!v) return defaultValue;
  return v === 'TRUE' || v === '1' || v === 'YES' || v === 'ON';
}

function boolToSheet_(value) {
  return value ? 'TRUE' : 'FALSE';
}

function getSettingsMapByKey_() {
  const rows = listSheetRows_(CONFIG.SHEETS.SETTINGS).data || [];
  const out = {};
  rows.forEach(function (r) {
    const key = String(r.key || '').trim();
    if (key) out[key] = r;
  });
  return out;
}

function upsertSettingByKey_(key, value, notes) {
  const sheet = getSheet_(CONFIG.SHEETS.SETTINGS);
  const values = sheet.getDataRange().getValues();
  if (!values.length) throw new Error('settings sheet header missing');

  const headers = values[0].map(String);
  const keyIdx = headers.indexOf('key');
  const valueIdx = headers.indexOf('value');
  const notesIdx = headers.indexOf('notes');
  const updatedAtIdx = headers.indexOf('updated_at');
  if (keyIdx === -1 || valueIdx === -1) {
    throw new Error('settings sheet must contain key and value columns');
  }

  const now = nowIso();
  const nextValue = String(value || '').toUpperCase() === 'TRUE' ? 'TRUE' : 'FALSE';
  for (let i = 1; i < values.length; i++) {
    if (String(values[i][keyIdx] || '').trim() !== key) continue;
    sheet.getRange(i + 1, valueIdx + 1).setValue(nextValue);
    if (notesIdx >= 0 && notes !== undefined) sheet.getRange(i + 1, notesIdx + 1).setValue(notes || '');
    if (updatedAtIdx >= 0) sheet.getRange(i + 1, updatedAtIdx + 1).setValue(now);
    return { mode: 'update', before: values[i][valueIdx], after: nextValue, updated_at: now };
  }

  const rowObj = {
    key: key,
    value: nextValue,
    notes: notes || '',
    updated_at: now,
  };
  const writeRow = headers.map(function (h) {
    return rowObj[h] !== undefined ? rowObj[h] : '';
  });
  sheet.appendRow(writeRow);
  return { mode: 'create', before: '', after: nextValue, updated_at: now };
}

function ensureNotificationDefaults_() {
  const defs = notificationSettingDefs_();
  const byKey = getSettingsMapByKey_();
  defs.forEach(function (d) {
    if (!byKey[d.key]) {
      upsertSettingByKey_(d.key, d.defaultValue, d.notes);
    }
  });
}

function readNotificationSettings_() {
  ensureNotificationDefaults_();
  const byKey = getSettingsMapByKey_();
  const getUpdatedAt = function (key) {
    return String((byKey[key] && byKey[key].updated_at) || '');
  };
  const updatedCandidates = notificationSettingDefs_()
    .map(function (d) { return getUpdatedAt(d.key); })
    .filter(function (x) { return !!x; });
  const updatedAt = updatedCandidates.length ? updatedCandidates.sort().slice(-1)[0] : '';

  return {
    in_app_enabled: true, // locked default
    email_approval: parseBool_((byKey['notify.email.approval'] || {}).value, false),
    email_failed_sync: parseBool_((byKey['notify.email.failed_sync'] || {}).value, false),
    email_daily_summary: parseBool_((byKey['notify.email.daily_summary'] || {}).value, false),
    email_due_reminder: parseBool_((byKey['notify.email.due_reminder'] || {}).value, false),
    email_security_alert: parseBool_((byKey['notify.email.security_alert'] || {}).value, false),
    updated_at: updatedAt,
  };
}

function getNotificationSettings_() {
  return { ok: true, data: readNotificationSettings_() };
}

function appUiSettingDefs_() {
  return [
    { key: 'report.default_from_date', defaultValue: '2022-01-26', notes: 'Default report range start date (YYYY-MM-DD)' },
    { key: 'report.default_to_date', defaultValue: 'TODAY', notes: 'Default report range end date (YYYY-MM-DD or TODAY)' },
    { key: 'report.max_range_days', defaultValue: String(MAX_REPORT_RANGE_DAYS), notes: 'Guard rail: max report span in days' },
  ];
}

function upsertSettingTextByKey_(key, value, notes) {
  const sheet = getSheet_(CONFIG.SHEETS.SETTINGS);
  const values = sheet.getDataRange().getValues();
  if (!values.length) throw new Error('settings sheet header missing');

  const headers = values[0].map(String);
  const keyIdx = headers.indexOf('key');
  const valueIdx = headers.indexOf('value');
  const notesIdx = headers.indexOf('notes');
  const updatedAtIdx = headers.indexOf('updated_at');
  if (keyIdx === -1 || valueIdx === -1) {
    throw new Error('settings sheet must contain key and value columns');
  }

  const now = nowIso();
  const nextValue = String(value === undefined || value === null ? '' : value).trim();
  for (let i = 1; i < values.length; i++) {
    if (String(values[i][keyIdx] || '').trim() !== key) continue;
    sheet.getRange(i + 1, valueIdx + 1).setValue(nextValue);
    if (notesIdx >= 0 && notes !== undefined) sheet.getRange(i + 1, notesIdx + 1).setValue(notes || '');
    if (updatedAtIdx >= 0) sheet.getRange(i + 1, updatedAtIdx + 1).setValue(now);
    return { mode: 'update', before: values[i][valueIdx], after: nextValue, updated_at: now };
  }

  const rowObj = {
    key: key,
    value: nextValue,
    notes: notes || '',
    updated_at: now,
  };
  const writeRow = headers.map(function (h) {
    return rowObj[h] !== undefined ? rowObj[h] : '';
  });
  sheet.appendRow(writeRow);
  return { mode: 'create', before: '', after: nextValue, updated_at: now };
}

function ensureAppUiDefaults_() {
  const defs = appUiSettingDefs_();
  const byKey = getSettingsMapByKey_();
  defs.forEach(function (d) {
    if (!byKey[d.key]) upsertSettingTextByKey_(d.key, d.defaultValue, d.notes);
  });
}

function readAppUiSettings_() {
  ensureAppUiDefaults_();
  const byKey = getSettingsMapByKey_();
  const fromRaw = String((byKey['report.default_from_date'] || {}).value || '2022-01-26').trim();
  const toRaw = String((byKey['report.default_to_date'] || {}).value || 'TODAY').trim().toUpperCase();
  const maxRaw = String((byKey['report.max_range_days'] || {}).value || String(MAX_REPORT_RANGE_DAYS)).trim();

  const from = isIsoDateText_(fromRaw) ? fromRaw : '2022-01-26';
  const to = toRaw === 'TODAY' ? todayIso_() : (isIsoDateText_(toRaw) ? toRaw : todayIso_());
  const maxDays = Math.max(1, Math.min(MAX_REPORT_RANGE_DAYS, parseInt(maxRaw, 10) || MAX_REPORT_RANGE_DAYS));
  const updatedCandidates = appUiSettingDefs_()
    .map(function (d) { return String((byKey[d.key] || {}).updated_at || ''); })
    .filter(function (v) { return !!v; });

  return {
    default_from_date: from,
    default_to_date: to,
    default_to_source: toRaw === 'TODAY' ? 'TODAY' : 'FIXED',
    max_range_days: maxDays,
    updated_at: updatedCandidates.length ? updatedCandidates.sort().slice(-1)[0] : '',
  };
}

function getAppUiSettings_(params) {
  params = params || {};
  assertPermission_(params, 'reports.view');
  return { ok: true, data: readAppUiSettings_() };
}

function upsertAppUiSettings_(payload, params) {
  payload = payload || {};
  params = params || {};

  const before = readAppUiSettings_();
  const from = normalizeIsoDate_(String(payload.default_from_date || before.default_from_date));
  const toToken = String(payload.default_to_mode || '').trim().toUpperCase();
  const toInputRaw = String(payload.default_to_date || before.default_to_date).trim();
  const to = toToken === 'TODAY' ? 'TODAY' : normalizeIsoDate_(toInputRaw);

  if (!isIsoDateText_(from)) return { ok: false, message: 'default_from_date must be YYYY-MM-DD' };
  if (to !== 'TODAY' && !isIsoDateText_(to)) {
    return { ok: false, message: 'default_to_date must be YYYY-MM-DD or TODAY mode' };
  }

  const resolvedTo = to === 'TODAY' ? todayIso_() : to;
  const days = rangeDaysInclusive_(from, resolvedTo);
  if (days > MAX_REPORT_RANGE_DAYS) {
    return { ok: false, message: 'Default range cannot exceed ' + MAX_REPORT_RANGE_DAYS + ' days' };
  }

  upsertSettingTextByKey_('report.default_from_date', from, 'Default report range start date (YYYY-MM-DD)');
  upsertSettingTextByKey_('report.default_to_date', to, 'Default report range end date (YYYY-MM-DD or TODAY)');
  upsertSettingTextByKey_('report.max_range_days', String(MAX_REPORT_RANGE_DAYS), 'Guard rail: max report span in days');

  const after = readAppUiSettings_();
  addAudit_(
    'settings',
    'APP_UI_RANGE_UPDATE',
    'report.default.range',
    JSON.stringify(before),
    JSON.stringify(after),
    String(params.user_id || params.user_role || 'admin')
  );
  return { ok: true, data: after };
}

function getEmailToggleByCategory_(settings, category) {
  if (category === 'approval') return !!settings.email_approval;
  if (category === 'failed_sync') return !!settings.email_failed_sync;
  if (category === 'daily_summary') return !!settings.email_daily_summary;
  if (category === 'due_reminder') return !!settings.email_due_reminder;
  if (category === 'security_alert') return !!settings.email_security_alert;
  return false;
}

function getAdminAlertEmail_() {
  const byKey = getSettingsMapByKey_();
  const raw = String(((byKey['notify.email.admin_recipient'] || {}).value) || '').trim();
  return raw || 'zakerchy@gmail.com';
}

function appendRowOptional_(sheetName, obj) {
  const ss = SpreadsheetApp.openById(getSheetId_());
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return false;

  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0].map(String);
  const row = headers.map(function (h) { return obj[h] !== undefined ? obj[h] : ''; });
  sheet.appendRow(row);
  return true;
}

function listOptionalSheetRows_(sheetName) {
  const ss = SpreadsheetApp.openById(getSheetId_());
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return [];
  const values = sheet.getDataRange().getValues();
  if (!values.length) return [];

  const headers = values[0].map(String);
  const rows = [];
  for (let i = 1; i < values.length; i++) {
    const row = values[i];
    if (!row.join('').trim()) continue;
    const obj = {};
    headers.forEach(function (h, idx) { obj[h] = row[idx]; });
    rows.push(obj);
  }
  return rows;
}

function createInAppNotification_(category, title, message, options) {
  options = options || {};
  const event = {
    id: uid_('notif'),
    category: category || 'general',
    title: title || 'Notification',
    message: message || '',
    target_role: options.target_role || '',
    target_user_id: options.target_user_id || '',
    email_enabled: boolToSheet_(!!options.email_enabled),
    email_sent: boolToSheet_(!!options.email_sent),
    email_error: options.email_error || '',
    meta_json: options.meta_json || '',
    created_by: options.created_by || 'system',
    created_at: nowIso(),
  };

  const stored = appendRowOptional_(CONFIG.SHEETS.NOTIFICATIONS, event);
  if (!stored) {
    addAudit_('notifications', 'IN_APP_EVENT', event.id, '', JSON.stringify(event), event.created_by);
  }
  return Object.assign({}, event, { stored: stored });
}

function trySendNotificationEmail_(recipient, subject, textBody, htmlBody) {
  if (!recipient) {
    return { sent: false, skipped: true, reason: 'recipient_missing' };
  }

  try {
    const quota = MailApp.getRemainingDailyQuota();
    if (Number(quota || 0) <= 0) {
      return { sent: false, skipped: true, reason: 'daily_quota_exhausted' };
    }

    GmailApp.sendEmail(recipient, subject, textBody, {
      name: 'মাদ্রাসা ERP',
      htmlBody: htmlBody,
    });
    return { sent: true };
  } catch (err) {
    return { sent: false, skipped: false, reason: String(err) };
  }
}

function dispatchNotification_(opts) {
  opts = opts || {};
  const category = String(opts.category || 'general');
  const settings = readNotificationSettings_();
  const emailEnabled = getEmailToggleByCategory_(settings, category);

  const emailResult = emailEnabled
    ? trySendNotificationEmail_(
        String(opts.recipient_email || ''),
        String(opts.email_subject || opts.title || 'Notification'),
        String(opts.email_text || opts.message || ''),
        String(opts.email_html || ('<p>' + String(opts.message || '') + '</p>'))
      )
    : { sent: false, skipped: true, reason: 'toggle_off' };

  const event = createInAppNotification_(
    category,
    String(opts.title || 'Notification'),
    String(opts.message || ''),
    {
      target_role: String(opts.target_role || ''),
      target_user_id: String(opts.target_user_id || ''),
      email_enabled: emailEnabled,
      email_sent: !!emailResult.sent,
      email_error: emailResult.reason || '',
      meta_json: JSON.stringify(opts.meta || {}),
      created_by: String(opts.created_by || 'system'),
    }
  );

  return {
    category: category,
    in_app: event,
    email: emailResult,
  };
}

function upsertNotificationSettings_(payload, params) {
  payload = payload || {};
  params = params || {};

  const before = readNotificationSettings_();

  const changes = [
    { key: 'notify.email.approval', value: parseBool_(payload.email_approval, before.email_approval), notes: 'Email on approval-status events' },
    { key: 'notify.email.failed_sync', value: parseBool_(payload.email_failed_sync, before.email_failed_sync), notes: 'Email on sync-failed events' },
    { key: 'notify.email.daily_summary', value: parseBool_(payload.email_daily_summary, before.email_daily_summary), notes: 'Email daily summary alerts' },
    { key: 'notify.email.due_reminder', value: parseBool_(payload.email_due_reminder, before.email_due_reminder), notes: 'Email due reminders' },
    { key: 'notify.email.security_alert', value: parseBool_(payload.email_security_alert, before.email_security_alert), notes: 'Email security alerts' },
  ];

  changes.forEach(function (c) {
    upsertSettingByKey_(c.key, boolToSheet_(c.value), c.notes);
  });

  // Locked by policy: in-app notification stays enabled.
  upsertSettingByKey_('notify.in_app.enabled', 'TRUE', 'In-app notifications always enabled');

  const after = readNotificationSettings_();
  addAudit_(
    'settings',
    'NOTIFICATION_TOGGLE_UPDATE',
    'notify.settings',
    JSON.stringify(before),
    JSON.stringify(after),
    String(params.user_id || params.user_role || 'admin')
  );

  return { ok: true, data: after };
}

function listInAppNotifications_(params) {
  params = params || {};
  assertPermission_(params, 'notifications.view');
  const role = String(params.user_role || '');
  const userId = String(params.user_id || '');

  const data = listOptionalSheetRows_(CONFIG.SHEETS.NOTIFICATIONS);
  const rows = data.filter(function (r) {
    const targetRole = String(r.target_role || '').trim();
    const targetUserId = String(r.target_user_id || '').trim();
    if (!targetRole && !targetUserId) return true;
    if (targetUserId && targetUserId === userId) return true;
    if (targetRole && targetRole === role) return true;
    return false;
  });

  rows.sort(function (a, b) {
    return String(b.created_at || '').localeCompare(String(a.created_at || ''));
  });
  return { ok: true, data: rows.slice(0, 100) };
}

function createNotificationEvent_(payload, params) {
  payload = payload || {};
  params = params || {};

  const category = String(payload.category || 'general');
  const title = String(payload.title || 'Notification');
  const message = String(payload.message || '');
  if (!message) return { ok: false, message: 'message is required' };

  const recipient = String(payload.recipient_email || '');
  const targetRole = String(payload.target_role || params.user_role || '');
  const targetUserId = String(payload.target_user_id || params.user_id || '');

  const result = dispatchNotification_({
    category: category,
    title: title,
    message: message,
    recipient_email: recipient,
    email_subject: String(payload.email_subject || title),
    email_text: String(payload.email_text || message),
    email_html: String(payload.email_html || ('<p>' + message + '</p>')),
    target_role: targetRole,
    target_user_id: targetUserId,
    created_by: String(params.user_id || params.user_role || 'system'),
    meta: payload.meta || {},
  });

  return { ok: true, data: result };
}

function logClientGuard_(payload, params) {
  payload = payload || {};
  params = params || {};
  const guardType = String(payload.type || 'ROUTE_DENIED').trim().toUpperCase();
  const permission = String(payload.permission || '').trim();
  const routeName = String(payload.route_name || '').trim();
  addAudit_(
    'client_guard',
    guardType,
    permission || routeName || uid_('guard'),
    '',
    JSON.stringify({
      permission: permission,
      route_name: routeName,
      role: String(params.user_role || ''),
      user_id: String(params.user_id || ''),
    }),
    String(params.user_id || params.user_role || 'unknown')
  );
  return { ok: true };
}

function assertRole_(currentRole, allowedRoles) {
  if (!currentRole) throw new Error('user_role is required');
  const role = validateRoleKey_(currentRole, 'user_role');
  if (Array.isArray(allowedRoles) && allowedRoles.length && allowedRoles.indexOf(role) === -1) {
    throw new Error('Permission denied for role: ' + role);
  }
  return role;
}

function requireUserIdIfFieldRole_(role, userId) {
  if (role === 'FIELD_USER' && !userId) {
    throw new Error('user_id is required for FIELD_USER scope');
  }
}

function isVisibleToFieldUser_(row, userId) {
  const createdBy = String((row && row.created_by) || '').trim();
  if (createdBy === String(userId || '').trim()) return true;
  // Legacy/migrated data had no user ownership. Keep visible as read-only history.
  return createdBy === '' || createdBy === 'migration' || createdBy === 'system';
}

function normalizeTransactionRow_(row) {
  const out = Object.assign({}, row || {});
  out.txn_date = normalizeIsoDate_(out.txn_date);
  out.direction = String(out.direction || '').trim().toUpperCase();
  out.fund_type = String(out.fund_type || '').trim().toUpperCase();
  out.status = String(out.status || 'ACTIVE').trim().toUpperCase() || 'ACTIVE';
  out.amount = normalizeNumber_(out.amount);
  return out;
}

function normalizeActiveStatus_(raw) {
  const value = String(raw || 'ACTIVE').trim().toUpperCase();
  return value === 'INACTIVE' || value === 'ARCHIVED' ? value : 'ACTIVE';
}

function normalizeAttendanceStatus_(raw) {
  const value = String(raw || 'PRESENT').trim().toUpperCase();
  const allowed = ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'];
  if (allowed.indexOf(value) === -1) throw new Error('Invalid attendance status: ' + value);
  return value;
}

function stableAcademicId_(prefix, parts) {
  const raw = parts.map(function (p) { return String(p || '').trim(); }).join('_');
  return prefix + '_' + raw.replace(/[^A-Za-z0-9]+/g, '_').replace(/^_+|_+$/g, '').slice(0, 120);
}

function gradeFromPercent_(percent) {
  const p = Number(percent || 0);
  if (p >= 80) return 'A+';
  if (p >= 70) return 'A';
  if (p >= 60) return 'A-';
  if (p >= 50) return 'B';
  if (p >= 40) return 'C';
  if (p >= 33) return 'D';
  return 'F';
}

function normalizeMonthKey_(raw) {
  if (raw === null || raw === undefined || raw === '') return '';
  if (Object.prototype.toString.call(raw) === '[object Date]' && !isNaN(raw.getTime())) {
    return Utilities.formatDate(raw, Session.getScriptTimeZone(), 'yyyy-MM');
  }
  const text = String(raw).trim();
  const match = text.match(/^(\d{4})[-/](\d{1,2})/);
  if (match) return match[1] + '-' + match[2].padStart(2, '0');
  const parsed = new Date(text);
  if (!isNaN(parsed.getTime())) {
    return Utilities.formatDate(parsed, Session.getScriptTimeZone(), 'yyyy-MM');
  }
  return text.slice(0, 7);
}

function isMonthKey_(text) {
  return /^\d{4}-(0[1-9]|1[0-2])$/.test(String(text || '').trim());
}

function lastDayOfMonthIso_(monthKey) {
  const parts = String(monthKey || '').split('-');
  const year = Number(parts[0] || 0);
  const month = Number(parts[1] || 0);
  if (!year || !month) return '';
  const d = new Date(Date.UTC(year, month, 0));
  return d.getUTCFullYear() + '-' + String(d.getUTCMonth() + 1).padStart(2, '0') + '-' + String(d.getUTCDate()).padStart(2, '0');
}

function normalizeIsoDate_(raw) {
  if (raw === null || raw === undefined || raw === '') return '';
  if (Object.prototype.toString.call(raw) === '[object Date]' && !isNaN(raw.getTime())) {
    return Utilities.formatDate(raw, Session.getScriptTimeZone(), 'yyyy-MM-dd');
  }
  const text = String(raw).trim();
  if (!text) return '';
  const match = text.match(/^(\d{4})[-/](\d{2})[-/](\d{2})/);
  if (match) return match[1] + '-' + match[2] + '-' + match[3];
  const parsed = new Date(text);
  if (!isNaN(parsed.getTime())) {
    return Utilities.formatDate(parsed, Session.getScriptTimeZone(), 'yyyy-MM-dd');
  }
  return text.slice(0, 10);
}

function isIsoDateText_(text) {
  return /^\d{4}-\d{2}-\d{2}$/.test(String(text || '').trim());
}

function rangeDaysInclusive_(fromIso, toIso) {
  const from = new Date(fromIso + 'T00:00:00Z');
  const to = new Date(toIso + 'T00:00:00Z');
  if (isNaN(from.getTime()) || isNaN(to.getTime())) return 0;
  return Math.floor((to.getTime() - from.getTime()) / 86400000) + 1;
}

function normalizeNumber_(raw) {
  if (raw === null || raw === undefined || raw === '') return 0;
  if (typeof raw === 'number') return isNaN(raw) ? 0 : raw;
  let s = String(raw).trim();
  if (!s) return 0;
  s = s.replace(/[৳,\s]/g, '').replace(/[^0-9.-]/g, '');
  const n = Number(s);
  return isNaN(n) ? 0 : n;
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

  const adminEmail = getAdminAlertEmail_();
  const result = dispatchNotification_({
    category: 'security_alert',
    title: 'পিন রিসেট অনুরোধ',
    message: 'ব্যবহারকারী ' + String(user.name || '') + ' (' + email + ') পিন রিসেট অনুরোধ করেছেন।',
    recipient_email: adminEmail,
    email_subject: 'পিন রিসেট অনুরোধ — ' + String(user.name || ''),
    email_text: 'ব্যবহারকারী: ' + user.name + '\nইমেইল: ' + email + '\n\nপিন রিসেট লিংক:\n' + resetUrl + '\n\n৩০ মিনিটের মধ্যে করতে হবে।',
    email_html:
      '<p><b>ব্যবহারকারী:</b> ' + user.name + '<br><b>ইমেইল:</b> ' + email + '</p>' +
      '<p><a href="' + resetUrl + '" style="background:#166534;color:white;padding:10px 20px;text-decoration:none;border-radius:6px">পিন রিসেট করুন</a></p>' +
      '<p style="color:#666;font-size:12px">লিংকটি ৩০ মিনিটের মধ্যে ব্যবহার করুন।</p>',
    target_role: 'ADMIN',
    created_by: email,
    meta: { email: email, user_id: user.id, type: 'pin_reset_request' },
  });

  return {
    ok: true,
    message: result.email.sent
      ? 'রিসেট অনুরোধ গ্রহণ করা হয়েছে এবং ইমেইল পাঠানো হয়েছে।'
      : 'রিসেট অনুরোধ গ্রহণ করা হয়েছে। Admin in-app notification দেখতে পারবেন।',
    data: result,
  };
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

function upsertUser_(payload, params) {
  payload = payload || {};
  params = params || {};
  validateRequired_(payload, ['id', 'name', 'email', 'role']);
  const roleKey = validateRoleKey_(payload.role, 'role');
  const email = String(payload.email || '').trim().toLowerCase();
  if (!email || email.indexOf('@') === -1) {
    return { ok: false, message: 'Valid email is required' };
  }

  const next = Object.assign({}, payload, {
    role: roleKey,
    email: email,
    name: String(payload.name || '').trim(),
    phone: String(payload.phone || '').trim(),
    active: String(payload.active || 'TRUE').trim().toUpperCase() === 'TRUE' ? 'TRUE' : 'FALSE',
    approval_status: String(payload.approval_status || 'APPROVED').trim().toUpperCase(),
    updated_by: String(params.user_id || params.user_role || 'admin'),
  });
  const res = upsertById_(CONFIG.SHEETS.USERS, next);
  addAudit_(
    'users',
    res.mode === 'create' ? 'CREATE' : 'UPDATE',
    next.id,
    '',
    JSON.stringify({
      role: next.role,
      active: next.active,
      approval_status: next.approval_status,
      email: next.email,
    }),
    String(params.user_id || params.user_role || 'admin')
  );
  return res;
}

function listUsers_(params) {
  params = params || {};
  assertPermission_(params, 'users.manage');
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

function setUserApprovalStatus_(payload, params) {
  params = params || {};
  validateRequired_(payload, ['id', 'approval_status']);
  const validStatuses = ['APPROVED', 'PENDING', 'REJECTED', 'BLOCKED'];
  if (validStatuses.indexOf(String(payload.approval_status)) === -1) {
    throw new Error('Invalid approval_status: ' + payload.approval_status);
  }
  const res = updateById_(CONFIG.SHEETS.USERS, payload.id, { approval_status: payload.approval_status });
  const userEmail = String((res.after || {}).email || '').trim().toLowerCase();
  const approval = String((res.after || {}).approval_status || payload.approval_status);
  const notification = dispatchNotification_({
    category: 'approval',
    title: 'Approval status updated',
    message: 'User "' + String((res.after || {}).name || payload.id) + '" status: ' + approval,
    recipient_email: userEmail,
    email_subject: 'Account status update',
    email_text: 'আপনার অ্যাকাউন্ট স্ট্যাটাস এখন: ' + approval,
    email_html: '<p>আপনার অ্যাকাউন্ট স্ট্যাটাস এখন: <b>' + approval + '</b></p>',
    target_user_id: String((res.after || {}).id || payload.id),
    created_by: String(params.user_id || params.user_role || 'admin'),
    meta: { user_id: payload.id, approval_status: approval },
  });
  return { ok: true, data: res.after, notification: notification };
}

function generateTempResetToken_(payload, params) {
  params = params || {};
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
  const notification = dispatchNotification_({
    category: 'security_alert',
    title: 'Temporary reset token generated',
    message: 'Reset token generated for ' + String(user.name || user.id || ''),
    recipient_email: getAdminAlertEmail_(),
    email_subject: 'Temporary reset token generated',
    email_text: 'User: ' + String(user.name || '') + '\nEmail: ' + String(user.email || '') + '\nToken expires at: ' + new Date(expiry).toISOString(),
    email_html: '<p><b>User:</b> ' + String(user.name || '') + '<br><b>Email:</b> ' + String(user.email || '') +
      '<br><b>Expires:</b> ' + new Date(expiry).toISOString() + '</p>',
    target_role: 'ADMIN',
    created_by: String(params.user_id || params.user_role || 'admin'),
    meta: { user_id: payload.id, type: 'temp_reset_token' },
  });

  return { ok: true, data: { token: token, expires_at: new Date(expiry).toISOString(), reset_url: resetUrl }, notification: notification };
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
