# Audio Toggle - Cross-Platform Audio Device Switcher

A lightweight application that adds a **system tray/menu bar icon** to quickly toggle between audio devices. Switch between headphones and speakers with a single click. Available for **Windows**, **macOS**, and **Linux**.

## Quick Install

### Windows 10/11
Run this in PowerShell:
```powershell
irm https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/install.ps1 | iex
```

### macOS
Run this in Terminal:
```bash
curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/install_mac.sh | bash
```

### Linux (Ubuntu, Fedora, Arch, openSUSE)
Run this in your terminal:
```bash
curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/install_linux.sh | bash
```

## Features

- **One-Click Audio Switching** - Toggle between audio configurations instantly
- **System Tray/Menu Bar Integration** - Native integration for each platform
- **Auto-Start Support** - Automatically starts when you log in
- **Two Audio Profiles** - Configure headset and speakers/desktop setups
- **Visual Notifications** - Feedback when audio devices switch
- **Lightweight** - Minimal resource usage
- **Easy Configuration** - Interactive device selection on first run

## Platform-Specific Details

### Windows
- **Technology**: PowerShell with Windows Forms
- **Audio API**: Core Audio API
- **System Tray**: Native Windows tray icon
- **Requirements**: Windows 10/11, PowerShell 5.1+
- **Auto-Start**: Startup folder integration

### macOS
- **Technology**: Python 3 with rumps (menu bar library)
- **Audio API**: SwitchAudioSource CLI (CoreAudio wrapper)
- **Menu Bar**: Native macOS menu bar icon (🔊)
- **Requirements**: macOS 10.14+, Python 3.7+, Homebrew
- **Auto-Start**: LaunchAgents
- **Dependencies**: Automatically installed (SwitchAudioSource, rumps)
- **[Full macOS Documentation →](README_MAC.md)**

### Linux
- **Technology**: Python 3 with GTK3 and AppIndicator3
- **Audio API**: pactl (PulseAudio/PipeWire compatible)
- **System Tray**: AppIndicator3 (works on most desktop environments)
- **Requirements**: Python 3.6+, PulseAudio or PipeWire
- **Auto-Start**: XDG autostart
- **Supported Distros**: Ubuntu, Debian, Fedora, RHEL, Arch, Manjaro, openSUSE
- **Desktop Environments**: KDE, XFCE, Cinnamon, MATE, Budgie (GNOME requires extension)
- **[Full Linux Documentation →](README_LINUX.md)**

## How It Works

The application allows you to configure two audio profiles:

1. **Profile 1 (Headset/Headphones)**
   - Output: Your headset or headphones
   - Input: Your headset microphone

2. **Profile 2 (Speakers/Desktop)**
   - Output: Your desktop speakers or monitor audio
   - Input: Your webcam or secondary microphone

With a single click, toggle between these two configurations - both output and input devices switch automatically.

## Configuration

All platforms use an interactive configuration wizard that:
1. Lists all available audio devices
2. Uses **NUMBERS** for output devices (speakers/headphones)
3. Uses **LETTERS** for input devices (microphones)
4. Saves your preferences to a configuration file

### Example Configuration
```
=== OUTPUT DEVICES - Use NUMBERS ===
  [0] Built-in Speakers
  [1] USB Headset
  [2] Bluetooth Headphones

=== INPUT DEVICES - Use LETTERS ===
  [A] Built-in Microphone
  [B] USB Headset Mic
  [C] Webcam Microphone

1. Speaker/Monitor (OUTPUT - enter number): 0
2. Secondary Microphone (INPUT - enter letter): A
3. Headset Output (OUTPUT - enter number): 1
4. Headset Microphone (INPUT - enter letter): B
```

## Use Cases

- **Gaming**: Quick switch between gaming headset and desktop speakers
- **Work**: Toggle between work headphones and meeting speakerphone
- **Streaming**: Easy audio output switching for broadcasting
- **Accessibility**: Avoid digging through system sound settings repeatedly

## Uninstall

### Windows
```powershell
# From the install directory
.\uninstall.ps1
```

### macOS
```bash
bash uninstall_mac.sh
# Or via curl:
curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/uninstall_mac.sh | bash
```

### Linux
```bash
bash uninstall_linux.sh
# Or via curl:
curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/uninstall_linux.sh | bash
```

## Platform Comparison

| Feature | Windows | macOS | Linux |
|---------|---------|-------|-------|
| **Language** | PowerShell | Python 3 | Python 3 |
| **System Tray** | ✅ Native | ✅ Menu Bar | ✅ AppIndicator |
| **Auto-Start** | ✅ Startup Folder | ✅ LaunchAgents | ✅ XDG Autostart |
| **Dependencies** | None | Homebrew, rumps | GTK3, AppIndicator3 |
| **Audio System** | Core Audio API | CoreAudio | PulseAudio/PipeWire |
| **Install Time** | < 1 min | 2-3 min | 2-3 min |
| **Configuration** | Numbers/Letters | Numbers/Letters | Numbers/Letters |

## Troubleshooting

### Windows
- Check PowerShell version: `$PSVersionTable.PSVersion`
- Verify script execution: `Get-ExecutionPolicy`
- Check system tray for icon

### macOS
- Check logs: `tail -f ~/Library/Logs/audio_toggle.log`
- Verify SwitchAudioSource: `which SwitchAudioSource`
- Check LaunchAgent: `launchctl list | grep audiotoggle`

### Linux
- Check PulseAudio/PipeWire: `pactl info`
- Verify system tray support: Install gnome-shell-extension-appindicator for GNOME
- Check autostart: `ls ~/.config/autostart/`

## Contributing

Contributions welcome! Feel free to:
- Report bugs or request features
- Submit pull requests for improvements
- Add support for additional platforms or features
- Improve documentation

## License

MIT License - Free to use, modify, and distribute.

Copyright (c) Pablo Echavarria

See [LICENSE](LICENSE) file for details.

## Support

If you find this project helpful, consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs or suggesting features
- 💝 [Supporting the developer](DONATE.md)

---

**Platform-Specific Documentation:**
- [Windows Documentation](https://github.com/pechavarriaa/WindowsAudioProfiles/blob/main/README.md) (on main branch)
- [macOS Documentation](README_MAC.md)
- [Linux Documentation](README_LINUX.md)
