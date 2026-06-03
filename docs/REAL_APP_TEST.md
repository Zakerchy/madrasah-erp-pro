# Real App Test (Native Android) - No Local Flutter Install

## 1) Backend ready করুন (Apps Script)
1. `backend-apps-script/Code.gs` Google Apps Script এ deploy করুন.
2. `CONFIG.SHEET_ID` আপনার Google Sheet ID দিন.
3. Deploy URL কপি করুন (শেষে `/exec` থাকবে).

## 2) GitHub secret set করুন
Repository -> Settings -> Secrets and variables -> Actions -> New repository secret

- Name: `APPS_SCRIPT_URL` (recommended)
- Optional legacy fallback: `API_BASE_URL`
- Value: আপনার Apps Script Web App URL (e.g. `https://script.google.com/macros/s/.../exec`)

## 3) APK build করুন
Repository -> Actions -> `build-android-apk` -> Run workflow

Build শেষ হলে artifact পাবেন:
- `madrasah-erp-pro-debug-apk`

Artifact download করে unzip দিলে `app-debug.apk` পাবেন.

## 4) Android phone এ install
1. APK phone এ পাঠান (WhatsApp/Drive/USB).
2. Install unknown apps permission দিন.
3. APK install করুন.

## 5) Login user তৈরি
`users_roles` sheet এ admin user row add করুন.
PIN hash দরকার হলে:
- browser এ খুলুন: `YOUR_API_URL?action=hashPin&pin=1234`
- response এর `pin_hash` value `users_roles.pin_hash` এ বসান.

## 6) Real functional test checklist
1. Login কাজ করছে কি.
2. Dashboard summary load হচ্ছে কি.
3. Donation add করলে sheet update হচ্ছে কি.
4. Expense add করলে balance কমছে কি.
5. Beneficiary add হলে list+sheet update হচ্ছে কি.
6. Salary payment দিলে `salary_payments` + `fund_transactions` দুটোতেই row হচ্ছে কি.
7. Scholarship payment দিলে `scholarship_payments` + `fund_transactions` row হচ্ছে কি.
8. Reports page এ month-wise in/out/balance আসছে কি.
9. `audit_log` এ entry হচ্ছে কি.

## 7) Known current scope (Phase 4 পর্যন্ত)
- Implemented: login/session, donation, expense, salary, scholarship, beneficiary, report summary.
- Pending (Phase 5+): PDF export, WhatsApp share, advanced reconciliation UI.
