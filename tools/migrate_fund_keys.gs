/**
 * Fund Key Migration Script
 * Google Apps Script-এ এই function টি একবার run করুন।
 *
 * কী করে:
 *   fund_transactions sheet-এ fund_type column-এর পুরনো key গুলো নতুন key-তে বদলায়:
 *     CONSTRUCTION → SADAQAH
 *     JAKAT        → ZAKAT
 *     SCHOLARSHIP  → TALEBE_ELM
 *     GENERAL      → (খালি রাখে — GENERAL fund আর নেই)
 *
 * কীভাবে run করবেন:
 *   1. Google Sheets খুলুন → Extensions → Apps Script
 *   2. এই পুরো code paste করুন (বিদ্যমান code-এর পরে)
 *   3. Function dropdown থেকে "migrateFundKeys" select করুন
 *   4. Run বাটনে click করুন
 *   5. Log-এ "Migration complete" দেখলে বুঝবেন শেষ হয়েছে
 */
function migrateFundKeys() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  const KEY_MAP = {
    'CONSTRUCTION': 'SADAQAH',
    'JAKAT': 'ZAKAT',
    'SCHOLARSHIP': 'TALEBE_ELM',
  };

  // মাইগ্রেট করার sheet গুলো ও fund_type column name
  const TARGETS = [
    { sheetName: 'fund_transactions', colName: 'fund_type' },
    { sheetName: 'reconciliation_snapshots', colName: 'fund_type' },
  ];

  let totalChanged = 0;

  for (const target of TARGETS) {
    const sheet = ss.getSheetByName(target.sheetName);
    if (!sheet) {
      Logger.log(`Sheet not found: ${target.sheetName} — skip`);
      continue;
    }

    const data = sheet.getDataRange().getValues();
    if (data.length < 2) continue;

    const headers = data[0].map(h => h.toString().trim().toLowerCase());
    const colIdx = headers.indexOf(target.colName.toLowerCase());
    if (colIdx === -1) {
      Logger.log(`Column "${target.colName}" not found in ${target.sheetName} — skip`);
      continue;
    }

    let changed = 0;
    for (let i = 1; i < data.length; i++) {
      const current = data[i][colIdx]?.toString().trim().toUpperCase();
      if (current && KEY_MAP[current]) {
        data[i][colIdx] = KEY_MAP[current];
        changed++;
      }
    }

    if (changed > 0) {
      sheet.getDataRange().setValues(data);
      Logger.log(`${target.sheetName}: ${changed} rows updated`);
      totalChanged += changed;
    } else {
      Logger.log(`${target.sheetName}: nothing to change`);
    }
  }

  Logger.log(`Migration complete. Total rows changed: ${totalChanged}`);
}
