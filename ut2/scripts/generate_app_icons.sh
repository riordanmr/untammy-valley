#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 /path/to/source-1024.png"
  exit 1
fi

SOURCE="$1"
ICONSET_DIR="$(cd "$(dirname "$0")/.." && pwd)/UT2/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$SOURCE" ]]; then
  echo "Source file not found: $SOURCE"
  exit 1
fi

mkdir -p "$ICONSET_DIR"

make_icon() {
  local pixels="$1"
  local filename="$2"
  sips -z "$pixels" "$pixels" "$SOURCE" --out "$ICONSET_DIR/$filename" >/dev/null
}

make_icon 40 icon-20@2x.png
make_icon 60 icon-20@3x.png
make_icon 58 icon-29@2x.png
make_icon 87 icon-29@3x.png
make_icon 80 icon-40@2x.png
make_icon 120 icon-40@3x.png
make_icon 120 icon-60@2x.png
make_icon 180 icon-60@3x.png
make_icon 20 icon-20@1x-ipad.png
make_icon 40 icon-20@2x-ipad.png
make_icon 29 icon-29@1x-ipad.png
make_icon 58 icon-29@2x-ipad.png
make_icon 40 icon-40@1x-ipad.png
make_icon 80 icon-40@2x-ipad.png
make_icon 76 icon-76@1x-ipad.png
make_icon 152 icon-76@2x-ipad.png
make_icon 167 icon-83.5@2x-ipad.png
cp "$SOURCE" "$ICONSET_DIR/icon-1024.png"

echo "Generated app icons in: $ICONSET_DIR"
