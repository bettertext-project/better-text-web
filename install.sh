#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/Bettertext"
REPO_URL="https://github.com/bettertext-project/better-text-web.git"
DEB_URL="https://github.com/bettertext-project/better-text-web/blob/main/bettertext_1.0.0-2_all.repacked.deb"
DEB_PATH="$APP_DIR/bettertext_1.0.0-2_all.deb"

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

need_cmds=(curl git dpkg)
missing=()
for c in "${need_cmds[@]}"; do
  command -v "$c" >/dev/null 2>&1 || missing+=("$c")
done

if (( ${#missing[@]} > 0 )); then
  warn "Missing dependencies: ${missing[*]}"
  if command -v sudo >/dev/null 2>&1; then
    if confirm "Install missing dependencies now?"; then
      sudo apt update
      sudo apt install -y curl git dpkg
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

mkdir -p "$APP_DIR"

if [ ! -d "$APP_DIR/.git" ]; then
  say "Cloning repo into $APP_DIR"
  git clone "$REPO_URL" "$APP_DIR"
else
  say "Repo already exists in $APP_DIR (skipping clone)"
fi

say "Downloading .deb"
curl -fL "$DEB_URL" -o "$DEB_PATH"

say "Installing .deb (force overwrite if conflicts)"
sudo dpkg -i --force-overwrite "$DEB_PATH"

say "${GREEN}BetterText Installed!${RESET} Run: ${BOLD}bettertext${RESET}"
