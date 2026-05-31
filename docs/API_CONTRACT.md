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

## Reports
- `GET ?action=monthlyReport&monthKey=YYYY-MM`

## Notification Settings (ADMIN)
- `GET ?action=getNotificationSettings&user_role=ADMIN`
- `POST { action: "upsertNotificationSettings", user_role: "ADMIN", payload: { email_approval, email_failed_sync, email_daily_summary, email_due_reminder, email_security_alert } }`

## In-App Notification Events
- `GET ?action=listInAppNotifications&user_role=&user_id=`
- `POST { action: "createNotificationEvent", user_role: "...", user_id: "...", payload: { category, title, message, recipient_email? } }`
