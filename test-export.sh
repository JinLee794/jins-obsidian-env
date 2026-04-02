#!/usr/bin/env bash
set -euo pipefail

# ── Test exported Obsidian config for secrets and private info ──
# Run after export.sh to validate the obsidian-config/ directory.
# Exit 0 = all clean, Exit 1 = problems found.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/obsidian-config"
FAILURES=0

red()   { printf "\033[1;31m%s\033[0m\n" "$*"; }
green() { printf "\033[1;32m%s\033[0m\n" "$*"; }
warn()  { printf "\033[1;33m%s\033[0m\n" "$*"; }

fail() {
  red "FAIL: $1"
  ((FAILURES++)) || true
}

pass() {
  green "PASS: $1"
}

if [[ ! -d "$BACKUP_DIR" ]]; then
  fail "obsidian-config/ directory not found — run export.sh first"
  exit 1
fi

echo "Running export safety tests on: $BACKUP_DIR"
echo ""

# ─────────────────────────────────────────────────
# 1. No binary files (by content detection)
# ─────────────────────────────────────────────────
BIN_FILES=()
while IFS= read -r -d '' f; do
  encoding=$(file -b --mime-encoding "$f" 2>/dev/null)
  if [[ "$encoding" == "binary" ]]; then
    BIN_FILES+=("$f")
  fi
done < <(find "$BACKUP_DIR" -type f -print0)

if [[ ${#BIN_FILES[@]} -gt 0 ]]; then
  fail "Binary files found (${#BIN_FILES[@]}):"
  for f in "${BIN_FILES[@]}"; do echo "  $f"; done
else
  pass "No binary files"
fi

# ─────────────────────────────────────────────────
# 2. No data.json files (vault-specific plugin state)
# ─────────────────────────────────────────────────
DATA_FILES=$(find "$BACKUP_DIR/plugins" -name 'data.json' 2>/dev/null)
if [[ -n "$DATA_FILES" ]]; then
  fail "Plugin data.json files found (should be stripped):"
  echo "$DATA_FILES" | sed 's/^/  /'
else
  pass "No plugin data.json files"
fi

# ─────────────────────────────────────────────────
# 3. No absolute user home paths
# ─────────────────────────────────────────────────
# Scan non-JS config files for home directory paths.
# Plugin main.js files are third-party code that may contain
# generic path-handling references like "/Users/" — skip them.
HOME_HITS=$(grep -rn '/Users/\|/home/\|C:\\Users\\' "$BACKUP_DIR" \
  --include='*.json' --include='*.css' \
  2>/dev/null | grep -v '/manifest\.json' || true)

if [[ -n "$HOME_HITS" ]]; then
  fail "Absolute home-directory paths found:"
  echo "$HOME_HITS" | head -20 | sed 's/^/  /'
else
  pass "No absolute home-directory paths in config"
fi

# ─────────────────────────────────────────────────
# 4. No API keys, tokens, or secrets in config files
# ─────────────────────────────────────────────────
# Only scan JSON config files (not plugin source code or plugin manifests,
# which legitimately reference words like "token" in descriptions).
SECRET_PATTERNS='(api[_-]?key|api[_-]?secret|access[_-]?token|refresh[_-]?token|auth[_-]?token|bearer [a-z0-9]|private[_-]?key|client[_-]?secret|password\s*[:=])'

SECRET_HITS=$(grep -rniE "$SECRET_PATTERNS" "$BACKUP_DIR" \
  --include='*.json' \
  --exclude='manifest.json' \
  2>/dev/null || true)

# Filter out plugin main.js / manifest references — focus on config JSONs
SECRET_HITS=$(echo "$SECRET_HITS" | grep -v '/plugins/.*/manifest\.json' | grep -v '^$' || true)

if [[ -n "$SECRET_HITS" ]]; then
  fail "Potential secrets/tokens in config files:"
  echo "$SECRET_HITS" | head -20 | sed 's/^/  /'
else
  pass "No API keys or secrets in config files"
fi

# ─────────────────────────────────────────────────
# 5. No email addresses (except third-party plugin authors)
# ─────────────────────────────────────────────────
# Plugin manifest.json files often include author emails — that's fine.
# We check everything else.
EMAIL_HITS=$(grep -rnoE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$BACKUP_DIR" \
  --include='*.json' --include='*.css' \
  2>/dev/null | grep -v '/plugins/.*/manifest\.json' | grep -v '^$' || true)

if [[ -n "$EMAIL_HITS" ]]; then
  fail "Email addresses found outside plugin manifests:"
  echo "$EMAIL_HITS" | head -20 | sed 's/^/  /'
else
  pass "No email addresses outside plugin manifests"
fi

# ─────────────────────────────────────────────────
# 6. No high-entropy strings (potential leaked secrets)
# ─────────────────────────────────────────────────
# Look for long hex or base64 strings in JSON configs that look like
# tokens/keys (40+ chars of hex, or base64-ish with mix of upper/lower/digits).
# Skip plugin source code and manifests.
HEX_HITS=$(grep -rnoE '[0-9a-fA-F]{40,}' "$BACKUP_DIR" \
  --include='*.json' \
  --exclude='manifest.json' \
  2>/dev/null | grep -v '/plugins/.*/manifest\.json' | grep -v '^$' || true)

if [[ -n "$HEX_HITS" ]]; then
  fail "Long hex strings found (potential tokens):"
  echo "$HEX_HITS" | head -10 | sed 's/^/  /'
else
  pass "No suspicious long hex strings in config"
fi

# ─────────────────────────────────────────────────
# 7. No .DS_Store or OS metadata files
# ─────────────────────────────────────────────────
OS_FILES=$(find "$BACKUP_DIR" -name '.DS_Store' -o -name 'Thumbs.db' -o -name 'desktop.ini' 2>/dev/null)
if [[ -n "$OS_FILES" ]]; then
  fail "OS metadata files found:"
  echo "$OS_FILES" | sed 's/^/  /'
else
  pass "No OS metadata files (.DS_Store, Thumbs.db)"
fi

# ─────────────────────────────────────────────────
# 8. No vault-specific state files
# ─────────────────────────────────────────────────
STATE_FILES=$(find "$BACKUP_DIR/plugins" \( \
  -name 'cursor-positions.json' \
  -o -name 'brat-migrations.json' \
  -o -name 'workspace.json' \
  -o -name 'workspace-mobile.json' \
  \) 2>/dev/null)

if [[ -n "$STATE_FILES" ]]; then
  fail "Vault-specific state files found:"
  echo "$STATE_FILES" | sed 's/^/  /'
else
  pass "No vault-specific state files"
fi

# ─────────────────────────────────────────────────
# 9. No private vault names or paths in JSON configs
# ─────────────────────────────────────────────────
# Check for the literal vault path (from $OBSIDIAN_VAULT env or common patterns)
VAULT_PATH_HITS=""
if [[ -n "${OBSIDIAN_VAULT:-}" ]]; then
  VAULT_NAME=$(basename "$OBSIDIAN_VAULT")
  VAULT_PATH_HITS=$(grep -rn "$OBSIDIAN_VAULT" "$BACKUP_DIR" \
    --include='*.json' \
    2>/dev/null || true)
fi

if [[ -n "$VAULT_PATH_HITS" ]]; then
  fail "Vault-specific paths found in config:"
  echo "$VAULT_PATH_HITS" | head -10 | sed 's/^/  /'
else
  pass "No vault-specific paths in config"
fi

# ─────────────────────────────────────────────────
# 10. Only expected file types present
# ─────────────────────────────────────────────────
# Allowed: .json, .js, .css (and directories)
UNEXPECTED=$(find "$BACKUP_DIR" -type f \
  ! -name '*.json' \
  ! -name '*.js' \
  ! -name '*.css' \
  2>/dev/null)

if [[ -n "$UNEXPECTED" ]]; then
  fail "Unexpected file types:"
  echo "$UNEXPECTED" | sed 's/^/  /'
else
  pass "Only expected file types (.json, .js, .css)"
fi

# ─────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────
echo ""
if [[ $FAILURES -eq 0 ]]; then
  green "All tests passed ✅"
  exit 0
else
  red "$FAILURES test(s) failed ❌"
  exit 1
fi
