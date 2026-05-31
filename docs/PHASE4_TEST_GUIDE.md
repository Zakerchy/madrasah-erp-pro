# Phase 4 Testing Guide (End-to-End)

This guide verifies everything implemented up to Phase 4.

## A) Prepare Google Sheet
1. Create a new Google Spreadsheet.
2. Create tabs with these exact names:
- `users_roles`
- `fund_transactions`
- `expense_details`
- `salary_staff`
- `salary_payments`
- `beneficiaries`
- `scholarship_monthly_plan`
- `scholarship_payments`
- `audit_log`
- `settings`
- `notifications`
3. From `sheets/*.csv`, copy only header row to each tab.

## B) Import Initial Data (Optional but Recommended)
1. Use these generated files:
- `tools/output/migrated_fund_transactions.csv`
- `tools/output/migrated_beneficiaries.csv`
- `tools/output/migrated_scholarship_payments.csv`
2. Import each CSV into corresponding tab.

## C) Deploy Apps Script Backend
1. Open Google Apps Script.
2. Create project and paste:
- `backend-apps-script/Code.gs`
- `backend-apps-script/appsscript.json`
3. In `Code.gs`, set:
- `CONFIG.SHEET_ID = "YOUR_SPREADSHEET_ID"`
4. Deploy as Web App:
- Execute as: Me
- Access: Anyone with link (or restricted if you prefer)
5. Copy deployment URL.

## D) Create First Login User
1. Open deployed URL in browser with:
- `?action=hashPin&pin=1234`
2. Copy `pin_hash` from response JSON.
3. Add one row in `users_roles` tab:
- `id`: `u_admin_1`
- `name`: `Admin`
- `phone`: `01700000000`
- `email`: `admin@example.com`
- `role`: `ADMIN`
- `active`: `TRUE`
- `pin_hash`: (copied hash)
- `created_at`: now
- `updated_at`: now

## E) Configure Mobile App
1. Open `mobile-app/lib/core/app_config.dart`.
2. Replace `apiBaseUrl` with your deployed Apps Script URL.

## F) Run Mobile App
1. Install Flutter SDK on machine.
2. From `mobile-app/` run:
- `flutter pub get`
- `flutter run`
3. Login with:
- Phone: `01700000000`
- PIN: `1234`

## G) Functional Test Cases

### 1) Login and Session
1. Login with valid phone/PIN.
2. Expect dashboard to open.
3. Drawer should show user name and role.

### 2) Donation Flow
1. Go to Donations.
2. Add one donation (IN).
3. Verify it appears in recent list.
4. Verify new row in `fund_transactions`.
5. Verify dashboard totals increase.

### 3) Expense Flow
1. Go to Expenses.
2. Add one expense (OUT) with fund type.
3. Verify it appears in recent list.
4. Verify row in `fund_transactions`.
5. Verify dashboard balance reduces.

### 4) Beneficiary Flow
1. Go to Beneficiaries.
2. Add one beneficiary.
3. Verify entry appears in list and `beneficiaries` tab.

### 5) Salary Flow
1. Go to Salary.
2. Add a staff member.
3. Record salary payment.
4. Verify rows in:
- `salary_staff`
- `salary_payments`
- `fund_transactions` (auto OUT)

### 6) Scholarship Flow
1. Go to Scholarship.
2. Select month and beneficiary.
3. Enter payment breakup and save.
4. Verify rows in:
- `scholarship_payments`
- `fund_transactions` (auto OUT)

### 7) Reports Flow
1. Go to Reports.
2. Load a `month_key` (e.g. `2025-04`).
3. Verify total in/out/balance shown.
4. Verify rows list matches `fund_transactions` for same month.

### 8) Audit Log Check
1. Open `audit_log` sheet.
2. Verify create/update actions are being logged.

## H) Quick API Smoke Tests (Browser)
Use your deployed URL with query:
1. `?action=health`
2. `?action=dashboardSummary`
3. `?action=listTransactions&direction=IN`
4. `?action=listSalaryPayments`
5. `?action=listScholarshipByMonth&monthKey=2025-04`

## I) Expected Result Criteria
1. All module saves should reflect in Google Sheet instantly.
2. Dashboard balance should match sheet totals.
3. Salary/Scholarship payments must auto-generate linked transactions.
4. No role should perform restricted write actions.

## J) If Something Fails
1. Check tab names and header names exactly match templates.
2. Confirm `CONFIG.SHEET_ID` is correct.
3. Confirm app `apiBaseUrl` is correct deployment URL.
4. Check Apps Script execution logs for exact error line.
