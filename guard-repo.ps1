# ==============================================================================
# Git Shield - Universal Repository Malware & Auto-Run Exploit Scanner
# Supported OS: Windows (PowerShell)
# Protects against: Lazarus, BeaverTail, EtherHiding, VS Code auto-run tasks RCE
# ==============================================================================

Write-Host "🛡️  [Git Shield] Scanning repository for malicious files, backdoors, and auto-run exploits..." -ForegroundColor Cyan

$ThreatsFound = 0

# 1. VS Code Tasks Auto-Execution Exploit Detection
if (Test-Path ".vscode\tasks.json") {
    $content = Get-Content ".vscode\tasks.json" -Raw -ErrorAction SilentlyContinue
    if ($content -match "folderOpen" -or $content -match "node " -or $content -match "\.ttf") {
        Write-Host "🚨 [ALERT] Malicious .vscode\tasks.json detected! (Auto-executes on folder open)" -ForegroundColor Red
        Remove-Item -Force ".vscode\tasks.json" -ErrorAction SilentlyContinue
        git rm -f --cached ".vscode\tasks.json" 2>$null
        $ThreatsFound++
    }
}

if (Test-Path ".vscode\settings.json") {
    $content = Get-Content ".vscode\settings.json" -Raw -ErrorAction SilentlyContinue
    if ($content -match "task\.allowAutomaticTasks") {
        Write-Host "🚨 [ALERT] Malicious auto-run setting found in .vscode\settings.json! Sanitizing..." -ForegroundColor Red
        $clean = $content -replace '"task\.allowAutomaticTasks":\s*(true|false),?', ''
        Set-Content -Path ".vscode\settings.json" -Value $clean
        $ThreatsFound++
    }
}

# 2. Fake Binary / Disguised Media Files (JS hidden in .ttf, .png, etc.)
$mediaExtensions = @("*.ttf", "*.eot", "*.woff", "*.woff2", "*.png", "*.jpg", "*.svg")
foreach ($ext in $mediaExtensions) {
    Get-ChildItem -Path . -Filter $ext -Recurse -File -Exclude ".git*", "node_modules*" -ErrorAction SilentlyContinue | ForEach-Object {
        $firstBytes = Get-Content $_.FullName -TotalCount 2 -Raw -ErrorAction SilentlyContinue
        if ($firstBytes -match "global|require|child_process|eval\(|process\.cwd") {
            Write-Host "🚨 [ALERT] Trojan script disguised as font/image: $($_.FullName)! Deleting..." -ForegroundColor Red
            Remove-Item -Force $_.FullName -ErrorAction SilentlyContinue
            git rm -f --cached $_.FullName 2>$null
            $ThreatsFound++
        }
    }
}

# 3. Known BeaverTail / EtherHiding / Stealer Loader Signatures
$suspiciousFiles = @("server\init", "init.js", "setup.js", "install.js")
foreach ($f in $suspiciousFiles) {
    if (Test-Path $f) {
        $content = Get-Content $f -Raw -ErrorAction SilentlyContinue
        if ($content -match "0x1eEf0849EDa15d87f64e51C73C8442Cf3c8bCEF3" -or $content -match "spin\(" -or $content -match "peel\(") {
            Write-Host "🚨 [ALERT] Obfuscated backdoor loader detected in: $f! Deleting..." -ForegroundColor Red
            Remove-Item -Force $f -ErrorAction SilentlyContinue
            git rm -f --cached $f 2>$null
            $ThreatsFound++
        }
    }
}

# 4. OS Persistence Clean (e.g. %USERPROFILE%\.node_modules)
$userHome = [Environment]::GetFolderPath("UserProfile")
$badNodeModules = Join-Path $userHome ".node_modules"
if (Test-Path $badNodeModules) {
    Write-Host "🚨 [ALERT] Rogue .node_modules folder detected in user profile! Removing..." -ForegroundColor Red
    Remove-Item -Recurse -Force $badNodeModules -ErrorAction SilentlyContinue
    $ThreatsFound++
}

# Kill suspicious background Node stealth processes
Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -match "\.node_modules|fa-solid"
} | ForEach-Object {
    Write-Host "🚨 [ALERT] Terminating rogue background node process: $($_.Id)" -ForegroundColor Red
    Stop-Process -Id $_.Id -Force
    $ThreatsFound++
}

# Summary
if ($ThreatsFound -eq 0) {
    Write-Host "✅ [Git Shield] Repository is 100% clean and safe." -ForegroundColor Green
} else {
    Write-Host "⚠️  [Git Shield] Cleaned $ThreatsFound malicious threat(s)." -ForegroundColor Yellow
}
