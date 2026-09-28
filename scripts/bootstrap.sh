#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

chmod +x "$ROOT/scripts/fetch-fonts.sh"

cd "$ROOT"
swift "$ROOT/scripts/generate-app-icon.swift"
"$ROOT/scripts/fetch-fonts.sh"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen is required."
  echo "Install it with: brew install xcodegen"
  exit 1
fi

cd "$ROOT"
xcodegen generate
echo "Generated Zentra.xcodeproj"
echo "Open it with: open Zentra.xcodeproj"
