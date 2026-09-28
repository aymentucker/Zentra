#!/bin/bash
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen is required."
  echo "Install it with: brew install xcodegen"
  exit 1
fi

xcodegen generate
echo "Generated Zentra.xcodeproj"
echo "Open it with: open Zentra.xcodeproj"
