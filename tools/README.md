# Tools

## Migration Script
`migrate_excel_to_normalized.js`

Purpose:
- Parse existing two Excel files
- Normalize date and amount formats
- Produce initial CSV files for import

## Usage
1. `cd tools`
2. `npm install`
3. `npm run migrate`
4. Check `tools/output/`

## Output Files
- `migrated_fund_transactions.csv`
- `migrated_beneficiaries.csv`
- `migrated_scholarship_payments.csv`
