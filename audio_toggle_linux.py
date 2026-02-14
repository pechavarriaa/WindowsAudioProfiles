#!/usr/bin/env python3
"""
Linux Audio Device Toggle - System Tray Application
Provides a system tray icon to quickly toggle between audio devices on Linux.
Supports PulseAudio and PipeWire.
"""

# Unique identifier for this Audio Toggle installation
AUDIO_TOGGLE_ID = "AudioToggle-pechavarriaa-CrossPlatformAudioToggle-v1.0"

import subprocess
import json
import os
import sys
import time
import fcntl
import atexit
from pathlib import Path
import signal

try:
    import gi
    gi.require_version('Gtk', '3.0')
    gi.require_version('AppIndicator3', '0.1')
    from gi.repository import Gtk, AppIndicator3, GLib
except ImportError:
    print("Error: Required libraries not found.")
    print("Install with:")
    print("  Ubuntu/Debian: sudo apt install python3-gi gir1.2-appindicator3-0.1")
    print("  Fedora: sudo dnf install python3-gobject gtk3 libappindicator-gtk3")
    print("  Arch: sudo pacman -S python-gobject gtk3 libappindicator-gtk3")
    sys.exit(1)


class AudioToggle:
    def __init__(self):
        self.config_file = Path.home() / ".config" / "audio_toggle" / "config.json"
        self.lockfile_path = Path.home() / ".config" / "audio_toggle" / ".audio_toggle.lock"
        self.lockfile = None

        # Ensure lock directory exists
        self.lockfile_path.parent.mkdir(parents=True, exist_ok=True)

        # Try to acquire lock
        if not self._acquire_lock():
            print("Audio Toggle is already running.")
            sys.exit(0)

        self.load_config()
        
        # Detect audio system (PulseAudio or PipeWire)
        self.audio_system = self.detect_audio_system()
        
        # Create indicator
        self.indicator = AppIndicator3.Indicator.new(
            "audio-toggle",
            "audio-volume-high",
            AppIndicator3.IndicatorCategory.APPLICATION_STATUS
        )
        self.indicator.set_status(AppIndicator3.IndicatorStatus.ACTIVE)
        
        # Create menu
        self.menu = Gtk.Menu()
        
        # Toggle item
        item_toggle = Gtk.MenuItem(label="Toggle Audio")
        item_toggle.connect("activate", self.toggle_audio)
        self.menu.append(item_toggle)
        
        # Separator
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Configure item
        item_configure = Gtk.MenuItem(label="Configure Devices...")
        item_configure.connect("activate", self.configure_devices)
        self.menu.append(item_configure)
        
        # Separator
        self.menu.append(Gtk.SeparatorMenuItem())
        
        # Quit item
        item_quit = Gtk.MenuItem(label="Quit")
        item_quit.connect("activate", self.quit)
        self.menu.append(item_quit)
        
        self.menu.show_all()
        self.indicator.set_menu(self.menu)
        
        # Check configuration
        if not all([self.speaker_device, self.headset_output, self.speaker_input, self.headset_input]):
            self.show_notification("Configuration Required", "Please configure your audio devices first.")

    def _acquire_lock(self):
        """Acquire exclusive lock to prevent multiple instances"""
        try:
            self.lockfile = open(self.lockfile_path, 'w')
            fcntl.flock(self.lockfile.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            # Write PID to lockfile
            self.lockfile.write(str(os.getpid()))
            self.lockfile.flush()
            # Register cleanup
            atexit.register(self._release_lock)
            return True
        except IOError:
            # Lock already held by another process
            return False
        except Exception as e:
            print(f"Warning: Could not acquire lock: {e}")
            return True  # Continue anyway if lock fails

    def _release_lock(self):
        """Release the lock file"""
        try:
            if self.lockfile:
                fcntl.flock(self.lockfile.fileno(), fcntl.LOCK_UN)
                self.lockfile.close()
            if self.lockfile_path.exists():
                self.lockfile_path.unlink()
        except Exception:
            pass  # Ignore errors during cleanup

    def detect_audio_system(self):
        """Detect if using PulseAudio or PipeWire"""
        try:
            # Check for PipeWire
            result = subprocess.run(['/usr/bin/pactl', 'info'], capture_output=True, text=True)
            if 'PipeWire' in result.stdout:
                return 'pipewire'
            return 'pulseaudio'
        except FileNotFoundError:
            print("Error: pactl not found. Please install PulseAudio or PipeWire.")
            sys.exit(1)
    
    def load_config(self):
        """Load device configuration from file"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                    self.speaker_device = config.get('speaker_device', '')
                    self.headset_output = config.get('headset_output', '')
                    self.speaker_input = config.get('speaker_input', '')
                    self.headset_input = config.get('headset_input', '')
            except Exception as e:
                print(f"Failed to load config: {e}")
                self.speaker_device = ''
                self.headset_output = ''
                self.speaker_input = ''
                self.headset_input = ''
        else:
            self.speaker_device = ''
            self.headset_output = ''
            self.speaker_input = ''
            self.headset_input = ''

    def get_short_device_name(self, device_name):
        """
        Simplify device names for display - matches Windows implementation
        Extracts brand/model from parentheses and cleans up special characters
        """
        import re

        # Extract content from parentheses if present
        match = re.search(r'\(([^)]+)\)', device_name)
        if match:
            name = match.group(1)
        else:
            name = device_name

        # Remove any remaining parentheses and their content (including partial ones)
        name = re.sub(r'\([^)]*\)', '', name)   # Complete pairs like (R)
        name = re.sub(r'\([^)]*$', '', name)    # Partial opening like (R
        name = re.sub(r'\(', '', name)          # Any remaining (
        name = re.sub(r'\)', '', name)          # Any remaining )
        name = re.sub(r'\s+', ' ', name)        # Collapse multiple spaces
        name = name.strip()

        # Truncate if too long
        if len(name) > 30:
            name = name[:27] + "..."

        return name

    def get_device_display_name(self, device_id, device_type):
        """
        Convert device ID to friendly display name
        device_type: 'sinks' or 'sources'
        """
        try:
            devices = self.get_audio_devices(device_type)
            for device in devices:
                if device.get('id') == device_id:
                    return device.get('name', device_id)
            # Fallback to device ID if not found
            return device_id
        except Exception:
            return device_id

    def save_config(self):
        """Save device configuration to file"""
        self.config_file.parent.mkdir(parents=True, exist_ok=True)
        config = {
            'speaker_device': self.speaker_device,
            'headset_output': self.headset_output,
            'speaker_input': self.speaker_input,
            'headset_input': self.headset_input
        }
        with open(self.config_file, 'w') as f:
            json.dump(config, f, indent=2)
    
    def get_audio_devices(self, device_type='sinks'):
        """Get list of audio devices using pactl - optimized to run pactl only once"""
        try:
            # Get full device list with descriptions in one call
            cmd = ['/usr/bin/pactl', 'list', device_type]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)

            devices = []
            current_device = {}

            for line in result.stdout.split('\n'):
                line = line.strip()

                # New device entry
                if line.startswith('Name:'):
                    if current_device and 'id' in current_device:
                        # Skip monitor sources for inputs
                        if device_type != 'sources' or not current_device['id'].endswith('.monitor'):
                            devices.append(current_device)
                    current_device = {'id': line.split('Name:')[1].strip()}

                # Get description
                elif line.startswith('Description:') and 'id' in current_device:
                    current_device['name'] = line.split('Description:')[1].strip()

            # Add last device
            if current_device and 'id' in current_device:
                if device_type != 'sources' or not current_device['id'].endswith('.monitor'):
                    devices.append(current_device)

            # Ensure all devices have a name
            for device in devices:
                if 'name' not in device:
                    device['name'] = device['id']

            return devices
        except Exception as e:
            print(f"Error getting devices: {e}")
            return []
    
    def get_current_device(self, device_type='sink'):
        """Get current default audio device"""
        try:
            cmd = ['/usr/bin/pactl', f'get-default-{device_type}']
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except Exception as e:
            print(f"Error getting current device: {e}")
            return None
    
    def set_audio_device(self, device_id, device_type='sink'):
        """Set default audio device"""
        try:
            cmd = ['/usr/bin/pactl', f'set-default-{device_type}', device_id]
            subprocess.run(cmd, check=True, capture_output=True)
            return True
        except Exception as e:
            print(f"Error setting device: {e}")
            return False
    
    def toggle_audio(self, _):
        """Toggle between audio configurations"""
        # Reload configuration to get latest settings
        self.load_config()
        
        if not all([self.speaker_device, self.headset_output, self.speaker_input, self.headset_input]):
            self.show_notification("Configuration Required", "Please use 'Configure Devices...' from the menu to set up your audio devices.")
            return
        
        # Get current device
        current_output = self.get_current_device('sink')
        
        # Debug logging
        print(f"[Toggle] Current output: '{current_output}'")
        print(f"[Toggle] Profile 1 Output: '{self.speaker_device}'")
        print(f"[Toggle] Profile 2 Output: '{self.headset_output}'")
        
        # Determine target devices based on current state
        if current_output == self.headset_output:
            # Currently on headset (Profile 2), switch to speakers (Profile 1)
            target_output = self.speaker_device
            target_input = self.speaker_input
            profile_name = "Profile 1"
        elif current_output == self.speaker_device:
            # Currently on speakers (Profile 1), switch to headset (Profile 2)
            target_output = self.headset_output
            target_input = self.headset_input
            profile_name = "Profile 2"
        else:
            # Current device doesn't match either configured device
            # Default to switching to speakers
            print(f"[Toggle] Warning: Current device doesn't match configured devices")
            print(f"[Toggle] Defaulting to Profile 1")
            target_output = self.speaker_device
            target_input = self.speaker_input
            profile_name = "Profile 1"
        
        print(f"[Toggle] Switching to {profile_name}: output='{target_output}', input='{target_input}'")
        
        # Attempt to switch output device
        output_success = self.set_audio_device(target_output, 'sink')
        if not output_success:
            self.show_notification("Audio Toggle", f"Failed to switch output to {target_output}")
            return

        # Attempt to switch input device
        input_success = self.set_audio_device(target_input, 'source')
        if not input_success:
            self.show_notification("Audio Toggle", f"Output switched but input failed")
            return

        # Brief delay to allow camera-embedded microphones to initialize
        time.sleep(0.5)

        # Both switches succeeded
        # Get display names from device IDs
        target_output_display = self.get_device_display_name(target_output, 'sinks')
        target_input_display = self.get_device_display_name(target_input, 'sources')

        # Shorten device names for display
        out_short = self.get_short_device_name(target_output_display)
        in_short = self.get_short_device_name(target_input_display)

        # Determine full profile label
        if profile_name == "Profile 1":
            profile_label = "Profile 1 (Desktop)"
        elif profile_name == "Profile 2":
            profile_label = "Profile 2 (Headset)"
        else:
            profile_label = profile_name  # Fallback for edge cases

        # Format notification to match Windows
        message = f"{profile_label}\n🔊 {out_short}\n🎤 {in_short}"
        self.show_notification("Audio Toggle", message)
    
    def show_notification(self, title, message):
        """Show desktop notification"""
        try:
            subprocess.run(['/usr/bin/notify-send', title, message], check=False)
        except Exception:
            print(f"{title}: {message}")
    
    def configure_devices(self, _):
        """Open configuration in terminal"""
        script_path = Path(__file__).resolve()
        terminals = [
            ['gnome-terminal', '--', 'bash', '-c'],
            ['konsole', '-e', 'bash', '-c'],
            ['xfce4-terminal', '-e', 'bash -c'],
            ['xterm', '-e', 'bash', '-c'],
        ]

        cmd_str = f"python3 {script_path} --configure"

        for terminal in terminals:
            try:
                subprocess.Popen(terminal + [cmd_str])
                return
            except FileNotFoundError:
                continue

        print("No terminal found. Please run manually:")
        print(f"python3 {script_path} --configure")
    
    def quit(self, _):
        """Quit the application"""
        self._release_lock()
        Gtk.main_quit()
    
    def run(self):
        """Run the GTK main loop"""
        signal.signal(signal.SIGINT, signal.SIG_DFL)
        Gtk.main()


def parse_pactl_devices(device_type):
    """Helper function to parse devices from pactl output - runs pactl only once!"""
    try:
        cmd = ['/usr/bin/pactl', 'list', device_type]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        devices = []
        current_device = {}

        for line in result.stdout.split('\n'):
            line = line.strip()

            # New device entry
            if line.startswith('Name:'):
                if current_device and 'id' in current_device:
                    # Skip monitor sources for inputs
                    if device_type != 'sources' or not current_device['id'].endswith('.monitor'):
                        devices.append(current_device)
                current_device = {'id': line.split('Name:')[1].strip()}

            # Get description
            elif line.startswith('Description:') and 'id' in current_device:
                current_device['name'] = line.split('Description:')[1].strip()

        # Add last device
        if current_device and 'id' in current_device:
            if device_type != 'sources' or not current_device['id'].endswith('.monitor'):
                devices.append(current_device)

        # Ensure all devices have a name
        for device in devices:
            if 'name' not in device:
                device['name'] = device['id']

        return devices
    except Exception as e:
        print(f"Error getting devices: {e}")
        return []


def configure_interactive():
    """Interactive configuration mode"""
    # Open /dev/tty for reading input, with fallback to stdin
    try:
        tty = open('/dev/tty', 'r', buffering=1)
    except (OSError, IOError):
        tty = sys.stdin
    
    print("\n=== Configure Audio Toggle for Linux ===\n")

    # Check audio system
    try:
        result = subprocess.run(['/usr/bin/pactl', 'info'], capture_output=True, text=True, check=True)
        if 'PipeWire' in result.stdout:
            print("Detected audio system: PipeWire")
        else:
            print("Detected audio system: PulseAudio")
    except FileNotFoundError:
        print("Error: pactl not found. Please install PulseAudio or PipeWire.")
        return

    print("\nFetching audio devices...\n")

    # Get devices using optimized helper function
    output_devices = parse_pactl_devices('sinks')
    input_devices = parse_pactl_devices('sources')

    if not output_devices or not input_devices:
        print("Error: Could not retrieve audio devices.")
        return
    
    # Letters for input devices (matching Windows installer pattern)
    letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P']
    
    # Display devices
    print("=== OUTPUT DEVICES (Speakers/Headphones) - Use NUMBERS ===")
    for i, device in enumerate(output_devices):
        print(f"  [{i}] {device['name']}")
    
    print("\n=== INPUT DEVICES (Microphones) - Use LETTERS ===")
    for i, device in enumerate(input_devices):
        if i < len(letters):
            print(f"  [{letters[i]}] {device['name']}")
    
    print("\n")
    print("Enter NUMBER for outputs, LETTER for inputs (or 'q' to quit):")
    print()
    
    # Get user selections
    try:
        # Get speaker output
        print("1. Profile 1 Output (OUTPUT - enter number): ", end='', flush=True)
        speaker_input_str = tty.readline().strip()
        if speaker_input_str.lower() == 'q':
            print("Configuration cancelled.")
            return
        speaker_idx = int(speaker_input_str)
        if speaker_idx < 0 or speaker_idx >= len(output_devices):
            print("Error: Number out of range.")
            return
        speaker_device = output_devices[speaker_idx]['id']
        speaker_name = output_devices[speaker_idx]['name']
        
        # Get speaker input
        print("2. Profile 1 Input (INPUT - enter letter): ", end='', flush=True)
        speaker_input_letter = tty.readline().strip().upper()
        if speaker_input_letter == 'Q':
            print("Configuration cancelled.")
            return
        if speaker_input_letter not in letters:
            print("Error: Invalid letter.")
            return
        speaker_input_idx = letters.index(speaker_input_letter)
        if speaker_input_idx >= len(input_devices):
            print("Error: Letter out of range.")
            return
        speaker_input = input_devices[speaker_input_idx]['id']
        speaker_input_name = input_devices[speaker_input_idx]['name']
        
        # Get headset output
        print("3. Profile 2 Output (OUTPUT - enter number): ", end='', flush=True)
        headset_output_str = tty.readline().strip()
        if headset_output_str.lower() == 'q':
            print("Configuration cancelled.")
            return
        headset_output_idx = int(headset_output_str)
        if headset_output_idx < 0 or headset_output_idx >= len(output_devices):
            print("Error: Number out of range.")
            return
        headset_output = output_devices[headset_output_idx]['id']
        headset_output_name = output_devices[headset_output_idx]['name']
        
        # Get headset input
        print("4. Profile 2 Input (INPUT - enter letter): ", end='', flush=True)
        headset_input_letter = tty.readline().strip().upper()
        if headset_input_letter == 'Q':
            print("Configuration cancelled.")
            return
        if headset_input_letter not in letters:
            print("Error: Invalid letter.")
            return
        headset_input_idx = letters.index(headset_input_letter)
        if headset_input_idx >= len(input_devices):
            print("Error: Letter out of range.")
            return
        headset_input = input_devices[headset_input_idx]['id']
        headset_input_name = input_devices[headset_input_idx]['name']
        
        # Show configuration
        print("\nYour configuration:")
        print(f"  1. Profile 1 Output: {speaker_name}")
        print(f"  2. Profile 1 Input: {speaker_input_name}")
        print(f"  3. Profile 2 Output: {headset_output_name}")
        print(f"  4. Profile 2 Input: {headset_input_name}")
        
        print("\nSave this configuration? (Y/n): ", end='', flush=True)
        confirm = tty.readline().strip()
        if confirm.lower() != 'n':
            config_file = Path.home() / ".config" / "audio_toggle" / "config.json"
            config_file.parent.mkdir(parents=True, exist_ok=True)
            
            config = {
                'speaker_device': speaker_device,
                'headset_output': headset_output,
                'speaker_input': speaker_input,
                'headset_input': headset_input
            }
            
            with open(config_file, 'w') as f:
                json.dump(config, f, indent=2)
            
            print("\n✓ Configuration saved!")
            print("\nThe Audio Toggle app will now use these devices.")
        else:
            print("\nConfiguration cancelled.")
    
    except (ValueError, IndexError):
        print("\nError: Invalid selection.")
    except KeyboardInterrupt:
        print("\n\nConfiguration cancelled.")
    finally:
        if tty != sys.stdin:
            tty.close()


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--configure':
        configure_interactive()
    else:
        app = AudioToggle()
        app.run()
