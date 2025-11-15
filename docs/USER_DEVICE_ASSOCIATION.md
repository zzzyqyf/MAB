# User-Device Association Implementation

## Overview
This document explains the implementation of user-specific device associations in the MAB application. Each user now has their own set of devices stored in Firestore, ensuring complete data isolation between users.

## Architecture

### Firestore Schema

#### Users Collection
```
users/
  {userId}/
    email: string
    role: string
    createdAt: timestamp
    emailVerified: boolean
    devices: array [
      {
        deviceId: string (UUID),
        name: string,
        mqttId: string (MAC address or ESP32 name),
        addedAt: timestamp
      }
    ]
```

### Key Components

#### 1. UserDeviceService (`lib/shared/services/user_device_service.dart`)
Central service for managing user-device associations in Firestore.

**Methods:**
- `addDeviceToUser()` - Adds a device to the current user's devices array
- `removeDeviceFromUser()` - Removes a device from the user's devices array
- `getUserDevices()` - Retrieves all devices for the current user
- `userOwnsDevice()` - Checks if a device belongs to the current user
- `updateDeviceName()` - Updates device name in Firestore

#### 2. DeviceManager Updates (`lib/features/device_management/presentation/viewmodels/deviceManager.dart`)

**New Methods:**
- `loadUserDevicesFromFirestore()` - Loads user-specific devices from Firestore when user logs in

**Updated Methods:**
- `addDeviceWithId()` - Now syncs with Firestore when adding devices
- `removeDevice()` - Now removes from Firestore when deleting devices
- `updateDeviceName()` - Now updates Firestore when renaming devices

#### 3. Main App Updates (`lib/main.dart`)

**MyHomePage State:**
- Added `_loadUserDevices()` method called in `initState()`
- Loads user's devices from Firestore when home page initializes
- Uses `_devicesLoaded` flag to prevent duplicate loads

## Data Flow

### User Registration
1. User signs up with email and OTP verification
2. Firebase Auth account created
3. Firestore user document created with empty `devices: []` array
4. User is redirected to dashboard

### Adding a Device
1. User navigates to device registration (Register4Widget)
2. Device credentials entered (WiFi SSID, password)
3. `DeviceManager.addDevice()` called
4. Device stored in local Hive storage
5. **NEW:** Device added to Firestore user's `devices` array via `UserDeviceService.addDeviceToUser()`
6. MQTT connection initialized
7. Device appears in dashboard

### Loading Devices on Login
1. User logs in successfully (signIn.dart)
2. AuthWrapper detects authenticated user
3. MyHomePage initializes
4. `_loadUserDevices()` called in `initState()`
5. `DeviceManager.loadUserDevicesFromFirestore()` fetches user's devices from Firestore
6. Local Hive storage cleared and repopulated with Firestore devices
7. MQTT connections initialized for each device
8. Devices displayed in dashboard

### Removing a Device
1. User removes device from dashboard
2. `DeviceManager.removeDevice()` called
3. MQTT service disposed
4. Device removed from local Hive storage
5. **NEW:** Device removed from Firestore via `UserDeviceService.removeDeviceFromUser()`
6. UI updates via `notifyListeners()`

### Switching Users
1. User A logs out
2. Local Hive storage remains (but will be cleared on next login)
3. User B logs in
4. `loadUserDevicesFromFirestore()` clears local storage
5. Only User B's devices loaded from Firestore
6. User B sees only their devices

## Security Considerations

### Firestore Rules (IMPORTANT - Must be configured)

Add these rules to your Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Ensure devices array can only be modified by the owner
      allow update: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.data.keys().hasAll(['devices'])
        && request.resource.data.devices is list;
    }
    
    // OTP verification documents (existing rules)
    match /otp_verifications/{email} {
      allow read, write: if request.auth == null; // Allow during signup
    }
    
    // Invitations (existing rules)
    match /invitations/{invitationId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Data Isolation
- Each user's devices stored in their own Firestore document
- No cross-user data access possible
- Local Hive storage cleared and repopulated on each login
- MQTT topics use device-specific identifiers (not user-specific)

## Testing Checklist

### Manual Testing Steps

1. **User Registration**
   - [ ] Sign up new user
   - [ ] Verify Firestore user document created with `devices: []`
   
2. **Add Device as User A**
   - [ ] Log in as User A
   - [ ] Add a device (e.g., "GreenHouse_A")
   - [ ] Verify device appears in dashboard
   - [ ] Check Firestore: User A's document should have device in `devices` array
   
3. **Add Another Device as User A**
   - [ ] Add second device (e.g., "GreenHouse_B")
   - [ ] Verify both devices appear in dashboard
   - [ ] Check Firestore: User A has 2 devices
   
4. **Logout and Login as User B**
   - [ ] Log out User A
   - [ ] Log in as User B (different account)
   - [ ] Verify User B sees NO devices (empty dashboard)
   
5. **Add Device as User B**
   - [ ] Add device as User B (e.g., "Mushroom_Farm_1")
   - [ ] Verify only this device appears for User B
   - [ ] Check Firestore: User B has 1 device, User A still has 2
   
6. **Switch Back to User A**
   - [ ] Log out User B
   - [ ] Log in as User A
   - [ ] Verify User A sees their 2 original devices
   - [ ] User A should NOT see User B's device
   
7. **Remove Device**
   - [ ] As User A, remove one device
   - [ ] Verify device removed from dashboard
   - [ ] Check Firestore: User A now has 1 device
   - [ ] Log out and back in, verify device stays removed

8. **Rename Device**
   - [ ] Rename a device
   - [ ] Verify name updates in UI
   - [ ] Check Firestore: device name updated
   - [ ] Log out and back in, verify new name persists

### Expected Debug Console Logs

When loading devices:
```
📥 DeviceManager: Loading user devices from Firestore...
✅ DeviceManager: Found 2 devices in Firestore
✅ DeviceManager: All user devices loaded and initialized
```

When adding a device:
```
📝 UserDeviceService: Adding device to user xyz123...
   Device ID: abc-def-ghi
   Device Name: GreenHouse_A
   MQTT ID: GreenHouse_A
✅ UserDeviceService: Device added to Firestore successfully
✅ DeviceManager: Device abc-def-ghi added to Firestore
```

When removing a device:
```
🗑️ UserDeviceService: Removing device abc-def-ghi from user xyz123
✅ UserDeviceService: Device removed from Firestore successfully
✅ DeviceManager: Device abc-def-ghi removed from Firestore
```

## Troubleshooting

### Issue: User sees no devices after login
**Solution:**
- Check Firebase Console: Verify user document has `devices` array
- Check debug logs for "Loading user devices from Firestore"
- Verify internet connection
- Check Firestore security rules allow read access

### Issue: Devices not persisting across logins
**Solution:**
- Verify `UserDeviceService.addDeviceToUser()` is being called
- Check Firebase Console: devices array should be populated
- Look for Firestore errors in debug console
- Verify user is authenticated before adding devices

### Issue: Seeing other users' devices
**Solution:**
- Check Firestore security rules are properly configured
- Verify `loadUserDevicesFromFirestore()` is clearing local storage
- Check that `UserDeviceService.currentUserId` returns correct UID

### Issue: Firebase permission errors
**Solution:**
- Update Firestore security rules as shown above
- Verify user is authenticated (`FirebaseAuth.instance.currentUser != null`)
- Check Firebase project permissions in console

## Migration for Existing Users

If you have existing devices in Hive storage that need to be migrated to Firestore:

1. Create a migration script in DeviceManager:
```dart
Future<void> migrateLocalDevicesToFirestore() async {
  final userId = UserDeviceService.currentUserId;
  if (userId == null) return;
  
  // Get existing devices from Hive
  final localDevices = devices;
  
  for (var device in localDevices) {
    await UserDeviceService.addDeviceToUser(
      deviceId: device['id'],
      deviceName: device['name'],
      mqttId: device['mqttId'],
    );
  }
}
```

2. Call once per user, then remove the code

## Future Enhancements

- [ ] Device sharing between users
- [ ] Device access permissions (owner, viewer, editor)
- [ ] Device groups/collections
- [ ] Historical device data in Firestore
- [ ] Real-time device sync across multiple sessions
- [ ] Offline device management with sync on reconnect

## Related Files

- `lib/shared/services/user_device_service.dart` - User-device service
- `lib/features/device_management/presentation/viewmodels/deviceManager.dart` - Device manager
- `lib/main.dart` - App entry and device loading
- `lib/features/authentication/presentation/pages/sinUp.dart` - User registration
- `lib/features/authentication/presentation/pages/signIn.dart` - User login
- `lib/features/authentication/presentation/widgets/auth_wrapper.dart` - Auth state handler
