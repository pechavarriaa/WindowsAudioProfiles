#Requires -Version 5.1
<#
.SYNOPSIS
    Stops all running Audio Toggle instances from the standard installation.
.DESCRIPTION
    Finds and terminates PowerShell processes running toggleAudio.ps1 from the
    standard installation directory (%LOCALAPPDATA%\AudioToggle).
    Only stops verified Audio Toggle instances to prevent accidentally stopping
    unrelated PowerShell scripts.
.PARAMETER Force
    Skip confirmation prompt
#>

param(
    [switch]$Force
)

$ErrorActionPreference = "Continue"

# Define expected installation paths
$standardInstallPath = Join-Path $env:LOCALAPPDATA "AudioToggle\toggleAudio.ps1"
$currentDirPath = Join-Path $PSScriptRoot "toggleAudio.ps1"

# Paths to check (both standard installation and current directory)
$validPaths = @(
    $standardInstallPath,
    $currentDirPath
)

Write-Host "Searching for Audio Toggle instances..." -ForegroundColor Cyan
Write-Host "Valid paths:" -ForegroundColor Gray
foreach ($path in $validPaths) {
    if (Test-Path $path) {
        Write-Host "  ✓ $path" -ForegroundColor Green
    } else {
        Write-Host "  - $path (not found)" -ForegroundColor DarkGray
    }
}
Write-Host ""

# Find all PowerShell processes
$allPowerShellProcesses = Get-WmiObject Win32_Process -Filter "name='powershell.exe'" -ErrorAction SilentlyContinue

if (-not $allPowerShellProcesses) {
    Write-Host "No PowerShell processes found." -ForegroundColor Gray
    exit 0
}

$audioToggleProcesses = @()

foreach ($process in $allPowerShellProcesses) {
    $cmdLine = $process.CommandLine
    if (-not $cmdLine) { continue }

    # Check if it's running toggleAudio.ps1
    if ($cmdLine -notlike "*toggleAudio.ps1*") { continue }

    # Extract the script path from command line
    $scriptPath = $null

    # Try to match common patterns: -File "path" or -File path
    if ($cmdLine -match '-File\s+"([^"]+toggleAudio\.ps1)"') {
        $scriptPath = $matches[1]
    } elseif ($cmdLine -match '-File\s+([^\s]+toggleAudio\.ps1)') {
        $scriptPath = $matches[1]
    } elseif ($cmdLine -match '([A-Z]:\\[^"]+toggleAudio\.ps1)') {
        $scriptPath = $matches[1]
    }

    if ($scriptPath) {
        # Normalize path for comparison
        $scriptPath = [System.IO.Path]::GetFullPath($scriptPath)

        # Check if this path matches one of our valid paths
        $isValid = $false
        foreach ($validPath in $validPaths) {
            if (Test-Path $validPath) {
                $normalizedValidPath = [System.IO.Path]::GetFullPath($validPath)
                if ($scriptPath -eq $normalizedValidPath) {
                    $isValid = $true
                    break
                }
            }
        }

        if ($isValid) {
            $audioToggleProcesses += [PSCustomObject]@{
                ProcessId = $process.ProcessId
                CommandLine = $cmdLine
                ScriptPath = $scriptPath
            }
        } else {
            Write-Host "Skipping non-Audio Toggle script at: $scriptPath" -ForegroundColor DarkGray
        }
    }
}

if ($audioToggleProcesses.Count -eq 0) {
    Write-Host "No Audio Toggle instances found running from standard installation." -ForegroundColor Green
    exit 0
}

Write-Host "Found $($audioToggleProcesses.Count) Audio Toggle instance(s):" -ForegroundColor Yellow
foreach ($proc in $audioToggleProcesses) {
    Write-Host "  - PID $($proc.ProcessId): $($proc.ScriptPath)" -ForegroundColor White
}
Write-Host ""

# Confirmation prompt unless -Force is used
if (-not $Force) {
    $confirm = Read-Host "Stop these processes? (Y/n)"
    if ($confirm -eq 'n' -or $confirm -eq 'N') {
        Write-Host "Cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Stop the processes
foreach ($proc in $audioToggleProcesses) {
    try {
        Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop
        Write-Host "  ✓ Stopped PID $($proc.ProcessId)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to stop PID $($proc.ProcessId): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n✓ Done." -ForegroundColor Green
Write-Host "You can now run install.ps1 or toggleAudio.ps1 again." -ForegroundColor White
Write-Host ""
