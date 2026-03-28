#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$HOME/Bettertext"
BIN_DIR="$HOME/.local/bin"
APP_ID="bettertext"

mkdir -p "$APP_DIR" "$BIN_DIR" "$HOME/.local/share/applications" "$HOME/.local/share/icons/hicolor/scalable/apps" "$HOME/.local/share/mime/packages"

install -m 0755 "$(dirname "$0")/bettertext.py" "$APP_DIR/bettertext.py"
install -m 0644 "$(dirname "$0")/bettertext.desktop" "$APP_DIR/bettertext.desktop"
install -m 0644 "$(dirname "$0")/bettertext.svg" "$APP_DIR/bettertext.svg"

cat > "$BIN_DIR/bettertext" <<'EOF'
#!/usr/bin/env bash
exec python3 "$HOME/Bettertext/bettertext.py" "$@"
EOF
chmod 0755 "$BIN_DIR/bettertext"

install -m 0644 "$(dirname "$0")/bettertext.desktop" "$HOME/.local/share/applications/bettertext.desktop"
install -m 0644 "$(dirname "$0")/bettertext.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/bettertext.svg"

cat > "$HOME/.local/share/mime/packages/bettertext.xml" <<'EOF'
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

update-mime-database "$HOME/.local/share/mime"
update-desktop-database "$HOME/.local/share/applications" || true

echo "Installed. Run: bettertext"
