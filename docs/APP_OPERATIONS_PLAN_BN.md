# Madrasah ERP Mobile Operations Plan (Final)

## 1) লক্ষ্য
- Google Sheet-কে single source of truth রাখা
- Mobile app online/offline দুই মোডেই usable রাখা
- GitHub Desktop থেকে push দিলেই backend + APK pipeline auto চলা

## 2) আপনার Sheet এর সাথে binding
- Production Sheet ID: `1oDjX_FS0F0_4ZjZM0YBS-TLHFRmYwbNRCPKhcTUxr3Y`
- GitHub Secret `GOOGLE_SHEET_ID` এ এই ID দিন
- `deploy-apps-script` workflow deploy করার আগে `Code.gs` এ এই ID auto inject করবে

## 3) Push থেকে auto update flow
1. আপনি GitHub Desktop দিয়ে commit + push করবেন।
2. `deploy-apps-script` workflow backend code auto deploy করবে।
3. `build-android-apk` workflow APK build করবে।
4. GitHub `latest-apk` release এ সর্বশেষ APK auto replace হবে।

## 4) Offline workflow (APK fully usable target)
- App cached GET data local storage-এ রাখে।
- Internet না থাকলে:
  - cached list/report data দেখাবে
  - donation/expense/salary/scholarship/beneficiary write request local queue-তে জমা হবে
- App bar এর sync icon এ pending count দেখাবে।
- Internet এ ফিরে sync button চাপলে queued entries server/sheet-এ push হবে।

## 5) Login আচরণ
- Online login success হলে user session + offline credential locally save হয়।
- পরে network না থাকলে একই phone+pin দিয়ে offline login করা যায়।

## 6) Required GitHub Secrets
- `CLASPRC_JSON`
- `APPS_SCRIPT_SCRIPT_ID`
- `APPS_SCRIPT_DEPLOYMENT_ID`
- `APPS_SCRIPT_URL` (recommended)
- `API_BASE_URL` (legacy fallback)
- `GOOGLE_SHEET_ID`

## 7) Release ব্যবহার পদ্ধতি
- Actions success হওয়ার পর GitHub -> Releases -> `latest-apk` থেকে APK নিন।
- একই নামের release সবসময় newest build দিয়ে update হবে।

## 8) Risk/Limit (সত্য অবস্থা)
- First-time install যদি একদম offline হয়, server থেকে initial data pull করা যাবে না।
- Offline queue sync হওয়ার আগে report/dashboard server-side summary update হবে না।
