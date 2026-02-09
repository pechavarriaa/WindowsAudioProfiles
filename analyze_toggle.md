# Toggle Logic Analysis

## Current Code (Lines 111-122)
```python
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
```

## Problems Identified

### Issue 1: Always switches to headset if not exact match
- If `current_output` doesn't exactly match `self.headset_output`, it goes to else branch
- This means it ALWAYS switches to headset unless current is exactly headset
- User likely has headset as current, so it keeps trying to switch to headset (no change!)

### Issue 2: No feedback on failure
- If `self.set_audio_device` returns False, the notification still shows
- User doesn't know the switch failed

### Issue 3: Input switching happens regardless
- Even if output switch fails, input still switches
- Could lead to mismatched state

### Issue 4: No actual toggle behavior
- Should toggle between two states
- Currently it's: "if headset then speakers, else headset"
- This is correct logic, but...
- If it's already on speakers, it switches to headset (correct)
- If it's already on headset, it switches to speakers (correct)
- But if comparison fails, it always goes to headset

## The Real Problem
The issue is likely that `current_output` doesn't match either device name exactly!

Possible causes:
1. Device names have extra whitespace
2. Device names have different characters
3. `get_current_device` returns something unexpected
4. Config has wrong device names saved
