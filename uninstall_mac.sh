#!/bin/bash
#
# Audio Toggle Uninstaller for macOS
# Removes the Audio Toggle menu bar application
#

INSTALL_DIR="$HOME/.local/share/audio_toggle"
CONFIG_DIR="$HOME/.config/audio_toggle"
PLIST_NAME="com.pechavarriaa.audiotoggle.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Audio Toggle for macOS - Uninstaller ===${NC}\n"

# Stop the LaunchAgent
if [ -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME" ]; then
    echo -e "${CYAN}Stopping Audio Toggle...${NC}"
    launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
    rm -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME"
    echo -e "  ${GREEN}✓${NC} Removed LaunchAgent"
fi

# Kill any running instances
pkill -f "audio_toggle_mac.py" 2>/dev/null || true

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "  ${GREEN}✓${NC} Removed installation directory"
fi

# Ask about config
if [ -d "$CONFIG_DIR" ]; then
    echo -e "\n${CYAN}Configuration directory found: $CONFIG_DIR${NC}"
    read -p "Remove configuration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo -e "  ${GREEN}✓${NC} Removed configuration"
    else
        echo -e "  Configuration kept (you can remove it manually later)"
    fi
fi

echo -e "\n${GREEN}=== Uninstallation Complete ===${NC}"
echo -e "\nAudio Toggle has been removed from your system."
echo -e "\nTo reinstall: ${CYAN}bash install_mac.sh${NC}\n"
