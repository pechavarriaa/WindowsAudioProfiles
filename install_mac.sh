#!/bin/bash
#
# Audio Toggle Installer for macOS
# Installs the Audio Toggle menu bar application
#

set -e

INSTALL_DIR="$HOME/.local/share/audio_toggle"
CONFIG_DIR="$HOME/.config/audio_toggle"
SCRIPT_NAME="audio_toggle_mac.py"
PLIST_NAME="com.pechavarriaa.audiotoggle.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Audio Toggle for macOS - Installer ===${NC}\n"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This installer is for macOS only.${NC}"
    exit 1
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Python 3 not found. Installing Python 3...${NC}"
    brew install python3
fi

# Check for pip3
if ! command -v pip3 &> /dev/null; then
    echo -e "${YELLOW}pip3 not found. Installing pip3...${NC}"
    python3 -m ensurepip --upgrade
fi

# Install SwitchAudioSource
if ! command -v SwitchAudioSource &> /dev/null; then
    echo -e "${YELLOW}Installing SwitchAudioSource (required for audio switching)...${NC}"
    brew install switchaudio-osx
fi

# Install Python dependencies
echo -e "${CYAN}Installing Python dependencies...${NC}"
pip3 install --user rumps pyobjc-framework-Cocoa || {
    echo -e "${YELLOW}Note: If installation failed, you may need to use: pip3 install --user --break-system-packages rumps pyobjc-framework-Cocoa${NC}"
    pip3 install --user --break-system-packages rumps pyobjc-framework-Cocoa
}

# Create installation directory
echo -e "${CYAN}Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

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

# Create LaunchAgent plist for auto-start
echo -e "${CYAN}Setting up auto-start...${NC}"
mkdir -p "$LAUNCH_AGENTS_DIR"

cat > "$LAUNCH_AGENTS_DIR/$PLIST_NAME" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.pechavarriaa.audiotoggle</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$INSTALL_DIR/$SCRIPT_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/audio_toggle.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/audio_toggle_error.log</string>
</dict>
</plist>
EOF

# Load the LaunchAgent
launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo -e "\n${GREEN}=== Installation Complete ===${NC}\n"
echo -e "Installation directory: ${CYAN}$INSTALL_DIR${NC}"
echo -e "Configuration directory: ${CYAN}$CONFIG_DIR${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Configure your audio devices:"
echo -e "   ${CYAN}python3 $INSTALL_DIR/$SCRIPT_NAME --configure${NC}"
echo -e "\n2. The app will start automatically and appear in your menu bar (🔊)"
echo -e "\n3. To reconfigure later, click the menu bar icon and select 'Configure Devices...'"

echo -e "\n${GREEN}✓ Audio Toggle has been installed and started via LaunchAgent!${NC}"
echo -e "The app should appear in your menu bar shortly (🔊)"
echo -e "\nTo uninstall: ${CYAN}bash uninstall_mac.sh${NC}"
