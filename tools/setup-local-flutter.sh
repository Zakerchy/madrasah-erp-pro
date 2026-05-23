#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE="$REPO_ROOT/.local-tools"
SDK_DIR="$BASE/flutter"
FLUTTER_UPDATE="${FLUTTER_UPDATE:-0}"

mkdir -p "$BASE"

if [ ! -d "$SDK_DIR/.git" ]; then
  echo "Installing Flutter stable via git clone..."
  rm -rf "$SDK_DIR"
  git clone https://github.com/flutter/flutter.git -b stable "$SDK_DIR"
else
  if [ "$FLUTTER_UPDATE" = "1" ]; then
    echo "Flutter SDK exists. Updating..."
    git -C "$SDK_DIR" fetch --tags
    git -C "$SDK_DIR" pull --ff-only
  else
    echo "Flutter SDK already installed. Skipping update (set FLUTTER_UPDATE=1 to update)."
  fi
fi

echo "Preparing Flutter SDK..."
"$SDK_DIR/bin/flutter" --disable-analytics >/dev/null
"$SDK_DIR/bin/flutter" config --enable-web >/dev/null
"$SDK_DIR/bin/flutter" precache --web

echo "Flutter installed at: $SDK_DIR"
"$SDK_DIR/bin/flutter" --version
