# Apps Script Backend Setup

1. Create a Google Apps Script project.
2. Paste `Code.gs` and `appsscript.json` content.
3. Set `CONFIG.SHEET_ID` to your spreadsheet ID.
4. Deploy as Web App.
5. Update mobile app API base URL.

## Notes
- Keep the first row in each sheet as exact header row.
- Backend expects column names from `sheets/*.csv` headers.
- Notification controls are stored in `settings` sheet keys:
  - `notify.in_app.enabled` (locked TRUE)
  - `notify.email.approval`
  - `notify.email.failed_sync`
  - `notify.email.daily_summary`
  - `notify.email.due_reminder`
  - `notify.email.security_alert`
