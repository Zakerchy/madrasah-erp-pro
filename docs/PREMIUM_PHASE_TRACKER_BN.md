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

Status: `⬜ Pending`

Goal:
- Students, classes, sections, subjects, guardians, and base academic schemas add করা।

Work items:
- Student, guardian, class, section, subject data model define করা।
- Apps Script create/list/update endpoints add করা।
- Flutter models, routes, drawer entries, and basic management UI add করা।
- Audit log নিশ্চিত করা for create/update/status changes।

Files/modules touched:
- Pending.

Backend endpoints/sheets added:
- Pending.

Verification commands:
- Pending.

Acceptance checklist:
- Student create/list/update works.
- Class/section/subject create/list/update works.
- Guardian data is linked to student.
- Audit row is created for every write.
- Existing finance modules still work.

Completion note:
- Pending.

---

## Phase 2: Academic Core

Status: `⬜ Pending`

Goal:
- Student management, class setup, attendance, and exam/result base complete করা।

Work items:
- Student profile detail/search/filter UI.
- Daily student attendance save/load.
- Attendance summary by date/class/month.
- Exam term setup, marks entry, grading/report base.

Files/modules touched:
- Pending.

Backend endpoints/sheets added:
- Pending.

Verification commands:
- Pending.

Acceptance checklist:
- Attendance save/load works.
- Class-wise filtering works.
- Exam marks can be saved and retrieved.
- Basic result summary is generated.

Completion note:
- Pending.

---

## Phase 3: Fee, Dues, Scholarship Automation

Status: `⬜ Pending`

Goal:
- Fee plan, payments, dues, waivers, and scholarship due states automate করা।

Work items:
- Fee plan and payment module.
- Due calculation by student/month.
- Waiver handling with audit.
- Scholarship due/paid/partial/unpaid status upgrade.

Files/modules touched:
- Pending.

Backend endpoints/sheets added:
- Pending.

Verification commands:
- Pending.

Acceptance checklist:
- Fee dues calculation matches expected totals.
- Payment updates due balance.
- Waiver requires reason and audit.
- Scholarship reports match payment state.

Completion note:
- Pending.

---

## Phase 4: Finance Control

Status: `⬜ Pending`

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

