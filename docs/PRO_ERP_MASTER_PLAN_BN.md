# Madrasah ERP Pro Master Plan (Offline-First + Auto Sync)

## 1) লক্ষ্য (Final Target)
- Native Android APK, সম্পূর্ণ offline-first usable।
- Internet থাকলে auto background sync হয়ে Google Sheet update হবে।
- `fund_transactions` কে single source of truth রেখে সব total/balance dashboard এ auto reflect হবে।
- কোনো entry `VOID`/delete করলে total সঙ্গে সঙ্গে recalculate হবে।
- Real Excel data already migrated structure ধরে Pro-level ERP module complete করা।

## 2) বর্তমান অবস্থা (যা আছে)
- Core modules implemented: Login, Dashboard, Donation, Expense, Salary, Scholarship, Beneficiaries।
- Google Apps Script API connected।
- Offline queue + cached GET response basicভাবে আছে (`shared_preferences`)।
- Manual sync button আছে।
- Real data migration scripts + output আছে।

## 3) Gap Analysis (Pro হওয়ার জন্য যা বাকি)

### A) Offline Engine gap
- Local storage এখন `shared_preferences` ভিত্তিক; এটি transactional নয়।
- Relational local DB নেই (query/report speed এবং data consistency risk)।
- Background auto-sync scheduler নেই (manual click dependency)।
- Conflict handling policy formalized না।
- Delete/void sync reconciliation robust না।

### B) Ledger & Reporting gap
- Dashboard KPI আছে, কিন্তু pro-level reconciliation blocks নেই।
- Fund-wise opening/closing, daily running balance, variance report নেই।
- Void/adjustment audit drilldown UI নেই।
- Monthly lock/freeze system নেই (close period)।

### C) ERP Coverage gap
- Budget planning module নেই।
- Vendor/Expense head registry নেই (free text বেশি)।
- Attachment/document workflow নেই।
- Approval workflow নেই (multi-role checking)।
- Backup/restore অপারেশন SOP app থেকে trigger করা যায় না।

## 4) Pro Data Model Upgrade (Google Sheet + Local DB)

## 4.1 Existing master sheets (keep)
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

## 4.2 New sheets/columns (add)
1. `sync_queue_log` (server-side sync trace)
- `mutation_id`, `device_id`, `action`, `entity_type`, `entity_id`, `status`, `error`, `created_at`

2. `fund_opening_balance`
- `id`, `fund_type`, `as_of_date`, `amount`, `notes`, `created_at`

3. `budget_plan_monthly`
- `id`, `month_key`, `fund_type`, `budget_head`, `planned_amount`, `created_by`, `created_at`

4. `approval_log`
- `id`, `module`, `entity_id`, `submitted_by`, `approved_by`, `status`, `notes`, `at`

5. `fund_transactions` extra columns
- `mutation_id` (idempotency)
- `device_id`
- `is_synced` (`TRUE/FALSE`)
- `void_reason`

## 4.3 Local DB (SQLite/Drift) tables
- `txn_local`
- `beneficiary_local`
- `staff_local`
- `scholarship_local`
- `salary_payment_local`
- `outbox_queue`
- `sync_state`
- `app_meta`

Rule:
- UI reads from local DB only।
- Network operations শুধু sync worker করবে।

## 5) Offline-First Sync Architecture (Target)

## 5.1 Write flow (offline/online একই)
1. User submit
2. Local DB transaction commit
3. `outbox_queue` এ job enqueue (`mutation_id` সহ)
4. UI immediate success + dashboard local recalc
5. Internet থাকলে instant sync trigger
6. না থাকলে background periodic sync later

## 5.2 Read flow
- প্রথমে local DB render।
- Background এ server pull -> diff apply -> UI refresh।
- No-internet এ full usable state বজায় থাকবে।

## 5.3 Auto sync triggers
- App launch
- Network reconnect
- Every X minutes (e.g., 5 min foreground, 15 min background)
- Manual sync button fallback

## 5.4 Conflict policy
- Primary: `updated_at` + `mutation_id` idempotent merge
- Same row conflict: latest server `updated_at` wins, কিন্তু `audit_log` mandatory
- Void always append-audit করে apply হবে

## 5.5 Delete policy
- Hard delete না করে `status=VOID`
- Dashboard/report সব query তে `status != VOID`
- Void করলে total auto কমে যাবে, history থাকবে

## 6) Dashboard হিসাব (Exact Ledger Logic)

## 6.1 Core formulas
- `total_in = SUM(amount যেখানে direction='IN' AND status='ACTIVE')`
- `total_out = SUM(amount যেখানে direction='OUT' AND status='ACTIVE')`
- `balance = total_in - total_out`

## 6.2 Fund-wise formulas
প্রতিটি `fund_type` এর জন্য:
- `fund_in = SUM(IN, ACTIVE, fund_type=X)`
- `fund_out = SUM(OUT, ACTIVE, fund_type=X)`
- `fund_balance = fund_in - fund_out`

## 6.3 Monthly summary
- `month_in`, `month_out`, `month_balance`
- Opening + current month flow + closing block

## 6.4 Adjustment/Void impact
- Entry void হলে সেটি instantly summary থেকে বাদ যাবে
- Adjustment entry হলে আলাদা category `ADJUSTMENT` tag থাকবে

## 6.5 Required dashboard cards (Pro)
- Grand Total In/Out/Balance
- Fund-wise balances
- Today In/Out
- Pending Sync count
- Unapproved entries count
- Scholarship due / Salary due snapshots

## 7) Pro Modules To Add (Priority)
1. `Reconciliation Center`
- Source totals vs app totals vs sheet totals match checker

2. `Budget & Control`
- মাসভিত্তিক budget plan
- actual vs budget variance

3. `Approval Workflow`
- Maker-checker for high-value expense

4. `Document Vault`
- Voucher ছবি/ফাইল attach + Drive link

5. `Period Closing`
- মাস close করে lock; lock period edit restricted

6. `Advanced Reports`
- Fund statement
- Category expense statement
- Beneficiary lifecycle report
- Salary dues aging

7. `Admin Ops`
- backup snapshot trigger
- restore guidance screen
- user/device access revoke

## 8) Native APK Hardening Plan
- Add release signing pipeline with keystore নিরাপদ secret হিসেবে।
- `dev` ও `prod` flavor split।
- Crash-safe logging।
- Versioning: `major.minor.patch+build`।
- Auto release note generation।

## 9) Security Plan
- PIN hashing with salt (plain-text fallback remove করতে হবে)।
- Device binding option (`trusted device`)।
- Role-based endpoint strict validation।
- Sensitive config via secrets only।
- Audit trail immutable রাখার policy।

## 10) Step-by-Step Execution Roadmap

## Phase A (Foundation Hardening) - 4 days
- Local DB migrate (`drift/sqflite`)।
- Repository pattern + offline-first read path।
- Outbox queue schema finalize।

## Phase B (Auto Sync Engine) - 5 days
- Connectivity listener + periodic worker।
- Idempotent mutation sync।
- Conflict + retry + backoff।

## Phase C (Ledger Integrity) - 4 days
- Reconciliation engine।
- Opening balance + closing summary।
- Void/adjustment safe flow।

## Phase D (Pro Modules) - 8 days
- Budget module
- Approval flow
- Advanced reports
- Period closing

## Phase E (Release + Ops) - 3 days
- Signed APK pipeline finalization
- Pilot run
- Go-live checklist + SOP freeze

## 11) Definition of Done (Must Pass)
- Offline এ internet ছাড়া entry/add/edit/void কাজ করবে।
- Online হলে user action ছাড়া auto sync হবে।
- Duplicate sync হবে না (`mutation_id` idempotency)।
- Dashboard totals = sheet totals (reconciliation pass)।
- Void করলে সব KPI/report এ immediate reflect হবে।
- 7 দিনের pilot এ no critical data mismatch।

## 12) Immediate Next Implementation Order (from now)
1. Local DB migration (shared_preferences -> SQLite/Drift)
2. Outbox + auto background sync worker
3. Dashboard reconciliation blocks + fund opening balance
4. Approval + budget modules
5. Release hardening + signed APK distribution

---

এই প্ল্যান অনুযায়ী কাজ করলে app টি “lite” থেকে real “pro offline-first ERP” হবে, যেখানে offline usage, auto Google Sheet sync, এবং finance summary integrity production-grade হবে।
