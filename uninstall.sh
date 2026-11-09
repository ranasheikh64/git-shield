#!/usr/bin/env bash
# ==============================================================================
# Git Shield - Uninstaller
# ==============================================================================

set -e

echo "Uninstalling Git Shield..."
git config --global --unset core.hooksPath || true
rm -rf "$HOME/.git-shield"
rm -f "$HOME/.local/bin/guard-repo"
rm -f "$HOME/bin/guard-repo"

echo "✓ Git Shield successfully uninstalled."
