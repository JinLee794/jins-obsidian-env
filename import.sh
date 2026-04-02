#!/usr/bin/env bash
set -euo pipefail

# ── Import Obsidian environment from this repo into a vault ──
# Usage: ./import.sh /path/to/your/vault

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/obsidian-config"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-obsidian-vault>"
  echo "Example: $0 ~/Documents/MyVault"
  exit 1
fi

VAULT_DIR="$1"

if [[ ! -d "$VAULT_DIR" ]]; then
  echo "Error: Vault directory does not exist: $VAULT_DIR"
  exit 1
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Error: No exported config found at $BACKUP_DIR"
  echo "Run ./export.sh first to export a config."
  exit 1
fi

OBSIDIAN_DIR="$VAULT_DIR/.obsidian"

# If .obsidian already exists, back it up
if [[ -d "$OBSIDIAN_DIR" ]]; then
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUP_PATH="$VAULT_DIR/.obsidian-backup-$TIMESTAMP"
  echo "⚠️  Existing .obsidian found. Backing up to: $BACKUP_PATH"
  cp -r "$OBSIDIAN_DIR" "$BACKUP_PATH"
fi

mkdir -p "$OBSIDIAN_DIR"

echo "Importing Obsidian config into: $VAULT_DIR"

rsync -av \
  "$BACKUP_DIR/" "$OBSIDIAN_DIR/"

echo ""
echo "✅ Imported successfully!"
echo ""
echo "Imported contents:"
echo "  Config files:  $(find "$OBSIDIAN_DIR" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ') JSON files"
echo "  Plugins:       $(find "$OBSIDIAN_DIR/plugins" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') plugins"
echo "  Themes:        $(find "$OBSIDIAN_DIR/themes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') themes"
echo "  Snippets:      $(find "$OBSIDIAN_DIR/snippets" -name '*.css' 2>/dev/null | wc -l | tr -d ' ') CSS snippets"
echo ""
echo "Restart Obsidian (or reopen the vault) to apply changes."
