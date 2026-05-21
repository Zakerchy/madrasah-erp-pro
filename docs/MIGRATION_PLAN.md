# Migration Plan from Existing Excel

## Source Files
- `কম_প্লে_ক্সের দা_নের হিসাব.xlsx`
- `Helpless girls students.xlsx`

## Observed Challenges
- Header rows are multi-level and mixed
- Same row contains donation + multiple expense sections
- Dates are mixed: Bangla text, Excel serial, and string
- Amounts include Bangla digits and text suffix (e.g., "১,৫০০ টাকা")
- Scholarship monthly data is stored as repeated blocks by month

## Migration Strategy
1. Read raw rows into staging JSON
2. Detect real header and section markers
3. Split mixed rows into normalized events:
   - Donation event
   - Construction expense event
   - Jakat expense event
   - Scholarship expense/payment event
4. Normalize:
   - Date to `YYYY-MM-DD`
   - Amount to numeric decimal
5. Build keys:
   - `month_key` for scholarship (e.g., `2025-04`)
6. Export CSV per target sheet
7. Import CSV into Google Sheet
8. Verify balances with reconciliation script

## Data Validation Checklist
- Total donation in source vs target
- Fund-wise expense totals vs target
- Scholarship monthly planned vs paid
- Running balance match
