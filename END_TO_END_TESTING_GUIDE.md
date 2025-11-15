# End-to-End Testing Guide - MAB Alarm System

## Overview
This guide will walk you through complete end-to-end testing of the alarm system, from ESP32 sensor detection to Flutter app notification.

---

## ✅ Step 1: Keep-Alive Setup (AUTOMATED)

**Status**: ✅ Deployed automatically

The `keepAlive` Cloud Function runs every 5 minutes to maintain the MQTT connection.

**Verify it's working**:
```bash
# Check logs
firebase functions:log --only keepAlive

# Look for: "🔄 Keep-alive ping - maintaining MQTT connection"
```

---

## 📱 Step 2: Verify Flutter App Setup

### 2.1 Build and Install App

```bash
# Clean build
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# Or run in debug mode
flutter run
```

### 2.2 Login and Check FCM Token

1. **Open the app** on your phone
2. **Login** with your credentials
3. **Check Firestore** for FCM token:
   - Go to: https://console.firebase.google.com/project/mab-fyp/firestore
   - Navigate to: `users/{your_user_id}`
   - Verify: `fcmToken` field exists

**Expected**:
```
users/YOUR_USER_ID:
  email: "your@email.com"
  fcmToken: "eXxXx..." ✅
  fcmTokenUpdatedAt: [timestamp]
```

### 2.3 Check Device Document

Verify your device exists in Firestore:

```
devices/ESP32_001:  (or your ESP32 MAC address)
  id: "ESP32_001"
  name: "Mushroom Tent A"
  userId: "YOUR_USER_ID"  ← Must match your logged-in user
  mqttId: "ESP32_001"
  mode: "n"
  alarmActive: false
  alarmAcknowledged: true
  snoozeUntil: null
```

**If device doesn't exist, create it manually**:
1. Go to Firestore console
2. Click "+ Start collection" or navigate to `devices`
3. Add document with ID: `ESP32_001` (or your ESP32 MAC)
4. Add all fields shown above
5. **Important**: Set `userId` to your actual user ID!

---

## 🔧 Step 3: Test with MQTT (No ESP32 Required)

This tests the Cloud Function → FCM → Flutter flow without needing ESP32 hardware.

### 3.1 Trigger Alarm via MQTT

Open PowerShell and run:

```powershell
# Install mosquitto-clients if not installed
# Download from: https://mosquitto.org/download/

# Publish test alarm
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath "C:\Program Files\OpenSSL\certs" `
  -t "topic/ESP32_001/alarm" `
  -m "[75.0,45.0,31.0,25.0,n]"
```

**Note**: Adjust `--capath` to your system's certificate location, or use `--insecure` for testing:
```powershell
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --insecure `
  -t "topic/ESP32_001/alarm" `
  -m "[75.0,45.0,31.0,25.0,n]"
```

### 3.2 Watch Cloud Function Logs

In another terminal:

```bash
firebase functions:log --only mqttAlarmMonitor --follow
```

**Expected logs**:
```
🔗 Connecting to MQTT broker...
✅ MQTT connected
📡 Subscribed to: topic/+/alarm
📨 Received alarm message
   Topic: topic/ESP32_001/alarm
   Payload: [75.0,45.0,31.0,25.0,n]
📊 Parsed sensor data:
   Humidity: 75.0% (Threshold: 80-85%)
   Temperature: 31.0°C (Threshold: <30°C)
🚨 Alarm triggered for: humidity, temperature
📝 Querying device: ESP32_001
✅ Device found, userId: YOUR_USER_ID
📝 Querying user FCM token
✅ FCM token found
📤 Sending FCM notification
✅ FCM sent successfully
```

### 3.3 Check Phone Notification

Within 5-10 seconds, you should:
1. **See notification** on your phone: "🚨 Sensor Alert: Mushroom Tent A"
2. **Hear alarm sound** (beep every 2 seconds)
3. **Feel vibration**

### 3.4 Test Dismiss

1. Tap **"Dismiss"** button on notification
2. Alarm should **stop immediately**
3. Check Firestore:
   ```
   devices/ESP32_001:
     alarmActive: false
     alarmAcknowledged: true
     acknowledgedAt: [timestamp]
   ```

### 3.5 Test Snooze

1. Trigger alarm again (run mosquitto_pub command again)
2. Tap **"Snooze"** button
3. Select **"1 minute"** from dialog
4. Alarm should **stop**
5. Check Firestore:
   ```
   devices/ESP32_001:
     snoozeUntil: [now + 1 minute]
     snoozedAt: [timestamp]
   ```
6. **Wait 1 minute**
7. Reminder notification should appear: "⏰ Snooze Reminder: Mushroom Tent A"

---

## 🤖 Step 4: Test with Real ESP32

### 4.1 Prepare ESP32 Code

Navigate to your ESP32 code directory and verify settings:

```cpp
// esp32/main.cpp

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT settings
const char* mqtt_server = "api.milloserver.uk";
const int mqtt_port = 8883;
const char* mqtt_user = "zhangyifei";
const char* mqtt_password = "123456";

// Device ID (use your ESP32 MAC address or custom ID)
String deviceId = "ESP32_001";  // Change to match Firestore device ID
```

### 4.2 Flash ESP32

**Using PlatformIO**:
```bash
cd esp32
pio run --target upload
pio device monitor --baud 115200
```

**Using Arduino IDE**:
1. Open `esp32/main.cpp`
2. Select board: ESP32 Dev Module
3. Select port: COMX
4. Click Upload
5. Open Serial Monitor (115200 baud)

### 4.3 Monitor Serial Output

**Expected output**:
```
🚀 Starting ESP32...
📡 Connecting to WiFi...
✅ WiFi connected
📡 IP: 192.168.1.100
🔗 Connecting to MQTT...
✅ MQTT connected
📨 Publishing registration...
✅ Registered device: ESP32_001

--- Sensor loop ---
🌡️ Temperature: 28.5°C
💧 Humidity: 82.3%
💦 Water: 55.2%
💡 Light: 42
📊 Mode: n (Normal)
📤 Publishing: [82.3,42.0,28.5,55.2,n]
✅ Published to: topic/ESP32_001
```

### 4.4 Trigger Real Alarm

**Method 1: Modify Thresholds in Code (for testing)**
```cpp
// Temporarily adjust values for testing
float humidity = 75.0;  // Below 80% → ALARM
float temperature = 31.0;  // Above 30°C → ALARM
```

Re-upload code and watch serial monitor for:
```
🚨 ALARM DETECTED!
📊 Humidity: 75.0% (out of range: 80-85%)
📊 Temperature: 31.0°C (above max: 30°C)
📤 Publishing alarm: [75.0,42.0,31.0,55.2,n]
✅ Alarm published to: topic/ESP32_001/alarm
```

**Method 2: Heat Sensor (real test)**
- Place DHT22 sensor near heat source
- Temperature will rise above 30°C
- Alarm will trigger automatically

**Method 3: Simulate Low Humidity**
- Place DHT22 in dry environment
- Humidity will drop below 80%
- Alarm will trigger

### 4.5 Verify Complete Flow

When alarm triggers on ESP32:

1. **Serial Monitor** shows alarm published ✅
2. **Cloud Function logs** show alarm received ✅
3. **Phone notification** appears within 5-10 seconds ✅
4. **Alarm sound** plays (beep beep beep) ✅
5. **Dismiss** or **Snooze** works ✅

---

## 🧪 Step 5: Advanced Testing

### 5.1 Test Multiple Devices

If you have multiple ESP32s:

1. Flash each with different `deviceId`
2. Create Firestore document for each
3. Trigger alarms on both
4. Verify independent operation
5. Dismiss one, snooze the other

### 5.2 Test App States

**Foreground Test**:
- App open and visible
- Trigger alarm
- Should play immediately

**Background Test**:
- Minimize app (home button)
- Trigger alarm
- Notification appears
- Tap notification → app opens → alarm plays

**Terminated Test**:
- Force close app (swipe away from recent apps)
- Trigger alarm
- Notification appears
- Tap notification → app launches → alarm plays

### 5.3 Test Network Conditions

**WiFi → Mobile Data**:
- Start with WiFi
- Trigger alarm
- Switch to mobile data
- Verify still works

**Connection Loss**:
- Disconnect internet
- Trigger alarm (ESP32 will queue message)
- Reconnect
- Message should be delivered

### 5.4 Test Mode Changes

**Normal → Pinning**:
1. In Flutter app, switch device to Pinning mode (1 hour)
2. Check Firestore: `mode: "p"`
3. ESP32 should receive mode change: `topic/ESP32_001/mode/set` = `p,3600`
4. ESP32 publishes countdown every 60 seconds
5. Humidity threshold changes to 90-95%

**Pinning → Normal**:
1. Wait for timer to expire or manually switch back
2. Check Firestore: `mode: "n"`
3. Humidity threshold reverts to 80-85%

---

## 📊 Step 6: Monitor Costs

### 6.1 Check Firebase Usage

1. Go to: https://console.firebase.google.com/project/mab-fyp/usage
2. Click **"Usage and billing"**
3. Check each service:

**Cloud Functions**:
- Invocations: Should be ~8,000-10,000/month
- Free tier: 125,000/month
- Usage: ~6-8% ✅

**Firestore**:
- Reads: ~2,000-5,000/month
- Writes: ~1,000-3,000/month
- Free tier: 50K reads, 20K writes per day ✅

**Cloud Messaging (FCM)**:
- Messages: ~100-500/month
- Free tier: Unlimited ✅

### 6.2 Set Budget Alerts

1. Go to **Settings** → **Usage and billing**
2. Click **"Details & settings"**
3. Set spending limit: **$5/month**
4. Set alerts at: 50%, 90%, 100%

**Expected monthly cost**: **$0** ✅

---

## ✅ Success Criteria

Check all items to confirm system is working:

### Infrastructure
- [ ] Cloud Functions deployed
- [ ] Keep-alive function running every 5 minutes
- [ ] MQTT connection stable
- [ ] Firestore documents exist

### ESP32
- [ ] WiFi connected
- [ ] MQTT connected
- [ ] Publishing sensor data every 5 seconds
- [ ] Alarm detection working
- [ ] Alarm publishing working

### Cloud Function
- [ ] Receiving MQTT messages
- [ ] Parsing sensor data correctly
- [ ] Checking thresholds
- [ ] Querying Firestore
- [ ] Sending FCM
- [ ] Deduplication working

### Flutter App
- [ ] FCM token saved to Firestore
- [ ] Receiving notifications (foreground/background/terminated)
- [ ] Alarm sound playing
- [ ] Dismiss working
- [ ] Snooze working
- [ ] Firestore updates working

### User Experience
- [ ] Alarm triggers within 10 seconds
- [ ] Sound is loud and clear
- [ ] Vibration works
- [ ] Dismiss stops alarm immediately
- [ ] Snooze reminder appears on time
- [ ] No duplicate notifications

### Cost
- [ ] Firebase usage within free tier
- [ ] No unexpected charges
- [ ] Budget alerts configured

---

## 🐛 Troubleshooting

### Issue: No notification received

**Check**:
1. FCM token in Firestore: `users/{userId}/fcmToken`
2. Device userId matches logged-in user
3. Cloud Function logs for errors
4. Phone notification permissions enabled
5. App not battery optimized

**Solution**:
```bash
# Check logs
firebase functions:log --only mqttAlarmMonitor

# Verify MQTT
mosquitto_pub --help

# Test FCM manually
curl -X POST https://us-central1-mab-fyp.cloudfunctions.net/testAlarm \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "ESP32_001", "payload": "[75.0,45.0,31.0,25.0,n]"}'
```

### Issue: ESP32 not connecting to MQTT

**Check**:
1. WiFi credentials correct
2. Internet connection stable
3. MQTT broker reachable
4. Certificate validation (try `--insecure` for testing)

**Solution**:
```cpp
// In ESP32 code, add debug output
Serial.println("WiFi connected: " + WiFi.localIP().toString());
Serial.println("MQTT connecting to: " + String(mqtt_server));
```

### Issue: Alarm not stopping after dismiss

**Check**:
1. Device ID passed to AlarmService
2. Firestore update succeeding
3. Network connection stable

**Solution**:
Check Flutter logs:
```bash
adb logcat | grep -E "FCM|ALARM"
```

### Issue: Cloud Function cold starts

**Check**:
```bash
firebase functions:log --only keepAlive
```

Should see: "🔄 Keep-alive ping" every 5 minutes

---

## 📝 Test Log Template

Use this template to document your testing:

```
Date: _____________
Tester: _____________

[ ] Step 1: Keep-alive deployed
    Status: _______________
    Notes: _______________

[ ] Step 2: Flutter app verified
    FCM token: _______________
    Device ID: _______________
    Notes: _______________

[ ] Step 3: MQTT test
    Command run: _______________
    Result: _______________
    Notification received: Yes / No
    Time delay: _____ seconds
    Notes: _______________

[ ] Step 4: ESP32 test
    Device ID: _______________
    Sensor readings: _______________
    Alarm triggered: Yes / No
    FCM received: Yes / No
    Notes: _______________

[ ] Step 5: Dismiss test
    Worked: Yes / No
    Firestore updated: Yes / No
    Notes: _______________

[ ] Step 6: Snooze test
    Duration: _______________
    Reminder received: Yes / No
    Notes: _______________

Issues found:
1. _______________
2. _______________

Overall result: PASS / FAIL
```

---

## 🎉 Completion

When all tests pass:
1. ✅ Mark TODO item complete
2. ✅ Document any issues found
3. ✅ Celebrate! The system is working! 🎊

---

**Last Updated**: After Cloud Function deployment
**Next**: Begin Step 2 - Verify Flutter App Setup
