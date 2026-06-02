# Apps Script API Contract (Draft)

Base URL:
- `https://script.google.com/macros/s/{DEPLOYMENT_ID}/exec`

Headers:
- `Content-Type: application/json`
- `x-api-key: {optional_shared_key}`

## Health
- `GET ?action=health`

## Login
- `POST { action: "login", phone: "...", pin: "..." }`

## Dashboard Summary
- `GET ?action=dashboardSummary&from=YYYY-MM-DD&to=YYYY-MM-DD`

## Fund Transactions
- `GET ?action=listTransactions&fundType=&from=&to=`
- `POST { action: "createTransaction", payload: {...} }`
- `POST { action: "updateTransaction", id: "...", payload: {...} }`

## Salary
- `GET ?action=listStaff`
- `POST { action: "upsertStaff", payload: {...} }`
- `POST { action: "recordSalaryPayment", payload: {...} }`

## Beneficiaries
- `GET ?action=listBeneficiaries`
- `POST { action: "upsertBeneficiary", payload: {...} }`

## Scholarship
- `GET ?action=listScholarshipByMonth&monthKey=YYYY-MM`
- `POST { action: "saveScholarshipPayment", payload: {...} }`

## Academic Foundation
- `GET ?action=listStudents&class_id=&section_id=&status=&search=&limit=300`
- `POST { action: "upsertStudent", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { id?, student_code?, name_bn, name_en?, gender?, date_of_birth?, admission_date?, class_id, section_id?, roll_no?, status?, phone?, address?, notes? } }`
- `GET ?action=listStudentGuardians&student_id=`
- `POST { action: "upsertStudentGuardian", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { id?, student_id, name, relation, phone, email?, address?, occupation?, primary_contact?, status?, notes? } }`
- `GET ?action=listClasses`
- `POST { action: "upsertClass", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { id?, name, level?, sort_order?, status?, notes? } }`
- `GET ?action=listSections&class_id=`
- `POST { action: "upsertSection", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { id?, class_id, name, capacity?, status?, notes? } }`
- `GET ?action=listSubjects&class_id=`
- `POST { action: "upsertSubject", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { id?, class_id, name, code?, sort_order?, status?, notes? } }`
- Phase 1 academic sheets are auto-provisioned by Apps Script on first list/upsert if missing.
- Every upsert uses audit log through `upsertById_`.

## Academic Core
- `GET ?action=listAttendance&attendance_date=YYYY-MM-DD&class_id=&section_id=&student_id=`
- `POST { action: "saveAttendance", user_role: "ADMIN|ACCOUNTANT|FIELD_USER", user_id: "...", payload: { attendance_date, class_id, section_id?, rows: [{ student_id, status, notes? }] } }`
- `GET ?action=listExamTerms&class_id=&section_id=`
- `POST { action: "upsertExamTerm", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { id?, name, class_id, section_id?, start_date, end_date, status?, notes? } }`
- `GET ?action=listExamMarks&exam_term_id=&student_id=&subject_id=&class_id=`
- `POST { action: "saveExamMark", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { exam_term_id, student_id, subject_id, class_id?, marks_obtained, max_marks, grade?, notes? } }`
- `GET ?action=resultSummary&exam_term_id=&class_id=&section_id=`
- Phase 2 sheets are auto-provisioned by Apps Script on first list/upsert if missing.
- Attendance IDs are deterministic by date/student, and marks IDs are deterministic by exam/student/subject to prevent duplicate rows.
- Every attendance/exam/mark write uses audit log through `upsertById_`.

## Fee, Dues, Scholarship Automation
- `GET ?action=listFeePlans&class_id=`
- `POST { action: "upsertFeePlan", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { id?, name, class_id?, month_from?, month_to?, amount, frequency?, status?, notes? } }`
- `GET ?action=listFeePayments&month_key=YYYY-MM&student_id=`
- `POST { action: "recordFeePayment", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { student_id, month_key, amount, payment_date?, method?, reference?, fund_type?, notes? } }`
- `GET ?action=listFeeWaivers&month_key=YYYY-MM&student_id=`
- `POST { action: "upsertFeeWaiver", user_role: "ADMIN|ACCOUNTANT", user_id: "...", payload: { id?, student_id, month_key, amount, reason, notes? } }`
- `GET ?action=listFeeDues&month_key=YYYY-MM&class_id=&student_id=`
- Fee payment creates an `IN` ledger row in `fund_transactions` with category `STUDENT_FEE`.
- Dues are calculated as `planned - paid - waived`, capped at `0`.
- Waiver requires a reason and writes audit through `upsertById_`.

## Reports
- `GET ?action=monthlyReport&monthKey=YYYY-MM`
- `GET ?action=rangeReport&from=YYYY-MM-DD&to=YYYY-MM-DD`
- Range reports are limited to 366 days.

## App UI Settings
- `GET ?action=getAppUiSettings&user_role=ADMIN`
- `POST { action: "upsertAppUiSettings", user_role: "ADMIN", payload: { default_from_date, default_to_date, default_to_mode } }`

## Audit Log
- `GET ?action=listAuditLog&user_role=ADMIN&limit=80`

## Notification Settings (ADMIN)
- `GET ?action=getNotificationSettings&user_role=ADMIN`
- `POST { action: "upsertNotificationSettings", user_role: "ADMIN", payload: { email_approval, email_failed_sync, email_daily_summary, email_due_reminder, email_security_alert } }`

## In-App Notification Events
- `GET ?action=listInAppNotifications&user_role=&user_id=`
- `POST { action: "createNotificationEvent", user_role: "...", user_id: "...", payload: { category, title, message, recipient_email? } }`
