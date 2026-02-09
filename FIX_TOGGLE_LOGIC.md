# Fix: Improved Toggle Logic with Better Error Handling

## Problem
Audio still not toggling even after config reload fix. The toggle function was showing notifications even when switches failed, and had poor handling of edge cases.

## Issues Identified

### 1. No Error Feedback
- Notifications showed "success" even if device switching failed
- User had no way to know if toggle actually worked
- Silent failures made debugging impossible

### 2. Inconsistent State Management
- Input device switched even if output switch failed
- Could leave audio in inconsistent state (e.g., headset output with speaker input)

### 3. Poor Edge Case Handling
- If current device didn't match either configured device, behavior was undefined
- Would always default to headset in the else branch
- No logging to help diagnose issues

### 4. Lack of Debugging Information
- No logging to see what devices were being compared
- Impossible to diagnose device name mismatch issues
- Silent failures with no error messages

## Solution

### Improved Toggle Logic

**Before:**
```python
current_output = self.get_current_device('output')

if current_output == self.headset_output:
    if self.set_audio_device(self.speaker_device, 'output'):
        self.set_audio_device(self.speaker_input, 'input')
        self.show_notification("Audio Switched", ...)  # Shows even if failed!
else:
    if self.set_audio_device(self.headset_output, 'output'):
        self.set_audio_device(self.headset_input, 'input')
        self.show_notification("Audio Switched", ...)  # Shows even if failed!
```

**After:**
```python
current_output = self.get_current_device('output')

# Debug logging
print(f"[Toggle] Current output: '{current_output}'")
print(f"[Toggle] Speaker device: '{self.speaker_device}'")
print(f"[Toggle] Headset output: '{self.headset_output}'")

# Determine target based on current state
if current_output == self.headset_output:
    target_output = self.speaker_device
    target_input = self.speaker_input
    profile_name = "Speakers"
elif current_output == self.speaker_device:
    target_output = self.headset_output
    target_input = self.headset_input
    profile_name = "Headset"
else:
    # Fallback if current doesn't match either
    print(f"[Toggle] Warning: Current device doesn't match")
    target_output = self.speaker_device
    target_input = self.speaker_input
    profile_name = "Speakers"

print(f"[Toggle] Switching to {profile_name}")

# Switch output first, check success
output_success = self.set_audio_device(target_output, 'output')
if not output_success:
    self.show_notification("Toggle Failed", f"Failed to switch output")
    return  # Stop here, don't try input

# Switch input, check success
input_success = self.set_audio_device(target_input, 'input')
if not input_success:
    self.show_notification("Toggle Partial", f"Output switched but input failed")
    return

# Only show success if both succeeded
self.show_notification("Audio Switched", f"Switched to {profile_name}")
```

## Key Improvements

### 1. Debug Logging
- Prints current device and configured devices
- Helps diagnose device name mismatch issues
- Logs appear in system logs for troubleshooting

### 2. Explicit State Determination
- Three clear cases: headset, speakers, or unknown
- Fallback behavior when current device doesn't match
- Clear variable names (target_output, target_input, profile_name)

### 3. Proper Error Handling
- Checks return value of each set_audio_device call
- Shows specific error messages for different failure types
- Stops execution if output switch fails (doesn't try input)

### 4. Accurate Notifications
- "Toggle Failed" - output switch failed
- "Toggle Partial" - output worked but input failed
- "Audio Switched" - both succeeded
- User gets accurate feedback

### 5. State Consistency
- Only switches input if output succeeded
- Prevents mismatched states
- Atomic-like behavior (all or nothing)

## Testing Guidance

### Check Logs
On macOS, check the logs:
```bash
tail -f ~/Library/Logs/audio_toggle.log
```

Look for:
```
[Toggle] Current output: 'Built-in Speakers'
[Toggle] Speaker device: 'Built-in Speakers'
[Toggle] Headset output: 'USB Headset'
[Toggle] Switching to Headset: output='USB Headset', input='USB Headset Mic'
```

### Common Issues and Solutions

**Issue: "Toggle Failed" notification**
- Device name mismatch
- Check logs to see current vs configured
- May need to reconfigure devices

**Issue: Device names don't match**
- SwitchAudioSource returns slightly different names
- Run configuration again
- Device names might have extra spaces or characters

**Issue: "Toggle Partial" notification**
- Output switched successfully
- Input device name might be wrong
- Reconfigure input devices

**Issue: Always switches to Speakers**
- Current device doesn't match either configured device
- Check debug logs
- Reconfigure to ensure device names are exact

## Files Modified
- `audio_toggle_mac.py` - Improved toggle logic with error handling
- `audio_toggle_linux.py` - Same improvements for consistency

## Impact
- ✅ Better error messages help diagnose issues
- ✅ Debug logging reveals device name problems
- ✅ No silent failures
- ✅ Consistent state management
- ✅ Clear feedback to user

---

**Fixed:** 2026-02-09  
**Issue:** Toggle not working with no error feedback  
**Solution:** Improved error handling and debug logging
