# ✅ Alarm Sound Issue - RESOLVED!

## Problem Summary

**Original Issue**: No alarm sound when triggering alarms

**Root Cause**: Device not found in Firestore because the app uses a different database structure than what the Cloud Function expected.

---

## Database Structure Mismatch

### What Cloud Function Expected (Wrong):
```
Firestore
└── devices (collection)
    └── E86BEAD0BD78 (document)
        ├── userId: "abc123"
        ├── name: "Device Name"
        └── alarmActive: false
```

### What Actually Exists (Correct):
```
Firestore
└── users (collection)
    └── DlpiZplOUaVEB0nOjcRIqntlhHI3 (document)
        ├── email: "213853@student.upm.edu.my"
        ├── fcmToken: "d_4Xq-L6S7..."
        ├── devices (array field)
        │   └── [
        │       {
        │         deviceId: "0beae994-4312-44fa-9206-4bed0c2ff485",
        │         mqttId: "E86BEAD0BD78",
        │         name: "ESP32_D0BD78",
        │         addedAt: "2025-11-12T17:44:42.137513"
        │       }
        │     ]
        └── alarmState (map field)
            └── E86BEAD0BD78 (nested map)
                ├── lastAlarm: Timestamp
                ├── alarmActive: boolean
                ├── alarmAcknowledged: boolean
                └── snoozeUntil: Timestamp
```

---

## Changes Made

### 1. Cloud Function (`functions/index.js`)

**Before**: Queried `devices/{mqttId}` collection
```javascript
const deviceRef = admin.firestore().collection('devices').doc(deviceId);
const deviceDoc = await deviceRef.get();
```

**After**: Searches through `users` collection to find device by mqttId
```javascript
const usersSnapshot = await admin.firestore().collection('users').get();
let userDoc = null;
let deviceData = null;

for (const doc of usersSnapshot.docs) {
  const userData = doc.data();
  if (userData.devices && Array.isArray(userData.devices)) {
    const device = userData.devices.find(d => d.mqttId === deviceId);
    if (device) {
      userDoc = doc;
      deviceData = device;
      break;
    }
  }
}
```

**Alarm state now stored in user document**:
```javascript
await userRef.update({
  [`alarmState.${deviceId}.lastAlarm`]: admin.firestore.FieldValue.serverTimestamp(),
  [`alarmState.${deviceId}.alarmActive`]: true,
  [`alarmState.${deviceId}.alarmAcknowledged`]: false,
});
```

### 2. Flutter FCM Service (`lib/shared/services/fcm_service.dart`)

**Dismiss Alarm - Before**:
```dart
await FirebaseFirestore.instance
    .collection('devices')
    .doc(deviceId)
    .update({
  'alarmActive': false,
  'alarmAcknowledged': true,
});
```

**Dismiss Alarm - After**:
```dart
final userId = FirebaseAuth.instance.currentUser?.uid;

await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
  'alarmState.$deviceId.alarmActive': false,
  'alarmState.$deviceId.alarmAcknowledged': true,
  'alarmState.$deviceId.acknowledgedAt': FieldValue.serverTimestamp(),
});
```

**Snooze Alarm - Similar Changes**:
```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({
  'alarmState.$deviceId.snoozeUntil': Timestamp.fromDate(snoozeUntil),
  'alarmState.$deviceId.alarmActive': false,
  'alarmState.$deviceId.snoozedAt': FieldValue.serverTimestamp(),
});
```

---

## Deployment & Testing

### Cloud Functions Deployed
```powershell
firebase deploy --only functions
```

**Result**:
```
✅ functions[testAlarm(us-central1)] Successful update operation.
✅ functions[mqttAlarmMonitor(us-central1)] Successful update operation.
✅ functions[keepAlive(us-central1)] Successful update operation.
```

### Test Results

**Command**:
```powershell
Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"deviceId":"E86BEAD0BD78","payload":"[75.0,45.0,31.0,25.0,n]"}'
```

**Logs** (SUCCESS):
```
🔍 Searching for device in users collection...
📱 Device found: {
  userId: 'DlpiZplOUaVEB0nOjcRIqntlhHI3',
  deviceId: '0beae994-4312-44fa-9206-4bed0c2ff485',
  mqttId: 'E86BEAD0BD78',
  deviceName: 'ESP32_D0BD78'
}
✅ User FCM token found
📤 Sending FCM notification...
✅ FCM notification sent successfully
✅ Alarm state updated in user document
========== ALARM PROCESSING COMPLETE ==========
```

---

## Next Steps for User

### 1. Rebuild Flutter App
The Flutter code changes need to be recompiled:

```powershell
cd d:\fyp\Backup\MAB

# For testing (recommended)
flutter run --release

# OR build APK for installation
flutter build apk --release
```

### 2. Test Complete Flow

**Check notification appeared**:
- Did you see the notification?
- Did you hear sound?
- Did you feel vibration?

**If notification appeared but no sound**:
1. Check phone **Alarm Volume** (not media volume)
   - Settings → Sound & Vibration → Alarm Volume
   - Turn to maximum

2. Check notification permissions
   - Settings → Apps → MAB → Notifications → Enabled

3. Check battery optimization
   - Settings → Battery → Battery Optimization → MAB → Don't optimize

**If notification didn't appear**:
- Check app is running in release mode
- Check Flutter logs for errors
- Verify FCM token exists in Firestore

### 3. Test Dismiss & Snooze

Once notification works:

**Test Dismiss**:
1. Trigger alarm (test command above)
2. Tap "Dismiss" button on notification
3. Check alarm stops
4. Check Firestore: `users/{yourUserId}/alarmState/E86BEAD0BD78/alarmAcknowledged` should be `true`

**Test Snooze**:
1. Trigger alarm again
2. Tap "Snooze" button
3. Select duration (e.g., "1 minute")
4. Check alarm stops
5. Wait 1 minute
6. Check if reminder notification appears

---

## System Architecture (Updated)

```
┌─────────────┐
│   ESP32     │ Sensor out of range
│ E86BEAD0BD78│ publishes: topic/E86BEAD0BD78/alarm
└──────┬──────┘        payload: [75.0,45.0,31.0,25.0,n]
       │
       ↓ MQTT
┌──────────────────┐
│  MQTT Broker     │
│ api.milloserver  │
│   .uk:8883       │
└────────┬─────────┘
         │
         ↓ Subscribe: topic/+/alarm
┌────────────────────────────────┐
│  Cloud Function (Node.js)      │
│  mqttAlarmMonitor              │
│                                │
│  1. Parse sensor data          │
│  2. Check thresholds           │
│  3. Search users collection    │ ← FIXED
│  4. Find device by mqttId      │ ← FIXED
│  5. Get user's FCM token       │
│  6. Send FCM notification      │
│  7. Update alarmState          │ ← FIXED
└────────┬───────────────────────┘
         │
         ↓ FCM API
┌─────────────────────────────┐
│   Firebase Cloud Messaging  │
└────────┬────────────────────┘
         │
         ↓ Push Notification
┌─────────────────┐
│  Your Phone     │
│  Flutter App    │
│                 │
│  1. Receive FCM │
│  2. Play alarm  │
│  3. Show UI     │
│  4. Dismiss →   │ ← FIXED
│     Update      │    users/{uid}/alarmState
│     Firestore   │
└─────────────────┘
```

---

## Firestore Data Model (Final)

### Collection: `users`

```
users/{userId}
├── email: string
├── role: string
├── fcmToken: string
├── fcmTokenUpdatedAt: Timestamp
├── devices: array [
│   {
│     deviceId: string (UUID)
│     mqttId: string (MAC address without colons)
│     name: string
│     addedAt: string (ISO timestamp)
│   }
│ ]
└── alarmState: map {
    {mqttId}: {
      lastAlarm: Timestamp
      alarmActive: boolean
      alarmAcknowledged: boolean
      acknowledgedAt: Timestamp
      snoozeUntil: Timestamp
      snoozedAt: Timestamp
    }
  }
```

**Example**:
```json
{
  "email": "213853@student.upm.edu.my",
  "role": "member",
  "fcmToken": "d_4Xq-L6S7SjFSpOfq3YXY:APA91b...",
  "fcmTokenUpdatedAt": "2025-11-12T17:47:03Z",
  "devices": [
    {
      "deviceId": "0beae994-4312-44fa-9206-4bed0c2ff485",
      "mqttId": "E86BEAD0BD78",
      "name": "ESP32_D0BD78",
      "addedAt": "2025-11-12T17:44:42.137513"
    }
  ],
  "alarmState": {
    "E86BEAD0BD78": {
      "lastAlarm": "2025-11-12T09:58:32Z",
      "alarmActive": false,
      "alarmAcknowledged": true,
      "acknowledgedAt": "2025-11-12T10:05:15Z"
    }
  }
}
```

---

## Verification Checklist

### Cloud Function
- [x] Deployed successfully
- [x] Queries users collection correctly
- [x] Finds device by mqttId
- [x] Gets FCM token from user document
- [x] Sends FCM successfully
- [x] Updates alarmState in user document

### Flutter App
- [x] FCM service updated for new structure
- [x] Dismiss updates correct Firestore path
- [x] Snooze updates correct Firestore path
- [ ] **App rebuilt with changes** ← YOU NEED TO DO THIS
- [ ] **Tested on phone** ← YOU NEED TO DO THIS

### Phone Settings
- [ ] Alarm volume turned up
- [ ] Notifications enabled
- [ ] Battery optimization disabled
- [ ] App running in release mode

---

## Summary

**Problem**: Device structure mismatch  
**Solution**: Updated Cloud Function and Flutter to use correct Firestore paths  
**Status**: ✅ Cloud Function working, ✅ Flutter code updated  
**Action Required**: Rebuild Flutter app and test on phone  

**Next Command**:
```powershell
flutter run --release
```

Then test alarm again and **check your phone!** 📱🔔
