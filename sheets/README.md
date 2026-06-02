# Sheet Templates

Create a Google Spreadsheet and add one sheet tab for each CSV filename.
Copy the header row from each CSV into the corresponding tab.

Recommended tab names:
- users_roles
- fund_transactions
- expense_details
- salary_staff
- salary_payments
- beneficiaries
- scholarship_monthly_plan
- scholarship_payments
- students
- student_guardians
- classes
- sections
- subjects
- audit_log
- settings
- notifications

Phase 1 academic tabs are also auto-created by the Apps Script backend on first
`list*` or `upsert*` call if they are missing. These CSV files remain the repo
source of truth for header order.
