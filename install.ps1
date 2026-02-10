#Requires -Version 5.1
<#
.SYNOPSIS
    Installs Audio Toggle to your system.
.DESCRIPTION
    Downloads and installs the Audio Toggle system tray utility.
    Creates shortcuts and optionally adds to Windows startup.
.PARAMETER Reconfigure
    Skip download and just reconfigure device settings.
.LINK
    https://github.com/pechavarriaa/CrossPlatformAudioToggle
#>

param(
    [switch]$AddToStartup,
    [switch]$DesktopShortcut,
    [switch]$Silent,
    [switch]$Reconfigure
)

$ErrorActionPreference = "Stop"

$repoUrl = "https://raw.githubusercontent.com/pechavarriaa/CrossPlatformAudioToggle/main"
$installDir = Join-Path $env:LOCALAPPDATA "AudioToggle"
$scriptPath = Join-Path $installDir "toggleAudio.ps1"

function Write-Status {
    param([string]$Message)
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

function Write-Success {
    param([string]$Message)
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor Green
    }
}

# Create shortcut helper function - defined early so we can use it

function New-Shortcut {
    param(
        [string]$ShortcutPath,
        [string]$TargetPath,
        [string]$Arguments,
        [string]$IconLocation
    )
    
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.Arguments = $Arguments
    $shortcut.WindowStyle = 7  # Minimized
    if ($IconLocation) {
        $shortcut.IconLocation = $IconLocation
    }
    $shortcut.Save()
}

$pwshPath = "powershell.exe"
$arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
$iconPath = "C:\Windows\System32\SndVol.exe,0"

# Skip download if reconfiguring
if (-not $Reconfigure) {
    # Create install directory
    Write-Status "Creating install directory..."
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    # Download the script
    Write-Status "Downloading Audio Toggle..."
    try {
        Invoke-WebRequest -Uri "$repoUrl/toggleAudio.ps1" -OutFile $scriptPath -UseBasicParsing
    } catch {
        Write-Error "Failed to download script: $_"
        exit 1
    }

    # Unblock the file
    Write-Status "Unblocking script..."
    Unblock-File -Path $scriptPath

    # Create Start Menu shortcut
    Write-Status "Creating Start Menu shortcut..."
    $startMenuPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Audio Toggle.lnk"
    New-Shortcut -ShortcutPath $startMenuPath -TargetPath $pwshPath -Arguments $arguments -IconLocation $iconPath

    # Desktop shortcut (optional)
    if ($DesktopShortcut) {
        Write-Status "Creating Desktop shortcut..."
        $desktopPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Audio Toggle.lnk"
        New-Shortcut -ShortcutPath $desktopPath -TargetPath $pwshPath -Arguments $arguments -IconLocation $iconPath
    }

    # Add to Startup (optional)
    if ($AddToStartup) {
        Write-Status "Adding to Windows Startup..."
        $startupPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\Audio Toggle.lnk"
        New-Shortcut -ShortcutPath $startupPath -TargetPath $pwshPath -Arguments $arguments -IconLocation $iconPath
    }

    Write-Success "`n=== Installation Complete ==="
    Write-Host ""
    Write-Host "Installed to: $scriptPath" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "=== Reconfigure Audio Devices ===" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Test-Path $scriptPath)) {
        Write-Error "Audio Toggle not installed. Run without -Reconfigure first."
        exit 1
    }
}

# Device configuration
if (-not $Silent) {
    Write-Host "=== Configure Your Audio Devices ===" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Loading audio devices..." -ForegroundColor Cyan
    
    # Load the script to get device list
    $scriptContent = Get-Content $scriptPath -Raw
    # Execute just the C# part and Add-Type to load the API
    $csharpMatch = [regex]::Match($scriptContent, '\$csharpCode = @"(.+?)"@', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($csharpMatch.Success) {
        $csharpCode = $csharpMatch.Groups[1].Value
        Add-Type -TypeDefinition $csharpCode -ErrorAction SilentlyContinue
    }
    
    Add-Type -AssemblyName System.Windows.Forms
    
    # Letters for input devices
    $letters = @('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P')
    
    Write-Host ""
    Write-Host "=== OUTPUT DEVICES (Speakers/Headphones) - Use NUMBERS ===" -ForegroundColor Cyan
    $outputDevices = [CoreAudioApi.CoreAudioController]::GetAudioDevices([CoreAudioApi.EDataFlow]::eRender)
    for ($i = 0; $i -lt $outputDevices.Count; $i++) {
        Write-Host "  [$i] $($outputDevices[$i])"
    }
    
    Write-Host ""
    Write-Host "=== INPUT DEVICES (Microphones) - Use LETTERS ===" -ForegroundColor Cyan
    $inputDevices = [CoreAudioApi.CoreAudioController]::GetAudioDevices([CoreAudioApi.EDataFlow]::eCapture)
    for ($i = 0; $i -lt $inputDevices.Count; $i++) {
        Write-Host "  [$($letters[$i])] $($inputDevices[$i])"
    }
    
    Write-Host ""
    Write-Host "Enter NUMBER for outputs, LETTER for inputs (or 'q' to quit):" -ForegroundColor Yellow
    
    # Configuration loop with validation
    $configured = $false
    while (-not $configured) {
        Write-Host ""
        
        # Get speaker (with validation loop)
        $validSpeaker = $false
        while (-not $validSpeaker) {
            Write-Host "1. Profile 1 Output (OUTPUT - enter number):" -ForegroundColor Cyan
            $speakerInput = Read-Host "   "
            if ($speakerInput -eq 'q') { Write-Host "Cancelled." -ForegroundColor Yellow; return }
            try {
                $speakerIdx = [int]$speakerInput
                if ($speakerIdx -ge 0 -and $speakerIdx -lt $outputDevices.Count) {
                    $validSpeaker = $true
                } else { Write-Warning "Number out of range. Try again." }
            } catch { Write-Warning "Please enter a valid number." }
        }
        
        # Get secondary mic (with validation loop)
        $validSecondMic = $false
        while (-not $validSecondMic) {
            Write-Host "2. Profile 1 Input (INPUT - enter letter):" -ForegroundColor Cyan
            $secondMicLetter = (Read-Host "   ").ToUpper()
            if ($secondMicLetter -eq 'Q') { Write-Host "Cancelled." -ForegroundColor Yellow; return }
            $secondMicIdx = [array]::IndexOf($letters, $secondMicLetter)
            if ($secondMicIdx -ge 0 -and $secondMicIdx -lt $inputDevices.Count) {
                $validSecondMic = $true
            } else { Write-Warning "Invalid letter. Try again." }
        }
        
        # Get headset output (with validation loop)
        $validHeadsetOut = $false
        while (-not $validHeadsetOut) {
            Write-Host "3. Profile 2 Output (OUTPUT - enter number):" -ForegroundColor Cyan
            $headsetOutInput = Read-Host "   "
            if ($headsetOutInput -eq 'q') { Write-Host "Cancelled." -ForegroundColor Yellow; return }
            try {
                $headsetOutIdx = [int]$headsetOutInput
                if ($headsetOutIdx -ge 0 -and $headsetOutIdx -lt $outputDevices.Count) {
                    $validHeadsetOut = $true
                } else { Write-Warning "Number out of range. Try again." }
            } catch { Write-Warning "Please enter a valid number." }
        }
        
        # Get headset mic (with validation loop)
        $validHeadsetIn = $false
        while (-not $validHeadsetIn) {
            Write-Host "4. Profile 2 Input (INPUT - enter letter):" -ForegroundColor Cyan
            $headsetInLetter = (Read-Host "   ").ToUpper()
            if ($headsetInLetter -eq 'Q') { Write-Host "Cancelled." -ForegroundColor Yellow; return }
            $headsetInIdx = [array]::IndexOf($letters, $headsetInLetter)
            if ($headsetInIdx -ge 0 -and $headsetInIdx -lt $inputDevices.Count) {
                $validHeadsetIn = $true
            } else { Write-Warning "Invalid letter. Try again." }
        }
        
        # Get device names
        $speakerDevice = $outputDevices[$speakerIdx]
        $secondMicDevice = $inputDevices[$secondMicIdx]
        $headsetOutput = $outputDevices[$headsetOutIdx]
        $headsetInput = $inputDevices[$headsetInIdx]
        
        Write-Host ""
        Write-Host "Your configuration:" -ForegroundColor Green
        Write-Host "  1. Profile 1 Output: $speakerDevice"
        Write-Host "  2. Profile 1 Input: $secondMicDevice"
        Write-Host "  3. Profile 2 Output: $headsetOutput"
        Write-Host "  4. Profile 2 Input: $headsetInput"
        Write-Host ""
        
        $confirm = Read-Host "Save this configuration? (Y/n/r to redo)"
        if ($confirm -eq 'n' -or $confirm -eq 'N') {
            Write-Host "Cancelled. Run 'install.ps1 -Reconfigure' to try again." -ForegroundColor Yellow
            return
        } elseif ($confirm -eq 'r' -or $confirm -eq 'R') {
            Write-Host "`nLet's try again...`n" -ForegroundColor Cyan
            continue
        }
        
        $configured = $true
    }
    
    # Update the script with user's devices
    $scriptContent = $scriptContent -replace '\$speakerDevice = ".*?"', "`$speakerDevice = `"$speakerDevice`""
    $scriptContent = $scriptContent -replace '\$headsetOutput = ".*?"', "`$headsetOutput = `"$headsetOutput`""
    $scriptContent = $scriptContent -replace '\$headsetInput = ".*?"', "`$headsetInput = `"$headsetInput`""
    $scriptContent = $scriptContent -replace '\$secondMicDevice = ".*?"', "`$secondMicDevice = `"$secondMicDevice`""
    
    Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
    Write-Success "Configuration saved!"
    Write-Host ""
    
    Write-Host "Launch from Start Menu: 'Audio Toggle'" -ForegroundColor White
    Write-Host "To reconfigure: install.ps1 -Reconfigure" -ForegroundColor Gray
    Write-Host ""
    
    $launch = Read-Host "Launch Audio Toggle now? (Y/n)"
    if ($launch -ne 'n' -and $launch -ne 'N') {
        Start-Process $pwshPath -ArgumentList $arguments
    }
}
