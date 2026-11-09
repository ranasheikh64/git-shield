#!/usr/bin/env bash
# ==============================================================================
# Git Shield - 1-Line Installer for macOS & Linux
# ==============================================================================

set -e

BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}🛡️  Installing Git Shield (Repository Auto-Malware Protection)...${RESET}"

INSTALL_DIR="$HOME/.git-shield"
HOOKS_DIR="$INSTALL_DIR/hooks"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$HOOKS_DIR"
mkdir -p "$BIN_DIR"

# 1. Install guard-repo engine
SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/guard-repo.sh"
if [ -f "$SCRIPT_SRC" ]; then
    cp "$SCRIPT_SRC" "$INSTALL_DIR/guard-repo.sh"
else
    # Remote install via curl
    curl -fsSL https://raw.githubusercontent.com/ranasheikh64/git-shield/main/guard-repo.sh -o "$INSTALL_DIR/guard-repo.sh"
fi

chmod +x "$INSTALL_DIR/guard-repo.sh"

# Create symlink or wrapper in bin
cat << 'EOF' > "$BIN_DIR/guard-repo"
#!/usr/bin/env bash
exec "$HOME/.git-shield/guard-repo.sh" "$@"
EOF
chmod +x "$BIN_DIR/guard-repo"

# Ensure ~/.local/bin is in PATH if not already
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    PROFILE_FILE=""
    if [ -f "$HOME/.zshrc" ]; then
        PROFILE_FILE="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        PROFILE_FILE="$HOME/.bashrc"
    fi
    if [ -n "$PROFILE_FILE" ]; then
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$PROFILE_FILE"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE_FILE"
        fi
    fi
fi

# 2. Setup Global Git Hooks
cat << 'EOF' > "$HOOKS_DIR/post-merge"
#!/usr/bin/env bash
if [ -x "$HOME/.git-shield/guard-repo.sh" ]; then
    "$HOME/.git-shield/guard-repo.sh"
elif command -v guard-repo >/dev/null 2>&1; then
    guard-repo
fi
EOF
chmod +x "$HOOKS_DIR/post-merge"
cp "$HOOKS_DIR/post-merge" "$HOOKS_DIR/post-checkout"

git config --global core.hooksPath "$HOOKS_DIR"
echo -e "${GREEN}✓ Global git hooks configured at $HOOKS_DIR${RESET}"

# 3. Harden VS Code / Cursor / IDE User Settings (Block automatic tasks)
IDE_SETTINGS_PATHS=(
    "$HOME/Library/Application Support/Code/User/settings.json"
    "$HOME/Library/Application Support/Antigravity IDE/User/settings.json"
    "$HOME/Library/Application Support/Antigravity/User/settings.json"
    "$HOME/Library/Application Support/Cursor/User/settings.json"
    "$HOME/Library/Application Support/VSCodium/User/settings.json"
    "$HOME/.config/Code/User/settings.json"
    "$HOME/.config/VSCodium/User/settings.json"
    "$HOME/.config/Cursor/User/settings.json"
)

harden_settings() {
    local target="$1"
    [ -d "$(dirname "$target")" ] || return 0

    if [ ! -f "$target" ]; then
        echo "{}" > "$target"
    fi

    # Use node or python or sed to cleanly inject settings
    if command -v node >/dev/null 2>&1; then
        node -e '
        const fs = require("fs");
        const file = process.argv[1];
        try {
            let data = {};
            try { data = JSON.parse(fs.readFileSync(file, "utf8")); } catch(e){}
            data["task.allowAutomaticTasks"] = "off";
            data["security.workspace.trust.enabled"] = true;
            fs.writeFileSync(file, JSON.stringify(data, null, 4));
        } catch(err){}
        ' "$target" 2>/dev/null || true
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c '
import json, sys, os
file = sys.argv[1]
try:
    with open(file, "r") as f: data = json.load(f)
except: data = {}
data["task.allowAutomaticTasks"] = "off"
data["security.workspace.trust.enabled"] = True
with open(file, "w") as f: json.dump(data, f, indent=4)
' "$target" 2>/dev/null || true
    fi
}

for cfg in "${IDE_SETTINGS_PATHS[@]}"; do
    if [ -d "$(dirname "$cfg")" ]; then
        harden_settings "$cfg"
        echo -e "${GREEN}✓ Hardened IDE configuration at: $(basename "$(dirname "$(dirname "$cfg")")")${RESET}"
    fi
done

echo ""
echo -e "${BOLD}${GREEN}🎉 Git Shield successfully installed!${RESET}"
echo -e "Whenever you run ${BOLD}git pull${RESET} in any repository, Git Shield will automatically guard your system."
echo -e "You can also run ${BOLD}guard-repo${RESET} manually inside any directory at any time."

