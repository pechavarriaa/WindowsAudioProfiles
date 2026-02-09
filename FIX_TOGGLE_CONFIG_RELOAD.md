# Fix: Toggle Not Working After Configuration

## Problem
After configuring audio devices, the toggle audio function doesn't work - audio continues playing on the same device instead of switching between configured devices.

## Root Cause
The application loads configuration only once during initialization:

1. **App starts**: `__init__` calls `load_config()` → loads config (possibly empty)
2. **User configures**: Runs `--configure` in Terminal → saves new config to file
3. **User toggles**: App still has old config in memory → toggle uses stale/empty config
4. **Result**: Toggle doesn't work because app thinks devices aren't configured

### Technical Details
The configuration workflow:
- **Menu bar app**: Runs continuously in memory (started by LaunchAgent)
- **Configuration**: Runs in separate Terminal process (`--configure` flag)
- **Config file**: `~/.config/audio_toggle/config.json`

The issue: Two separate processes, config saved by one isn't automatically loaded by the other.

## Solution
Reload configuration from file at the start of `toggle_audio()` method.

### Why This Works
- Ensures the latest configuration is always used when toggling
- Very low overhead (small JSON file read)
- Simple and reliable solution
- No complex file watching or IPC needed

### Code Changes

**Before:**
```python
@rumps.clicked("Toggle Audio")
def toggle_audio(self, _):
    """Toggle between audio configurations"""
    if not all([self.speaker_device, self.headset_output, ...]):
        # Check fails with stale config
```

**After:**
```python
@rumps.clicked("Toggle Audio")
def toggle_audio(self, _):
    """Toggle between audio configurations"""
    # Reload configuration to get latest settings
    self.load_config()  # ← Always get fresh config
    
    if not all([self.speaker_device, self.headset_output, ...]):
        # Check now uses current config
```

## Testing Workflow

### Before Fix ❌
```
1. Install app → App starts with empty config
2. Run "Configure Devices..." → Config saved to file
3. Click "Toggle Audio" → Doesn't work (app has old config)
4. Audio stays on same device
```

### After Fix ✅
```
1. Install app → App starts with empty config
2. Run "Configure Devices..." → Config saved to file
3. Click "Toggle Audio" → Reloads config first ← FIX
4. Audio switches correctly between devices
```

## Files Modified
- `audio_toggle_mac.py` - Added `self.load_config()` in toggle_audio
- `audio_toggle_linux.py` - Same fix for consistency

## Impact
- ✅ Toggle works immediately after configuration
- ✅ No app restart required
- ✅ Config changes detected automatically
- ✅ Minimal performance impact
- ✅ Both Mac and Linux fixed

## Alternative Solutions Considered

### Option 1: File watching
- Monitor config file for changes
- Reload automatically when modified
- **Rejected**: Too complex for this use case

### Option 2: Manual reload menu item
- Add "Reload Configuration" menu option
- User manually reloads after configuring
- **Rejected**: Less user-friendly, extra step

### Option 3: Restart app after configure
- Kill and restart app after configuration
- **Rejected**: Disruptive to user experience

### Option 4: IPC between processes
- Configure process signals running app
- **Rejected**: Over-engineered for simple config reload

### Selected: Reload on toggle (Option 5)
- Simple, reliable, immediate
- No user action needed
- Works every time

## User Experience

### Before
1. Configure devices ✅
2. Click Toggle Audio
3. Nothing happens 😕
4. User confused, tries again
5. Still doesn't work 😠

### After
1. Configure devices ✅
2. Click Toggle Audio
3. Audio switches! 🎉
4. Everything works as expected

---

**Fixed:** 2026-02-09  
**Issue:** Toggle not working after configuration  
**Solution:** Reload config before toggling  
**Status:** ✅ Complete
