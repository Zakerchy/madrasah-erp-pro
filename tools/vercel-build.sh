#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/mobile-app"
LOCAL_FLUTTER="$ROOT/.local-tools/flutter/bin/flutter"
HOME_FLUTTER="$HOME/flutter/bin/flutter"

if [ -x "$LOCAL_FLUTTER" ]; then
  FLUTTER_BIN="$LOCAL_FLUTTER"
elif [ -x "$HOME_FLUTTER" ]; then
  FLUTTER_BIN="$HOME_FLUTTER"
else
  echo "Flutter SDK not found. Installing stable Flutter into \$HOME/flutter..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
  FLUTTER_BIN="$HOME_FLUTTER"
fi

export PATH="$(dirname "$FLUTTER_BIN"):$PATH"

URL="${APPS_SCRIPT_URL:-${API_BASE_URL:-}}"
DEFINE_ARGS=()

if [ -n "$URL" ]; then
  DEFINE_ARGS+=("--dart-define=APPS_SCRIPT_URL=$URL")
elif [ -n "${APPS_SCRIPT_DEPLOYMENT_ID:-}" ]; then
  DEFINE_ARGS+=("--dart-define=APPS_SCRIPT_DEPLOYMENT_ID=${APPS_SCRIPT_DEPLOYMENT_ID}")
else
  echo "No APPS_SCRIPT_URL/API_BASE_URL/APPS_SCRIPT_DEPLOYMENT_ID provided. Falling back to the app's built-in endpoint."
fi

if [ -n "${BOOTSTRAP_ADMIN_EMAIL:-}" ]; then
  DEFINE_ARGS+=("--dart-define=BOOTSTRAP_ADMIN_EMAIL=${BOOTSTRAP_ADMIN_EMAIL}")
fi

if [ -n "${APK_DOWNLOAD_URL:-}" ]; then
  DEFINE_ARGS+=("--dart-define=APK_DOWNLOAD_URL=${APK_DOWNLOAD_URL}")
fi

DEFINE_ARGS+=("--dart-define=ENABLE_DEBUG_LOGS=false")

echo "Using Flutter: $FLUTTER_BIN"
"$FLUTTER_BIN" config --enable-web >/dev/null

cd "$APP_DIR"
if ! "$FLUTTER_BIN" pub get; then
  echo "Online pub get failed. Retrying with --offline using cached packages..."
  "$FLUTTER_BIN" pub get --offline
fi
"$FLUTTER_BIN" build web --release --no-pub --pwa-strategy=offline-first "${DEFINE_ARGS[@]}"
