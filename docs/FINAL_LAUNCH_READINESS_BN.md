# Final Launch Readiness - Madrasah ERP Lite

Date: 2026-06-02

## Launch Status

Current repo phases:
- Phase 1 Data Foundation: Completed
- Phase 2 Academic Core: Completed
- Phase 3 Fee, Dues, Scholarship Automation: Completed
- Phase 4 Finance Control: Completed
- Phase 5 Communication & Documents: Completed
- Phase 6 Launch Hardening: In verification/completion

## Required GitHub Secrets

For Apps Script deploy:
- `CLASPRC_JSON`
- `APPS_SCRIPT_SCRIPT_ID`
- `APPS_SCRIPT_DEPLOYMENT_ID`

For web/APK runtime:
- `APPS_SCRIPT_URL` recommended
- `API_BASE_URL` fallback
- `APPS_SCRIPT_DEPLOYMENT_ID` fallback

## Required Vercel Settings

- Project root: `mobile-app`
- Framework preset: Other
- Build command: `flutter build web --release --dart-define=APPS_SCRIPT_URL=$APPS_SCRIPT_URL`
- Output directory: `build/web`
- Environment variable: `APPS_SCRIPT_URL`

## GitHub Workflow Checks

After push to `main`, verify:
- `.github/workflows/deploy-apps-script.yml` completes if backend/sheets changed.
- `.github/workflows/web-build-check.yml` completes if mobile app changed.
- `.github/workflows/android-apk.yml` completes if mobile/backend changed.
- Latest APK release tag `latest-apk` updates.
- Vercel production deployment completes.

## Local Verification Commands

From repo root:

```bash
cp backend-apps-script/Code.gs /tmp/madrasah_code_check.js && node --check /tmp/madrasah_code_check.js
```

From `mobile-app`:

```bash
HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter analyze lib/features/academic/academic_foundation_screen.dart lib/features/academic/academic_core_screen.dart lib/features/fees/fee_dues_screen.dart lib/features/finance_control/finance_control_screen.dart lib/features/communication/communication_documents_screen.dart lib/core/app_shell.dart lib/shared/widgets/app_drawer.dart lib/shared/services/api_service.dart
```

```bash
HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter build web --release --dart-define=APPS_SCRIPT_URL=https://script.google.com/macros/s/AKfycbzbgTChISsQWhEU_EG06UYO3kTGhH-NsEiSdd0v-PEftI3882X7sUDRWCL96224-Bui/exec
```

## Live Smoke Checklist

After GitHub deploy finishes:
- Login as admin.
- Open Dashboard.
- Open Students & Academic and create/list/update one class and one student.
- Open Attendance & Results and save one attendance row.
- Open Fees & Dues and create a fee plan, payment, waiver, then verify due.
- Open Finance Control and verify reconciliation shows `PASS`.
- Open Notices & Documents and publish one notice plus link one document.
- Open Settings and verify audit log has new write rows.

## Backup SOP

Weekly:
- Open Google Sheet.
- File -> Make a copy.
- Store copy with date: `Madrasah ERP Backup YYYY-MM-DD`.

Before major import/deploy:
- Create a manual Google Sheet copy.
- Export sheets as CSV if migration work is planned.

## Restore SOP

If live sheet data breaks:
- Stop new data entry temporarily.
- Copy rows from latest backup sheet into the live sheet tabs.
- Keep column headers unchanged.
- Run app smoke checklist.
- Record restore event in admin notes/audit if applicable.

## Monthly Close SOP

At month end:
- Run range report for the month.
- Run Finance Control for the month.
- Confirm reconciliation `PASS`.
- Check fee dues totals.
- Export/share report summary.
- Backup Google Sheet after close.

## Known Residual Notes

- Full-app `flutter analyze` still reports existing info-level lint warnings in older auth/salary/scholarship/local-store files. New Phase 1-5 touched files analyze clean.
- Live Apps Script/Vercel/APK workflow success requires GitHub push and secrets to be valid.
