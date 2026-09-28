#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FONT_DIR="$ROOT/Zentra/Resources/Fonts"
mkdir -p "$FONT_DIR"

download() {
  local url="$1"
  local output="$2"
  if [ -s "$output" ]; then
    echo "✓ $(basename "$output") already exists"
    return
  fi
  echo "Downloading $(basename "$output")..."
  curl --fail --location --retry 3 --silent --show-error "$url" --output "$output"
}

download "https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf" "$FONT_DIR/Cairo-Variable.ttf"
download "https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf" "$FONT_DIR/Inter-Variable.ttf"

echo "✓ Local fonts ready in Zentra/Resources/Fonts"
