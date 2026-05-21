# Architecture

## Stack
- Mobile: Flutter (Android-first)
- Backend: Google Apps Script (Web App)
- Database: Google Sheets
- Storage: Google Drive (vouchers/documents)

## Flow
1. User submits entry from mobile app
2. App calls Apps Script endpoint
3. Backend validates role + payload
4. Backend writes to relevant sheet tabs
5. Backend writes audit log row
6. App refreshes module and dashboard summary

## Modules
- Donations
- Expenses
- Salary
- Beneficiaries
- Scholarship (plan + payments)
- Reports

## Design Principles
- One source of truth: `fund_transactions`
- Derived balances only from transaction ledger
- Soft-delete and audit-log mandatory
- Low complexity, high transparency
