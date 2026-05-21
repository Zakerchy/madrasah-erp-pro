# Live Sheet Linkage Audit (Madrasah-ERP-Pro)

Audit Time:
- UTC: 2026-05-21T21:10:59.992Z (latest structure/provision run)
- Asia/Dhaka: 2026-05-22 03:10 AM

Spreadsheet:
- ID: `1oDjX_FS0F0_4ZjZM0YBS-TLHFRmYwbNRCPKhcTUxr3Y`
- Title: `Madrasah-ERP-Pro`

## 1) বর্তমান Tabs
1. `Sheet1` (empty, ব্যবহারহীন)
2. `users_roles`
3. `fund_transactions`
4. `expense_details`
5. `salary_staff`
6. `salary_payments`
7. `beneficiaries`
8. `scholarship_monthly_plan`
9. `scholarship_payments`
10. `audit_log`
11. `settings`

## 2) Intended Link Map (Production)
- `users_roles.id` -> `fund_transactions.created_by`
- `users_roles.id` -> `audit_log.done_by`
- `fund_transactions.id` -> `expense_details.txn_id`
- `fund_transactions.id` -> `salary_payments.txn_id`
- `fund_transactions.id` -> `scholarship_payments.txn_id`
- `salary_staff.id` -> `salary_payments.staff_id`
- `beneficiaries.id` -> `scholarship_monthly_plan.beneficiary_id`
- `beneficiaries.id` -> `scholarship_payments.beneficiary_id`

## 3) Live Data Reality Check
### A) `fund_transactions`
- Header: 15 columns.
- Migrated rows currently 7-column short format (id/metadata columns missing).
- অর্থাৎ row data header alignment mismatch আছে।

### B) `beneficiaries`
- Header: 12 columns.
- Migrated rows currently 9-column short format.
- `serial_no` column effectively name data নিচ্ছে, id linkage weak.

### C) `scholarship_payments`
- Header: 14 columns.
- Migrated rows currently 10-column short format.
- `beneficiary_id` এ আসলে beneficiary name আছে, numeric/string id নয়।

### D) `salary_staff`, `salary_payments`, `expense_details`, `audit_log`
- Schema ready, কিন্তু live rows প্রায় empty (app entry/use on-going না হলে স্বাভাবিক)।

## 4) Risk Summary
- Historical migrated data এখন relational join-friendly নয়।
- নতুন app entries (API থেকে create হওয়া) schema অনুযায়ী ঠিকভাবে insert হবে, কিন্তু পুরোনো rows re-map না করলে full reconciliation/report এ mixed behavior আসবে।

## 5) Mandatory Fix Before Full Pro Reporting
1. Historical data backfill script চালিয়ে missing columns পূরণ করা
   - `fund_transactions.id`, `status`, `created_by`, timestamps
   - `beneficiaries.id` consistency
   - `scholarship_payments.id`, `payment_status`, `beneficiary_id` id-based remap
2. `beneficiary_id` name->id mapping table generate করা
3. `txn_id` backfill for scholarship/salary/expense details (যেখানে applicable)
4. `Sheet1` unused tab optional cleanup

## 6) Offline Mobile Implementation Priority (as per current sheet)
1. Existing online create flow keep করে offline queue auto sync চালু রাখা
2. New entries অবশ্যই full schema fields সহ save করা
3. Dashboard total শুধু `status != VOID` থেকে গণনা করা
4. Legacy rows compatibility parser add করা (short-row fallback)
5. Data normalization pass complete হলে strict schema mode enable করা

## 7) Current Decision
- Sheet access + editor permission + auto tab/schema write capability confirmed.
- Next iteration এ: `historical row normalization + relational linkage hardening` করতে হবে, তারপর advanced pro reports safely চালু করা যাবে।
