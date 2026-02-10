#!/usr/bin/env python3
"""
macOS Audio Device Toggle - Menu Bar Application
Provides a menu bar icon to quickly toggle between audio devices on macOS.
"""

import subprocess
import json
import os
import sys
from pathlib import Path

try:
    import rumps
except ImportError:
    print("Error: rumps library not found. Install with: pip3 install rumps")
    sys.exit(1)


class AudioToggle(rumps.App):
    def __init__(self):
        super(AudioToggle, self).__init__("🔊", quit_button=None)
        self.config_file = Path.home() / ".config" / "audio_toggle" / "config.json"
        self.load_config()
        self.menu = [
            rumps.MenuItem("Toggle Audio", callback=self.toggle_audio),
            rumps.separator,
            rumps.MenuItem("Configure Devices...", callback=self.configure_devices),
            rumps.separator,
            rumps.MenuItem("Quit", callback=self.quit_app)
        ]
        
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
        """Get list of audio devices using SwitchAudioSource"""
        try:
            cmd = ['SwitchAudioSource', '-a', '-t', device_type]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            devices = [line.strip() for line in result.stdout.split('\n') if line.strip()]
            return devices
        except subprocess.CalledProcessError:
            self.show_notification("Error", "SwitchAudioSource not found. Please install it.")
            return []
        except Exception as e:
            self.show_notification("Error", f"Failed to get devices: {e}")
            return []
    
    def get_current_device(self, device_type='output'):
        """Get current default audio device"""
        try:
            cmd = ['SwitchAudioSource', '-c', '-t', device_type]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except Exception as e:
            print(f"Error getting current device: {e}")
            return None
    
    def set_audio_device(self, device_name, device_type='output'):
        """Set default audio device"""
        try:
            cmd = ['SwitchAudioSource', '-s', device_name, '-t', device_type]
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
        print(f"[Toggle] Speaker device: '{self.speaker_device}'")
        print(f"[Toggle] Headset output: '{self.headset_output}'")
        
        # Determine target devices based on current state
        if current_output == self.headset_output:
            # Currently on headset, switch to speakers
            target_output = self.speaker_device
            target_input = self.speaker_input
            profile_name = "Speakers"
        elif current_output == self.speaker_device:
            # Currently on speakers, switch to headset
            target_output = self.headset_output
            target_input = self.headset_input
            profile_name = "Headset"
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
            self.show_notification("Toggle Failed", f"Failed to switch output to {target_output}")
            return
        
        # Attempt to switch input device
        input_success = self.set_audio_device(target_input, 'input')
        if not input_success:
            self.show_notification("Toggle Partial", f"Output switched but input failed")
            return
        
        # Both switches succeeded
        self.show_notification("Audio Switched", f"Switched to {profile_name}\nOutput: {target_output}\nInput: {target_input}")
    
    def show_notification(self, title, message):
        """Show macOS notification"""
        rumps.notification(title, "", message)
    
    @rumps.clicked("Configure Devices...")
    def configure_devices(self, _):
        """Open configuration in terminal"""
        script_path = Path(__file__).resolve()
        applescript = f'''
        tell application "Terminal"
            activate
            do script "cd {script_path.parent} && python3 {script_path} --configure"
        end tell
        '''
        subprocess.run(['osascript', '-e', applescript])
    
    @rumps.clicked("Quit")
    def quit_app(self, _):
        """Quit the application"""
        rumps.quit_application()


def configure_interactive():
    """Interactive configuration mode"""
    print("\n=== Configure Audio Toggle for macOS ===\n")
    
    # Check if SwitchAudioSource is available
    try:
        subprocess.run(['SwitchAudioSource', '-h'], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Error: SwitchAudioSource not found.")
        print("Install with: brew install switchaudio-osx")
        return
    
    # Get devices
    print("Fetching audio devices...\n")
    output_devices = []
    input_devices = []
    
    try:
        result = subprocess.run(['SwitchAudioSource', '-a', '-t', 'output'], 
                              capture_output=True, text=True, check=True)
        output_devices = [line.strip() for line in result.stdout.split('\n') if line.strip()]
        
        result = subprocess.run(['SwitchAudioSource', '-a', '-t', 'input'], 
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
        speaker_input_str = input("1. Speaker/Monitor (OUTPUT - enter number): ")
        if speaker_input_str.lower() == 'q':
            print("Configuration cancelled.")
            return
        speaker_idx = int(speaker_input_str)
        if speaker_idx < 0 or speaker_idx >= len(output_devices):
            print("Error: Number out of range.")
            return
        speaker_device = output_devices[speaker_idx]
        
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
        speaker_input = input_devices[speaker_input_idx]
        
        # Get headset output
        headset_output_str = input("3. Headset Output (OUTPUT - enter number): ")
        if headset_output_str.lower() == 'q':
            print("Configuration cancelled.")
            return
        headset_output_idx = int(headset_output_str)
        if headset_output_idx < 0 or headset_output_idx >= len(output_devices):
            print("Error: Number out of range.")
            return
        headset_output = output_devices[headset_output_idx]
        
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
        headset_input = input_devices[headset_input_idx]
        
        # Show configuration
        print("\nYour configuration:")
        print(f"  1. Speaker Output: {speaker_device}")
        print(f"  2. Speaker Input: {speaker_input}")
        print(f"  3. Headset Output: {headset_output}")
        print(f"  4. Headset Input: {headset_input}")
        
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
