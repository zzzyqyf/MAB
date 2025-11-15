# Quick Testing Guide - Alarm System

## 🚀 Quick Start

### 1. Build and Run
```bash
cd "D:\fyp\Backup\MAB"
flutter clean
flutter pub get
flutter run
```

### 2. Login
- Open app
- Login with your credentials
- FCM token will auto-save to Firestore

### 3. Verify Setup
Check Firestore console:
```
users/{your_user_id}:
  fcmToken: "eXxXx..." ✅
  
devices/{ESP32_001}:
  userId: "your_user_id" ✅
  alarmActive: false ✅
  alarmAcknowledged: true ✅
```

---

## 🧪 Test Scenarios

### Test 1: Basic Alarm (2 minutes)
```bash
# Trigger test alarm via MQTT
mosquitto_pub -h api.milloserver.uk -p 8883 \
  -u zhangyifei -P 123456 \
  --capath /etc/ssl/certs \
  -t "topic/ESP32_001/alarm" \
  -m "[75.0,45.0,31.0,25.0,n]"
```

**Expected**:
1. Cloud Function receives MQTT ✅
2. FCM sent to your phone ✅
3. Notification appears ✅
4. Alarm sound plays (beep every 2 seconds) ✅
5. Phone vibrates ✅

**Check Logs**:
```bash
# Cloud Function
firebase functions:log --only alarmMonitor

# Flutter (if connected)
adb logcat | grep -E "FCM|ALARM"
```

### Test 2: Dismiss (1 minute)
1. While alarm is playing, tap **"Dismiss"** on notification
2. Alarm should stop immediately
3. Check Firestore:
   ```
   devices/ESP32_001:
     alarmActive: false
     alarmAcknowledged: true
     acknowledgedAt: [timestamp]
   ```

### Test 3: Snooze 1 Minute (2 minutes)
1. Trigger alarm again (use MQTT command above)
2. Tap **"Snooze"** on notification
3. Dialog appears with 10 options
4. Select **"1 minute"**
5. Alarm stops
6. Check Firestore:
   ```
   devices/ESP32_001:
     snoozeUntil: [now + 1 minute]
     snoozedAt: [timestamp]
   ```
7. Wait 1 minute
8. Reminder notification should appear: "⏰ Snooze Reminder: ..."
9. Tap reminder → app opens

### Test 4: Snooze with Fixed Sensor (3 minutes)
1. Trigger alarm
2. Snooze for 1 minute
3. While snoozed, "fix" the sensor (don't publish alarm topic)
4. Wait 1 minute for reminder
5. Reminder shows
6. Tap reminder
7. **Expected**: No alarm plays (sensor is now good)

### Test 5: Multiple Devices (5 minutes)
**Setup**: Create second device in Firestore
```javascript
devices/ESP32_002:
  id: "ESP32_002"
  name: "Mushroom Tent B"
  userId: "your_user_id"
  ...
```

**Test**:
1. Trigger alarm on Device A:
   ```bash
   mosquitto_pub ... -t "topic/ESP32_001/alarm" ...
   ```
2. Trigger alarm on Device B:
   ```bash
   mosquitto_pub ... -t "topic/ESP32_002/alarm" ...
   ```
3. Both alarms should play
4. Dismiss Device A → only A stops
5. Device B continues playing
6. Snooze Device B → B stops

---

## 🔍 Debug Checklist

### FCM Not Received
- [ ] User logged in?
  ```dart
  print(FirebaseAuth.instance.currentUser?.uid);
  ```
- [ ] FCM token in Firestore?
  ```bash
  # Check Firebase console
  users/{userId}/fcmToken
  ```
- [ ] Notification permission granted?
  ```bash
  # Android: Settings → Apps → MAB → Notifications → Allowed
  ```
- [ ] Cloud Function running?
  ```bash
  firebase functions:log
  ```

### Alarm Not Playing
- [ ] beep.mp3 exists?
  ```bash
  ls assets/sounds/beep.mp3
  ```
- [ ] Volume up?
  ```bash
  # Check phone volume (alarm channel)
  ```
- [ ] App in foreground?
  ```bash
  # Foreground messages should trigger immediately
  ```

### Snooze Dialog Not Showing
- [ ] Context set in MyApp?
  ```dart
  // In main.dart
  FcmService().setContext(context);
  ```
- [ ] Build with latest code?
  ```bash
  flutter clean && flutter pub get && flutter run
  ```

### Reminder Not Showing
- [ ] Timezone initialized?
  ```dart
  // In main.dart
  tz.initializeTimeZones();
  ```
- [ ] Notification channel created?
  ```bash
  adb shell dumpsys notification_listener
  ```
- [ ] Battery optimization disabled?
  ```bash
  # Settings → Battery → MAB → Don't optimize
  ```

### Firestore Update Fails
- [ ] Device ID available?
  ```dart
  print(AlarmService().currentDeviceId);
  ```
- [ ] Security rules correct?
  ```javascript
  match /devices/{deviceId} {
    allow read, write: if request.auth.uid == resource.data.userId;
  }
  ```

---

## 📊 Expected Timings

| Action | Expected Time |
|--------|---------------|
| ESP32 → Cloud Function | 1-3 seconds |
| Cloud Function → FCM | 1-3 seconds |
| FCM → Flutter | 1-3 seconds |
| Flutter → Alarm Play | <500ms |
| **Total Alarm Latency** | **3-10 seconds** |
| Dismiss → Firestore Update | 500-1000ms |
| Snooze → Schedule Reminder | <2 seconds |

---

## 🎯 Success Criteria

### Must Pass
- ✅ Alarm plays within 10 seconds of MQTT publish
- ✅ Dismiss stops alarm and updates Firestore
- ✅ Snooze shows picker dialog
- ✅ Reminder shows after snooze period
- ✅ Multiple devices work independently
- ✅ App closed: notifications still show

### Nice to Have
- ✅ Alarm latency < 5 seconds
- ✅ Firestore update < 1 second
- ✅ Smooth UI transitions
- ✅ No crashes or errors

---

## 🛠️ Quick Fixes

### Reset Alarm State
```javascript
// In Firebase console
devices/ESP32_001:
  alarmActive: false
  alarmAcknowledged: true
  snoozeUntil: null
```

### Clear Notifications
```bash
adb shell pm clear com.example.flutter_application_final
```

### Restart Cloud Function
```bash
firebase deploy --only functions
```

### Reinstall App
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📱 Testing on Real ESP32

### 1. Flash ESP32
```bash
cd esp32
pio run --target upload

# Or use Arduino IDE
# Open main.cpp and upload
```

### 2. Monitor Serial
```bash
pio device monitor --baud 115200

# Look for:
# ✅ WiFi connected
# ✅ MQTT connected
# 📨 Publishing alarm: [75.0,45.0,31.0,25.0,n]
```

### 3. Trigger Real Alarm
Adjust sensor readings in code:
```cpp
// In esp32/main.cpp - for testing
float humidity = 75.0; // Below 80% → ALARM
float temperature = 31.0; // Above 30°C → ALARM
```

### 4. Verify Flow
1. ESP32 detects out of range
2. Publishes to alarm topic
3. Cloud Function receives
4. FCM sent
5. Phone receives notification
6. Alarm plays

---

## 📈 Performance Monitoring

### Firebase Console
1. **Functions** → Usage
   - Check invocation count
   - Monitor execution time
   - Verify $0 cost

2. **Firestore** → Usage
   - Check read/write counts
   - Verify within free tier

3. **Cloud Messaging** → Reports
   - Check delivery rate
   - Monitor send success

### App Logs
```bash
# Watch real-time logs
adb logcat -s flutter

# Filter for alarm
adb logcat | grep -i alarm

# Filter for FCM
adb logcat | grep -i fcm
```

---

## 🎉 Ready to Test!

**Estimated Testing Time**: 15-30 minutes

**Steps**:
1. Build and run app (5 min)
2. Test basic alarm (2 min)
3. Test dismiss (1 min)
4. Test snooze (2 min)
5. Test multiple devices (5 min)
6. Test with real ESP32 (10 min)

**Total**: ~25 minutes for complete testing

---

**Last Updated**: Phase 7 Complete  
**Next**: Phase 8 - End-to-End Testing  
**Status**: Ready for Testing! 🚀
