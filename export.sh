#!/usr/bin/env bash
set -euo pipefail

# ── Export Obsidian environment from a vault to this repo ──
# Usage: ./export.sh /path/to/your/vault

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/obsidian-config"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-obsidian-vault>"
  echo "Example: $0 ~/Documents/MyVault"
  exit 1
fi

VAULT_DIR="$1"
OBSIDIAN_DIR="$VAULT_DIR/.obsidian"

if [[ ! -d "$OBSIDIAN_DIR" ]]; then
  echo "Error: No .obsidian folder found at $OBSIDIAN_DIR"
  echo "Make sure the path points to an Obsidian vault."
  exit 1
fi

echo "Exporting Obsidian config from: $VAULT_DIR"

# Clean previous export
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Files/folders to skip (machine-specific, not useful to sync)
EXCLUDES=(
  "workspace.json"
  "workspace-mobile.json"
  ".obsidian-git-data"
  ".trash"
  "cache"
  ".DS_Store"
)

# Binary file patterns to exclude (bloat the repo, not useful in version control)
BINARY_EXCLUDES=(
  "*.wasm" "*.node" "*.dylib" "*.so" "*.dll" "*.exe"
  "*.png" "*.jpg" "*.jpeg" "*.gif" "*.ico" "*.bmp" "*.webp"
  "*.ttf" "*.woff" "*.woff2" "*.eot" "*.otf"
  "*.zip" "*.tar" "*.gz" "*.7z" "*.rar"
  "*.pdf" "*.mp3" "*.mp4" "*.wav" "*.ogg"
)

# Build rsync exclude args
EXCLUDE_ARGS=()
for pattern in "${EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=(--exclude "$pattern")
done
for pattern in "${BINARY_EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=(--exclude "$pattern")
done

rsync -av --delete \
  "${EXCLUDE_ARGS[@]}" \
  "$OBSIDIAN_DIR/" "$BACKUP_DIR/"

# Remove any remaining binary files detected by content (catches extensionless binaries)
BIN_COUNT=0
while IFS= read -r -d '' f; do
  encoding=$(file -b --mime-encoding "$f" 2>/dev/null)
  if [[ "$encoding" == "binary" ]]; then
    rm -f "$f"
    ((BIN_COUNT++)) || true
  fi
done < <(find "$BACKUP_DIR" -type f -print0)
if [[ $BIN_COUNT -gt 0 ]]; then
  echo "Removed $BIN_COUNT binary files"
fi

# Remove all plugin data.json files — these contain vault-specific state,
# cached file paths, tokens, and other data that shouldn't be committed.
# Plugin settings will reset to defaults on import.
DATA_COUNT=$(find "$BACKUP_DIR/plugins" -name 'data.json' 2>/dev/null | wc -l | tr -d ' ')
find "$BACKUP_DIR/plugins" -name 'data.json' -delete 2>/dev/null
# Also remove other known state files
find "$BACKUP_DIR/plugins" -name 'cursor-positions.json' -delete 2>/dev/null
find "$BACKUP_DIR/plugins" -name 'brat-migrations.json' -delete 2>/dev/null
echo "Removed $DATA_COUNT plugin data.json files (vault-specific state)"

echo ""
echo "✅ Exported to: $BACKUP_DIR"
echo ""
echo "Exported contents:"
echo "  Config files:  $(find "$BACKUP_DIR" -maxdepth 1 -name '*.json' | wc -l | tr -d ' ') JSON files"
echo "  Plugins:       $(find "$BACKUP_DIR/plugins" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') plugins"
echo "  Themes:        $(find "$BACKUP_DIR/themes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') themes"
echo "  Snippets:      $(find "$BACKUP_DIR/snippets" -name '*.css' 2>/dev/null | wc -l | tr -d ' ') CSS snippets"
echo ""
echo "Now commit and push to save your environment."
