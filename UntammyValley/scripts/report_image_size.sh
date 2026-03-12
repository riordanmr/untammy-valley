#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <image_file>"
  echo "Example: $0 tmp/studyguide.png"
  exit 1
fi

image_file="$1"

if [[ ! -f "$image_file" ]]; then
  echo "Error: file not found: $image_file"
  exit 1
fi

# Query pixel dimensions with sips and print a compact result.
width="$(sips -g pixelWidth "$image_file" | awk -F': ' '/pixelWidth/ {print $2; exit}')"
height="$(sips -g pixelHeight "$image_file" | awk -F': ' '/pixelHeight/ {print $2; exit}')"

if [[ -z "$width" || -z "$height" ]]; then
  echo "Error: unable to read image dimensions for: $image_file"
  exit 1
fi

echo "${image_file}: ${width}x${height}"