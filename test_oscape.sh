#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
mkdir -p "$TMP/bin" "$TMP/cache"

cat > "$TMP/bin/playerctl" <<'EOF'
#!/usr/bin/env bash
cat "$OSCAPE_TEST_STATE"
EOF
cat > "$TMP/bin/noctalia" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$OSCAPE_TEST_LOG"
printf 'ok\n'
EOF
cat > "$TMP/bin/mpvpaper" <<'EOF'
#!/usr/bin/env bash
echo $$ > "$OSCAPE_TEST_MPV_PID"
trap 'rm -f "$OSCAPE_TEST_MPV_PID"; exit 0' TERM
while :; do sleep 1; done
EOF
chmod +x "$TMP/bin/"*

ffmpeg -y -v error -f lavfi -i color=red:size=16x16 -frames:v 1 "$TMP/art.png"
ffmpeg -y -v error -f lavfi -i testsrc=size=16x16:rate=5 -t 1 \
  -pix_fmt yuv420p "$TMP/video.mp4"
printf 'Playing\x1f\x1ffile://%s/video.mp4\n' "$TMP" > "$TMP/state"

export PATH="$TMP/bin:$PATH"
export XDG_CACHE_HOME="$TMP/cache"
export OSCAPE_TEST_STATE="$TMP/state"
export OSCAPE_TEST_LOG="$TMP/noctalia.log"
export OSCAPE_TEST_MPV_PID="$TMP/mpv.pid"

"$ROOT/oscape.sh" >/dev/null 2>&1 &
OS_PID=$!
cleanup() {
  kill "$OS_PID" 2>/dev/null || true
  wait "$OS_PID" 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

sleep 2
[ -f "$OSCAPE_TEST_MPV_PID" ] || fail "video did not start"

printf 'Playing\x1f%s\x1f\n' "file://$TMP/art.png" > "$OSCAPE_TEST_STATE"
sleep 2
[ ! -f "$OSCAPE_TEST_MPV_PID" ] || fail "video did not stop for image"
grep -q wallpaper-set "$OSCAPE_TEST_LOG" || fail "image not applied"

printf 'Playing\x1f\x1ffile://%s/video.mp4\n' "$TMP" > "$OSCAPE_TEST_STATE"
sleep 2
[ -f "$OSCAPE_TEST_MPV_PID" ] || fail "video did not restart"

: > "$OSCAPE_TEST_STATE"
sleep 2
[ ! -f "$OSCAPE_TEST_MPV_PID" ] || fail "video did not stop when idle"

printf 'ok\n'
