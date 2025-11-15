# Alarm Sound Troubleshooting Guide

## Problem: No Alarm Sound on Physical Phone

If the alarm works in the emulator but not on your physical phone, this is a **common Android issue** related to device-specific audio settings and permissions.

## Why Does It Work in Emulator But Not on Phone?

1. **Volume Settings**: Physical phones often have alarm volume turned down or muted
2. **Do Not Disturb Mode**: Many users enable DND which silences alarms
3. **Battery Optimization**: Some phones aggressively kill background audio
4. **Manufacturer Restrictions**: Some brands (Samsung, Xiaomi, Oppo) have strict audio policies

## Solutions Implemented

### 1. Enhanced Audio Permissions ✅
Added to `AndroidManifest.xml`:
- `MODIFY_AUDIO_SETTINGS` - Allows app to adjust audio settings
- `ACCESS_NOTIFICATION_POLICY` - Allows app to check DND status
- `VIBRATE` - Provides haptic feedback as backup

### 2. Improved Audio Implementation ✅
Updated `MainActivity.kt` with:
- **Louder tone**: Changed from `TONE_CDMA_ALERT_CALL_GUARD` to `TONE_CDMA_EMERGENCY_RINGBACK`
- **Longer duration**: Increased from 200ms to 500ms per beep
- **Maximum volume**: Using `ToneGenerator.MAX_VOLUME` instead of fixed 100
- **Vibration backup**: Adds strong vibration pattern (200ms-100ms-200ms)
- **Volume logging**: Debug output shows current alarm volume level

### 3. Volume Monitoring ✅
The app now:
- Checks current alarm volume vs max volume
- Logs warning if volume is below 25% of maximum
- Returns volume info for debugging

## How to Test

### Step 1: Check Phone Volume Settings
1. Press volume up button on your phone
2. Tap the settings icon (⚙️) that appears
3. Make sure **Alarm volume** slider is at least 50% or higher
4. Verify **Do Not Disturb** is OFF

### Step 2: Rebuild the App
Since we modified native Android code, you must rebuild:

```powershell
# Clean build files
flutter clean

# Get dependencies
flutter pub get

# Build and install on phone
flutter run --release
```

### Step 3: Test the Alarm
1. Open a device in the app
2. Trigger an alarm condition (e.g., high temperature):
   ```powershell
   mosquitto_pub -h api.milloserver.uk -p 8883 `
     -u zhangyifei -P 123456 `
     --capath /etc/ssl/certs `
     -t "devices/ESP32_001/sensors/temperature" `
     -m '{"value": 35.0, "timestamp": 1234567890}'
   ```
3. You should now hear:
   - **Loud beep sound** every 2 seconds
   - **Phone vibration** pattern (buzz-pause-buzz)
   - **TTS announcement** "Urgent Alert: [device name]..."
   - **Red banner** on screen

### Step 4: Check Debug Logs
Use `adb logcat` to see alarm activity:

```powershell
# Filter for alarm-related logs
adb logcat | Select-String -Pattern "AlarmService"

# Look for these messages:
# "Alarm volume: X / Y"
# "Playing ToneGenerator beep"
# "Vibration triggered"
```

## Manufacturer-Specific Issues

### Samsung Phones
1. Go to **Settings** → **Apps** → **Your App**
2. Tap **Battery**
3. Select **Unrestricted** for battery usage
4. Enable **Allow background activity**

### Xiaomi/MIUI
1. Go to **Settings** → **Apps** → **Manage apps** → **Your App**
2. Enable **Autostart**
3. Set **Battery saver** to **No restrictions**
4. Go to **Other permissions** → Enable **Display pop-up windows**

### Oppo/ColorOS
1. Go to **Settings** → **Battery** → **App Battery Management**
2. Find your app and set to **Allow background activity**
3. Go to **Settings** → **App Management** → **Your App**
4. Enable **Allow notifications**

### Huawei/EMUI
1. Go to **Settings** → **Battery** → **App launch**
2. Find your app and set to **Manage manually**
3. Enable all three options (Auto-launch, Secondary launch, Run in background)

## Testing Checklist

- [ ] Phone alarm volume is above 50%
- [ ] Do Not Disturb mode is OFF
- [ ] App has been rebuilt after code changes (`flutter clean` + `flutter run`)
- [ ] Battery optimization is disabled for the app
- [ ] Notification permissions are granted
- [ ] Test in a quiet environment
- [ ] Check if vibration works (if sound doesn't)
- [ ] Check `adb logcat` for "AlarmService" logs

## Expected Behavior

### When Alarm Triggers:
✅ **Sound**: Loud emergency tone every 2 seconds  
✅ **Vibration**: Strong buzz pattern (200ms-100ms-200ms)  
✅ **Visual**: Red banner with warning icon  
✅ **TTS**: Voice announcement of the alert  

### If Sound Still Doesn't Work:
1. **Vibration should still work** - You'll feel the phone buzz
2. **Visual alert still shows** - Red banner appears
3. **TTS still speaks** - Voice announces the alert
4. **Check volume**: The app logs will show if volume is too low

## Common Debugging Commands

```powershell
# Check if app is installed
adb shell pm list packages | Select-String "flutter_application_final"

# Check current alarm volume
adb shell media volume --show --stream 4

# Set alarm volume to maximum (stream 4 = alarm)
adb shell media volume --set 4 --volume 15

# View all app logs
adb logcat -s "AlarmService:*" "flutter:*"

# Force stop and restart app
adb shell am force-stop com.example.flutter_application_final
adb shell am start -n com.example.flutter_application_final/.MainActivity
```

## Advanced: Test Tone Directly

Test if ToneGenerator works on your phone:

```kotlin
// In MainActivity.kt, add a test button or temporary code
val tg = ToneGenerator(AudioManager.STREAM_ALARM, ToneGenerator.MAX_VOLUME)
tg.startTone(ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK, 1000)
Thread.sleep(1000)
tg.release()
```

## Key Improvements from This Update

| Aspect | Before | After |
|--------|--------|-------|
| Volume | Fixed at 100 | MAX_VOLUME (system max) |
| Tone Type | Alert guard (quiet) | Emergency ringback (loud) |
| Duration | 200ms | 500ms |
| Vibration | Only as fallback | Always active |
| Volume Check | None | Logs current volume level |
| Permissions | Basic audio | Full audio control |

## Still Not Working?

If after all these steps the alarm still doesn't work:

1. **Check phone model**: Some phones have very restrictive audio policies
2. **Test other alarm apps**: Try a third-party alarm app to see if sound works
3. **Check phone speakers**: Play music to verify speakers work
4. **Try different tone**: Modify `TONE_CDMA_EMERGENCY_RINGBACK` to other tones in MainActivity.kt:
   - `TONE_CDMA_ABBR_ALERT`
   - `TONE_CDMA_ALERT_NETWORK_LITE`
   - `TONE_PROP_BEEP2`
5. **Use MediaPlayer instead**: As last resort, play an actual audio file (requires adding .mp3 to assets)

## Questions?

- Check the main alarm documentation: `docs/ALARM_SYSTEM.md`
- Review system architecture: `docs/SYSTEM_ARCHITECTURE.md`
- ESP32 integration: `docs/ESP32_MQTT_CODE.md`
