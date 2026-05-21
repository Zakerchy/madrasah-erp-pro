# Real Data Mapping (Based on Provided Excel Files)

## Source A
File: `কম_প্লে_ক্সের দা_নের হিসাব.xlsx`
Sheet: `Sheet1`

### Observed Structure
- Mixed multi-header layout
- Same row may contain:
  - Donation IN (construction/jakat/scholarship)
  - Construction expense OUT
  - Jakat expense OUT
  - Scholarship expense OUT
- Dates are mixed:
  - Bangla string date (e.g., `১০/০৪/২২`)
  - Excel serial date (e.g., `44898`)
  - Blank date (carry-forward needed)

### Mapping to New Schema
- `date` column -> `fund_transactions.txn_date`
- Donor name -> `fund_transactions.source_or_vendor`
- Construction/Jakat/Scholarship donation amounts -> separate `direction=IN` rows
- Expense heads -> `category`
- Expense amounts -> separate `direction=OUT` rows by fund type
- Notes -> `migrated`

## Source B
File: `Helpless girls students.xlsx`

### Sheet: `Copy of Sheet1`
Used as beneficiary master.

Mapping:
- serial -> `beneficiaries.serial_no`
- name -> `beneficiaries.name_bn`
- age -> `beneficiaries.age`
- guardian status -> `beneficiaries.guardian_status`
- class -> `beneficiaries.class_name`
- primary need -> `beneficiaries.primary_need`
- monthly need text -> `beneficiaries.monthly_need`
- monthly need amount -> `beneficiaries.monthly_need_amount`

### Sheet: `Monthly Hishab of scholarship`
Used as monthly scholarship disbursement rows.

Mapping:
- month header (e.g., `মাস: এপ্রিল ২৫ইং`) -> normalized `month_key` (`YYYY-MM`)
- student name -> later mapped to `beneficiary_id` by name matching / manual resolve
- school/bangla/arabi/material/other columns -> scholarship payment component fields
- total paid -> `scholarship_payments.total_paid`
- remaining -> `scholarship_payments.remaining_amount`
- CANCELLED -> `scholarship_payments.payment_status=CANCELLED`

## Data Rules Applied
1. Amount normalization:
- Bangla digits and text suffix removed, numeric stored.

2. Date normalization:
- serial/string converted to `YYYY-MM-DD`.
- blank row dates can reuse previous valid date in same section.

3. Month key normalization:
- Bangla month labels converted to `YYYY-MM`.

4. Auditability:
- Every migrated record marked with `notes=migrated`.
