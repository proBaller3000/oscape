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

echo ":: Installing pacman packages"
$SUDO pacman -S --needed --noconfirm \
  playerctl curl mpv yt-dlp deno imagemagick

if ! command -v yay >/dev/null 2>&1; then
  echo "error: yay not found; install it first: https://github.com/Jguer/yay" >&2
  exit 1
fi

echo ":: Installing AUR packages"
yay -S --needed --noconfirm mpvpaper

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

