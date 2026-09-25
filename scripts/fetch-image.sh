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
cache_version=2
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

# Keep the asset small enough for the 26px horizontal bar while preserving
# its aspect ratio. A transparent square gives favicons a stable footprint.
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
  -thumbnail '20x20>' \
  -gravity center \
  -extent 20x20 \
  "PNG32:$converted"

mv -f -- "$converted" "$output"
printf '%s\n' "$output"
