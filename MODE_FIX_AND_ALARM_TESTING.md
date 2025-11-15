# Mode Display Fix + Alarm Testing Guide

## 🐛 Mode Display Issue - FIXED

### Problem
Device cards on the dashboard always showed "Normal Mode" even when ESP32 was in Pinning mode.

### Root Cause
ESP32 was not publishing its initial mode status when connecting to MQTT. The Flutter app had no way to know the current mode until ESP32 received a mode change command.

### Solution Applied
Added initial mode status publication when ESP32 connects to MQTT broker.

**File**: `esp32/main.cpp` (around line 674)

**Added**:
```cpp
// Publish initial mode status: topic/{deviceId}/mode/status
String modeStatusTopic = "topic/" + deviceId + "/mode/status";
char modeChar = (currentMode == PINNING) ? 'p' : 'n';
client.publish(modeStatusTopic.c_str(), String(modeChar).c_str());
Serial.print("📢 Initial mode published: ");
Serial.println(modeChar == 'p' ? "PINNING" : "NORMAL");
```

### To Apply Fix
```bash
cd esp32
pio run --target upload
```

**Expected Serial Output After Fix**:
```
✅ MQTT connected
📬 Subscribed to: topic/E86BEAD0BD78/mode/set
📢 Publishing device registration...
✅ Device registration published
📢 Initial mode published: NORMAL  ← NEW!
📢 Status published: online
```

---

## 📱 Flutter Run Modes

### Debug Mode (for development)
```bash
flutter run
```
**Use for**:
- ✅ Debugging mode display
- ✅ Seeing console logs
- ✅ Hot reload
- ❌ FCM may be unreliable
- ❌ Slower performance

### Release Mode (for testing)
```bash
flutter run --release
```
**Use for**:
- ✅ Testing FCM notifications (more reliable)
- ✅ Testing background processing
- ✅ Production-like performance
- ✅ Real user experience
- ❌ No debug logs
- ❌ No hot reload

### Build APK (for installation)
```bash
flutter build apk --release
```
**Output**: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🚨 Alarm Testing - Quick Start

### Prerequisite Checks

**1. Check Firestore Setup**
- Go to: https://console.firebase.google.com/project/mab-fyp/firestore
- Verify `users/{your_uid}/fcmToken` exists
- Verify `devices/E86BEAD0BD78/userId` matches your user ID

**2. Run App in Release Mode**
```bash
flutter run --release
```

**3. Check App is Logged In**
- Open app
- Verify you're on the dashboard (not login page)

### Test Method 1: MQTT Simulation (Easiest)

**Trigger alarm directly via MQTT:**
```powershell
# Replace E86BEAD0BD78 with your ESP32 MAC address (no colons)
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --insecure `
  -t "topic/E86BEAD0BD78/alarm" `
  -m "[75.0,45.0,31.0,25.0,n]"
```

**Payload Explanation**: `[humidity, light, temp, water, mode]`
- `75.0` = Humidity 75% (below 80% threshold) → ⚠️ ALARM
- `45.0` = Light (not checked)
- `31.0` = Temperature 31°C (above 30°C) → ⚠️ ALARM
- `25.0` = Water 25% (OK)
- `n` = Normal mode

**Expected Result (within 5-10 seconds)**:
1. 🔔 Notification appears on phone
2. 🔊 Alarm sound plays (beep every 2 seconds)
3. 📳 Vibration
4. Two buttons: **Dismiss** | **Snooze**

### Test Method 2: Cloud Function Endpoint

```powershell
Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"deviceId":"E86BEAD0BD78","payload":"[75.0,45.0,31.0,25.0,n]"}'
```

### Test Method 3: Real ESP32

**Upload fixed code first**:
```bash
cd esp32
pio run --target upload
pio device monitor --baud 115200
```

**Option A: Modify Code (for testing)**
```cpp
// In loop(), temporarily override sensor values
float temperature = 31.5;  // Force high temp
float humidity = 75.0;     // Force low humidity
```

**Option B: Physical Manipulation**
- Heat DHT22 sensor (hair dryer, hand)
- Temperature rises above 30°C → Alarm triggers

---

## 🔍 Monitoring & Debugging

### Watch Cloud Function Logs
```bash
firebase functions:log --only mqttAlarmMonitor --follow
```

**Expected logs**:
```
📨 Received alarm message
📊 Parsed sensor data:
   Humidity: 75.0% (below 80%)
   Temperature: 31.0°C (above 30°C)
🚨 Alarm triggered for: humidity, temperature
✅ FCM sent successfully
```

### Watch ESP32 Serial Monitor
```bash
pio device monitor --baud 115200
```

**Expected logs when alarm triggers**:
```
🚨 ALARM ACTIVATED!
Reason: Temperature critical (31.0°C > 30°C); Humidity too low (75.0% < 80%);
📤 Publishing alarm: [75.0,42.0,31.0,55.2,n]
✅ Alarm published to: topic/E86BEAD0BD78/alarm
```

### Watch Flutter Debug Console
```bash
adb logcat | grep -E "FCM|ALARM|MqttManager"
```

**Expected logs**:
```
I/flutter: 📨 MqttManager: Received message on topic/E86BEAD0BD78/alarm
I/flutter: 🔔 FCM: Received alarm notification
I/flutter: 🔊 AlarmService: Starting alarm for device E86BEAD0BD78
```

---

## 🧪 Testing Checklist

### Basic Alarm Flow
- [ ] Trigger alarm (any method)
- [ ] Notification appears within 10 seconds
- [ ] Alarm sound plays (continuous beeping)
- [ ] Vibration works
- [ ] Two buttons visible: Dismiss | Snooze

### Dismiss Function
- [ ] Tap "Dismiss" button
- [ ] Alarm stops immediately
- [ ] Notification disappears
- [ ] Check Firestore: `devices/E86BEAD0BD78/alarmAcknowledged` = true

### Snooze Function
- [ ] Trigger alarm again
- [ ] Tap "Snooze" button
- [ ] Dialog appears with duration options
- [ ] Select "1 minute"
- [ ] Alarm stops
- [ ] Wait 1 minute
- [ ] Reminder notification appears: "⏰ Snooze Reminder"

### Mode Display (After Fix)
- [ ] Device card shows correct mode icon (🌱 Normal / 🍄 Pinning)
- [ ] Mode updates when changed in device page
- [ ] Mode persists after app restart

### Different Alarm Conditions

**Test 1: Humidity Only**
```powershell
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 --insecure `
  -t "topic/E86BEAD0BD78/alarm" `
  -m "[75.0,45.0,28.0,50.0,n]"
```

**Test 2: Temperature Only**
```powershell
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 --insecure `
  -t "topic/E86BEAD0BD78/alarm" `
  -m "[82.0,45.0,31.5,50.0,n]"
```

**Test 3: Water Level Low**
```powershell
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 --insecure `
  -t "topic/E86BEAD0BD78/alarm" `
  -m "[82.0,45.0,28.0,25.0,n]"
```

**Test 4: Pinning Mode (different thresholds)**
```powershell
# In Pinning mode, humidity should be 90-95%
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 --insecure `
  -t "topic/E86BEAD0BD78/alarm" `
  -m "[85.0,45.0,28.0,50.0,p]"
```

---

## 🎯 Success Criteria

### ✅ Alarm System Works If:
1. Notification appears within 10 seconds of trigger
2. Alarm sound plays continuously
3. Dismiss stops alarm and updates Firestore
4. Snooze schedules reminder notification
5. No duplicate notifications for same alarm
6. Works in foreground, background, and terminated states

### ✅ Mode Display Works If:
1. Device card shows "🌱 Normal" or "🍄 Pinning"
2. Mode updates immediately when changed
3. Correct mode shown after ESP32 reconnect
4. Mode persists after app restart

---

## 🐛 Common Issues

### Issue: "No notification received"

**Check**:
1. App is in release mode: `flutter run --release`
2. FCM token exists: `users/{uid}/fcmToken` in Firestore
3. Device document has correct `userId`
4. Phone notifications enabled for app
5. App not battery optimized

**Debug**:
```bash
# Check Cloud Function logs
firebase functions:log --only mqttAlarmMonitor

# Check if FCM token is being sent
# Look for: "✅ FCM token found"
```

### Issue: "Alarm sound not playing"

**Check**:
1. Phone not on silent mode
2. App has audio permissions
3. File `assets/sounds/beep.mp3` exists
4. Volume is turned up

**Debug**:
```bash
adb logcat | grep AlarmService
# Look for: "🔊 AlarmService: Starting alarm"
```

### Issue: "Mode always shows Normal"

**Check**:
1. ESP32 code updated with fix (initial mode publication)
2. ESP32 re-uploaded and running
3. ESP32 connected to MQTT

**Debug**:
```bash
# Check ESP32 serial monitor
# Look for: "📢 Initial mode published: NORMAL"

# Check Flutter logs
adb logcat | grep "Mode updated"
```

---

## 📝 Quick Test Script

Save this as `test_alarm.ps1`:

```powershell
# Quick Alarm Test Script
$ESP32_MAC = "E86BEAD0BD78"  # Replace with your MAC

Write-Host "🚨 Testing alarm system..." -ForegroundColor Yellow

# Test 1: Basic alarm
Write-Host "`n1️⃣ Test 1: Basic alarm (humidity + temp)" -ForegroundColor Cyan
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 --insecure `
  -t "topic/$ESP32_MAC/alarm" `
  -m "[75.0,45.0,31.0,25.0,n]"

Write-Host "   Sent! Check your phone for notification..." -ForegroundColor Green
Write-Host "   Waiting 15 seconds before next test...`n"
Start-Sleep -Seconds 15

# Test 2: Humidity only
Write-Host "2️⃣ Test 2: Humidity alarm only" -ForegroundColor Cyan
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 --insecure `
  -t "topic/$ESP32_MAC/alarm" `
  -m "[75.0,45.0,28.0,50.0,n]"

Write-Host "   Sent! Check your phone for notification..." -ForegroundColor Green
Write-Host "`n✅ Tests complete!" -ForegroundColor Green
Write-Host "   Check Cloud Function logs: firebase functions:log --only mqttAlarmMonitor" -ForegroundColor Yellow
```

Run with:
```powershell
.\test_alarm.ps1
```

---

## 🎉 Final Steps

1. **Fix mode display**:
   ```bash
   cd esp32
   pio run --target upload
   ```

2. **Run app in release mode**:
   ```bash
   flutter run --release
   ```

3. **Test alarm**:
   ```powershell
   mosquitto_pub -h api.milloserver.uk -p 8883 `
     -u zhangyifei -P 123456 --insecure `
     -t "topic/E86BEAD0BD78/alarm" `
     -m "[75.0,45.0,31.0,25.0,n]"
   ```

4. **Verify**:
   - ✅ Notification appears
   - ✅ Alarm plays
   - ✅ Dismiss works
   - ✅ Snooze works
   - ✅ Mode displays correctly

---

**Need help?** Check:
- `END_TO_END_TESTING_GUIDE.md` - Complete testing documentation
- `DEVICE_REGISTRATION_BUG_FIX.md` - Device registration fix
- Cloud Function logs: `firebase functions:log`
- ESP32 serial monitor: `pio device monitor`
