# Audio Toggle for Linux - System Tray Application

A lightweight Python application that adds a **system tray icon** to quickly toggle between audio devices on Linux. Switch between headphones and speakers with a single click. Works with both PulseAudio and PipeWire.

## Quick Install

Run this in your terminal:
```bash
curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/install_linux.sh | bash
```

The installer will:
1. Detect your Linux distribution (Ubuntu, Fedora, Arch, etc.)
2. Install required dependencies automatically
3. Install the Audio Toggle application
4. Show your available audio devices
5. Let you configure your preferred devices
6. Set up auto-start on login

## Supported Distributions

- **Ubuntu** / Debian / Linux Mint / Pop!_OS
- **Fedora** / RHEL / CentOS
- **Arch Linux** / Manjaro / EndeavourOS
- **openSUSE**
- Other distributions (may require manual dependency installation)

## Features

- **One-Click Audio Switching** - Click the tray icon to instantly switch between audio configurations
- **System Tray Integration** - Runs silently in the background with a convenient tray icon
- **Native Notifications** - Visual feedback showing which audio device is now active
- **Auto-Start** - Automatically starts when you log in
- **PulseAudio & PipeWire Support** - Works with both audio systems
- **Lightweight** - Minimal resource usage, written in Python
- **Customizable** - Easily configure your own audio device names

## Use Cases

- Switch between gaming headset and desktop speakers
- Toggle between work headphones and meeting speakerphone
- Quick audio output switching for streaming/recording
- Accessibility: avoid digging through audio settings

## Requirements

- Linux distribution (Ubuntu, Fedora, Arch, etc.)
- Python 3.6 or later
- PulseAudio or PipeWire
- GTK 3
- AppIndicator3 library
- libnotify (for notifications)

All dependencies are automatically installed by the installer script.

## Manual Installation

If you prefer to install manually:

### Ubuntu/Debian
```bash
# Install dependencies
sudo apt update
sudo apt install -y python3 python3-pip python3-gi gir1.2-appindicator3-0.1 libnotify-bin pulseaudio-utils

# Create directories
mkdir -p ~/.local/share/audio_toggle
mkdir -p ~/.config/audio_toggle
mkdir -p ~/.config/autostart

# Download script
curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/audio_toggle_linux.py -o ~/.local/share/audio_toggle/audio_toggle_linux.py
chmod +x ~/.local/share/audio_toggle/audio_toggle_linux.py

# Configure
python3 ~/.local/share/audio_toggle/audio_toggle_linux.py --configure

# Run
python3 ~/.local/share/audio_toggle/audio_toggle_linux.py &
```

### Fedora
```bash
# Install dependencies
sudo dnf install -y python3 python3-pip python3-gobject gtk3 libappindicator-gtk3 libnotify pulseaudio-utils

# Create directories and download (same as above)
mkdir -p ~/.local/share/audio_toggle
mkdir -p ~/.config/audio_toggle
mkdir -p ~/.config/autostart

curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/audio_toggle_linux.py -o ~/.local/share/audio_toggle/audio_toggle_linux.py
chmod +x ~/.local/share/audio_toggle/audio_toggle_linux.py

python3 ~/.local/share/audio_toggle/audio_toggle_linux.py --configure
python3 ~/.local/share/audio_toggle/audio_toggle_linux.py &
```

### Arch Linux
```bash
# Install dependencies
sudo pacman -S --needed python python-pip python-gobject gtk3 libappindicator-gtk3 libnotify pulseaudio

# Create directories and download (same as above)
mkdir -p ~/.local/share/audio_toggle
mkdir -p ~/.config/audio_toggle
mkdir -p ~/.config/autostart

curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/audio_toggle_linux.py -o ~/.local/share/audio_toggle/audio_toggle_linux.py
chmod +x ~/.local/share/audio_toggle/audio_toggle_linux.py

python3 ~/.local/share/audio_toggle/audio_toggle_linux.py --configure
python3 ~/.local/share/audio_toggle/audio_toggle_linux.py &
```

## Usage

### System Tray Mode (Recommended)
After installation, the app appears in the system tray:
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
python3 ~/.local/share/audio_toggle/audio_toggle_linux.py --configure
```

Or use the "Configure Devices..." option from the tray icon menu.

## Auto-Start with Your Desktop

The installer automatically sets up auto-start. If you installed manually and want to enable auto-start, create a desktop file at `~/.config/autostart/audio-toggle.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=Audio Toggle
Comment=Toggle between audio devices
Exec=python3 /home/YOUR_USERNAME/.local/share/audio_toggle/audio_toggle_linux.py
Icon=audio-volume-high
Terminal=false
X-GNOME-Autostart-enabled=true
```

## Troubleshooting

### Tray icon doesn't appear

**GNOME Desktop:**
GNOME removed native tray icon support. Install an extension:
```bash
# Ubuntu/Debian
sudo apt install gnome-shell-extension-appindicator

# Fedora
sudo dnf install gnome-shell-extension-appindicator

# Then enable it
gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
```

**Other desktops:** KDE Plasma, XFCE, Cinnamon, MATE should work out of the box.

### "pactl not found" error
```bash
# Ubuntu/Debian
sudo apt install pulseaudio-utils

# Fedora
sudo dnf install pulseaudio-utils

# Arch
sudo pacman -S pulseaudio
```

### Python dependencies not found
```bash
# Ubuntu/Debian
sudo apt install python3-gi gir1.2-appindicator3-0.1

# Fedora
sudo dnf install python3-gobject libappindicator-gtk3

# Arch
sudo pacman -S python-gobject libappindicator-gtk3
```

### Notifications don't work
```bash
# Ubuntu/Debian
sudo apt install libnotify-bin

# Fedora
sudo dnf install libnotify

# Arch
sudo pacman -S libnotify
```

### Audio doesn't switch
- Check if PulseAudio/PipeWire is running: `pactl info`
- List devices: `pactl list short sinks` and `pactl list short sources`
- Reconfigure: `python3 ~/.local/share/audio_toggle/audio_toggle_linux.py --configure`

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/uninstall_linux.sh | bash
```

Or if you have the uninstall script locally:
```bash
bash uninstall_linux.sh
```

## How It Works

The application uses:
- **PyGObject (python3-gi)** - Python bindings for GTK
- **AppIndicator3** - System tray icon library
- **pactl** - PulseAudio/PipeWire control utility
- **libnotify** - Desktop notifications
- **systemd/XDG autostart** - Auto-start on login

The app queries PulseAudio/PipeWire for the current default audio devices and switches between your configured devices based on the current state.

## Desktop Environment Compatibility

| Desktop Environment | System Tray Support | Status |
|---------------------|---------------------|---------|
| KDE Plasma | Native | ✅ Works |
| XFCE | Native | ✅ Works |
| Cinnamon | Native | ✅ Works |
| MATE | Native | ✅ Works |
| LXDE/LXQt | Native | ✅ Works |
| GNOME | Requires extension | ⚠️ Needs appindicator extension |
| Budgie | Native | ✅ Works |
| Deepin | Native | ✅ Works |

For GNOME users: Install `gnome-shell-extension-appindicator` to enable system tray icons.

## License

MIT License - Free to use, modify, and distribute.

## Contributing

Feel free to fork and submit pull requests for:
- Additional features
- Improved error handling
- Support for more desktop environments
- Custom tray icons
- Support for more than 2 device configurations
