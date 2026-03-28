
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/Bettertext"
BIN_DIR="$HOME/.local/bin"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
APPS_DIR="$HOME/.local/share/applications"
MIME_DIR="$HOME/.local/share/mime"

REPO_URL="https://github.com/bettertext-project/better-text-web.git"
DEB_URL="https://raw.githubusercontent.com/bettertext-project/better-text-web/main/bettertext_1.0.0-2_all.deb"
DEB_PATH="$APP_DIR/bettertext_1.0.0-2_all.deb"
DEB_UNPACK_DIR="$APP_DIR/deb-unpacked"

# Colors
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

say() { echo -e "${BOLD}[BetterText]${RESET} $*"; }
warn() { echo -e "${YELLOW}[BetterText]${RESET} $*"; }
err() { echo -e "${RED}[BetterText]${RESET} $*"; }

confirm() {
  local prompt="$1"
  read -r -p "${prompt} [y/N]: " ans || true
  case "${ans,,}" in y|yes) return 0;; *) return 1;; esac
}

need_cmds=(python3 curl git dpkg-deb)
missing=()
for c in "${need_cmds[@]}"; do
  command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done

# Check GTK Python bindings
have_gtk=1
if ! python3 - <<'PY'
import gi
from gi.repository import Gtk
PY
then
  have_gtk=0
fi

if (( ${#missing[@]} > 0 || have_gtk == 0 )); then
  warn "Missing dependencies detected."
  echo "Required: python3, curl, git, dpkg, python3-gi, gir1.2-gtk-3.0"
  if command -v sudo >/dev/null 2>&1; then
    if confirm "Install missing dependencies now?"; then
      sudo apt update
      sudo apt install -y python3 curl git dpkg python3-gi gir1.2-gtk-3.0
    else
      err "Please install dependencies and re-run."
      exit 1
    fi
  else
    err "sudo not available. Install dependencies manually and re-run."
    exit 1
  fi
fi

say "This will install BetterText to: ${BOLD}$APP_DIR${RESET}"
if [ -d "$APP_DIR" ] && [ ! -d "$APP_DIR/.git" ]; then
  warn "$APP_DIR exists but is not a git repo."
  if ! confirm "Continue and keep existing files?"; then
    err "Cancelled."
    exit 1
  fi
fi

mkdir -p "$APP_DIR" "$BIN_DIR" "$APPS_DIR" "$ICON_DIR" "$MIME_DIR/packages"

if [ ! -d "$APP_DIR/.git" ]; then
  say "Cloning repo into $APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
else
  say "Repo already exists in $APP_DIR (skipping clone)"
fi

say "Downloading .deb"
curl -fL "$DEB_URL" -o "$DEB_PATH"

say "Unpacking .deb"
rm -rf "$DEB_UNPACK_DIR"
mkdir -p "$DEB_UNPACK_DIR"
dpkg-deb -x "$DEB_PATH" "$DEB_UNPACK_DIR"

SCRIPT_DIR="$APP_DIR/linux"
install -m 0755 "$SCRIPT_DIR/bettertext.py" "$APP_DIR/bettertext.py"
install -m 0644 "$SCRIPT_DIR/bettertext.desktop" "$APP_DIR/bettertext.desktop"
install -m 0644 "$SCRIPT_DIR/bettertext.svg" "$APP_DIR/bettertext.svg"

cat > "$BIN_DIR/bettertext" <<'EOF'
#!/usr/bin/env bash
exec python3 "$HOME/Bettertext/bettertext.py" "$@"
EOF
chmod 0755 "$BIN_DIR/bettertext"

install -m 0644 "$SCRIPT_DIR/bettertext.desktop" "$APPS_DIR/bettertext.desktop"
install -m 0644 "$SCRIPT_DIR/bettertext.svg" "$ICON_DIR/bettertext.svg"

cat > "$MIME_DIR/packages/bettertext.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-bettertext">
    <comment>BetterText Document</comment>
    <glob pattern="*.txt"/>
    <glob pattern="*.md"/>
    <glob pattern="*.log"/>
  </mime-type>
</mime-info>
EOF

update-mime-database "$MIME_DIR"
update-desktop-database "$APPS_DIR" || true

say "${GREEN}Installed!${RESET} Run: ${BOLD}bettertext${RESET}"
say "Files live in: $APP_DIR"
