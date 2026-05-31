# Google Sheet Schema (Final Draft)

## 1) users_roles
Columns:
- id
- name
- phone
- email
- role (ADMIN|ACCOUNTANT|FIELD_USER|VIEWER)
- active (TRUE|FALSE)
- pin_hash
- created_at
- updated_at

## 2) fund_transactions (Single Ledger)
Columns:
- id
- txn_date
- direction (IN|OUT)
- fund_type (CONSTRUCTION|JAKAT|SCHOLARSHIP|GENERAL)
- amount
- source_or_vendor
- category
- reference
- notes
- related_entity_type (SALARY|SCHOLARSHIP_PAYMENT|EXPENSE|DONATION|ADJUSTMENT)
- related_entity_id
- status (ACTIVE|VOID)
- created_by
- created_at
- updated_at

## 3) expense_details
Columns:
- id
- txn_id
- expense_date
- expense_head
- payment_method
- voucher_no
- attachment_url
- remarks

## 4) salary_staff
Columns:
- id
- staff_name
- role
- monthly_salary
- active
- created_at
- updated_at

## 5) salary_payments
Columns:
- id
- staff_id
- month_key
- payable_amount
- paid_amount
- due_amount
- payment_date
- txn_id
- status (PAID|PARTIAL|UNPAID)
- notes

## 6) beneficiaries
Columns:
- id
- serial_no
- name_bn
- age
- guardian_status
- class_name
- primary_need
- monthly_need
- monthly_need_amount
- active
- created_at
- updated_at

## 7) scholarship_monthly_plan
Columns:
- id
- month_key
- beneficiary_id
- planned_amount
- notes

## 8) scholarship_payments
Columns:
- id
- month_key
- beneficiary_id
- school_fee
- bangla_tutor
- arabi_tutor
- materials
- other
- total_paid
- remaining_amount
- payment_date
- payment_status (PAID|PARTIAL|CANCELLED)
- txn_id
- notes

## 9) audit_log
Columns:
- id
- module
- action
- entity_id
- before_json
- after_json
- done_by
- done_at

## 10) settings
Columns:
- key
- value
- notes
- updated_at

## 11) notifications
Columns:
- id
- category
- title
- message
- target_role
- target_user_id
- email_enabled (TRUE|FALSE)
- email_sent (TRUE|FALSE)
- email_error
- meta_json
- created_by
- created_at
