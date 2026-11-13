#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oscape"

get_playing_art() {
  local player status art
  while IFS= read -r player; do
    status="$(playerctl -p "$player" status 2>/dev/null)" || continue
    [ "$status" = "Playing" ] || continue
    art="$(playerctl -p "$player" metadata mpris:artUrl 2>/dev/null || true)"
    [ -n "$art" ] || continue
    printf '%s\n' "$art"
    return 0
  done < <(playerctl -l 2>/dev/null)
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

main() {
  local art dest
  if ! art="$(get_playing_art)"; then
    echo "no playing media with artwork" >&2
    return 1
  fi
  dest="$(cache_art "$art")"
  noctalia msg wallpaper-set "$dest"
  cleanup_art "$dest"
}

main "$@"
