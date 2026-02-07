# PowerShell Audio Device Switcher - Windows System Tray Tool

A lightweight PowerShell script that adds a **system tray icon** to quickly toggle between audio devices on Windows 10/11. Switch between headphones and speakers with a single click—no third-party software required.

## Quick Install

Run this in PowerShell:
```powershell
irm https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/install.ps1 | iex
```

The installer will:
1. Download the script
2. Show your available audio devices
3. Let you pick your devices by number
4. Save your configuration automatically

**With options:**
```powershell
# Add to startup + desktop shortcut
irm https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/install.ps1 -OutFile install.ps1; .\install.ps1 -AddToStartup -DesktopShortcut
```

## Features

- **One-Click Audio Switching** - Left-click the tray icon to instantly switch between audio configurations
- **System Tray Integration** - Runs silently in the background with no console window
- **Balloon Notifications** - Visual feedback showing which audio device is now active
- **No Dependencies** - Pure PowerShell using native Windows Core Audio API
- **Lightweight** - Minimal resource usage, starts instantly
- **Customizable** - Easily configure your own audio device names

## Use Cases

- Switch between gaming headset and desktop speakers
- Toggle between work headphones and meeting speakerphone
- Quick audio output switching for streaming/recording
- Accessibility: avoid digging through Windows Sound settings

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 (pre-installed on Windows)
- No admin rights required

## Manual Installation

1. **Download** `toggleAudio.ps1` to a folder of your choice

2. **Unblock the file** (if downloaded from the internet):
   ```powershell
   Unblock-File -Path "C:\path\to\toggleAudio.ps1"
   ```

3. **Edit device names** in the script to match your audio devices:
   ```powershell
   $speakerDevice = "Speakers (Your Speaker Name)"
   $headsetOutput = "Headphones (Your Headphone Name)"
   $headsetInput = "Microphone (Your Headset Mic Name)"
   $secondMicDevice = "Microphone (Your Webcam/Alt Mic Name)"
   ```

   To find your exact device names, run this in PowerShell after loading the script:
   ```powershell
   . .\toggleAudio.ps1
   Get-AudioDevices
   ```

4. **Create a shortcut** for the taskbar:
   - Right-click on Desktop → New → Shortcut
   - Target: `powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\path\to\toggleAudio.ps1"`
   - Name it "Audio Toggle"
   - Pin to taskbar or add to Startup folder

## Usage

### System Tray Mode (Recommended)
Run via the shortcut created above. The icon appears in the system tray:
- **Left-click**: Toggle between audio configurations
- **Right-click**: Menu with Toggle and Exit options

### Command Line Mode
```powershell
# Load the script
. .\toggleAudio.ps1

# Toggle audio devices
Toggle-AudioSetup

# List all audio devices
Get-AudioDevices
```

### Auto-Start with Windows
1. Press `Win + R`, type `shell:startup`
2. Copy your shortcut to this folder

## Configuration

The script switches between two audio configurations:

**Configuration 1 (Headset mode):**
- Output: Your headset speakers
- Input: Your headset microphone

**Configuration 2 (Desktop mode):**
- Output: Your desktop speakers/monitor
- Input: Your webcam/secondary microphone

The installer will guide you through selecting your devices, or you can edit the variables at the top of the script manually.

## Troubleshooting

### "Script cannot be loaded" error
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "File is blocked" warning
```powershell
Unblock-File -Path "C:\path\to\toggleAudio.ps1"
```

### C# compilation error with `?.` operator
This happens when running via shortcut with older .NET Framework. The script has been updated to avoid this—ensure you have the latest version.

### Device not found
Run `Get-AudioDevices` to see the exact device names Windows uses, then update the script variables to match exactly (including parentheses and spaces).

## How It Works

The script uses the Windows Core Audio API (MMDevice API) via inline C# code compiled at runtime. It:

1. Queries the current default audio endpoint
2. Determines which configuration is active
3. Switches to the alternate configuration
4. Sets both Console and Multimedia roles for seamless switching

No external DLLs or modules required—everything is built into Windows.

## Uninstall

```powershell
irm https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/uninstall.ps1 | iex
```

## Keywords

Windows audio switcher, PowerShell audio toggle, system tray audio switcher, change default audio device script, Windows 10 audio hotkey, Windows 11 sound output switcher, headphone speaker toggle, gaming audio switch, MMDevice API PowerShell, Core Audio API script, no-install audio switcher, portable audio toggle Windows

## License

MIT License - Free to use, modify, and distribute.

## Contributing

Feel free to fork and submit pull requests for:
- Additional audio configurations
- Hotkey support
- Custom tray icons
- Multi-monitor/multi-device scenarios
