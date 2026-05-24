#!/usr/bin/env python3
"""One-time data migration: imports CSV rows into Google Sheet via Apps Script endpoint."""

import csv
import json
import sys
import urllib.request
import urllib.error

APPS_SCRIPT_URL = "https://script.google.com/macros/s/AKfycbzbgTChISsQWhEU_EG06UYO3kTGhH-NsEiSdd0v-PEftI3882X7sUDRWCL96224-Bui/exec"
IMPORT_SECRET = "MADRASAH_IMPORT_2025"

CSV_DIR = "output"
FILES = {
    "beneficiaries": f"{CSV_DIR}/migrated_beneficiaries.csv",
    "fund_transactions": f"{CSV_DIR}/migrated_fund_transactions.csv",
    "scholarship_payments": f"{CSV_DIR}/migrated_scholarship_payments.csv",
}

BATCH_SIZE = 50


def read_csv(path):
    rows = []
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(dict(row))
    return rows


def post_json(url, payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = resp.read().decode("utf-8")
            return json.loads(body)
    except urllib.error.HTTPError as e:
        # Apps Script returns 302; urllib follows redirects by default
        body = e.read().decode("utf-8")
        return json.loads(body) if body.startswith("{") else {"ok": False, "error": str(e), "body": body[:200]}
    except Exception as ex:
        return {"ok": False, "error": str(ex)}


def import_sheet(sheet_name, rows):
    print(f"\n→ Importing {len(rows)} rows into '{sheet_name}'...")
    # Send in batches to avoid timeout
    total_imported = 0
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i : i + BATCH_SIZE]
        payload = {
            "action": "importMigratedData",
            "import_secret": IMPORT_SECRET,
            "sheet_name": sheet_name,
            "rows": batch,
        }
        result = post_json(APPS_SCRIPT_URL, payload)
        if result.get("ok"):
            imported = result.get("imported", len(batch))
            total_imported += imported
            print(f"  Batch {i // BATCH_SIZE + 1}: {imported} rows imported ✓")
        else:
            msg = result.get("message") or result.get("error") or str(result)
            print(f"  Batch {i // BATCH_SIZE + 1}: FAILED — {msg}")
            if "already has" in msg:
                print(f"  Skipping: sheet already has data.")
                return
            sys.exit(1)
    print(f"  Total: {total_imported} rows imported into '{sheet_name}' ✓")


def main():
    # Import order matters: beneficiaries first (scholarship_payments looks up their IDs)
    order = ["beneficiaries", "fund_transactions", "scholarship_payments"]
    for sheet_name in order:
        path = FILES[sheet_name]
        rows = read_csv(path)
        import_sheet(sheet_name, rows)

    print("\n✅ Migration complete.")


if __name__ == "__main__":
    main()
