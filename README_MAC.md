# Audio Toggle for macOS - Menu Bar Application

A lightweight Python application that adds a **menu bar icon** to quickly toggle between audio devices on macOS. Switch between headphones and speakers with a single click.

## Quick Install

Run this in Terminal:
```bash
curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/copilot/mac-version-installation/install_mac.sh | bash
```

The installer will:
1. Install required dependencies (Homebrew, Python, SwitchAudioSource)
2. Install the Audio Toggle application
3. Show your available audio devices
4. Let you configure your preferred devices
5. Set up auto-start on login

## Features

- **One-Click Audio Switching** - Click the menu bar icon to instantly switch between audio configurations
- **Menu Bar Integration** - Runs silently in the background with a convenient menu bar icon (🔊)
- **Native Notifications** - Visual feedback showing which audio device is now active
- **Auto-Start** - Automatically starts when you log in
- **Lightweight** - Minimal resource usage, written in Python
- **Customizable** - Easily configure your own audio device names

## Use Cases

- Switch between gaming headset and desktop speakers
- Toggle between work headphones and meeting speakerphone
- Quick audio output switching for streaming/recording
- Accessibility: avoid digging through macOS Sound settings

## Requirements

- macOS 10.14 (Mojave) or later
- Python 3.7 or later (pre-installed on modern macOS)
- Homebrew (automatically installed by installer)
- SwitchAudioSource (automatically installed by installer)

## Manual Installation

If you prefer to install manually:

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install SwitchAudioSource**:
   ```bash
   brew install switchaudio-osx
   ```

3. **Install Python dependencies**:
   ```bash
   pip3 install --user rumps pyobjc-framework-Cocoa
   ```

4. **Download the script**:
   ```bash
   mkdir -p ~/.local/share/audio_toggle
   curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/copilot/mac-version-installation/audio_toggle_mac.py -o ~/.local/share/audio_toggle/audio_toggle_mac.py
   chmod +x ~/.local/share/audio_toggle/audio_toggle_mac.py
   ```

5. **Configure your devices**:
   ```bash
   python3 ~/.local/share/audio_toggle/audio_toggle_mac.py --configure
   ```

6. **Run the app**:
   ```bash
   python3 ~/.local/share/audio_toggle/audio_toggle_mac.py &
   ```

## Usage

### Menu Bar Mode (Recommended)
After installation, the app appears in the menu bar (🔊 icon):
- **Click icon**: Opens menu with options
- **Select "Toggle Audio"**: Switch between audio configurations
- **Select "Configure Devices..."**: Reconfigure your audio devices
- **Select "Quit"**: Exit the application

### Configuration

The application switches between two audio configurations:

**Configuration 1 (Headset mode):**
- Output: Your headset speakers
- Input: Your headset microphone

**Configuration 2 (Desktop mode):**
- Output: Your desktop speakers/monitor
- Input: Your webcam/secondary microphone

To reconfigure at any time:
```bash
python3 ~/.local/share/audio_toggle/audio_toggle_mac.py --configure
```

Or use the "Configure Devices..." option from the menu bar menu.

## Auto-Start with macOS

The installer automatically sets up auto-start using LaunchAgents. If you installed manually and want to enable auto-start:

1. Create a plist file at `~/Library/LaunchAgents/com.pechavarriaa.audiotoggle.plist` with the following content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.pechavarriaa.audiotoggle</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/Users/YOUR_USERNAME/.local/share/audio_toggle/audio_toggle_mac.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

2. Load the LaunchAgent:
```bash
launchctl load ~/Library/LaunchAgents/com.pechavarriaa.audiotoggle.plist
```

## Troubleshooting

### "SwitchAudioSource not found" error
```bash
brew install switchaudio-osx
```

### "rumps not found" error
```bash
pip3 install --user rumps pyobjc-framework-Cocoa
```

### App doesn't appear in menu bar
- Check if the app is running: `ps aux | grep audio_toggle`
- Check logs: `cat ~/Library/Logs/audio_toggle_error.log`
- Try running manually: `python3 ~/.local/share/audio_toggle/audio_toggle_mac.py`

### Device not found
Run the configuration again and make sure you select the correct device numbers:
```bash
python3 ~/.local/share/audio_toggle/audio_toggle_mac.py --configure
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/copilot/mac-version-installation/uninstall_mac.sh | bash
```

Or if you have the uninstall script locally:
```bash
bash uninstall_mac.sh
```

## How It Works

The application uses:
- **rumps** - A Python library for creating macOS menu bar applications
- **SwitchAudioSource** - A command-line utility to change audio devices on macOS
- **CoreAudio** - macOS's native audio framework (accessed via SwitchAudioSource)
- **LaunchAgents** - macOS's system for auto-starting applications

The app queries the current default audio device and switches between your configured devices based on the current state.

## License

MIT License - Free to use, modify, and distribute.

## Contributing

Feel free to fork and submit pull requests for:
- Additional features
- Improved error handling
- Custom menu bar icons
- Support for more than 2 device configurations
