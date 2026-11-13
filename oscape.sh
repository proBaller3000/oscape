#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oscape"
POLL_INTERVAL=1

MEDIA_MODE=""
MEDIA_SOURCE=""
CURRENT_MODE=""
CURRENT_SOURCE=""
VIDEO_PID=""
PROBED_URL=""
PROBED_IS_VIDEO=1

is_video() {
  local url="$1" codec
  if [ "$url" = "$PROBED_URL" ]; then
    return "$PROBED_IS_VIDEO"
  fi
  PROBED_URL="$url"
  if codec="$(timeout 10 ffprobe -v error -select_streams v:0 \
      -show_entries stream=codec_type -of csv=p=0 "$url" 2>/dev/null)" &&
     [ "$codec" = "video" ]; then
    PROBED_IS_VIDEO=0
  else
    PROBED_IS_VIDEO=1
  fi
  return "$PROBED_IS_VIDEO"
}

detect_media() {
  MEDIA_MODE=""
  MEDIA_SOURCE=""
  local sep=$'\x1f' status art url
  while IFS="$sep" read -r status art url; do
    [ "$status" = "Playing" ] || continue
    if [ -n "$url" ] && is_video "$url"; then
      MEDIA_MODE="video"
      MEDIA_SOURCE="$url"
      return 0
    fi
    if [ -z "$MEDIA_MODE" ] && [ -n "$art" ]; then
      MEDIA_MODE="image"
      MEDIA_SOURCE="$art"
    fi
  done < <(playerctl --all-players metadata \
    --format "{{status}}${sep}{{mpris:artUrl}}${sep}{{xesam:url}}" 2>/dev/null || true)
  [ -n "$MEDIA_MODE" ]
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

apply_image() {
  local url="$1" dest
  dest="$(cache_art "$url")" || return 1
  noctalia msg wallpaper-set "$dest" || return 1
  cleanup_art "$dest"
}

start_video() {
  stop_video
  mpvpaper -l bottom -o "audio=auto loop=inf" ALL "$1" &
  VIDEO_PID=$!
}

stop_video() {
  [ -n "$VIDEO_PID" ] || return 0
  kill "$VIDEO_PID" 2>/dev/null || true
  wait "$VIDEO_PID" 2>/dev/null || true
  VIDEO_PID=""
}

watch_media() {
  while true; do
    if ! detect_media; then
      if [ "$CURRENT_MODE" = "video" ]; then
        stop_video
        CURRENT_MODE=""
        CURRENT_SOURCE=""
      fi
      sleep "$POLL_INTERVAL"
      continue
    fi

    if [ "$CURRENT_MODE" = "video" ] && ! kill -0 "$VIDEO_PID" 2>/dev/null; then
      CURRENT_MODE=""
      CURRENT_SOURCE=""
      VIDEO_PID=""
    fi

    if [ "$MEDIA_MODE" != "$CURRENT_MODE" ] ||
       [ "$MEDIA_SOURCE" != "$CURRENT_SOURCE" ]; then
      if [ "$MEDIA_MODE" = "video" ]; then
        start_video "$MEDIA_SOURCE"
        CURRENT_MODE="video"
        CURRENT_SOURCE="$MEDIA_SOURCE"
      else
        stop_video
        if apply_image "$MEDIA_SOURCE"; then
          CURRENT_MODE="image"
          CURRENT_SOURCE="$MEDIA_SOURCE"
        fi
      fi
    fi

    sleep "$POLL_INTERVAL"
  done
}

main() {
  trap stop_video EXIT
  trap 'exit 0' INT TERM
  watch_media
}

main "$@"
