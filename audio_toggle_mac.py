#!/usr/bin/env python3
"""
macOS Audio Device Toggle - Menu Bar Application
Provides a menu bar icon to quickly toggle between audio devices on macOS.
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

try:
    import rumps
except ImportError:
    print("Error: rumps library not found. Install with: pip3 install rumps")
    sys.exit(1)

try:
    from AppKit import NSApplication, NSApplicationActivationPolicyAccessory
    from Foundation import NSUserNotification, NSUserNotificationCenter, NSObject
except ImportError:
    print("Error: AppKit not found. Install with: pip3 install pyobjc-framework-Cocoa")
    sys.exit(1)


class NotificationDelegate(NSObject):
    """Delegate for NSUserNotificationCenter to ensure notifications are displayed"""
    
    def userNotificationCenter_shouldPresentNotification_(self, center, notification):
        """Always show notifications as banners, even for background menu bar apps"""
        return True


class AudioToggle(rumps.App):
    def __init__(self):
        # Use template icon for better visibility in dark themes
        # Template icons adapt to light/dark themes automatically
        icon_path = Path(__file__).parent / "icons" / "speaker_template.png"
        if icon_path.exists():
            super(AudioToggle, self).__init__("AudioToggle", icon=str(icon_path), template=True, quit_button=None)
        else:
            # Fallback to emoji if icon file not found
            super(AudioToggle, self).__init__("AudioToggle", title="🔊", quit_button=None)
        self.config_file = Path.home() / ".config" / "audio_toggle" / "config.json"
        self.lockfile_path = Path.home() / ".config" / "audio_toggle" / ".audio_toggle.lock"
        self.lockfile = None

        # Ensure lock directory exists
        self.lockfile_path.parent.mkdir(parents=True, exist_ok=True)

        # Try to acquire lock
        if not self._acquire_lock():
            print("Audio Toggle is already running.")
            sys.exit(0)

        # Create persistent notification delegate
        self.notification_delegate = NotificationDelegate.alloc().init()

        self.load_config()
        self.menu = [
            rumps.MenuItem("Toggle Audio", callback=self.toggle_audio),
            rumps.separator,
            rumps.MenuItem("Configure Devices...", callback=self.configure_devices),
            rumps.separator,
            rumps.MenuItem("Quit", callback=self.quit_app)
        ]

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
                self.show_notification("Error", f"Failed to load config: {e}")
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
    
    def get_audio_devices(self, device_type='output'):
        """Get list of audio devices using /opt/homebrew/bin/SwitchAudioSource"""
        try:
            cmd = ['/opt/homebrew/bin/SwitchAudioSource', '-a', '-t', device_type]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            devices = [line.strip() for line in result.stdout.split('\n') if line.strip()]
            return devices
        except subprocess.CalledProcessError:
            self.show_notification("Error", "/opt/homebrew/bin/SwitchAudioSource not found. Please install it.")
            return []
        except Exception as e:
            self.show_notification("Error", f"Failed to get devices: {e}")
            return []
    
    def get_current_device(self, device_type='output'):
        """Get current default audio device"""
        try:
            cmd = ['/opt/homebrew/bin/SwitchAudioSource', '-c', '-t', device_type]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except Exception as e:
            print(f"Error getting current device: {e}")
            return None
    
    def set_audio_device(self, device_name, device_type='output'):
        """Set default audio device"""
        try:
            cmd = ['/opt/homebrew/bin/SwitchAudioSource', '-s', device_name, '-t', device_type]
            subprocess.run(cmd, check=True, capture_output=True)
            return True
        except Exception as e:
            self.show_notification("Error", f"Failed to set device: {e}")
            return False
    
    @rumps.clicked("Toggle Audio")
    def toggle_audio(self, _):
        """Toggle between audio configurations"""
        # Reload configuration to get latest settings
        self.load_config()
        
        if not all([self.speaker_device, self.headset_output, self.speaker_input, self.headset_input]):
            self.show_notification("Configuration Required", "Please use 'Configure Devices...' from the menu to set up your audio devices.")
            return
        
        # Get current device
        current_output = self.get_current_device('output')
        
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
            print(f"[Toggle] Defaulting to Speakers profile")
            target_output = self.speaker_device
            target_input = self.speaker_input
            profile_name = "Speakers"
        
        print(f"[Toggle] Switching to {profile_name}: output='{target_output}', input='{target_input}'")
        
        # Attempt to switch output device
        output_success = self.set_audio_device(target_output, 'output')
        if not output_success:
            self.show_notification("Audio Toggle", f"Failed to switch output to {target_output}")
            return
        
        # Set system audio device (for communication apps like MS Teams)
        system_success = self.set_audio_device(target_output, 'system')
        if not system_success:
            print(f"[Toggle] Warning: Failed to set system device, continuing anyway")

        # Attempt to switch input device
        input_success = self.set_audio_device(target_input, 'input')
        if not input_success:
            self.show_notification("Audio Toggle", f"Output switched but input failed")
            return
        
        # Brief delay to allow camera-embedded microphones to initialize
        time.sleep(0.5)

        # Both switches succeeded
        # Shorten device names for display
        out_short = self.get_short_device_name(target_output)
        in_short = self.get_short_device_name(target_input)

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
        """Show macOS notification using NSUserNotification"""
        try:
            # Configure notification center with persistent delegate
            center = NSUserNotificationCenter.defaultUserNotificationCenter()
            center.setDelegate_(self.notification_delegate)
            
            # Create and deliver notification
            notification = NSUserNotification.alloc().init()
            notification.setTitle_(title)
            notification.setInformativeText_(message)
            center.deliverNotification_(notification)
        except Exception:
            # Fallback: print to console if notification fails
            print(f"{title}: {message}")
    
    @rumps.clicked("Configure Devices...")
    def configure_devices(self, _):
        """Open configuration in terminal"""
        script_path = Path(__file__).resolve()
        applescript = f'''
        tell application "Terminal"
            activate
            set newWindow to do script "cd {script_path.parent} && python3 {script_path} --configure"
            repeat
                delay 0.5
                if not busy of newWindow then exit repeat
            end repeat
            delay 0.5
            close (every window whose id = (id of newWindow))
        end tell
        '''
        subprocess.run(['osascript', '-e', applescript])
    
    @rumps.clicked("Quit")
    def quit_app(self, _):
        """Quit the application"""
        self._release_lock()
        rumps.quit_application()


def read_input_line(tty_file):
    """Read a line from tty_file with proper EOF handling.
    
    Returns the stripped input string, or None if EOF/empty/whitespace-only input.
    """
    try:
        line = tty_file.readline()
        if line == '':
            # EOF reached - no more input available
            return None
        stripped = line.strip()
        if stripped == '':
            # Whitespace-only input treated as empty
            return None
        return stripped
    except (OSError, IOError):
        return None


def configure_interactive():
    """Interactive configuration mode"""
    # Open /dev/tty for reading input, with fallback to stdin
    tty_file = None
    try:
        tty_file = open('/dev/tty', 'r', buffering=1)
    except (OSError, IOError):
        tty_file = sys.stdin
    
    # Check if we have a valid interactive terminal
    if tty_file == sys.stdin and not sys.stdin.isatty():
        print("\nError: No interactive terminal available.")
        print("Please run this command directly in a terminal, not via a pipe.")
        print("\nUsage: python3 audio_toggle_mac.py --configure")
        return
    
    print("\n=== Configure Audio Toggle for macOS ===\n")
    
    # Check if /opt/homebrew/bin/SwitchAudioSource is available
    try:
        subprocess.run(['/opt/homebrew/bin/SwitchAudioSource', '-h'], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Error: /opt/homebrew/bin/SwitchAudioSource not found.")
        print("Install with: brew install switchaudio-osx")
        return
    
    # Get devices
    print("Fetching audio devices...\n")
    output_devices = []
    input_devices = []
    
    try:
        result = subprocess.run(['/opt/homebrew/bin/SwitchAudioSource', '-a', '-t', 'output'], 
                              capture_output=True, text=True, check=True)
        output_devices = [line.strip() for line in result.stdout.split('\n') if line.strip()]
        
        result = subprocess.run(['/opt/homebrew/bin/SwitchAudioSource', '-a', '-t', 'input'], 
                              capture_output=True, text=True, check=True)
        input_devices = [line.strip() for line in result.stdout.split('\n') if line.strip()]
    except Exception as e:
        print(f"Error getting devices: {e}")
        return
    
    # Letters for input devices (matching Windows installer pattern)
    letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P']
    
    # Display output devices
    print("=== OUTPUT DEVICES (Speakers/Headphones) - Use NUMBERS ===")
    for i, device in enumerate(output_devices):
        print(f"  [{i}] {device}")
    
    print("\n=== INPUT DEVICES (Microphones) - Use LETTERS ===")
    for i, device in enumerate(input_devices):
        if i < len(letters):
            print(f"  [{letters[i]}] {device}")
    
    print("\n")
    print("Enter NUMBER for outputs, LETTER for inputs (or 'q' to quit):")
    print()
    
    # Get user selections
    try:
        # Get speaker output
        print("1. Profile 1 Output (OUTPUT - enter number): ", end='', flush=True)
        speaker_input_str = read_input_line(tty_file)
        if speaker_input_str is None:
            print("\nError: No input received. Please run this command in an interactive terminal.")
            return
        if speaker_input_str.lower() == 'q':
            print("Configuration cancelled.")
            return
        if not speaker_input_str.isdigit():
            print(f"\nError: '{speaker_input_str}' is not a valid number.")
            return
        speaker_idx = int(speaker_input_str)
        if speaker_idx < 0 or speaker_idx >= len(output_devices):
            print("Error: Number out of range.")
            return
        speaker_device = output_devices[speaker_idx]
        
        # Get speaker input
        print("2. Profile 1 Input (INPUT - enter letter): ", end='', flush=True)
        speaker_input_letter = read_input_line(tty_file)
        if speaker_input_letter is None:
            print("\nError: No input received. Please run this command in an interactive terminal.")
            return
        speaker_input_letter = speaker_input_letter.upper()
        if speaker_input_letter == 'Q':
            print("Configuration cancelled.")
            return
        if speaker_input_letter not in letters:
            print(f"\nError: '{speaker_input_letter}' is not a valid letter.")
            return
        speaker_input_idx = letters.index(speaker_input_letter)
        if speaker_input_idx >= len(input_devices):
            print("Error: Letter out of range.")
            return
        speaker_input = input_devices[speaker_input_idx]
        
        # Get headset output
        print("3. Profile 2 Output (OUTPUT - enter number): ", end='', flush=True)
        headset_output_str = read_input_line(tty_file)
        if headset_output_str is None:
            print("\nError: No input received. Please run this command in an interactive terminal.")
            return
        if headset_output_str.lower() == 'q':
            print("Configuration cancelled.")
            return
        if not headset_output_str.isdigit():
            print(f"\nError: '{headset_output_str}' is not a valid number.")
            return
        headset_output_idx = int(headset_output_str)
        if headset_output_idx < 0 or headset_output_idx >= len(output_devices):
            print("Error: Number out of range.")
            return
        headset_output = output_devices[headset_output_idx]
        
        # Get headset input
        print("4. Profile 2 Input (INPUT - enter letter): ", end='', flush=True)
        headset_input_letter = read_input_line(tty_file)
        if headset_input_letter is None:
            print("\nError: No input received. Please run this command in an interactive terminal.")
            return
        headset_input_letter = headset_input_letter.upper()
        if headset_input_letter == 'Q':
            print("Configuration cancelled.")
            return
        if headset_input_letter not in letters:
            print(f"\nError: '{headset_input_letter}' is not a valid letter.")
            return
        headset_input_idx = letters.index(headset_input_letter)
        if headset_input_idx >= len(input_devices):
            print("Error: Letter out of range.")
            return
        headset_input = input_devices[headset_input_idx]
        
        # Show configuration
        print("\nYour configuration:")
        print(f"  1. Profile 1 Output: {speaker_device}")
        print(f"  2. Profile 1 Input: {speaker_input}")
        print(f"  3. Profile 2 Output: {headset_output}")
        print(f"  4. Profile 2 Input: {headset_input}")
        
        print("\nSave this configuration? (Y/n): ", end='', flush=True)
        confirm = read_input_line(tty_file)
        if confirm is None:
            print("\nError: No input received. Configuration cancelled.")
            return
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


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--configure':
        configure_interactive()
    else:
        # Set activation policy to prevent Python from showing in Dock
        # This must be done before creating the rumps App instance
        app_instance = NSApplication.sharedApplication()
        app_instance.setActivationPolicy_(NSApplicationActivationPolicyAccessory)
        
        app = AudioToggle()
        app.run()
