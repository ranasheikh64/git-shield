# ==============================================================================
# Git Shield - 1-Line Installer for Windows (PowerShell)
# ==============================================================================

Write-Host "🛡️  Installing Git Shield (Repository Auto-Malware Protection for Windows)..." -ForegroundColor Cyan

$InstallDir = Join-Path $env:USERPROFILE ".git-shield"
$HooksDir = Join-Path $InstallDir "hooks"

New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null

# 1. Download or copy guard-repo.ps1
$ScriptPath = Join-Path $PSScriptRoot "guard-repo.ps1"
$DestPath = Join-Path $InstallDir "guard-repo.ps1"

if (Test-Path $ScriptPath) {
    Copy-Item -Force $ScriptPath $DestPath
} else {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ranasheikh64/git-shield/main/guard-repo.ps1" -OutFile $DestPath
}

# 2. Setup Global Git Hooks
$HookScript = @"
#!/usr/bin/env bash
powershell.exe -ExecutionPolicy Bypass -File "$DestPath"
"@

Set-Content -Path (Join-Path $HooksDir "post-merge") -Value $HookScript -NoNewline
Set-Content -Path (Join-Path $HooksDir "post-checkout") -Value $HookScript -NoNewline

git config --global core.hooksPath "$HooksDir"
Write-Host "✓ Global git hooks configured at $HooksDir" -ForegroundColor Green

# 3. Harden VS Code / Cursor Settings
$CodeSettings = Join-Path $env:APPDATA "Code\User\settings.json"
if (Test-Path (Split-Path $CodeSettings)) {
    try {
        $json = @{}
        if (Test-Path $CodeSettings) {
            $json = Get-Content $CodeSettings -Raw | ConvertFrom-Json -AsHashtable
        }
        $json["task.allowAutomaticTasks"] = "off"
        $json["security.workspace.trust.enabled"] = $true
        $json | ConvertTo-Json -Depth 10 | Set-Content $CodeSettings
        Write-Host "✓ Hardened VS Code User Settings (Disabled automatic tasks)" -ForegroundColor Green
    } catch {}
}

Write-Host "`n🎉 Git Shield successfully installed on Windows!" -ForegroundColor Green
Write-Host "Whenever you run 'git pull', Git Shield will automatically inspect and protect your repo." -ForegroundColor Cyan

