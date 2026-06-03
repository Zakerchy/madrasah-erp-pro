#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-pro"

ok(){ printf "[OK] %s\n" "$1"; }
warn(){ printf "[WARN] %s\n" "$1"; }
step(){ printf "\n=== %s ===\n" "$1"; }

step "Project Health"
[ -f "$ROOT/backend-apps-script/Code.gs" ] && ok "Apps Script backend file present" || warn "Missing Code.gs"
[ -f "$ROOT/.github/workflows/deploy-apps-script.yml" ] && ok "Backend auto-deploy workflow present" || warn "Missing deploy-apps-script workflow"
[ -f "$ROOT/.github/workflows/android-apk.yml" ] && ok "APK build workflow present" || warn "Missing android-apk workflow"
[ -f "$ROOT/tools/migrate_excel_to_normalized.js" ] && ok "Migration tool present" || warn "Missing migration tool"

step "Run Migration"
cd "$ROOT"
npm run migrate >/tmp/madrasah_migrate.log 2>&1 && ok "Migration done" || { warn "Migration failed"; cat /tmp/madrasah_migrate.log; exit 1; }

step "Local Smoke (auto)"
PORT=4123 npm run check:server >/tmp/madrasah_server.log 2>&1 &
PID=$!
sleep 2
if npm run check:smoke >/tmp/madrasah_smoke.log 2>&1; then
  ok "Smoke test passed"
else
  warn "Smoke test failed"
  cat /tmp/madrasah_smoke.log
  kill "$PID" >/dev/null 2>&1 || true
  exit 1
fi
kill "$PID" >/dev/null 2>&1 || true

step "Git Status"
git -C "$ROOT" status --short && ok "Repo status shown"
git -C "$ROOT" remote -v | sed -n '1,2p'

step "Only One-Time Manual Security Steps Left"
printf "%s\n" "1) Google Apps Script Web App deploy (account security required)"
printf "%s\n" "2) GitHub Secrets add করা (account security required)"
printf "%s\n" "   - CLASPRC_JSON"
printf "%s\n" "   - APPS_SCRIPT_SCRIPT_ID"
printf "%s\n" "   - APPS_SCRIPT_DEPLOYMENT_ID"
printf "%s\n" "   - APPS_SCRIPT_URL (recommended)"
printf "%s\n" "   - API_BASE_URL (legacy fallback)"

step "Done"
printf "%s\n" "Automation pipeline প্রস্তুত। এরপর code push দিলে backend deploy + apk build auto চলবে।"
