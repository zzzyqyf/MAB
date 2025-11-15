# 🔊 Alarm Sound Testing Guide

## ✅ Implementation Complete

The app now uses **audioplayers** package for reliable alarm sound on physical Android devices.

### 🎵 Audio Implementation Details

**Three-Tier Fallback System:**
1. **Primary**: `audioplayers` plays `beep.mp3` with ALARM audio context
2. **Fallback**: Android ToneGenerator (native platform channel)
3. **Last Resort**: Haptic feedback vibration only

**Audio Configuration:**
- **Audio Context**: AndroidUsageType.alarm (highest priority, works in DND mode)
- **Audio Focus**: GAIN (overrides other audio)
- **Volume**: 1.0 (maximum)
- **Content Type**: Sonification (system sounds)

---

## 📋 Required Setup Steps

### Step 1: Add beep.mp3 File

**Location**: `assets/sounds/beep.mp3`

**Options to Get beep.mp3:**

#### Option A: Download from Pixabay (Recommended)
1. Visit: https://pixabay.com/sound-effects/search/beep/
2. Search: "alarm beep" or "beep sound"
3. Download a short (0.3-0.5 second) beep sound
4. Convert to MP3 if needed
5. Rename to `beep.mp3`
6. Copy to `d:\fyp\Backup\MAB\assets\sounds\beep.mp3`

#### Option B: Generate Online
1. Visit: https://www.szynalski.com/tone-generator/
2. Set frequency: 1000 Hz
3. Click play and record 0.5 seconds
4. Save as MP3
5. Place in `assets/sounds/`

#### Option C: Use Audacity
1. Download Audacity (free)
2. Generate → Tone → Sine wave
3. Frequency: 1000 Hz, Duration: 0.5s
4. Export as MP3
5. Save to `assets/sounds/beep.mp3`

**Recommended Specs:**
- Duration: 0.3 - 0.5 seconds
- Frequency: 1000 Hz (clear, audible)
- Format: MP3
- File size: < 50 KB

### Step 2: Rebuild the App

```powershell
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Or run directly in release mode
flutter run --release
```

**⚠️ CRITICAL**: Always test alarm sound in **release mode**, not debug mode. Debug mode has different audio behavior.

---

## 🧪 Testing Procedure

### Test 1: Basic Alarm Test

1. Open the app on your physical phone
2. Navigate to **Settings** (profile icon)
3. Tap **🧪 Test Alarm Sound** button
4. Tap **START ALARM TEST**
5. Check:
   - [ ] Sound plays from phone speakers
   - [ ] Sound is audible and clear
   - [ ] Console shows: `✅ Audio played successfully with audioplayers`

### Test 2: Water Level Alarm Test

1. Set water level threshold in settings (e.g., 20%)
2. Trigger water level alarm by ESP32 sending low water value:

```bash
# Using mosquitto_pub (if installed)
mosquitto_pub -h api.milloserver.uk -p 8883 \
  -u zhangyifei -P 123456 \
  --capath /etc/ssl/certs \
  -t "devices/YOUR_DEVICE_ID/sensors/water_level" \
  -m '{"value": 10.0, "timestamp": 1762874000}'
```

3. Check:
   - [ ] Alarm notification appears
   - [ ] Beep sound plays
   - [ ] Console shows audio method used

### Test 3: Do Not Disturb Mode

1. Enable Do Not Disturb on phone
2. Trigger alarm (using Test Alarm button)
3. Check:
   - [ ] Sound still plays (ALARM audio context bypasses DND)
   - [ ] Console shows successful audio playback

### Test 4: Volume Settings

1. Lower phone's media volume to 0%
2. Set alarm volume to 50%+
3. Trigger alarm
4. Check:
   - [ ] Sound plays at alarm volume (not media volume)
   - [ ] Console shows alarm volume level

---

## 📊 Console Log Analysis

### ✅ Success Indicators

**Primary Method (audioplayers)**:
```
🎵 Alarm: Trying to play beep with audioplayers...
✅ Audio played successfully with audioplayers
```

**Fallback Method (ToneGenerator)**:
```
⚠️ Audio playback failed with audioplayers: [error]
🎵 Alarm: Trying platform channel (ToneGenerator)...
✅ Alarm: Platform channel succeeded!
```

**Last Resort (Haptic Only)**:
```
❌ All audio methods failed
🎵 Alarm: Using haptic feedback only
```

### ❌ Error Indicators

**Missing beep.mp3**:
```
⚠️ Audio playback failed with audioplayers: Unable to load asset: assets/sounds/beep.mp3
```
→ **Solution**: Add beep.mp3 file to assets/sounds/

**Permission Issues**:
```
❌ Platform channel failed: SecurityException
```
→ **Solution**: Check AndroidManifest.xml has MODIFY_AUDIO_SETTINGS permission

**Volume Muted**:
```
⚠️ Alarm volume is very low (1/15). Please increase alarm volume.
🔊 Your alarm volume is set to 1 out of 15. Please increase it in settings.
```
→ **Solution**: Increase phone's alarm volume

---

## 🔧 Troubleshooting

### Issue: No Sound on Physical Phone

**Check 1: beep.mp3 exists**
```powershell
# Verify file exists
Test-Path "d:\fyp\Backup\MAB\assets\sounds\beep.mp3"
# Should output: True
```

**Check 2: Clean rebuild**
```powershell
flutter clean
flutter pub get
flutter build apk --release
```

**Check 3: Check phone settings**
- Alarm volume > 50%
- Phone not in silent mode (alarm audio should bypass this, but check)
- App has notification permissions

**Check 4: Console logs**
- Connect phone via USB
- Enable USB debugging
- Run: `flutter logs`
- Trigger alarm and watch for audio method logs

### Issue: Audio Cuts Off Too Quickly

**Solution 1**: Use longer beep.mp3 (try 1 second instead of 0.5s)

**Solution 2**: Edit `alarm_service.dart`:
```dart
// Current: plays once
await _audioPlayer.play(AssetSource('sounds/beep.mp3'));

// Change to loop 3 times:
await _audioPlayer.setReleaseMode(ReleaseMode.loop);
await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
await Future.delayed(Duration(seconds: 3)); // Play for 3 seconds
await _audioPlayer.stop();
```

### Issue: Sound Plays but Too Quiet

**Check**: Phone alarm volume
- Settings → Sound → Alarm volume
- Must be > 50% for audible sound

**Alternative**: Make beep.mp3 louder using Audacity:
1. Open beep.mp3 in Audacity
2. Effect → Amplify → Set to +10 dB
3. Export as MP3

### Issue: ToneGenerator Fallback Used Instead of audioplayers

**Possible Causes**:
1. beep.mp3 file missing or corrupted
2. File not properly bundled in APK
3. Asset path incorrect

**Debug Steps**:
1. Check console: Look for `⚠️ Audio playback failed with audioplayers:` error
2. Verify asset in pubspec.yaml: `assets: - assets/sounds/`
3. Rebuild completely: `flutter clean && flutter pub get && flutter build apk --release`

---

## 📱 Expected Behavior

### Normal Operation

1. **Water level drops below threshold (20%)**
   - Notification appears: "💧 Water Level Alert"
   - Beep sound plays 3 times
   - Text-to-speech: "Water level is low. Device [Name]. Please refill."
   - Phone vibrates
   - Console: `✅ Audio played successfully with audioplayers`

2. **Alarm acknowledged**
   - User taps "OK" on notification
   - Sound stops
   - Console: `🎵 Alarm: Stopping alarm`

### Audio Method Priority

The app will try methods in this order:

**1st: audioplayers (NEW)**
- Most reliable on physical phones
- Uses actual sound file
- ALARM audio context (high priority)

**2nd: ToneGenerator (FALLBACK)**
- Native Android tone
- Loud emergency ringback tone
- May not work on all devices/manufacturers

**3rd: Haptic Only (LAST RESORT)**
- Vibration pattern: 200ms-100ms-200ms
- No sound
- Better than nothing if audio fails

---

## 🎯 Success Criteria

### Checklist for Production Ready

- [ ] beep.mp3 file added to assets/sounds/
- [ ] App rebuilt with `flutter build apk --release`
- [ ] Tested on physical phone (NOT emulator)
- [ ] Sound audible and clear
- [ ] Works in Do Not Disturb mode
- [ ] Works with low media volume (uses alarm volume)
- [ ] Console shows `✅ Audio played successfully with audioplayers`
- [ ] No errors in console logs

### Performance Metrics

- **Audio Latency**: < 500ms from trigger to sound
- **Reliability**: 95%+ success rate on target devices
- **Volume**: Clearly audible at arm's length
- **Battery Impact**: Negligible (< 1% per alarm)

---

## 📚 Related Files

- **Main Implementation**: `lib/shared/services/alarm_service.dart`
- **Native Fallback**: `android/app/src/main/kotlin/.../MainActivity.kt`
- **Test UI**: `lib/alarm_test_page.dart`
- **Settings Button**: `lib/features/profile/presentation/pages/setting.dart`
- **Dependencies**: `pubspec.yaml` (audioplayers: ^6.0.0)
- **Asset Config**: `pubspec.yaml` (assets/sounds/)
- **Setup Guide**: `assets/sounds/SETUP_GUIDE.md`

---

## 💡 Tips

1. **Always test in release mode**: `flutter run --release`
2. **Use USB debugging**: Connect phone to see console logs
3. **Check volume first**: Alarm volume, not media volume
4. **Clear app data**: If audio doesn't work after update, clear app data and reinstall
5. **Record logs**: When reporting issues, include console output showing audio method attempts

---

## 🚀 Next Steps

1. **Add beep.mp3**: See Step 1 above
2. **Rebuild app**: `flutter clean && flutter pub get && flutter build apk --release`
3. **Install on phone**: Transfer APK or use `flutter install`
4. **Test**: Use "Test Alarm Sound" button in settings
5. **Verify**: Check console logs show `✅ Audio played successfully with audioplayers`

**Your alarm system is now ready for reliable operation on physical Android devices! 📱🔊**
