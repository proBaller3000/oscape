#!/usr/bin/env bash
set -euo pipefail

if ! command -v pacman >/dev/null 2>&1; then
  echo "error: pacman not found; this script targets Arch Linux" >&2
  exit 1
fi

SUDO=""
if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
fi

echo ":: Installing runtime packages"
$SUDO pacman -S --needed --noconfirm \
  playerctl curl ffmpeg mpv yt-dlp deno imagemagick

# Needed to build mpvpaper locally: meson/gcc/pkgconf compile it,
# wayland/wayland-protocols/libglvnd provide its Wayland/EGL headers and libs.
echo ":: Installing build tools for mpvpaper"
$SUDO pacman -S --needed --noconfirm \
  meson wayland wayland-protocols libglvnd pkgconf gcc

echo ":: Building mpvpaper from pinned upstream source"
MPVPAPER_VER=1.9
MPVPAPER_B2SUM=6b3c148d812d068878ba3acdb48b1f6d376980de3bf7bf23204c906011fd0bb8c0ebbb10fd77de1fcb8b4e3c543a6b5a8f1db92e189b128ec44fdfefbfc4b9bf
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

curl -fsSL -o "$BUILD_DIR/mpvpaper.tar.gz" \
  "https://github.com/GhostNaN/mpvpaper/archive/${MPVPAPER_VER}.tar.gz"
echo "${MPVPAPER_B2SUM}  ${BUILD_DIR}/mpvpaper.tar.gz" | b2sum -c -
tar -xzf "$BUILD_DIR/mpvpaper.tar.gz" -C "$BUILD_DIR"
meson setup "$BUILD_DIR/build" "$BUILD_DIR/mpvpaper-${MPVPAPER_VER}" --prefix=/usr/local
meson compile -C "$BUILD_DIR/build"
$SUDO meson install -C "$BUILD_DIR/build"
$SUDO install -Dm644 "$BUILD_DIR/mpvpaper-${MPVPAPER_VER}/mpvpaper.man" \
  /usr/local/share/man/man1/mpvpaper.1

if ! command -v noctalia >/dev/null 2>&1; then
  echo "warning: noctalia not found; static wallpaper needs noctalia-git" >&2
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
mkdir -p "$BIN_DIR"
ln -sf "$REPO_DIR/oscape.sh" "$BIN_DIR/oscape"

if [ ! -f "$REPO_DIR/oscape.sh" ]; then
  echo "warning: $REPO_DIR/oscape.sh does not exist yet; the oscape alias will be dangling" >&2
fi

echo ":: Done. Start with: oscape"

