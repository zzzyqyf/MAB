# 🐛 Device Registration Bug Fix

## Problem Identified

**Issue**: ESP32 cannot register device, app waiting forever, no users showing in Firestore

**Root Cause**: MQTT topic mismatch!
- ESP32 was publishing to: `topic/system/devices/register` ❌
- Flutter app listening on: `system/devices/register` ✅

## Solution Applied

### 1. Fixed ESP32 Registration Topic ✅

**File**: `esp32/main.cpp`

**Changed**:
```cpp
// BEFORE (WRONG):
const char* registrationTopic = "topic/system/devices/register";

// AFTER (CORRECT):
const char* registrationTopic = "system/devices/register";
```

### 2. Upload Fixed Code to ESP32

```bash
cd esp32
pio run --target upload
```

**OR** if using Arduino IDE:
1. Open `esp32/main.cpp`
2. Verify change shows: `const char* registrationTopic = "system/devices/register";`
3. Click **Upload** button
4. Open **Serial Monitor** (115200 baud)

## Expected Behavior After Fix

### ESP32 Serial Monitor:
```
✅ WiFi connected!
✅ MQTT connected
📢 Publishing device registration...
✅ Device registration published:
   Topic: system/devices/register
   Payload: {"macAddress":"E8:6B:EA:D0:BD:78","deviceName":"ESP32_D0BD78","timestamp":1234567890}
```

### Flutter App Logs:
```
📡 DeviceRegistrationService: Starting to listen for registrations...
✅ DeviceRegistrationService: Now listening on system/devices/register
📨 DeviceRegistrationService: Received registration message
   MAC: E86BEAD0BD78
   Device Name: ESP32_D0BD78
🔄 RegisterFive: Starting device registration...
✅ Device added: ID=uuid-here, MAC=E86BEAD0BD78
```

### Firestore Console:
Navigate to: https://console.firebase.google.com/project/mab-fyp/firestore

**You should now see**:
```
users/
  {your_user_id}/
    email: "your@email.com"
    fcmToken: "eXxXx..."  (if logged in on phone)
    devices: [
      {
        deviceId: "uuid-generated",
        name: "ESP32_D0BD78",
        mqttId: "E86BEAD0BD78",
        addedAt: "2025-11-12T..."
      }
    ]
```

## Why This Happened

**Context**: Your project uses **two different topic naming schemes**:
1. **Sensor data topics**: `topic/{deviceId}` (with "topic/" prefix)
2. **System topics**: `system/devices/register` (no "topic/" prefix)

The ESP32 code was incorrectly mixing these by adding "topic/" to the system topic.

## Verification Steps

### 1. Test MQTT Manually (Optional)

```powershell
# Publish test registration
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --insecure `
  -t "system/devices/register" `
  -m '{"macAddress":"TEST123456","deviceName":"ESP32_TEST12","timestamp":1234567890}'
```

If app receives this, MQTT is working!

### 2. Check Flutter App Debug Console

Look for:
```
📨 DeviceRegistrationService: Received registration message
```

If you see this, registration is working!

### 3. Try Device Registration Again

1. Open Flutter app
2. Go to "Add Device" page
3. Enter WiFi credentials
4. Connect via BLE
5. Wait on "Waiting for device..." page
6. Should complete within 10-20 seconds ✅

## Additional Fixes (If Still Not Working)

### Issue: "No user document in Firestore"

**Check**:
1. Go to Firebase Console → Firestore
2. Verify `users/{your_uid}` document exists

**If missing, create manually**:
1. In Firestore, click "**+ Start collection**"
2. Collection ID: `users`
3. Document ID: (your Firebase Auth UID)
4. Add fields:
   ```
   email: "your@email.com"
   role: "member"
   createdAt: (timestamp)
   devices: []
   ```

**OR use Debug Page in app**:
1. Open app → Navigate to Debug Page
2. Tap "**Check Firebase**"
3. If user document missing, it will create it automatically

### Issue: "Firebase Rules Blocking"

**Deploy correct rules**:
```bash
cd d:\fyp\Backup\MAB
firebase deploy --only firestore:rules
```

**Rules should allow**:
- Users can read/write their own document
- Users can create user document during signup
- Users can update their devices array

See: `docs/FIRESTORE_SECURITY_RULES.rules`

## Summary

✅ **Fixed**: ESP32 registration topic  
✅ **Action Required**: Upload new code to ESP32  
✅ **Expected Result**: Device registration works within 10-20 seconds  

**Next Steps**:
1. Upload fixed code to ESP32
2. Power cycle ESP32
3. Try registration again in app
4. Check Firestore for user document and devices array

---

**Still having issues?** Check:
1. ESP32 serial monitor for exact topic published
2. Flutter debug console for received messages
3. Firestore security rules are deployed
4. User is logged into the app
