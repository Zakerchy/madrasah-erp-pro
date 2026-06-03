# Modules and Roles

## Roles
- `ADMIN`: full access, report, config
- `ACCOUNTANT`: add/edit financial entries
- `FIELD_USER`: limited field entry + attendance + own scoped records
- `VIEWER`: read-only + report/share access

## Module Access Matrix
- Dashboard: ADMIN, ACCOUNTANT, FIELD_USER, VIEWER
- Students & Academic setup: ADMIN, ACCOUNTANT
- Attendance & Results: ADMIN, ACCOUNTANT, FIELD_USER
- Donation: ADMIN, ACCOUNTANT, FIELD_USER
- Fees & Dues: ADMIN, ACCOUNTANT
- Finance Control: ADMIN, ACCOUNTANT
- Notices & Documents view/read: ADMIN, ACCOUNTANT, FIELD_USER, VIEWER
- Notices & Documents publish/save: ADMIN, ACCOUNTANT
- Expense: ADMIN, ACCOUNTANT
- Salary: ADMIN, ACCOUNTANT
- Scholarship: ADMIN, ACCOUNTANT
- Beneficiaries: ADMIN, ACCOUNTANT
- Reports/Share: ADMIN, ACCOUNTANT, FIELD_USER, VIEWER
- Settings/User Mgmt/Notification Controls: ADMIN

## Role Summary
- `ADMIN`: সব module access, user create/update, approval decision, settings, notification control, finance control
- `ACCOUNTANT`: প্রায় সব operational module access, কিন্তু settings/user management/final approval rule admin-only
- `FIELD_USER`: dashboard, donation create, attendance save, notice read, reports view; accounting/config write access নেই
- `VIEWER`: dashboard, reports, notices/documents read-only; data create/edit access নেই
