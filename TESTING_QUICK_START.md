# Quick Start - Test Your Alarm System NOW

## ⚡ Fastest Way to Test (5 minutes)

### Option 1: Test Without ESP32 (MQTT Simulation)

**1. Install Mosquitto Client** (if not already installed):
   - Download from: https://mosquitto.org/download/
   - Or use Chocolatey: `choco install mosquitto`

**2. Trigger Test Alarm**:
```powershell
# Open PowerShell and run:
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --insecure `
  -t "topic/ESP32_001/alarm" `
  -m "[75.0,45.0,31.0,25.0,n]"
```

**3. Watch Logs**:
```bash
# In another terminal:
firebase functions:log --only mqttAlarmMonitor
```

**4. Check Your Phone**:
- Open Flutter app (make sure you're logged in)
- Within 10 seconds: notification + alarm sound!
- Test "Dismiss" and "Snooze" buttons

---

### Option 2: Test Cloud Function Directly

**1. Use cURL** (Windows PowerShell):
```powershell
Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"deviceId":"ESP32_001","payload":"[75.0,45.0,31.0,25.0,n]"}'
```

**2. Check Response**:
```json
{
  "success": true,
  "message": "Test alarm processed"
}
```

**3. Check Phone**: Notification should appear!

---

### Option 3: Test with Real ESP32

**1. Flash ESP32**:
```bash
cd esp32
pio run --target upload
pio device monitor --baud 115200
```

**2. Verify Connection**:
```
✅ WiFi connected
✅ MQTT connected
📤 Publishing sensor data...
```

**3. Heat the Sensor**:
- Place DHT22 near heat source
- Watch serial output: "🚨 ALARM TRIGGERED!"
- Check phone for notification

---

## 🔍 Quick Checks

### Is Cloud Function Running?
```bash
firebase functions:log --only mqttAlarmMonitor
```
**Look for**: `✅ MQTT connected`

### Is Keep-Alive Working?
```bash
firebase functions:log --only keepAlive
```
**Look for**: `🔄 Keep-alive ping` (appears every 5 minutes)

### Is FCM Token Saved?
1. Go to: https://console.firebase.google.com/project/mab-fyp/firestore
2. Navigate to: `users/{your_user_id}`
3. Check: `fcmToken` field exists ✅

### Is Device Document Ready?
Navigate to: `devices/ESP32_001`
```
id: "ESP32_001"
userId: "YOUR_USER_ID"  ← Must match!
alarmActive: false
```

---

## ✅ Expected Results

### Successful Test Shows:
1. ✅ Cloud Function receives message
2. ✅ FCM notification sent
3. ✅ Phone notification appears (5-10 sec)
4. ✅ Alarm sound plays (beep beep beep)
5. ✅ Dismiss button stops alarm
6. ✅ Snooze button shows picker
7. ✅ Firestore updated with alarm status

### Troubleshooting:
- **No notification**: Check FCM token in Firestore
- **No alarm sound**: Check app permissions
- **Cloud Function error**: Check logs with `firebase functions:log`

---

## 📊 System Status

### Deployed Functions:
- ✅ `mqttAlarmMonitor` - Main alarm handler
- ✅ `testAlarm` - Manual test endpoint  
- ✅ `keepAlive` - Runs every 5 minutes

### Function URLs:
- Main: https://us-central1-mab-fyp.cloudfunctions.net/mqttAlarmMonitor
- Test: https://us-central1-mab-fyp.cloudfunctions.net/testAlarm

### MQTT Settings:
- Broker: api.milloserver.uk:8883
- Topic: `topic/+/alarm`
- Auth: zhangyifei / 123456

---

## 🎯 Next Steps

After basic test works:
1. Read full guide: `END_TO_END_TESTING_GUIDE.md`
2. Test all features (dismiss, snooze, modes)
3. Test with multiple devices
4. Monitor costs (should be $0)

---

**Need Help?** Check `END_TO_END_TESTING_GUIDE.md` for detailed troubleshooting.
