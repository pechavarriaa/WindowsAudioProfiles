#!/usr/bin/env python3
"""
Linux Audio Device Toggle - System Tray Application
Provides a system tray icon to quickly toggle between audio devices on Linux.
Supports PulseAudio and PipeWire.
"""

import subprocess
import json
import os
import sys
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
    
    def detect_audio_system(self):
        """Detect if using PulseAudio or PipeWire"""
        try:
            # Check for PipeWire
            result = subprocess.run(['pactl', 'info'], capture_output=True, text=True)
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
        """Get list of audio devices using pactl"""
        try:
            cmd = ['pactl', 'list', 'short', device_type]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            devices = []
            for line in result.stdout.strip().split('\n'):
                if line.strip():
                    parts = line.split('\t')
                    if len(parts) >= 2:
                        device_id = parts[1]
                        # Get friendly name
                        name_cmd = ['pactl', 'list', device_type]
                        name_result = subprocess.run(name_cmd, capture_output=True, text=True, check=True)
                        
                        # Parse friendly name from full output
                        friendly_name = device_id
                        in_device = False
                        for name_line in name_result.stdout.split('\n'):
                            if f'Name: {device_id}' in name_line:
                                in_device = True
                            elif in_device and 'Description:' in name_line:
                                friendly_name = name_line.split('Description:')[1].strip()
                                break
                            elif in_device and ('Sink #' in name_line or 'Source #' in name_line):
                                break
                        
                        devices.append({
                            'id': device_id,
                            'name': friendly_name
                        })
            return devices
        except Exception as e:
            print(f"Error getting devices: {e}")
            return []
    
    def get_current_device(self, device_type='sink'):
        """Get current default audio device"""
        try:
            cmd = ['pactl', f'get-default-{device_type}']
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except Exception as e:
            print(f"Error getting current device: {e}")
            return None
    
    def set_audio_device(self, device_id, device_type='sink'):
        """Set default audio device"""
        try:
            cmd = ['pactl', f'set-default-{device_type}', device_id]
            subprocess.run(cmd, check=True, capture_output=True)
            return True
        except Exception as e:
            print(f"Error setting device: {e}")
            return False
    
    def toggle_audio(self, _):
        """Toggle between audio configurations"""
        if not all([self.speaker_device, self.headset_output, self.speaker_input, self.headset_input]):
            self.show_notification("Configuration Required", "Please use 'Configure Devices...' from the menu to set up your audio devices.")
            return
        
        current_output = self.get_current_device('sink')
        
        if current_output == self.headset_output:
            # Switch to speakers
            if self.set_audio_device(self.speaker_device, 'sink'):
                self.set_audio_device(self.speaker_input, 'source')
                self.show_notification("Audio Switched", f"Speakers + Microphone active")
        else:
            # Switch to headset
            if self.set_audio_device(self.headset_output, 'sink'):
                self.set_audio_device(self.headset_input, 'source')
                self.show_notification("Audio Switched", f"Headset active")
    
    def show_notification(self, title, message):
        """Show desktop notification"""
        try:
            subprocess.run(['notify-send', title, message], check=False)
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
        
        cmd_str = f"python3 {script_path} --configure; read -p 'Press Enter to close...'"
        
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
        Gtk.main_quit()
    
    def run(self):
        """Run the GTK main loop"""
        signal.signal(signal.SIGINT, signal.SIG_DFL)
        Gtk.main()


def configure_interactive():
    """Interactive configuration mode"""
    print("\n=== Configure Audio Toggle for Linux ===\n")
    
    # Check audio system
    try:
        result = subprocess.run(['pactl', 'info'], capture_output=True, text=True, check=True)
        if 'PipeWire' in result.stdout:
            print("Detected audio system: PipeWire")
        else:
            print("Detected audio system: PulseAudio")
    except FileNotFoundError:
        print("Error: pactl not found. Please install PulseAudio or PipeWire.")
        return
    
    print("\nFetching audio devices...\n")
    
    # Get devices
    try:
        # Output devices (sinks)
        sink_cmd = ['pactl', 'list', 'short', 'sinks']
        sink_result = subprocess.run(sink_cmd, capture_output=True, text=True, check=True)
        output_devices = []
        for line in sink_result.stdout.strip().split('\n'):
            if line.strip():
                parts = line.split('\t')
                if len(parts) >= 2:
                    device_id = parts[1]
                    # Get friendly name
                    name_cmd = ['pactl', 'list', 'sinks']
                    name_result = subprocess.run(name_cmd, capture_output=True, text=True, check=True)
                    
                    friendly_name = device_id
                    in_device = False
                    for name_line in name_result.stdout.split('\n'):
                        if f'Name: {device_id}' in name_line:
                            in_device = True
                        elif in_device and 'Description:' in name_line:
                            friendly_name = name_line.split('Description:')[1].strip()
                            break
                        elif in_device and 'Sink #' in name_line:
                            break
                    
                    output_devices.append({'id': device_id, 'name': friendly_name})
        
        # Input devices (sources)
        source_cmd = ['pactl', 'list', 'short', 'sources']
        source_result = subprocess.run(source_cmd, capture_output=True, text=True, check=True)
        input_devices = []
        for line in source_result.stdout.strip().split('\n'):
            if line.strip():
                parts = line.split('\t')
                if len(parts) >= 2:
                    device_id = parts[1]
                    # Skip monitor devices
                    if '.monitor' in device_id:
                        continue
                    
                    # Get friendly name
                    name_cmd = ['pactl', 'list', 'sources']
                    name_result = subprocess.run(name_cmd, capture_output=True, text=True, check=True)
                    
                    friendly_name = device_id
                    in_device = False
                    for name_line in name_result.stdout.split('\n'):
                        if f'Name: {device_id}' in name_line:
                            in_device = True
                        elif in_device and 'Description:' in name_line:
                            friendly_name = name_line.split('Description:')[1].strip()
                            break
                        elif in_device and 'Source #' in name_line:
                            break
                    
                    input_devices.append({'id': device_id, 'name': friendly_name})
        
    except Exception as e:
        print(f"Error getting devices: {e}")
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
        speaker_input_str = input("1. Speaker/Monitor (OUTPUT - enter number): ")
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
        speaker_input_letter = input("2. Secondary Microphone - webcam, etc. (INPUT - enter letter): ").upper()
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
        headset_output_str = input("3. Headset Output (OUTPUT - enter number): ")
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
        headset_input_letter = input("4. Headset Microphone (INPUT - enter letter): ").upper()
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
        print(f"  1. Speaker Output: {speaker_name}")
        print(f"  2. Speaker Input: {speaker_input_name}")
        print(f"  3. Headset Output: {headset_output_name}")
        print(f"  4. Headset Input: {headset_input_name}")
        
        confirm = input("\nSave this configuration? (Y/n): ")
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
        app = AudioToggle()
        app.run()
