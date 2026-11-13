#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oscape"
POLL_INTERVAL=1

get_playing_art() {
  local status art
  while IFS=$'\t' read -r status art; do
    [ "$status" = "Playing" ] || continue
    [ -n "$art" ] || continue
    printf '%s\n' "$art"
    return 0
  done < <(playerctl --all-players metadata \
    --format $'{{status}}\t{{mpris:artUrl}}' 2>/dev/null || true)
  return 1
}

cache_art() {
  local url="$1" tmp dest
  mkdir -p "$CACHE_DIR"
  tmp="$CACHE_DIR/.artwork.tmp"
  curl -fsSL "$url" -o "$tmp"
  dest="$CACHE_DIR/artwork-$(sha256sum "$tmp" | cut -d' ' -f1)"
  mv "$tmp" "$dest"
  printf '%s\n' "$dest"
}

cleanup_art() {
  local keep="$1"
  find "$CACHE_DIR" -maxdepth 1 -type f \
    \( -name 'artwork-*' -o -name 'artwork' \) \
    ! -name "$(basename "$keep")" -delete
}

watch_art() {
  local art last_url="" dest last_dest=""
  while true; do
    art="$(get_playing_art || true)"
    if [ -n "$art" ] && [ "$art" != "$last_url" ]; then
      if dest="$(cache_art "$art")"; then
        if [ "$dest" = "$last_dest" ] || noctalia msg wallpaper-set "$dest"; then
          cleanup_art "$dest"
          last_dest="$dest"
          last_url="$art"
        fi
      fi
    fi
    sleep "$POLL_INTERVAL"
  done
}

main() {
  watch_art
}

main "$@"
