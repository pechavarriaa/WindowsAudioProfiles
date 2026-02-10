#!/bin/bash
#
# Audio Toggle Uninstaller for Linux
# Removes the Audio Toggle system tray application
#

INSTALL_DIR="$HOME/.local/share/audio_toggle"
CONFIG_DIR="$HOME/.config/audio_toggle"
DESKTOP_FILE="audio-toggle.desktop"
AUTOSTART_DIR="$HOME/.config/autostart"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Audio Toggle for Linux - Uninstaller ===${NC}\n"

# Stop running instances
echo -e "${CYAN}Stopping Audio Toggle...${NC}"
pkill -f "audio_toggle_linux.py" 2>/dev/null || true
sleep 1

# Remove autostart entry
if [ -f "$AUTOSTART_DIR/$DESKTOP_FILE" ]; then
    rm -f "$AUTOSTART_DIR/$DESKTOP_FILE"
    echo -e "  ${GREEN}✓${NC} Removed autostart entry"
fi

# Remove desktop file
if [ -f "$HOME/.local/share/applications/$DESKTOP_FILE" ]; then
    rm -f "$HOME/.local/share/applications/$DESKTOP_FILE"
    echo -e "  ${GREEN}✓${NC} Removed desktop entry"
fi

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
echo -e "\nTo reinstall: ${CYAN}bash install_linux.sh${NC}\n"
