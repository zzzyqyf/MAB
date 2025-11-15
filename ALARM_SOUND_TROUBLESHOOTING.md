# Alarm Sound Troubleshooting Guide

## ⚠️ Phone Has No Sound When Alarm Triggers

### Quick Diagnosis Checklist

Run through these checks in order:

#### 1. Check Phone Volume Settings ⚡ **MOST COMMON ISSUE**

**Problem**: Your phone's **Alarm volume** (not media/ringtone volume) is muted or too low.

**Solution**:
1. Go to **Settings → Sound & Vibration**
2. Find **Alarm Volume** slider
3. Turn it up to maximum
4. Test the alarm again

**Why this matters**: The app uses Android's `STREAM_ALARM` audio channel, which has a separate volume control from media playback.

---

#### 2. Check App is in Release Mode

**Problem**: Debug mode FCM notifications may not work properly, especially in background/killed states.

**Current Status**: Check how you're running the app:
```powershell
# Wrong (debug mode)
flutter run

# Correct (release mode)
flutter run --release
```

**Or build and install APK**:
```powershell
flutter build apk --release
# Install: build/app/outputs/flutter-apk/app-release.apk
```

---

#### 3. Verify App Has Notification Permissions

**Check**:
1. Go to **Settings → Apps → MAB → Notifications**
2. Ensure "Show notifications" is **ON**
3. Ensure "Alarm" channel is **ON**
4. Check sound is **NOT** set to "Silent"

**If channel doesn't exist**: Reinstall the app

---

#### 4. Check FCM Token Exists in Firestore

**Steps**:
1. Go to: https://console.firebase.google.com/project/mab-fyp/firestore
2. Navigate to: `users/{your_user_id}`
3. Check if `fcmToken` field exists
4. If missing or null:
   - Force close and reopen the app
   - Check Flutter logs for "✅ FCM token saved"

**Expected document structure**:
```
users/{userId}
  - email: "your@email.com"
  - fcmToken: "dABC123...xyz" ← Must exist
  - createdAt: Timestamp
```

---

#### 5. Verify Device-User Association

**Steps**:
1. In Firestore: `devices/E86BEAD0BD78`
2. Check `userId` field matches your user ID
3. If wrong/missing:
   ```dart
   // In Flutter, re-register device
   // Or manually update in Firestore console
   ```

**Expected document structure**:
```
devices/E86BEAD0BD78
  - userId: "{your_user_id}" ← Must match
  - name: "Mushroom Tent A"
  - mode: "n"
  - lastAlarm: Timestamp
  - alarmAcknowledged: true
```

---

#### 6. Check Battery Optimization Settings

**Problem**: Android may kill the app in background, preventing FCM from working.

**Solution**:
1. **Settings → Battery → Battery Optimization**
2. Find **MAB** app
3. Select **"Don't optimize"**

**Or in Battery Saver settings**:
1. **Settings → Battery → Battery Saver**
2. Turn **OFF** battery saver (or add MAB to exceptions)

---

#### 7. Verify Cloud Function is Running

**Check logs**:
```powershell
firebase functions:log --only mqttAlarmMonitor --follow
```

**Expected output when alarm triggers**:
```
📨 Received alarm message on topic: topic/E86BEAD0BD78/alarm
📊 Parsed sensor data:
   Humidity: 75.0% (below 80%)
   Temperature: 31.0°C (above 30°C)
🚨 Alarm triggered for: humidity, temperature
📝 Found device document with userId: abc123
📱 Found FCM token: dABC123...xyz
✅ FCM sent successfully
```

**If you see errors**:
- "Device document not found" → Check device exists in Firestore
- "No userId in device document" → Update device with userId
- "No FCM token found" → Check users/{userId}/fcmToken

---

#### 8. Test Audio System Directly

**Option A: Test from Settings Page**

1. Open the app
2. Go to **Profile/Settings** page
3. Look for **"🧪 Test Alarm Sound"** option
4. Tap to test

**Expected result**:
- Should hear beep sound
- Should feel vibration
- Check debug console for logs

**Option B: Test from Alarm Test Page**

```dart
// In your app, navigate to AlarmTestPage
// Or create a button that calls:
await AlarmService().startAlarm(
  'Test alarm',
  deviceId: 'TEST_DEVICE',
  deviceName: 'Test Device'
);
```

**Expected console logs**:
```
🚨 ALARM STARTED: Test alarm
🆔 Device ID: TEST_DEVICE
🔊 Starting alarm audio system...
🗣️ TTS announcement sent
🔔 Timer tick - playing beep...
🔊 _playBeep() called
🎵 Playing beep.mp3 using audioplayers...
✅ Audio file played successfully
📳 Triggering haptic feedback...
```

**If you see errors**:
```
❌ Audio playback FAILED: ...
🔄 Trying fallback methods...
📞 Invoking platform channel "playBeep"...
```

This means the audio file isn't playing. Check steps 9-11.

---

#### 9. Verify Audio File Exists

**Check file exists**:
```powershell
Test-Path d:\fyp\Backup\MAB\assets\sounds\beep.mp3
# Should return: True
```

**Check file size**:
```powershell
(Get-Item d:\fyp\Backup\MAB\assets\sounds\beep.mp3).Length
# Should be > 0 bytes
```

**If file is missing**:
You'll need to add a beep sound file:
1. Find a short beep sound (MP3, ~0.5 seconds)
2. Save as `assets/sounds/beep.mp3`
3. Rebuild the app

---

#### 10. Check pubspec.yaml Asset Configuration

**File**: `pubspec.yaml`

**Verify this section exists**:
```yaml
flutter:
  uses-material-design: true
  
  assets:
    - assets/icons/
    - assets/sounds/  # ← Must exist
```

**If missing**: Add it and run:
```powershell
flutter clean
flutter pub get
flutter run --release
```

---

#### 11. Check Android Notification Channel

The app should create a notification channel with sound enabled.

**Code location**: `lib/shared/services/fcm_service.dart`

**Verify this code exists**:
```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'alarm_channel',
  'Alarm Notifications',
  description: 'Critical sensor alarms requiring immediate attention',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('beep'), // ← Must have sound
  enableVibration: true,
  enableLights: true,
);
```

**If `playSound: false` or `sound:` is commented out**:
- This prevents notification sound from playing
- Fix the code and rebuild

---

#### 12. Check App State When Alarm Triggers

FCM behavior differs based on app state:

| App State | Notification Shown | Sound Should Play | onMessage Handler Runs |
|-----------|-------------------|-------------------|------------------------|
| **Foreground** | ❌ (we show custom UI) | ✅ Via AlarmService | ✅ Yes |
| **Background** | ✅ System notification | ✅ Via notification channel | ✅ Yes |
| **Terminated** | ✅ System notification | ✅ Via notification channel | ❌ No (until tap) |

**Test all 3 states**:

**A. Foreground Test**:
1. Open app, stay on main screen
2. Trigger alarm (see step 13)
3. Should hear beep every 2 seconds
4. Should see notification

**B. Background Test**:
1. Open app, press Home button
2. Trigger alarm
3. Should see notification
4. Should hear system notification sound
5. Tap notification → App opens, continuous beep starts

**C. Terminated Test**:
1. Force close app (swipe away from recents)
2. Trigger alarm
3. Should see notification
4. Should hear system notification sound
5. Tap notification → App opens, continuous beep starts

**If only foreground works**: Issue with FCM background handling
**If only background works**: Issue with AlarmService audio playback

---

#### 13. Test Alarm Trigger Methods

You have 4 ways to trigger an alarm:

**Method 1: Cloud Function Endpoint** (Easiest without mosquitto)
```powershell
Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"deviceId":"E86BEAD0BD78","payload":"[75.0,45.0,31.0,25.0,n]"}'
```

**Method 2: MQTT (if mosquitto installed)**
```powershell
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 --insecure `
  -t "topic/E86BEAD0BD78/alarm" `
  -m "[75.0,45.0,31.0,25.0,n]"
```

**Method 3: ESP32 Code Modification**
```cpp
// In esp32/main.cpp loop()
float temperature = 31.5;  // Force high temp
float humidity = 75.0;     // Force low humidity
```

**Method 4: Physical Sensor Manipulation**
- Heat DHT22 sensor above 30°C (hair dryer, hand heat)

---

#### 14. Check for Multiple App Instances

**Problem**: Installing multiple versions of the app can cause FCM conflicts.

**Solution**:
```powershell
# Uninstall all versions
flutter clean
adb uninstall com.example.flutter_application_final

# Rebuild and install fresh
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

#### 15. Check Logs for Specific Errors

**Enable verbose logging**:

**In Flutter** (`lib/shared/services/alarm_service.dart`):
```dart
// Already has debugPrint statements
// Check console output
```

**In Android** (`android/app/src/main/kotlin/.../MainActivity.kt`):
```kotlin
// Already has Log.d statements
// Use logcat to view
```

**View Android logs** (if you have adb):
```powershell
adb logcat | Select-String -Pattern "AlarmService"
```

**Look for these specific errors**:

**Error 1: Volume Muted**
```
❌ ALARM VOLUME IS MUTED! User won't hear anything!
```
**Fix**: Turn up alarm volume in phone settings

**Error 2: ToneGenerator Failed**
```
❌ ToneGenerator FAILED: ...
```
**Fix**: May be a device compatibility issue, fallback should use audioplayers

**Error 3: Audio File Not Found**
```
❌ Audio playback FAILED: Unable to load asset
```
**Fix**: Run `flutter clean && flutter pub get`, verify assets in pubspec.yaml

**Error 4: FCM Token Not Saved**
```
❌ Failed to save FCM token to Firestore
```
**Fix**: Check Firestore permissions, ensure user is logged in

---

### 🎯 Most Likely Solutions (Ordered by Probability)

Based on common issues, try these first:

1. **🔊 Turn up Alarm Volume** (70% of cases)
   - Settings → Sound → Alarm Volume → MAX
   
2. **📱 Use Release Mode** (15% of cases)
   - `flutter run --release`
   
3. **🔋 Disable Battery Optimization** (10% of cases)
   - Settings → Battery → Don't optimize MAB
   
4. **🔔 Check Notification Permissions** (5% of cases)
   - Settings → Apps → MAB → Notifications → ON

---

### 🧪 Quick Debug Script

Save this as `debug_alarm.ps1`:

```powershell
Write-Host "🔍 MAB Alarm Sound Debugging Script" -ForegroundColor Cyan

# 1. Check audio file exists
Write-Host "`n1️⃣ Checking audio file..." -ForegroundColor Yellow
if (Test-Path "assets/sounds/beep.mp3") {
    $size = (Get-Item "assets/sounds/beep.mp3").Length
    Write-Host "   ✅ beep.mp3 exists ($size bytes)" -ForegroundColor Green
} else {
    Write-Host "   ❌ beep.mp3 NOT FOUND!" -ForegroundColor Red
}

# 2. Check pubspec.yaml
Write-Host "`n2️⃣ Checking pubspec.yaml..." -ForegroundColor Yellow
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match "assets/sounds/") {
    Write-Host "   ✅ assets/sounds/ configured" -ForegroundColor Green
} else {
    Write-Host "   ❌ assets/sounds/ NOT in pubspec!" -ForegroundColor Red
}

# 3. Check if app is running
Write-Host "`n3️⃣ Checking if app is running..." -ForegroundColor Yellow
$processes = Get-Process | Where-Object {$_.ProcessName -like "*flutter*"}
if ($processes) {
    Write-Host "   ✅ Flutter process found" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ No Flutter process (app may not be running)" -ForegroundColor Yellow
}

# 4. Trigger test alarm via Cloud Function
Write-Host "`n4️⃣ Triggering test alarm..." -ForegroundColor Yellow
Write-Host "   Sending alarm to Cloud Function..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" `
        -Method POST `
        -Headers @{"Content-Type"="application/json"} `
        -Body '{"deviceId":"E86BEAD0BD78","payload":"[75.0,45.0,31.0,25.0,n]"}' `
        -TimeoutSec 10
    
    Write-Host "   ✅ Alarm triggered (HTTP $($response.StatusCode))" -ForegroundColor Green
    Write-Host "`n   📱 CHECK YOUR PHONE NOW!" -ForegroundColor Magenta
    Write-Host "   Expected: Notification + Sound + Vibration" -ForegroundColor Yellow
} catch {
    Write-Host "   ❌ Failed to trigger alarm: $_" -ForegroundColor Red
}

Write-Host "`n✅ Debug complete!" -ForegroundColor Green
Write-Host "`nIf you didn't hear sound:" -ForegroundColor Yellow
Write-Host "1. Check phone Alarm Volume (Settings → Sound)" -ForegroundColor White
Write-Host "2. Check app is in release mode (flutter run --release)" -ForegroundColor White
Write-Host "3. Check notification permissions" -ForegroundColor White
Write-Host "4. Check Cloud Function logs: firebase functions:log" -ForegroundColor White
```

**Run with**:
```powershell
cd d:\fyp\Backup\MAB
.\debug_alarm.ps1
```

---

### 📋 Checklist Summary

Copy this and check off as you go:

```
Phone Settings:
[ ] Alarm volume turned up (not media volume)
[ ] Notifications enabled for MAB app
[ ] Battery optimization disabled for MAB
[ ] Phone not on silent/DND mode

App Configuration:
[ ] Running in release mode (flutter run --release)
[ ] assets/sounds/beep.mp3 file exists
[ ] pubspec.yaml has "assets/sounds/" entry
[ ] App has notification permission (first launch prompt)

Firebase Setup:
[ ] FCM token exists in Firestore users/{uid}/fcmToken
[ ] Device document has correct userId field
[ ] Cloud Function is deployed and running
[ ] No errors in Cloud Function logs

Testing:
[ ] Tested with Cloud Function endpoint (Method 1)
[ ] Tested in foreground (app open)
[ ] Tested in background (app minimized)
[ ] Tested when terminated (app force closed)
[ ] Heard beep sound or vibration
```

---

### 🆘 Still Not Working?

If you've tried everything above and still no sound:

1. **Capture logs and share**:
   ```powershell
   # Cloud Function logs
   firebase functions:log --only mqttAlarmMonitor > cloud_logs.txt
   
   # Flutter debug logs
   flutter run --release > flutter_logs.txt
   ```

2. **Check specific error messages** in the logs for:
   - "❌ ALARM VOLUME IS MUTED"
   - "❌ Audio playback FAILED"
   - "❌ Failed to save FCM token"
   - "No FCM token found"

3. **Device-specific issues**:
   - Some phones (Xiaomi, Huawei, Oppo) have aggressive battery management
   - May need manufacturer-specific settings (e.g., "Autostart" permission)
   - Google "FCM not working on [your phone brand]"

4. **Try a different test device** if available to rule out device-specific issues

---

### 📝 Common Solutions Recap

| Symptom | Solution |
|---------|----------|
| No notification at all | Check FCM token in Firestore, verify userId in device doc |
| Notification appears but no sound | Check Alarm volume, verify notification channel settings |
| Sound only works in foreground | Release mode required for background FCM |
| Notification delayed >30 seconds | Battery optimization, check Cloud Function timeout |
| Multiple duplicate notifications | Check lastAlarm deduplication in Cloud Function |
| App crashes when alarm triggers | Check assets/sounds/beep.mp3 exists, check logs |

---

**Need more help?** Share these details:
- Phone model and Android version
- App mode (debug/release)
- Specific error messages from logs
- Which alarm trigger method you used
- What happens (or doesn't happen) when you test
