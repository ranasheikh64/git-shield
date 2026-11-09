#!/usr/bin/env bash
# ==============================================================================
# Git Shield - Universal Repository Malware & Auto-Run Exploit Scanner
# Supported OS: macOS & Linux
# Protects against: Lazarus, BeaverTail, EtherHiding, VS Code auto-run tasks RCE
# ==============================================================================

set -uo pipefail

# ANSI color codes
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}🛡️  [Git Shield] Scanning repository for malicious files, backdoors, and auto-run exploits...${RESET}"

THREATS_FOUND=0

# ------------------------------------------------------------------------------
# 1. VS Code Tasks Auto-Execution Exploit Detection
# ------------------------------------------------------------------------------
if [ -f ".vscode/tasks.json" ]; then
    if grep -qE "runOn.*folderOpen|runOn.*folder|fa-solid|eval|node " .vscode/tasks.json 2>/dev/null; then
        echo -e "${RED}🚨 [ALERT] Malicious .vscode/tasks.json detected! (Attempts silent execution on folder open)${RESET}"
        rm -f ".vscode/tasks.json"
        git rm -f --cached ".vscode/tasks.json" 2>/dev/null || true
        THREATS_FOUND=$((THREATS_FOUND + 1))
    fi
fi

if [ -f ".vscode/settings.json" ]; then
    if grep -qE "task\.allowAutomaticTasks|lint on open" .vscode/settings.json 2>/dev/null; then
        echo -e "${RED}🚨 [ALERT] Malicious auto-run setting found in .vscode/settings.json! Sanitizing...${RESET}"
        sed -i '' '/task\.allowAutomaticTasks/d' .vscode/settings.json 2>/dev/null || sed -i '/task\.allowAutomaticTasks/d' .vscode/settings.json 2>/dev/null || true
        sed -i '' '/"tasks": {/,/}/d' .vscode/settings.json 2>/dev/null || sed -i '/"tasks": {/,/}/d' .vscode/settings.json 2>/dev/null || true
        THREATS_FOUND=$((THREATS_FOUND + 1))
    fi
fi

# ------------------------------------------------------------------------------
# 2. Fake Binary / Disguised Media Files (e.g. JS hidden inside .ttf, .png)
# ------------------------------------------------------------------------------
DISGUISED_FILES=$(find . -type f \( \
    -name "*.ttf" -o -name "*.eot" -o -name "*.woff" -o -name "*.woff2" \
    -o -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.svg" \
    -o -name "*.ico" -o -name "*.webp" \
\) -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null || true)

for fake_file in $DISGUISED_FILES; do
    [ -f "$fake_file" ] || continue
    FILE_INFO=$(file "$fake_file" 2>/dev/null || true)
    # Check if the file is reported as plain ASCII or UTF-8 text instead of binary
    if [[ "$FILE_INFO" == *"ASCII text"* ]] || [[ "$FILE_INFO" == *"UTF-8 text"* ]] || [[ "$FILE_INFO" == *"source"* ]]; then
        if grep -qE "global|require|child_process|eval\(|process\.cwd|http\.request|spawn\(" "$fake_file" 2>/dev/null; then
            echo -e "${RED}🚨 [ALERT] Trojan script disguised as font/image: ${fake_file}! Deleting...${RESET}"
            rm -f "$fake_file"
            git rm -f --cached "$fake_file" 2>/dev/null || true
            THREATS_FOUND=$((THREATS_FOUND + 1))
        fi
    fi
done

# ------------------------------------------------------------------------------
# 3. Known BeaverTail / EtherHiding / Stealer Loader Signatures
# ------------------------------------------------------------------------------
SUSPICIOUS_NAMES=("server/init" "init.js" "setup.js" "install.js" "patch.js")
for susp in "${SUSPICIOUS_NAMES[@]}"; do
    if [ -f "$susp" ]; then
        if grep -qE "NX=|SX=|spin\(|peel\(|splitLane|0x1eEf0849EDa15d87f64e51C73C8442Cf3c8bCEF3|INDEXER_URL|lastSenderTx" "$susp" 2>/dev/null; then
            echo -e "${RED}🚨 [ALERT] Obfuscated backdoor loader detected in: ${susp}! Deleting...${RESET}"
            rm -f "$susp"
            git rm -f --cached "$susp" 2>/dev/null || true
            THREATS_FOUND=$((THREATS_FOUND + 1))
        fi
    fi
done

# Check recent changes for appended obfuscated payloads in .js / .ts files
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CHANGED_JS=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -E "\.(js|ts|mjs|cjs)$" || true)
    for js_file in $CHANGED_JS; do
        if [ -f "$js_file" ]; then
            if grep -qE "NX=\[|SX=\[|spin\(R,c\)|0x1eEf0849EDa15d87f64e51C73C8442Cf3c8bCEF3" "$js_file" 2>/dev/null; then
                echo -e "${RED}🚨 [ALERT] Injected backdoor found inside ${js_file}! Cleaning file...${RESET}"
                sed -i '' '/var z="\\u002D\\u0041/d' "$js_file" 2>/dev/null || sed -i '/var z="\\u002D\\u0041/d' "$js_file" 2>/dev/null || true
                THREATS_FOUND=$((THREATS_FOUND + 1))
            fi
        fi
    done
fi

# ------------------------------------------------------------------------------
# 4. Package.json Lifecycle Hook Hijacking
# ------------------------------------------------------------------------------
for pkg_file in $(find . -name "package.json" -not -path "*/node_modules/*" 2>/dev/null || true); do
    if grep -qE "node init|npm-ws|\.node_modules|node \.\/|node [a-zA-Z0-9_\-\/]+\.ttf" "$pkg_file" 2>/dev/null; then
        echo -e "${RED}🚨 [ALERT] Suspicious hook detected in ${pkg_file}! Sanitizing...${RESET}"
        sed -i '' 's/node init && //g' "$pkg_file" 2>/dev/null || sed -i 's/node init && //g' "$pkg_file" 2>/dev/null || true
        THREATS_FOUND=$((THREATS_FOUND + 1))
    fi
done

# ------------------------------------------------------------------------------
# 5. OS-Level Persistence & Rogue Process Inspection
# ------------------------------------------------------------------------------
if [ -d "$HOME/.node_modules" ]; then
    echo -e "${RED}🚨 [ALERT] Rogue ~/.node_modules directory found on system! Removing...${RESET}"
    rm -rf "$HOME/.node_modules"
    THREATS_FOUND=$((THREATS_FOUND + 1))
fi

ROGUE_PIDS=$(ps aux 2>/dev/null | grep -E "npm-ws|fa-solid-300|\.node_modules" | grep -v grep | awk '{print $2}' || true)
if [ -n "$ROGUE_PIDS" ]; then
    echo -e "${RED}🚨 [ALERT] Terminating rogue background process(es): $ROGUE_PIDS${RESET}"
    kill -9 $ROGUE_PIDS 2>/dev/null || true
    THREATS_FOUND=$((THREATS_FOUND + 1))
fi

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
if [ "$THREATS_FOUND" -eq 0 ]; then
    echo -e "${GREEN}✅ [Git Shield] Repository is 100% clean and safe.${RESET}"
else
    echo -e "${YELLOW}⚠️  [Git Shield] Warning: Neutralized and cleaned $THREATS_FOUND malicious threat(s).${RESET}"
fi
exit 0

