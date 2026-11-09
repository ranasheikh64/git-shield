# ==============================================================================
# Git Shield - Uninstaller for Windows
# ==============================================================================

git config --global --unset core.hooksPath
$InstallDir = Join-Path $env:USERPROFILE ".git-shield"
if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
}
Write-Host "✓ Git Shield successfully uninstalled." -ForegroundColor Green
