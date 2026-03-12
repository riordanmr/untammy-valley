#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <base_name> <xsize3> <ysize3> <output_directory>"
  echo "Example: $0 studyguide 192 192 UntammyValley/Assets.xcassets/studyguide.imageset"
  exit 1
fi

base_name="$1"
xsize3="$2"
ysize3="$3"
out_dir="$4"

if ! [[ "$xsize3" =~ ^[0-9]+$ && "$ysize3" =~ ^[0-9]+$ ]]; then
  echo "Error: xsize3 and ysize3 must be positive integers."
  exit 1
fi

if (( xsize3 < 3 || ysize3 < 3 )); then
  echo "Error: xsize3 and ysize3 must be at least 3."
  exit 1
fi

xsize1=$((xsize3 / 3))
xsize2=$(((2 * xsize3) / 3))
ysize1=$((ysize3 / 3))
ysize2=$(((2 * ysize3) / 3))

src="tmp/${base_name}.png"

if [[ ! -f "$src" ]]; then
  echo "Error: source image not found: $src"
  exit 1
fi

mkdir -p "$out_dir"

cmd="sips -z ${xsize1} ${ysize1} \"${src}\" --out \"${out_dir}/${base_name}.png\" && \
sips -z ${xsize2} ${ysize2} \"${src}\" --out \"${out_dir}/${base_name}@2x.png\" && \
sips -z ${xsize3} ${ysize3} \"${src}\" --out \"${out_dir}/${base_name}@3x.png\""

echo "Running:"
echo "$cmd"

eval "$cmd"

echo "Done: ${out_dir}"