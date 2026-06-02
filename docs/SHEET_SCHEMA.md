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

## 9) students
Columns:
- id
- student_code
- name_bn
- name_en
- gender
- date_of_birth
- admission_date
- class_id
- section_id
- roll_no
- status (ACTIVE|INACTIVE|ARCHIVED)
- phone
- address
- notes
- created_at
- updated_at
- updated_by

## 10) student_guardians
Columns:
- id
- student_id
- name
- relation
- phone
- email
- address
- occupation
- primary_contact (TRUE|FALSE)
- status (ACTIVE|INACTIVE|ARCHIVED)
- notes
- created_at
- updated_at
- updated_by

## 11) classes
Columns:
- id
- name
- level
- sort_order
- status (ACTIVE|INACTIVE|ARCHIVED)
- notes
- created_at
- updated_at
- updated_by

## 12) sections
Columns:
- id
- class_id
- name
- capacity
- status (ACTIVE|INACTIVE|ARCHIVED)
- notes
- created_at
- updated_at
- updated_by

## 13) subjects
Columns:
- id
- class_id
- name
- code
- sort_order
- status (ACTIVE|INACTIVE|ARCHIVED)
- notes
- created_at
- updated_at
- updated_by

## 14) student_attendance
Columns:
- id
- attendance_date
- student_id
- class_id
- section_id
- status (PRESENT|ABSENT|LATE|EXCUSED)
- notes
- recorded_by
- created_at
- updated_at
- updated_by

## 15) exam_terms
Columns:
- id
- name
- class_id
- section_id
- start_date
- end_date
- status (ACTIVE|INACTIVE|ARCHIVED)
- notes
- created_at
- updated_at
- updated_by

## 16) exam_marks
Columns:
- id
- exam_term_id
- student_id
- subject_id
- class_id
- marks_obtained
- max_marks
- grade
- status (RECORDED|VOID)
- notes
- created_at
- updated_at
- updated_by

## 17) fee_plans
Columns:
- id
- name
- class_id
- month_from
- month_to
- amount
- frequency (MONTHLY)
- status (ACTIVE|INACTIVE|ARCHIVED)
- notes
- created_at
- updated_at
- updated_by

## 18) fee_payments
Columns:
- id
- student_id
- month_key
- amount
- payment_date
- method
- reference
- fund_type (CONSTRUCTION|JAKAT|SCHOLARSHIP|GENERAL)
- txn_id
- status (ACTIVE|VOID)
- notes
- created_at
- updated_at
- updated_by

## 19) fee_waivers
Columns:
- id
- student_id
- month_key
- amount
- reason
- approved_by
- status (ACTIVE|VOID)
- notes
- created_at
- updated_at
- updated_by

## 20) finance_budgets
Columns:
- id
- month_key
- fund_type (CONSTRUCTION|JAKAT|SCHOLARSHIP|GENERAL)
- planned_in
- planned_out
- notes
- status (ACTIVE|VOID)
- created_at
- updated_at
- updated_by

## 21) approval_rules
Columns:
- id
- action_type
- threshold_amount
- approver_role
- active (TRUE|FALSE)
- notes
- created_at
- updated_at
- updated_by

## 22) approval_requests
Columns:
- id
- action_type
- amount
- entity_type
- entity_id
- summary
- status (PENDING|APPROVED|REJECTED)
- requested_by
- requested_at
- decided_by
- decided_at
- decision_notes
- payload_json
- created_at
- updated_at
- updated_by

## 23) reconciliation_snapshots
Columns:
- id
- month_key
- summary_json
- pass
- created_at
- updated_at
- updated_by

## 24) notices
Columns:
- id
- title
- message
- target_role
- target_user_id
- target_class_id
- priority (NORMAL|HIGH|URGENT)
- status (PUBLISHED|DRAFT|ARCHIVED)
- published_by
- published_at
- expires_at
- created_at
- updated_at
- updated_by

## 25) notice_reads
Columns:
- id
- notice_id
- user_id
- read_at
- created_at
- updated_at
- updated_by

## 26) document_vault
Columns:
- id
- title
- doc_type
- url
- entity_type
- entity_id
- notes
- status (ACTIVE|VOID)
- uploaded_by
- created_at
- updated_at
- updated_by

## 27) audit_log
Columns:
- id
- module
- action
- entity_id
- before_json
- after_json
- done_by
- done_at

## 28) settings
Columns:
- key
- value
- notes
- updated_at

## 29) notifications
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
