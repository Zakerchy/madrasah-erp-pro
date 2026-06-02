# Premium Phase Tracker & Completion Protocol

এই tracker conversation memory-এর বিকল্প নয়; এটি repo-র স্থায়ী source of truth। প্রতিটি premium phase শুরু, যাচাই, commit, এবং completion status এখানেই update হবে।

## Status Legend

- `⬜ Pending`: কাজ শুরু হয়নি।
- `🟡 In Progress`: কাজ চলছে।
- `🔁 Recheck Needed`: code হয়েছে, কিন্তু verification/deployment/secret/server dependency বাকি।
- `✅ Completed`: repeat-check pass হয়েছে এবং completion note/commit hash যোগ হয়েছে।

## Tick Confirmation Rule

কোনো phase `✅ Completed` করা যাবে না যতক্ষণ না নিচের repeat-check pass/record হয়:

- `flutter analyze` touched app files.
- `flutter build web --release` if UI/routes changed.
- Apps Script syntax check if backend changed.
- Endpoint smoke check plan for new API actions.
- UI route/navigation check.
- Sheet schema/docs update check.
- Existing donation/expense/salary/scholarship/report regression check.
- Git status check and commit hash capture.

যদি কোনো check local থেকে করা না যায়, phase status হবে `🔁 Recheck Needed` এবং exact remaining action লেখা থাকবে।

---

## Phase 1: Data Foundation

Status: `✅ Completed`

Goal:
- Students, classes, sections, subjects, guardians, and base academic schemas add করা।

Work items:
- Student, guardian, class, section, subject data model define করা। ✅
- Apps Script create/list/update endpoints add করা। ✅
- Flutter models, routes, drawer entries, and basic management UI add করা। ✅
- Audit log নিশ্চিত করা for create/update/status changes। ✅
- Missing Phase 1 Google Sheet tabs auto-create/header-heal করা। ✅

Files/modules touched:
- `backend-apps-script/Code.gs`
- `mobile-app/lib/features/academic/academic_foundation_screen.dart`
- `mobile-app/lib/features/academic/academic_models.dart`
- `mobile-app/lib/core/app_shell.dart`
- `mobile-app/lib/shared/widgets/app_drawer.dart`
- `mobile-app/lib/shared/services/api_service.dart`
- `docs/API_CONTRACT.md`
- `docs/SHEET_SCHEMA.md`
- `sheets/README.md`
- `sheets/students.csv`
- `sheets/student_guardians.csv`
- `sheets/classes.csv`
- `sheets/sections.csv`
- `sheets/subjects.csv`

Backend endpoints/sheets added:
- Sheets: `students`, `student_guardians`, `classes`, `sections`, `subjects`
- Read endpoints: `listStudents`, `listStudentGuardians`, `listClasses`, `listSections`, `listSubjects`
- Write endpoints: `upsertStudent`, `upsertStudentGuardian`, `upsertClass`, `upsertSection`, `upsertSubject`
- Audit: every Phase 1 `upsert*` write routes through `upsertById_`, generating `CREATE`/`UPDATE` audit rows.

Verification commands:
- `cp backend-apps-script/Code.gs /tmp/madrasah_phase1_code_check.js && node --check /tmp/madrasah_phase1_code_check.js` ✅
- `HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter analyze lib/features/academic/academic_foundation_screen.dart lib/features/academic/academic_models.dart lib/core/app_shell.dart lib/shared/widgets/app_drawer.dart lib/shared/services/api_service.dart` ✅
- `HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter build web --release --dart-define=APPS_SCRIPT_URL=https://script.google.com/macros/s/AKfycbzbgTChISsQWhEU_EG06UYO3kTGhH-NsEiSdd0v-PEftI3882X7sUDRWCL96224-Bui/exec` ✅
- `HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter test` ✅
- Apps Script mocked endpoint smoke: class/section/subject/student/guardian create/list/update + 6 audit rows ✅
- Static route/navigation check: `/academic`, drawer entry, and backend action names found by `rg` ✅
- Full-app `flutter analyze` note: Phase 1 touched files clean; existing info-level lints remain in older auth/salary/scholarship/local-store files and were not introduced by this phase.

Acceptance checklist:
- Student create/list/update works in mocked Apps Script smoke. ✅
- Class/section/subject create/list/update works in mocked Apps Script smoke. ✅
- Guardian data is linked to student and filtered by `student_id`. ✅
- Audit row is created for every write; smoke produced 6 audit rows. ✅
- Existing finance modules still build through release web build; no finance route/code changed. ✅

Completion note:
- Completed on 2026-06-02.
- Implementation commit: `8e19c23` (`feat: add academic data foundation`).
- Live Apps Script smoke will run automatically after GitHub deploy; local mocked smoke confirms endpoint behavior before deploy.

---

## Phase 2: Academic Core

Status: `✅ Completed`

Goal:
- Student management, class setup, attendance, and exam/result base complete করা।

Work items:
- Student profile detail/search/filter UI: Phase 1 foundation list + Phase 2 class/section filtered academic core workspace. ✅
- Daily student attendance save/load. ✅
- Attendance summary by date/class/section through filtered attendance rows and dashboard metrics. ✅
- Exam term setup, marks entry, grading/report base. ✅

Files/modules touched:
- `backend-apps-script/Code.gs`
- `mobile-app/lib/features/academic/academic_core_screen.dart`
- `mobile-app/lib/core/app_shell.dart`
- `mobile-app/lib/shared/widgets/app_drawer.dart`
- `mobile-app/lib/shared/services/api_service.dart`
- `docs/API_CONTRACT.md`
- `docs/SHEET_SCHEMA.md`
- `sheets/README.md`
- `sheets/student_attendance.csv`
- `sheets/exam_terms.csv`
- `sheets/exam_marks.csv`

Backend endpoints/sheets added:
- Sheets: `student_attendance`, `exam_terms`, `exam_marks`
- Read endpoints: `listAttendance`, `listExamTerms`, `listExamMarks`, `resultSummary`
- Write endpoints: `saveAttendance`, `upsertExamTerm`, `saveExamMark`
- Deterministic IDs: attendance uses date/student; marks use exam/student/subject to prevent duplicate rows.
- Audit: every Phase 2 write routes through `upsertById_`, generating `CREATE`/`UPDATE` audit rows.

Verification commands:
- Phase 1 recheck before Phase 2 start:
  - `cp backend-apps-script/Code.gs /tmp/madrasah_phase1_recheck_code.js && node --check /tmp/madrasah_phase1_recheck_code.js` ✅
  - touched-file `flutter analyze` ✅
  - `flutter build web --release --dart-define=APPS_SCRIPT_URL=...` ✅
  - `/tmp/phase1_smoke.js` mocked endpoint smoke ✅
- Phase 2 repeat-check:
  - `cp backend-apps-script/Code.gs /tmp/madrasah_phase2_code_check.js && node --check /tmp/madrasah_phase2_code_check.js` ✅
  - `HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter analyze lib/features/academic/academic_core_screen.dart lib/core/app_shell.dart lib/shared/widgets/app_drawer.dart lib/shared/services/api_service.dart` ✅
  - `HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter build web --release --dart-define=APPS_SCRIPT_URL=https://script.google.com/macros/s/AKfycbzbgTChISsQWhEU_EG06UYO3kTGhH-NsEiSdd0v-PEftI3882X7sUDRWCL96224-Bui/exec` ✅
  - `HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter test` ✅
  - Apps Script mocked endpoint smoke: attendance save/list, exam term, mark save/grade, result summary + 9 audit rows ✅
  - Static route/navigation check: `/academic-core`, drawer entry, and backend action names found by `rg` ✅
  - Full-app `flutter analyze` note: Phase 2 touched files clean; existing info-level lints remain in older auth/salary/scholarship/local-store files and were not introduced by this phase.

Acceptance checklist:
- Attendance save/load works in mocked Apps Script smoke with 2 rows. ✅
- Class-wise and section-wise filtering works for attendance and result summary. ✅
- Exam marks can be saved and retrieved; grade generated as `A+` for 85/100. ✅
- Basic result summary generated with 2 students and sorted percentage output. ✅
- Audit row is created for every write; smoke produced 9 audit rows. ✅
- Existing finance modules still build through release web build; no finance route/code changed. ✅

Completion note:
- Completed on 2026-06-02.
- Implementation commit: `0df5652` (`feat: add academic core attendance and exams`).
- Live Apps Script smoke will run automatically after GitHub deploy; local mocked smoke confirms endpoint behavior before deploy.

---

## Phase 3: Fee, Dues, Scholarship Automation

Status: `✅ Completed`

Goal:
- Fee plan, payments, dues, waivers, and scholarship due states automate করা।

Work items:
- Fee plan and payment module. ✅
- Due calculation by student/month. ✅
- Waiver handling with required reason and audit. ✅
- Scholarship due/paid/partial/unpaid-style state via `scholarship_due_state`. ✅

Files/modules touched:
- `backend-apps-script/Code.gs`
- `mobile-app/lib/features/fees/fee_dues_screen.dart`
- `mobile-app/lib/core/app_shell.dart`
- `mobile-app/lib/shared/widgets/app_drawer.dart`
- `mobile-app/lib/shared/services/api_service.dart`
- `docs/API_CONTRACT.md`
- `docs/SHEET_SCHEMA.md`
- `sheets/README.md`
- `sheets/fee_plans.csv`
- `sheets/fee_payments.csv`
- `sheets/fee_waivers.csv`

Backend endpoints/sheets added:
- Sheets: `fee_plans`, `fee_payments`, `fee_waivers`
- Read endpoints: `listFeePlans`, `listFeePayments`, `listFeeWaivers`, `listFeeDues`
- Write endpoints: `upsertFeePlan`, `recordFeePayment`, `upsertFeeWaiver`
- Ledger integration: `recordFeePayment` creates `fund_transactions` `IN` row with category `STUDENT_FEE`.
- Audit: fee plan/payment/waiver writes route through `upsertById_`.

Verification commands:
- `cp backend-apps-script/Code.gs /tmp/madrasah_phase3_code_check.js && node --check /tmp/madrasah_phase3_code_check.js` ✅
- `HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter analyze lib/features/fees/fee_dues_screen.dart lib/core/app_shell.dart lib/shared/widgets/app_drawer.dart lib/shared/services/api_service.dart` ✅
- `HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter build web --release --dart-define=APPS_SCRIPT_URL=https://script.google.com/macros/s/AKfycbzbgTChISsQWhEU_EG06UYO3kTGhH-NsEiSdd0v-PEftI3882X7sUDRWCL96224-Bui/exec` ✅
- `HOME=/Users/zakerchy/Desktop/MadrasahApp FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true ../.local-tools/flutter/bin/flutter test` ✅
- Apps Script mocked endpoint smoke: fee plan, due, payment/ledger txn, waiver, recalculated due + 6 audit rows ✅
- Static route/navigation check: `/fees`, drawer entry, and backend action names found by `rg` ✅

Acceptance checklist:
- Fee dues calculation matched expected totals: `1000 - 400 - 100 = 500`. ✅
- Payment updates due balance and creates one ledger transaction. ✅
- Waiver requires reason and writes audit. ✅
- Scholarship/due state returned `PARTIAL` after partial payment/waiver. ✅
- Existing finance modules still build through release web build. ✅

Completion note:
- Completed on 2026-06-02.
- Implementation commit: `7b86764` (`feat: add fee dues automation`).
- Live Apps Script smoke will run automatically after GitHub deploy; local mocked smoke confirms endpoint behavior before deploy.

---

## Phase 4: Finance Control

Status: `🟡 In Progress`

Goal:
- Budget, reconciliation, opening/closing balances, and approval workflow add করা।

Work items:
- Monthly budget planning.
- Actual vs budget variance.
- Fund opening/closing balance.
- Approval workflow for configured high-value actions.
- Reconciliation center for app totals vs sheet totals.

Files/modules touched:
- Pending.

Backend endpoints/sheets added:
- Pending.

Verification commands:
- Pending.

Acceptance checklist:
- Dashboard/report totals match backend.
- Reconciliation check reports pass/fail clearly.
- Approval rules work as configured.
- Audit log records approval decisions.

Completion note:
- Pending.

---

## Phase 5: Communication & Documents

Status: `⬜ Pending`

Goal:
- Notices, in-app targeting, and document/voucher vault add করা।

Work items:
- Notice publish/list/read flow.
- Target by role/class/student where applicable.
- Document/voucher link storage.
- Link documents to transaction/student/staff/scholarship records.

Files/modules touched:
- Pending.

Backend endpoints/sheets added:
- Pending.

Verification commands:
- Pending.

Acceptance checklist:
- Notice is visible to target users only.
- Notice read status works.
- Linked document opens from the relevant record.
- Audit log records document/notice writes.

Completion note:
- Pending.

---

## Phase 6: Launch Hardening

Status: `⬜ Pending`

Goal:
- Final readiness checklist, workflows, docs, web build, APK build, Apps Script deploy, and Vercel launch confidence complete করা।

Work items:
- Launch readiness checklist expand/finalize.
- GitHub Actions verification process document করা।
- Vercel/domain/env checklist finalize করা।
- APK release workflow verification.
- Backup/restore/monthly close SOP docs.

Files/modules touched:
- Pending.

Backend endpoints/sheets added:
- Pending.

Verification commands:
- Pending.

Acceptance checklist:
- Local app build passes.
- Web release build passes.
- Apps Script deploy workflow succeeds.
- Vercel production deployment succeeds.
- APK release workflow succeeds.
- Final launch checklist passes in Settings.

Completion note:
- Pending.
