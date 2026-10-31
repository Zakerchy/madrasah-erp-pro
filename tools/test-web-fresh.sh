#!/usr/bin/env bash
# Builds the Flutter web release and serves it on a freshly-picked port.
#
# Why: `python3 -m http.server` sends no cache-control headers, and the
# Browser tool's Chromium caches main.dart.js aggressively — reloading the
# same localhost URL after a rebuild can silently keep serving the OLD
# bundle. Always serving each rebuild on a brand-new port sidesteps that
# entirely (new origin = no stale cache), instead of hoping a hard-reload
# actually bypasses it.
#
# Usage: ./tools/test-web-fresh.sh
# Prints the URL to open once the server is up, and the PID to kill it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/mobile-app"
FLUTTER_SDK="${FLUTTER_SDK:-$ROOT/.local-tools/flutter}"

if [ ! -x "$FLUTTER_SDK/bin/flutter" ]; then
  echo "Flutter SDK not found at: $FLUTTER_SDK"
  echo "Run: $ROOT/tools/setup-local-flutter.sh"
  exit 1
fi
export PATH="$FLUTTER_SDK/bin:$PATH"

# Kill any previously started instance of this script's servers.
pkill -f "http.server .* --directory $APP_DIR/build/web" 2>/dev/null || true

cd "$APP_DIR"
flutter build web --release

PORT=$(( (RANDOM % 5000) + 9000 ))
cd build/web
nohup python3 -m http.server "$PORT" > /tmp/madrasah_web_test_"$PORT".log 2>&1 &
SERVER_PID=$!

sleep 1
echo ""
echo "Fresh build served at: http://localhost:$PORT/"
echo "Server PID: $SERVER_PID  (kill with: kill $SERVER_PID)"
