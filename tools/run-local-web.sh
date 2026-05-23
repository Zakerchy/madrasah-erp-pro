#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT="$REPO_ROOT/mobile-app"
FLUTTER_SDK="${FLUTTER_SDK:-$REPO_ROOT/.local-tools/flutter}"
DEVICE="${1:-chrome}"
FORCE_PUB_GET="${FORCE_PUB_GET:-0}"

if [ ! -x "$FLUTTER_SDK/bin/flutter" ]; then
  echo "Flutter SDK not found at: $FLUTTER_SDK"
  echo "Run: $REPO_ROOT/tools/setup-local-flutter.sh"
  exit 1
fi

export PATH="$FLUTTER_SDK/bin:$PATH"

echo "Using Flutter: $($FLUTTER_SDK/bin/flutter --version | head -n 1)"
cd "$PROJECT"

"$FLUTTER_SDK/bin/flutter" config --enable-web >/dev/null

if [ ! -d "$PROJECT/web" ]; then
  echo "Web scaffold missing. Generating web platform files..."
  "$FLUTTER_SDK/bin/flutter" create --platforms=web .
fi

if [ "$FORCE_PUB_GET" = "1" ] || [ ! -f "$PROJECT/.dart_tool/package_config.json" ]; then
  echo "Running flutter pub get..."
  "$FLUTTER_SDK/bin/flutter" pub get
else
  echo "Skipping pub get (set FORCE_PUB_GET=1 to force)."
fi

echo ""
if [ "$DEVICE" = "web-server" ]; then
  echo "Starting web dev server on http://localhost:7357"
  echo "Open this URL in your browser."
else
  echo "Starting Flutter web on $DEVICE with hot reload..."
fi
echo ""

if [ "$DEVICE" = "web-server" ]; then
  "$FLUTTER_SDK/bin/flutter" run -d web-server --web-hostname 0.0.0.0 --web-port 7357
else
  "$FLUTTER_SDK/bin/flutter" run -d "$DEVICE" --web-port 7357
fi
