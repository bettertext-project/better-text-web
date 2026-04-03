#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
APP_NAME="BetterText"
APP_DIR="$HOME/Bettertext"
REPO_URL="https://github.com/bettertext-project/better-text-web.git"
DEB_URL="https://github.com/bettertext-project/better-text-web/raw/main/bettertext_1.0_amd64.deb"
DEB_PATH="$APP_DIR/bettertext_1.0_amd64.deb"

# --- COLORS ---
BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
RESET="\033[0m"

log()   { echo -e "${BLUE}${BOLD}[$APP_NAME]${RESET} $*"; }
ok()    { echo -e "${GREEN}${BOLD}[$APP_NAME]${RESET} $*"; }
warn()  { echo -e "${YELLOW}${BOLD}[$APP_NAME]${RESET} $*"; }
fail()  { echo -e "${RED}${BOLD}[$APP_NAME]${RESET} $*"; exit 1; }

confirm() {
  read -r -p "$(echo -e "${BOLD}$1 [y/N]: ${RESET}")" ans || true
  [[ "${ans,,}" =~ ^(y|yes)$ ]]
}

# --- CHECK DEPENDENCIES ---
log "Checking dependencies..."
need_cmds=(curl git dpkg)
missing=()

for cmd in "${need_cmds[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if (( ${#missing[@]} > 0 )); then
  warn "Missing: ${missing[*]}"
  if command -v sudo >/dev/null 2>&1 && confirm "Install them now?"; then
    sudo apt update
    sudo apt install -y "${missing[@]}"
  else
    fail "Please install required packages and re-run."
  fi
fi

# --- SETUP DIRECTORY ---
log "Preparing install directory..."
mkdir -p "$APP_DIR"

if [ -d "$APP_DIR/.git" ]; then
  log "Repository already exists (skipping clone)"
else
  if [ -d "$APP_DIR" ] && [ "$(ls -A "$APP_DIR")" ]; then
    warn "$APP_DIR is not empty."
    confirm "Continue anyway?" || fail "Cancelled."
  fi

  log "Cloning repository..."
  git clone "$REPO_URL" "$APP_DIR"
fi

# --- DOWNLOAD PACKAGE ---
log "Downloading package..."
if ! curl -fL "$DEB_URL" -o "$DEB_PATH"; then
  fail "Download failed. Check your internet or URL."
fi

# Verify it's actually a .deb
if ! file "$DEB_PATH" | grep -q "Debian binary package"; then
  fail "Downloaded file is not a valid .deb package."
fi

ok "Download complete"

# --- INSTALL ---
log "Installing package..."
if sudo dpkg -i "$DEB_PATH"; then
  ok "Installation successful"
else
  warn "Fixing dependencies..."
  sudo apt-get install -f -y
fi

# --- DONE ---
echo
ok "🎉 $APP_NAME installed successfully!"
echo -e "Run it with: ${BOLD}bettertext${RESET}"
echo
