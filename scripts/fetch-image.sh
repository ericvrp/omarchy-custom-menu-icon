#!/usr/bin/env bash
set -euo pipefail

url=${1:-}

case "$url" in
  https://*) ;;
  *) exit 2 ;;
esac

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/omarchy-custom-menu-icon"
mkdir -p "$cache_dir"

# Bump this when image normalization changes so an existing cache cannot keep
# serving an image produced by an older conversion policy.
cache_version=3
hash=$(printf '%s\0%s' "$cache_version" "$url" | sha256sum | cut -d' ' -f1)
output="$cache_dir/$hash.png"

if [[ -s "$output" ]]; then
  printf '%s\n' "$output"
  exit 0
fi

download=$(mktemp "$cache_dir/.${hash}.download.XXXXXX")
converted=$(mktemp "$cache_dir/.${hash}.converted.XXXXXX.png")

cleanup() {
  rm -f -- "$download" "$converted"
}
trap cleanup EXIT

curl \
  --fail \
  --silent \
  --show-error \
  --location \
  --proto '=https' \
  --proto-redir '=https' \
  --connect-timeout 10 \
  --max-time 30 \
  --max-filesize 8M \
  --output "$download" \
  "$url"

# Keep the visible artwork small enough for the 26px horizontal bar while
# preserving its aspect ratio. The transparent 20px square gives every image
# a stable footprint, and the 16px artwork keeps solid logos visually aligned
# with the smaller emoji/text presets.
magick \
  -background none \
  -limit memory 128MiB \
  -limit map 256MiB \
  "$download" \
  -auto-orient \
  -alpha on \
  -fuzz 3% \
  -fill none \
  -draw 'color 0,0 floodfill' \
  -thumbnail '16x16>' \
  -gravity center \
  -extent 20x20 \
  "PNG32:$converted"

mv -f -- "$converted" "$output"
printf '%s\n' "$output"
