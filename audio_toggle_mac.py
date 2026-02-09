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
        if not all([self.speaker_device, self.headset_output, self.speaker_input, self.headset_input]):
            self.show_notification("Configuration Required", "Please configure your audio devices first.")
            self.configure_devices(None)
            return
        
        current_output = self.get_current_device('output')
        
        if current_output == self.headset_output:
            # Switch to speakers
            if self.set_audio_device(self.speaker_device, 'output'):
                self.set_audio_device(self.speaker_input, 'input')
                self.show_notification("Audio Switched", f"Output: {self.speaker_device}\nInput: {self.speaker_input}")
        else:
            # Switch to headset
            if self.set_audio_device(self.headset_output, 'output'):
                self.set_audio_device(self.headset_input, 'input')
                self.show_notification("Audio Switched", f"Output: {self.headset_output}\nInput: {self.headset_input}")
    
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
    
    # Display output devices
    print("=== OUTPUT DEVICES (Speakers/Headphones) ===")
    for i, device in enumerate(output_devices):
        print(f"  [{i}] {device}")
    
    print("\n=== INPUT DEVICES (Microphones) ===")
    for i, device in enumerate(input_devices):
        print(f"  [{i}] {device}")
    
    print("\n")
    
    # Get user selections
    try:
        speaker_idx = int(input("1. Select speaker/monitor output (number): "))
        speaker_device = output_devices[speaker_idx]
        
        speaker_input_idx = int(input("2. Select speaker input/microphone (number): "))
        speaker_input = input_devices[speaker_input_idx]
        
        headset_output_idx = int(input("3. Select headset output (number): "))
        headset_output = output_devices[headset_output_idx]
        
        headset_input_idx = int(input("4. Select headset microphone (number): "))
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
