#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oscape"
mkdir -p "$CACHE_DIR"

art=""
while IFS= read -r player; do
  status="$(playerctl -p "$player" status 2>/dev/null)" || continue
  [ "$status" = "Playing" ] || continue
  art="$(playerctl -p "$player" metadata mpris:artUrl 2>/dev/null || true)"
  [ -n "$art" ] && break
done < <(playerctl -l 2>/dev/null)

if [ -z "$art" ]; then
  echo "no playing media with artwork" >&2
  exit 1
fi

TMP="$CACHE_DIR/.artwork.tmp"
curl -fsSL "$art" -o "$TMP"
DEST="$CACHE_DIR/artwork-$(sha256sum "$TMP" | cut -d' ' -f1)"
mv "$TMP" "$DEST"

noctalia msg wallpaper-set "$DEST"
find "$CACHE_DIR" -maxdepth 1 -type f \
  \( -name 'artwork-*' -o -name 'artwork' \) ! -name "$(basename "$DEST")" -delete
