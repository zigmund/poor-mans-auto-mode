#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"

ln -sf "$REPO_DIR/bin/auto" "$BIN_DIR/auto"
ln -sf "$REPO_DIR/bin/auto-hook" "$BIN_DIR/auto-hook"

echo "Installed:"
echo "  $BIN_DIR/auto -> $REPO_DIR/bin/auto"
echo "  $BIN_DIR/auto-hook -> $REPO_DIR/bin/auto-hook"
echo ""
echo "Next steps:"
echo "  1. Ensure ~/.local/bin is on your PATH"
echo "  2. Add to ~/.claude/settings.json:"
echo '     permissions.allow: "Bash(auto *)"'
echo '     hooks.PreToolUse: [{"matcher":"Bash","hooks":[{"type":"command","command":"~/.local/bin/auto-hook"}]}]'
