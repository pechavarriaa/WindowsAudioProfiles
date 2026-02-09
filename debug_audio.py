#!/usr/bin/env python3
import subprocess
import json
from pathlib import Path

# Get current devices
def get_current_device(device_type='output'):
    try:
        cmd = ['SwitchAudioSource', '-c', '-t', device_type]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except Exception as e:
        return f"Error: {e}"

# Get all devices
def get_all_devices(device_type='output'):
    try:
        cmd = ['SwitchAudioSource', '-a', '-t', device_type]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return [line.strip() for line in result.stdout.split('\n') if line.strip()]
    except Exception as e:
        return [f"Error: {e}"]

# Load config
config_file = Path.home() / ".config" / "audio_toggle" / "config.json"
if config_file.exists():
    with open(config_file) as f:
        config = json.load(f)
    print("=== CONFIGURATION ===")
    print(f"Speaker Device: '{config.get('speaker_device', 'NOT SET')}'")
    print(f"Headset Output: '{config.get('headset_output', 'NOT SET')}'")
    print(f"Speaker Input:  '{config.get('speaker_input', 'NOT SET')}'")
    print(f"Headset Input:  '{config.get('headset_input', 'NOT SET')}'")
else:
    print("Config file not found!")
    config = {}

print("\n=== CURRENT DEVICES ===")
current_output = get_current_device('output')
current_input = get_current_device('input')
print(f"Current Output: '{current_output}'")
print(f"Current Input:  '{current_input}'")

print("\n=== ALL OUTPUT DEVICES ===")
for i, dev in enumerate(get_all_devices('output')):
    print(f"  [{i}] {dev}")

print("\n=== ALL INPUT DEVICES ===")
for i, dev in enumerate(get_all_devices('input')):
    print(f"  [{i}] {dev}")

print("\n=== COMPARISON CHECKS ===")
if config:
    print(f"Current output == headset_output? {current_output == config.get('headset_output', '')}")
    print(f"Current output == speaker_device? {current_output == config.get('speaker_device', '')}")
    print(f"Current input == headset_input? {current_input == config.get('headset_input', '')}")
    print(f"Current input == speaker_input? {current_input == config.get('speaker_input', '')}")
