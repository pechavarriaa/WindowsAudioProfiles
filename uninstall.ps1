#Requires -Version 5.1
<#
.SYNOPSIS
    Uninstalls Audio Toggle from your system.
.DESCRIPTION
    Removes the Audio Toggle utility and all shortcuts.
.LINK
    https://github.com/pechavarriaa/CrossPlatformAudioToggle
#>

$ErrorActionPreference = "SilentlyContinue"

$installDir = Join-Path $env:LOCALAPPDATA "AudioToggle"
$startMenuShortcut = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Audio Toggle.lnk"
$startupShortcut = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\Audio Toggle.lnk"
$desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "Audio Toggle.lnk"

Write-Host "Uninstalling Audio Toggle..." -ForegroundColor Cyan

# Stop running instances
Get-Process powershell | Where-Object {
    $_.MainWindowTitle -eq "" -and $_.CommandLine -like "*toggleAudio*"
} | Stop-Process -Force 2>$null

# Remove shortcuts
if (Test-Path $startMenuShortcut) {
    Remove-Item $startMenuShortcut -Force
    Write-Host "  Removed Start Menu shortcut" -ForegroundColor Gray
}

if (Test-Path $startupShortcut) {
    Remove-Item $startupShortcut -Force
    Write-Host "  Removed Startup shortcut" -ForegroundColor Gray
}

if (Test-Path $desktopShortcut) {
    Remove-Item $desktopShortcut -Force
    Write-Host "  Removed Desktop shortcut" -ForegroundColor Gray
}

# Remove install directory
if (Test-Path $installDir) {
    Remove-Item $installDir -Recurse -Force
    Write-Host "  Removed install directory" -ForegroundColor Gray
}

Write-Host "`nAudio Toggle has been uninstalled." -ForegroundColor Green
