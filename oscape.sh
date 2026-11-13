#!/usr/bin/env bash
set -euo pipefail

found=0
while IFS= read -r player; do
  status="$(playerctl -p "$player" status 2>/dev/null)" || continue
  [ "$status" = "Playing" ] || continue

  art="$(playerctl -p "$player" metadata mpris:artUrl 2>/dev/null || true)"
  [ -n "$art" ] || art="$(playerctl -p "$player" metadata xesam:url 2>/dev/null || true)"
  [ -n "$art" ] || continue

  title="$(playerctl -p "$player" metadata --format '{{xesam:artist}} - {{xesam:title}}' 2>/dev/null || true)"
  printf '%s\t%s\t%s\n' "$player" "$title" "$art"
  found=1
done < <(playerctl -l 2>/dev/null)

[ "$found" -eq 1 ] || echo "no playing media with artwork" >&2
