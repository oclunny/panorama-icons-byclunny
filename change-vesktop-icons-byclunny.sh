#!/usr/bin/env bash
# change-vesktop-icons-byclunny.sh
# Change the tray icon and the menu (launcher) icon of Vesktop (Flatpak).
set -uo pipefail

APP_ID="dev.vencord.Vesktop"
ASAR="npx --yes @electron/asar@3.2.18"
DATA="$HOME/.local/share/vesktop-icon-changer"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons"
DESKTOP_NAME="$APP_ID.desktop"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SRC="$SCRIPT_DIR"

mkdir -p "$DATA/backups" "$APPS" "$ICONS"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

die() { echo "Error: $*" >&2; exit 1; }

# ---------- dependency check ----------
check_deps() {
  command -v flatpak >/dev/null || die "Flatpak is not installed."
  flatpak info "$APP_ID" >/dev/null 2>&1 || die "Vesktop (Flatpak) is not installed."

  if ! command -v npx >/dev/null; then
    echo "Missing: nodejs and npm (needed to unpack Vesktop's app.asar)"
    read -rp "Install the missing packages now? [Y/n] " a
    if [[ ! "$a" =~ ^[Nn] ]]; then
      if command -v apt >/dev/null; then sudo apt install -y nodejs npm
      elif command -v dnf >/dev/null; then sudo dnf install -y nodejs npm
      elif command -v pacman >/dev/null; then sudo pacman -S --needed nodejs npm
      elif command -v zypper >/dev/null; then sudo zypper install -y nodejs npm
      elif command -v apk >/dev/null; then sudo apk add nodejs npm
      else die "Unknown package manager. Install nodejs and npm yourself."
      fi
    fi
    command -v npx >/dev/null || die "npx is still missing."
  fi
}

# ---------- helpers ----------
find_asar() {
  find "/var/lib/flatpak/app/$APP_ID" "$HOME/.local/share/flatpak/app/$APP_ID" \
    -name app.asar 2>/dev/null | head -n1
}

check_icons() {
  [ -f "$ICON_SRC/panorama-tray.png" ] && [ -f "$ICON_SRC/panorama-tray-unread.png" ] \
    && [ -f "$ICON_SRC/panorama-launcher.png" ] \
    || die "Icons not found in $ICON_SRC. Run the script from inside the cloned repo."
}

# ---------- tray icon ----------
apply_tray() {
  local asar hash backup
  asar=$(find_asar)
  [ -n "$asar" ] || die "Could not find Vesktop's app.asar."
  hash=$(echo "$asar" | sed -E 's#.*/([^/]+)/files/.*#\1#')

  cp "$1" "$TMP/icon.png"
  if command -v magick >/dev/null; then
    magick "$TMP/icon.png" -background none -resize 64x64 -gravity center -extent 64x64 "$TMP/icon64.png" && mv "$TMP/icon64.png" "$TMP/icon.png"
  elif command -v convert >/dev/null; then
    convert "$TMP/icon.png" -background none -resize 64x64 -gravity center -extent 64x64 "$TMP/icon64.png" && mv "$TMP/icon64.png" "$TMP/icon.png"
  else
    echo "Note: ImageMagick not found, using your image as-is (64x64 is recommended)."
  fi

  # one backup per Vesktop version, taken before the first change
  backup="$DATA/backups/app-$hash.asar"
  [ -f "$backup" ] || { cp "$asar" "$backup" && echo "Backup saved: $backup"; }

  $ASAR extract "$asar" "$TMP/src" || die "Could not unpack app.asar."
  [ -d "$TMP/src/static/tray" ] || die "Unexpected Vesktop layout (static/tray not found)."
  cp "$TMP/icon.png" "$TMP/src/static/tray.png"
  cp "$TMP/icon.png" "$TMP/src/static/tray/tray.png"
  if [ -n "${2:-}" ] && [ -f "$2" ]; then
    cp "$2" "$TMP/src/static/tray/trayUnread.png"
    cp "$2" "$DATA/tray-unread.png"
  fi
  $ASAR pack "$TMP/src" "$TMP/new.asar" || die "Could not repack app.asar."

  echo "Installing the new tray icon (needs sudo)..."
  sudo cp "$TMP/new.asar" "$asar" || die "Could not replace app.asar."
  cp "$TMP/icon.png" "$DATA/tray.png"
  echo "Tray icon changed."
}

# ---------- launcher icon ----------
apply_launcher() {
  local src="" d
  for d in /var/lib/flatpak/exports/share/applications "$HOME/.local/share/flatpak/exports/share/applications"; do
    if [ -f "$d/$DESKTOP_NAME" ]; then src="$d/$DESKTOP_NAME"; break; fi
  done
  [ -n "$src" ] || die "Could not find Vesktop's launcher file."

  cp "$1" "$ICONS/vesktop-custom.png"
  cp "$src" "$APPS/$DESKTOP_NAME"
  sed -i "s|^Icon=.*|Icon=$ICONS/vesktop-custom.png|" "$APPS/$DESKTOP_NAME"
  update-desktop-database "$APPS" 2>/dev/null || true
  echo "Menu icon changed. If it looks unchanged, remove Vesktop from your panel and re-add it."
}

# ---------- restore ----------
restore_original() {
  local asar hash backup
  rm -f "$APPS/$DESKTOP_NAME" "$ICONS/vesktop-custom.png"
  update-desktop-database "$APPS" 2>/dev/null || true
  echo "Menu icon restored."

  asar=$(find_asar)
  [ -n "$asar" ] || die "Could not find Vesktop's app.asar."
  hash=$(echo "$asar" | sed -E 's#.*/([^/]+)/files/.*#\1#')
  backup="$DATA/backups/app-$hash.asar"
  if [ -f "$backup" ]; then
    sudo cp "$backup" "$asar" && echo "Tray icon restored."
  else
    echo "No backup for this Vesktop version. To restore the tray icon, run: flatpak repair"
  fi
}

# ---------- menu ----------
check_deps
echo
echo "Vesktop icon changer"
echo "  [1] Apply the tray icon and the menu icon (recommended)"
echo "  [2] Apply the tray icon only"
echo "  [3] Apply the menu (launcher) icon only"
echo "  [4] Re-apply the saved tray icon (use after a Vesktop update)"
echo "  [5] Restore Vesktop's original icons"
echo "  [q] Quit"
read -rp "Choose: " choice

case "$choice" in
  1) check_icons; apply_tray "$ICON_SRC/panorama-tray.png" "$ICON_SRC/panorama-tray-unread.png"; apply_launcher "$ICON_SRC/panorama-launcher.png" ;;
  2) check_icons; apply_tray "$ICON_SRC/panorama-tray.png" "$ICON_SRC/panorama-tray-unread.png" ;;
  3) check_icons; apply_launcher "$ICON_SRC/panorama-launcher.png" ;;
  4) [ -f "$DATA/tray.png" ] || die "No saved tray icon yet. Use option 1 or 2 first."
     apply_tray "$DATA/tray.png" "$DATA/tray-unread.png" ;;
  5) restore_original ;;
  *) exit 0 ;;
esac

echo
echo "Done. Fully quit Vesktop (tray > Quit) and start it again."
