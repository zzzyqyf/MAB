# Alarm System Firestore Structure

## Overview
This document describes the updated Firestore structure to support the alarm system with Firebase Cloud Functions and FCM notifications.

---

## Collections Structure

### 1. **users/{userId}** (Existing - Updated)
Stores user information and FCM tokens for push notifications.

```javascript
{
  email: string,
  role: string,
  createdAt: timestamp,
  emailVerified: boolean,
  fcmToken: string,  // ✅ NEW: Firebase Cloud Messaging token for alarm notifications
  devices: array [    // Existing: device references
    {
      deviceId: string,  // UUID
      name: string,
      mqttId: string,
      addedAt: timestamp
    }
  ]
}
```

### 2. **devices/{deviceId}** (✅ NEW Collection)
Stores device-specific configuration and alarm state. One document per device.

```javascript
{
  // Device identification
  deviceId: string,           // UUID (matches user's devices array)
  mqttId: string,             // MAC address (e.g., "94B97EC04AD4")
  deviceName: string,         // User-friendly name
  userId: string,             // Owner's UID (single owner)
  
  // Current cultivation mode
  mode: string,               // "normal" or "pinning"
  pinningEndTime: timestamp,  // When pinning mode expires (null if normal)
  
  // Alarm state
  lastAlarm: timestamp,       // Last time alarm was triggered
  alarmActive: boolean,       // Is alarm currently active?
  alarmAcknowledged: boolean, // Has user dismissed alarm?
  snoozeUntil: timestamp,     // When to re-trigger alarm after snooze (null if not snoozed)
  
  // Sensor thresholds (for reference)
  thresholds: {
    temperature: { max: 30 },
    humidityNormal: { min: 80, max: 85 },
    humidityPinning: { min: 90, max: 95 },
    waterLevel: { min: 30, max: 70 }
  },
  
  // Metadata
  createdAt: timestamp,
  updatedAt: timestamp,
  lastSeen: timestamp
}
```

---

## Data Flow for Alarm System

### 1. **Device Registration**
```
User adds device → Flutter creates:
1. users/{userId}/devices[] entry
2. devices/{deviceId} document with:
   - userId
   - mode: "normal"
   - alarmActive: false
   - alarmAcknowledged: false
```

### 2. **FCM Token Registration**
```
App startup → Flutter:
1. Request notification permission
2. Get FCM token
3. Save to users/{userId}/fcmToken
```

### 3. **Alarm Trigger Flow**
```
ESP32 sensor out of range →
  MQTT: topic/{deviceId}/alarm published →
    Cloud Function triggered:
      1. Parse sensor data
      2. Read devices/{deviceId}
      3. Check: alarmActive, alarmAcknowledged, snoozeUntil
      4. If eligible for alarm:
         a. Query users/{userId} for FCM token
         b. Send FCM notification
         c. Update devices/{deviceId}:
            - lastAlarm: now
            - alarmActive: true
            - alarmAcknowledged: false
```

### 4. **User Dismisses Alarm**
```
User clicks "Dismiss" →
  Flutter updates devices/{deviceId}:
    - alarmActive: false
    - alarmAcknowledged: true
    - snoozeUntil: null
  Flutter stops alarm sound
```

### 5. **User Snoozes Alarm**
```
User clicks "Remind me later (2 hours)" →
  Flutter updates devices/{deviceId}:
    - alarmActive: false
    - alarmAcknowledged: false
    - snoozeUntil: now + 2 hours
  Flutter stops alarm sound
  Flutter schedules local notification for 2 hours
  
After 2 hours:
  If sensor still bad →
    Cloud Function checks snoozeUntil passed →
      Sends new FCM
```

### 6. **Alarm Deduplication Logic (Cloud Function)**
```javascript
// Don't send alarm if:
1. alarmActive === true (already notified)
2. alarmAcknowledged === true (user dismissed it)
3. snoozeUntil > now (snoozed, not yet time)
4. lastAlarm within 5 minutes (cooldown to prevent spam)
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection (existing + FCM token)
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow FCM token updates
      allow update: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.data.keys().hasAny(['fcmToken']);
    }
    
    // Devices collection (NEW)
    match /devices/{deviceId} {
      // User can read their own devices
      allow read: if request.auth != null 
        && request.auth.uid == resource.data.userId;
      
      // User can create device document when adding device
      allow create: if request.auth != null 
        && request.auth.uid == request.resource.data.userId;
      
      // User can update their own device
      allow update: if request.auth != null 
        && request.auth.uid == resource.data.userId;
      
      // User can delete their own device
      allow delete: if request.auth != null 
        && request.auth.uid == resource.data.userId;
      
      // Cloud Function can write (using service account)
      allow write: if request.auth.token.firebase.sign_in_provider == 'custom';
    }
  }
}
```

---

## Migration Steps

### 1. Update Firestore Rules
Copy rules above to Firebase Console → Firestore → Rules

### 2. Add FCM Token Field to Users
Flutter will automatically update on next app start when FCM token is retrieved.

### 3. Create devices/{deviceId} Documents
Two options:

**Option A: Automatic (Recommended)**
- On next app start, Flutter checks if `devices/{deviceId}` exists
- If not, creates it from `users/{userId}/devices[]` data
- Runs once per device

**Option B: Manual Migration Script**
```dart
// In DeviceManager
Future<void> migrateDevicesToCollection() async {
  final userId = UserDeviceService.currentUserId;
  if (userId == null) return;
  
  final userDevices = await UserDeviceService.getUserDevices();
  
  for (var device in userDevices) {
    await FirebaseFirestore.instance
      .collection('devices')
      .doc(device['deviceId'])
      .set({
        'deviceId': device['deviceId'],
        'mqttId': device['mqttId'],
        'deviceName': device['name'],
        'userId': userId,
        'mode': 'normal',
        'pinningEndTime': null,
        'lastAlarm': null,
        'alarmActive': false,
        'alarmAcknowledged': false,
        'snoozeUntil': null,
        'thresholds': {
          'temperature': {'max': 30},
          'humidityNormal': {'min': 80, 'max': 85},
          'humidityPinning': {'min': 90, 'max': 95},
          'waterLevel': {'min': 30, 'max': 70},
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastSeen': null,
      }, SetOptions(merge: true));
  }
}
```

---

## Cloud Function Access Pattern

```javascript
// Cloud Function reads:
const deviceDoc = await admin.firestore()
  .collection('devices')
  .doc(deviceId)
  .get();

const deviceData = deviceDoc.data();

// Check if should send alarm
if (deviceData.alarmActive || 
    deviceData.alarmAcknowledged || 
    (deviceData.snoozeUntil && deviceData.snoozeUntil.toDate() > new Date())) {
  console.log('Alarm already handled, skipping');
  return;
}

// Get user's FCM token
const userDoc = await admin.firestore()
  .collection('users')
  .doc(deviceData.userId)
  .get();

const fcmToken = userDoc.data().fcmToken;

// Send FCM notification
await admin.messaging().send({
  token: fcmToken,
  notification: {
    title: '🚨 Sensor Alert',
    body: `${deviceData.deviceName}: Temperature too high (31.5°C)`,
  },
  data: {
    deviceId: deviceId,
    deviceName: deviceData.deviceName,
    alarmType: 'temperature',
    value: '31.5',
    threshold: '30',
  },
  android: {
    priority: 'high',
  },
});

// Update device document
await admin.firestore()
  .collection('devices')
  .doc(deviceId)
  .update({
    lastAlarm: admin.firestore.FieldValue.serverTimestamp(),
    alarmActive: true,
    alarmAcknowledged: false,
  });
```

---

## Testing Checklist

- [ ] Create `devices/{deviceId}` document for existing device
- [ ] Verify FCM token saved to `users/{userId}/fcmToken`
- [ ] Test alarm trigger: ESP32 publishes to alarm topic
- [ ] Verify Cloud Function creates alarm document
- [ ] Verify FCM notification received on phone
- [ ] Test "Dismiss" button updates `alarmAcknowledged`
- [ ] Test "Snooze" sets `snoozeUntil` timestamp
- [ ] Verify alarm doesn't re-trigger during snooze
- [ ] Test alarm re-triggers after snooze expires
- [ ] Verify Firestore security rules block unauthorized access

---

## Cost Estimate (Free Tier)

**Firestore:**
- Read: ~100/day (Cloud Function checking device docs)
- Write: ~50/day (alarm state updates)
- Storage: ~1KB per device
- **Cost**: FREE (within 50K reads, 20K writes/day)

**Cloud Functions:**
- Invocations: ~100-500/month (only alarm events)
- **Cost**: FREE (within 125K invocations/month)

**FCM:**
- Notifications: ~100-500/month
- **Cost**: FREE (unlimited)

**Total**: $0/month ✅
