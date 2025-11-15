# Alarm Sound Issue - SOLUTION FOUND! ✅

## 🐛 Problem Identified

**Your device E86BEAD0BD78 doesn't exist in Firestore!**

When the Cloud Function receives the alarm, it looks for the device document to get the userId and send the notification. The logs show:

```
❌ Device E86BEAD0BD78 not found in Firestore
```

Without the device document, the Cloud Function cannot find your FCM token, so **no notification is sent**.

---

## ✅ Solution: Register Device in Firestore

You need to add your ESP32 device to Firestore with your user ID.

### Option 1: Via Flutter App (Easiest)

1. **Open your Flutter app**
2. **Log in** (if not already logged in)
3. **Go to device management page**
4. **Add a new device** with:
   - Device ID: `E86BEAD0BD78`
   - Device Name: `Mushroom Tent A` (or any name)
   - Location: (optional)

This will automatically create the device document in Firestore with your userId.

---

### Option 2: Manual Creation in Firebase Console

If the app device registration isn't working, manually create it:

1. **Go to**: https://console.firebase.google.com/project/mab-fyp/firestore

2. **Create a new document**:
   - Collection: `devices`
   - Document ID: `E86BEAD0BD78`

3. **Add these fields**:

| Field | Type | Value |
|-------|------|-------|
| `userId` | string | `{YOUR_USER_ID}` ← Get this from users collection |
| `name` | string | `Mushroom Tent A` |
| `mode` | string | `n` |
| `alarmAcknowledged` | boolean | `true` |
| `alarmActive` | boolean | `false` |
| `lastAlarm` | timestamp | (leave empty) |
| `snoozeUntil` | timestamp | (leave empty) |
| `cultivationPhase` | string | `normal` |
| `status` | string | `online` |

**To get YOUR_USER_ID**:
1. In Firestore, click on `users` collection
2. Find your email in the documents
3. Copy the document ID (that's your userId)

---

### Option 3: Quick Test Script (PowerShell)

**If you know your user ID**, run this script to manually add the device:

```powershell
# Replace YOUR_USER_ID_HERE with your actual user ID from Firestore
$userId = "YOUR_USER_ID_HERE"

Write-Host "Creating device document in Firestore..." -ForegroundColor Yellow

# Note: You'll need to do this manually in Firebase Console
# Firebase CLI doesn't have a simple command for this

Write-Host @"
Manual steps:
1. Go to: https://console.firebase.google.com/project/mab-fyp/firestore
2. Click 'Start collection' or navigate to 'devices' collection
3. Add document with ID: E86BEAD0BD78
4. Add field: userId = $userId
5. Add field: name = "Mushroom Tent A"
6. Add field: mode = "n"
7. Add field: alarmAcknowledged = true
8. Add field: status = "online"
9. Click 'Save'
"@ -ForegroundColor Cyan
```

---

## 🧪 After Adding Device - Test Again

Once the device document exists with your userId:

1. **Trigger alarm**:
   ```powershell
   Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" `
     -Method POST `
     -Headers @{"Content-Type"="application/json"} `
     -Body '{"deviceId":"E86BEAD0BD78","payload":"[75.0,45.0,31.0,25.0,n]"}'
   ```

2. **Check Cloud Function logs**:
   ```powershell
   firebase functions:log --only testAlarm -n 20
   ```

3. **Expected logs** (SUCCESS):
   ```
   📊 Parsed sensor data:
      Humidity: 75.0%
      Temperature: 31.0°C
   🚨 Alarm triggered for: humidity, temperature
   📝 Found device document with userId: abc123...
   📱 Found FCM token: dABC123...xyz
   ✅ FCM sent successfully to 1 device
   ```

4. **On your phone**:
   - 🔔 Notification appears
   - 🔊 Sound plays (if alarm volume is up)
   - 📳 Vibration

---

## 📋 Complete Checklist Before Testing

```
Firestore Setup:
[ ] Device document E86BEAD0BD78 exists
[ ] Device has userId field matching your user
[ ] User document has fcmToken field
[ ] FCM token is not null/empty

Phone Setup:
[ ] App is running in release mode
[ ] Alarm volume is turned up
[ ] Notifications enabled for app
[ ] Battery optimization disabled

App Setup:
[ ] Logged in to app
[ ] Device appears in device list
[ ] Can see device data on dashboard
```

---

## 🎯 Why This Happened

The device association workflow is:

1. **ESP32** publishes sensor data to MQTT
2. **Flutter app** receives MQTT data and displays it
3. **BUT** to receive FCM notifications:
   - Device must be registered in Firestore
   - Device must have `userId` field
   - This links the device to your account

The MQTT data flow works without Firestore (that's why you see sensor data), but the **alarm notifications require Firestore** because:
- Cloud Function needs to find your FCM token
- FCM token is stored in `users/{userId}/fcmToken`
- userId comes from `devices/{deviceId}/userId`

---

## 🔧 How to Register Devices (For Future)

### Automatic Registration (Recommended)

**In your Flutter app** (`lib/features/device_management/`):

When adding a device, it should:
1. Create Firestore document: `devices/{deviceId}`
2. Add field: `userId = currentUser.uid`
3. Add field: `name = device name`
4. Subscribe to MQTT topics

This is already implemented in your code at:
- `lib/features/device_management/domain/usecases/add_device.dart`
- `lib/features/device_management/data/repositories/device_repository_impl.dart`

### Manual Registration (Temporary Fix)

For devices already connected via MQTT but not in Firestore:
1. Open Firebase Console
2. Manually create device document
3. Add userId field

---

## 🆘 Still No Sound After Fixing?

If the device document exists and Cloud Function logs show "✅ FCM sent successfully", but still no sound:

**Then** refer to `ALARM_SOUND_TROUBLESHOOTING.md` for phone-specific fixes:
- Alarm volume settings
- Battery optimization
- Notification permissions
- Release mode requirement

---

## 📝 Summary

**Root cause**: Device not registered in Firestore  
**Symptom**: No notification received  
**Solution**: Register device with userId in Firestore  
**How**: Via Flutter app device management OR manually in Firebase Console

**After fix**: Alarm notifications will work! 🎉
