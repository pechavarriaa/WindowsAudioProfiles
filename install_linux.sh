#!/bin/bash
#
# Audio Toggle Installer for Linux
# Supports Ubuntu, Debian, Fedora, and Arch-based distributions
#

set -e

INSTALL_DIR="$HOME/.local/share/audio_toggle"
CONFIG_DIR="$HOME/.config/audio_toggle"
SCRIPT_NAME="audio_toggle_linux.py"
DESKTOP_FILE="audio-toggle.desktop"
AUTOSTART_DIR="$HOME/.config/autostart"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Audio Toggle for Linux - Installer ===${NC}\n"

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_LIKE=$ID_LIKE
else
    echo -e "${RED}Error: Cannot detect Linux distribution.${NC}"
    exit 1
fi

echo -e "Detected distribution: ${CYAN}$PRETTY_NAME${NC}\n"

# Function to install dependencies based on distro
install_dependencies() {
    echo -e "${CYAN}Installing dependencies...${NC}"
    
    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop)
            echo -e "Installing packages for Debian/Ubuntu-based system..."
            sudo apt update
            sudo apt install -y python3 python3-pip python3-gi gir1.2-appindicator3-0.1 libnotify-bin pulseaudio-utils
            ;;
        fedora|rhel|centos)
            echo -e "Installing packages for Fedora/RHEL-based system..."
            sudo dnf install -y python3 python3-pip python3-gobject gtk3 libappindicator-gtk3 libnotify pulseaudio-utils
            ;;
        arch|manjaro|endeavouros)
            echo -e "Installing packages for Arch-based system..."
            sudo pacman -S --needed --noconfirm python python-pip python-gobject gtk3 libappindicator-gtk3 libnotify pulseaudio
            ;;
        opensuse*)
            echo -e "Installing packages for openSUSE..."
            sudo zypper install -y python3 python3-pip python3-gobject gtk3 libappindicator3 libnotify-tools pulseaudio-utils
            ;;
        *)
            echo -e "${YELLOW}Warning: Unsupported distribution. Attempting to install with apt...${NC}"
            if command -v apt &> /dev/null; then
                sudo apt update
                sudo apt install -y python3 python3-pip python3-gi gir1.2-appindicator3-0.1 libnotify-bin pulseaudio-utils
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y python3 python3-pip python3-gobject gtk3 libappindicator-gtk3 libnotify pulseaudio-utils
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --needed --noconfirm python python-pip python-gobject gtk3 libappindicator-gtk3 libnotify pulseaudio
            else
                echo -e "${RED}Error: Cannot determine package manager. Please install dependencies manually:${NC}"
                echo "  - Python 3"
                echo "  - python3-gi (PyGObject)"
                echo "  - gir1.2-appindicator3-0.1 (AppIndicator)"
                echo "  - libnotify (notifications)"
                echo "  - pulseaudio-utils (pactl command)"
                exit 1
            fi
            ;;
    esac
    
    echo -e "${GREEN}✓ Dependencies installed${NC}\n"
}

# Install dependencies
install_dependencies

# Create installation directory
echo -e "${CYAN}Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$AUTOSTART_DIR"

# Download or copy the script
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${CYAN}Installing from local file...${NC}"
    cp "$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
else
    echo -e "${CYAN}Downloading Audio Toggle script...${NC}"
    curl -fsSL "https://raw.githubusercontent.com/pechavarriaa/WindowsAudioProfiles/main/$SCRIPT_NAME" -o "$INSTALL_DIR/$SCRIPT_NAME"
fi

# Make script executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Create desktop file
echo -e "${CYAN}Creating desktop entry...${NC}"
cat > "$HOME/.local/share/applications/$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Audio Toggle
Comment=Toggle between audio devices
Exec=python3 $INSTALL_DIR/$SCRIPT_NAME
Icon=audio-volume-high
Terminal=false
Categories=AudioVideo;Audio;
StartupNotify=false
EOF

# Create autostart entry
cat > "$AUTOSTART_DIR/$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Audio Toggle
Comment=Toggle between audio devices
Exec=python3 $INSTALL_DIR/$SCRIPT_NAME
Icon=audio-volume-high
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo -e "\n${GREEN}=== Installation Complete ===${NC}\n"
echo -e "Installation directory: ${CYAN}$INSTALL_DIR${NC}"
echo -e "Configuration directory: ${CYAN}$CONFIG_DIR${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Configure your audio devices:"
echo -e "   ${CYAN}python3 $INSTALL_DIR/$SCRIPT_NAME --configure${NC}"
echo -e "\n2. The app will start automatically on login"
echo -e "   You can also start it manually:"
echo -e "   ${CYAN}python3 $INSTALL_DIR/$SCRIPT_NAME &${NC}"
echo -e "\n3. Look for the audio icon in your system tray"

# Ask if user wants to configure now
echo -e "\n"
read -p "Configure audio devices now? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    python3 "$INSTALL_DIR/$SCRIPT_NAME" --configure
    
    echo -e "\n${YELLOW}Starting Audio Toggle...${NC}"
    python3 "$INSTALL_DIR/$SCRIPT_NAME" &
    echo -e "${GREEN}✓ Audio Toggle is now running in your system tray!${NC}"
else
    echo -e "\nYou can configure later with:"
    echo -e "${CYAN}python3 $INSTALL_DIR/$SCRIPT_NAME --configure${NC}"
fi

echo -e "\nTo uninstall: ${CYAN}bash uninstall_linux.sh${NC}\n"
