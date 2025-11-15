# Quick Test Instructions - Alarm Sound

## The Problem
Alarm works in emulator but not on physical phone.

## Key Difference: Debug vs Release Mode

**`flutter run` (Debug)**:
- For development with hot reload
- Sometimes audio doesn't work properly on physical devices
- Larger app size, slower

**`flutter run --release` (Release)**:
- Production mode - what users get
- Better native feature support (including audio!)
- **RECOMMENDED for testing audio on physical devices**

## Steps to Test Now

### 1. Rebuild with Enhanced Logging

```powershell
# Clean everything
flutter clean

# Get dependencies  
flutter pub get

# Build and run in RELEASE mode (important!)
flutter run --release
```

### 2. Navigate to Test Page

1. Open your app on your phone
2. Go to **any device** → Tap the settings icon (⚙️)
3. Scroll down and find **"🧪 Test Alarm Sound"**
4. **Double tap** on it to open the test page

### 3. Test the Alarm

1. On the test page, tap the big red button: **"START ALARM TEST"**
2. **What should happen:**
   - 🔊 **Loud beep sound** every 2 seconds
   - 📳 **Strong vibration** (buzz-pause-buzz pattern)
   - 🗣️ **Voice says**: "Urgent Alert: Test Alarm..."
   - Counter shows how many beeps have played

3. **If you DON'T hear sound:**
   - Check if you feel the vibration (this confirms the code is running)
   - Look at your phone's status bar - is "Do Not Disturb" enabled? (moon icon)
   - Check your phone's alarm volume (use volume buttons, tap settings icon)

### 4. Check Console Logs

The app now has VERY detailed logging. Watch the console output:

Look for these messages:
```
🚨 ALARM STARTED: Test Alarm...
🔊 _playBeep() called
📞 Invoking platform channel "playBeep"...
========== PLAYBEEP CALLED ==========
Alarm volume: X / Y
```

**If you see:**
- `Alarm volume: 0 / 15` → **Your alarm volume is MUTED!**
- `Alarm volume: 3 / 15` → **Volume is too low**
- `Alarm volume: 10 / 15` → **Volume should be loud enough**

### 5. Fix Volume Issues

**On your phone:**

1. Press the **volume UP button**
2. Tap the **settings icon** (⚙️) that appears
3. Look for the **"Alarm" volume slider**
4. Move it to at least **50% or higher**
5. Make sure **"Do Not Disturb"** is OFF

**On some phones (Samsung, Xiaomi, etc.):**
- Go to Settings → Sound → Volume
- Find "Alarm volume" specifically (not media or ringtone)
- Turn it up

## What the New Code Does

### Enhanced Logging
- Shows EVERY step of the alarm process
- Reports current alarm volume vs maximum
- Warns if volume is too low or muted
- Logs success/failure of each audio attempt

### Improved Sound
- Uses `TONE_CDMA_EMERGENCY_RINGBACK` (loudest tone)
- Maximum volume (ToneGenerator.MAX_VOLUME)
- Longer beep duration (500ms instead of 200ms)
- Always adds vibration as backup

### Permissions Added
- `MODIFY_AUDIO_SETTINGS` - Control audio
- `ACCESS_NOTIFICATION_POLICY` - Check DND status
- `VIBRATE` - Vibration backup

## Expected Console Output

### ✅ Success (Volume Good):
```
═══════════════════════════════════════
🧪 ALARM TEST STARTED
═══════════════════════════════════════
🚨 ALARM STARTED: Test Alarm - Temperature Critical: 35.0°C
📱 Platform: TargetPlatform.android
🔊 Starting alarm audio system...
🗣️ TTS announcement sent
🔔 Playing first beep immediately...
🔊 _playBeep() called
📞 Invoking platform channel "playBeep"...
========== PLAYBEEP CALLED ==========
D/AlarmService: Alarm volume: 12 / 15
I/AlarmService: ✅ Alarm volume OK: 12 / 15
D/AlarmService: 🔊 Playing ToneGenerator beep...
D/AlarmService: ToneGenerator.startTone() returned: true
I/AlarmService: ✅ ToneGenerator beep playing
D/AlarmService: 📳 Triggering vibration...
I/AlarmService: ✅ Vibration triggered
========== PLAYBEEP COMPLETE ==========
✅ Platform channel returned: {volume: 12, maxVolume: 15, success: true}
🔊 Volume info - Current: 12, Max: 15
✅ Alarm volume OK: 12/15
📳 Triggering haptic feedback...
```

### ⚠️ Problem (Volume Muted):
```
🚨 ALARM STARTED: Test Alarm...
🔊 _playBeep() called
📞 Invoking platform channel "playBeep"...
========== PLAYBEEP CALLED ==========
D/AlarmService: Alarm volume: 0 / 15
E/AlarmService: ❌ ALARM VOLUME IS MUTED! User won't hear anything!
D/AlarmService: 🔊 Playing ToneGenerator beep...
========== PLAYBEEP COMPLETE ==========
❌ CRITICAL: Alarm volume is MUTED (0/15)!
📱 USER ACTION NEEDED: Please turn up alarm volume on your phone!
```

## Debug vs Release - Why It Matters

| Aspect | Debug Mode | Release Mode |
|--------|-----------|--------------|
| Audio | May be delayed/broken | Works properly |
| Performance | Slow | Fast |
| Size | ~100MB | ~20MB |
| Hot Reload | ✅ Yes | ❌ No |
| **For Testing Audio** | ❌ Not recommended | ✅ **Use this!** |

## Still No Sound After All This?

If after testing in **release mode** with **alarm volume up** and **DND off**, you still don't hear anything BUT you feel vibration:

### Check Your Phone Model

Some manufacturers have aggressive audio restrictions:

**Samsung:**
- Settings → Apps → Your App → Battery → Unrestricted

**Xiaomi/MIUI:**
- Settings → Apps → Manage apps → Your App → Autostart (ON)
- Battery saver → No restrictions

**Oppo/ColorOS:**
- Settings → Battery → App Battery Management → Allow background

**Huawei:**
- Settings → Battery → App launch → Manage manually → Enable all

### Try Different Tone

Edit `MainActivity.kt` line ~63, change:
```kotlin
ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK
```

To one of these:
```kotlin
ToneGenerator.TONE_CDMA_ABBR_ALERT
ToneGenerator.TONE_PROP_BEEP2  
ToneGenerator.TONE_CDMA_ALERT_NETWORK_LITE
```

## Questions?

- Full troubleshooting: `docs/ALARM_TROUBLESHOOTING.md`
- Alarm system docs: `docs/ALARM_SYSTEM.md`
- System architecture: `docs/SYSTEM_ARCHITECTURE.md`
