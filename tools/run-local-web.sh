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

# Safe dotenv loader (avoids executing .env as shell code).
load_env_file() {
  local env_file="$1"
  [ -f "$env_file" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    # Trim trailing CR for Windows-formatted files.
    line="${line%$'\r'}"

    # Skip comments/empty lines.
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue

    # Only accept KEY=VALUE format.
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      local key="${line%%=*}"
      local value="${line#*=}"

      # Strip optional wrapping quotes.
      if [[ "$value" =~ ^\".*\"$ ]]; then
        value="${value:1:${#value}-2}"
      elif [[ "$value" =~ ^\'.*\'$ ]]; then
        value="${value:1:${#value}-2}"
      fi

      printf -v "$key" '%s' "$value"
      export "$key"
    fi
  done < "$env_file"
}

# Auto-load environment values once from local files (optional).
# Supported files:
# - repo root: .env.local
# - mobile app: mobile-app/.env.local
load_env_file "$REPO_ROOT/.env.local"
load_env_file "$PROJECT/.env.local"

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

APP_SCRIPT_URL="${APPS_SCRIPT_URL:-${API_BASE_URL:-}}"
EXTRA_ARGS=()
if [ -n "${APP_SCRIPT_URL}" ]; then
  EXTRA_ARGS+=(--dart-define=APPS_SCRIPT_URL="${APP_SCRIPT_URL}")
  echo "Using Apps Script URL from environment."
fi

if [ -n "${APPS_SCRIPT_DEPLOYMENT_ID:-}" ] && [ -z "${APP_SCRIPT_URL}" ]; then
  EXTRA_ARGS+=(--dart-define=APPS_SCRIPT_DEPLOYMENT_ID="${APPS_SCRIPT_DEPLOYMENT_ID}")
  echo "Using Apps Script deployment id from environment."
fi

if [ "$DEVICE" = "web-server" ]; then
  "$FLUTTER_SDK/bin/flutter" run -d web-server --web-hostname 0.0.0.0 --web-port 7357 "${EXTRA_ARGS[@]}"
else
  "$FLUTTER_SDK/bin/flutter" run -d "$DEVICE" --web-port 7357 "${EXTRA_ARGS[@]}"
fi
