# Firebase Cloud Messaging (FCM) Setup Guide

## Overview

This guide covers the Firebase Cloud Messaging integration for the MAB alarm system. FCM enables push notifications to be sent from the Cloud Function to the Flutter app, allowing alarms to trigger even when the app is closed or in the background.

## Architecture

```
ESP32 → MQTT (topic/{deviceId}/alarm) → Cloud Function → FCM → Flutter App → Alarm Sound
```

1. **ESP32** detects sensor out of range, publishes to alarm topic
2. **Cloud Function** receives MQTT message, sends FCM notification
3. **Flutter App** receives FCM, triggers alarm sound playback
4. **User** can dismiss or snooze the alarm

## Files Modified/Created

### New Files
- `lib/shared/services/fcm_service.dart` - FCM service implementation

### Modified Files
- `pubspec.yaml` - Added `firebase_messaging: ^14.7.19` dependency
- `lib/main.dart` - Initialize FCM service on app startup
- `android/app/src/main/AndroidManifest.xml` - Added FCM permissions and meta-data

## FCM Service Features

### 1. Permission Handling
```dart
await _firebaseMessaging.requestPermission(
  alert: true,
  badge: true,
  criticalAlert: true, // For critical alarms
  sound: true,
);
```

### 2. Token Management
- Gets FCM token on initialization
- Saves token to Firestore `users/{userId}/fcmToken`
- Listens for token refresh and updates Firestore

### 3. Message Handlers

#### Foreground Messages
App is open and visible:
```dart
FirebaseMessaging.onMessage.listen((message) {
  // Play alarm immediately
  // Show local notification
});
```

#### Background Messages
App is in background:
```dart
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

#### Notification Taps
User taps notification:
```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // Open app and play alarm
});
```

### 4. Local Notifications
Uses `flutter_local_notifications` to show custom notifications with action buttons:
- **Dismiss** - Stop alarm and mark as acknowledged
- **Remind me later** - Snooze alarm for selected duration

### 5. Alarm Integration
FCM service integrates with existing `AlarmService`:
```dart
await _alarmService.startAlarm(reason);
```

## Android Configuration

### Permissions Added
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### Meta-data Added
```xml
<!-- Default notification channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="alarm_channel" />

<!-- Default notification icon -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />

<!-- Default notification color -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@android:color/holo_red_light" />
```

## Notification Channel

Created in `fcm_service.dart`:
```dart
const androidChannel = AndroidNotificationChannel(
  'alarm_channel', // id
  'Alarm Notifications', // name
  description: 'Critical sensor alarm notifications',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  sound: RawResourceAndroidNotificationSound('beep'),
);
```

## FCM Message Format

### Data Payload (from Cloud Function)
```json
{
  "deviceId": "ESP32_001",
  "deviceName": "Mushroom Tent A",
  "alarmType": "humidity,temperature",
  "humidity": "78.5",
  "temperature": "32.0",
  "water": "65.0",
  "light": "45.0",
  "mode": "n"
}
```

### Notification (auto-shown by Firebase)
```json
{
  "title": "🚨 Sensor Alert: Mushroom Tent A",
  "body": "Humidity (78.5%) and Temperature (32.0°C) are critical!"
}
```

## Usage

### Initialize FCM
Already done in `main.dart`:
```dart
await FcmService().initialize();
```

### How It Works

1. **User logs in** → FCM token generated and saved to Firestore
2. **ESP32 detects alarm** → Publishes to `topic/{deviceId}/alarm`
3. **Cloud Function** → Queries Firestore for user's FCM token
4. **FCM sends notification** → To user's phone
5. **Flutter receives notification** → Triggers alarm sound
6. **User dismisses/snoozes** → Updates Firestore, stops alarm

## Testing

### 1. Verify FCM Token Saved
Check Firestore console:
```
users/{userId}:
  fcmToken: "abc123..."
  fcmTokenUpdatedAt: Timestamp
```

### 2. Test Foreground Notification
With app open, trigger alarm from ESP32 or Cloud Function test endpoint:
```bash
curl -X POST https://us-central1-YOUR_PROJECT.cloudfunctions.net/testAlarm \
  -H "Content-Type: application/json" \
  -d '{"deviceId": "ESP32_001"}'
```

### 3. Test Background Notification
1. Close app (swipe away from recent apps)
2. Trigger alarm
3. Notification should appear
4. Tap notification → App opens and alarm plays

### 4. Test Terminated State
1. Force stop app (Settings → Apps → Force Stop)
2. Trigger alarm
3. Notification should appear
4. Tap notification → App launches and alarm plays

## Troubleshooting

### Token Not Saved
**Symptom**: Cloud Function logs "No FCM token found for user"

**Solution**:
1. Check if user is logged in: `FirebaseAuth.instance.currentUser?.uid`
2. Check app logs for FCM initialization: `🔔 [FCM] Initializing FCM service...`
3. Manually trigger token save:
   ```dart
   await FcmService().initialize();
   ```

### Notification Not Received
**Symptom**: Cloud Function sends FCM but app doesn't receive

**Solution**:
1. Check if app has notification permission:
   ```dart
   final settings = await FirebaseMessaging.instance.getNotificationSettings();
   print(settings.authorizationStatus);
   ```
2. Check notification channel exists:
   ```bash
   adb shell dumpsys notification_listener
   ```
3. Check device battery optimization (Android):
   - Settings → Battery → Battery Optimization → App → Don't optimize

### Alarm Doesn't Play
**Symptom**: Notification received but no sound

**Solution**:
1. Check alarm service initialization:
   ```dart
   final alarmService = AlarmService();
   print(alarmService.isAlarmActive);
   ```
2. Check audio player initialization in `alarm_service.dart`
3. Verify `assets/sounds/beep.mp3` exists

### Background Handler Not Working
**Symptom**: Foreground works but background doesn't

**Solution**:
1. Ensure handler is top-level function:
   ```dart
   @pragma('vm:entry-point')
   Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
     // Must be at file level, not inside class
   }
   ```
2. Rebuild app after adding handler:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## iOS Configuration (Future)

For iOS support, add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

And request provisional authorization:
```dart
await FirebaseMessaging.instance.requestPermission(
  provisional: true,
);
```

## Best Practices

### 1. Error Handling
All FCM operations wrapped in try-catch:
```dart
try {
  await _firebaseMessaging.requestPermission();
} catch (e) {
  debugPrint('❌ [FCM] Error: $e');
}
```

### 2. Logging
Comprehensive emoji-prefixed logs:
- 🔔 = FCM events
- 🚨 = Alarm processing
- ✅ = Success
- ❌ = Error

### 3. Token Refresh
Automatically updates Firestore on token refresh:
```dart
_firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
```

### 4. Graceful Degradation
If FCM fails, app still works:
- MQTT alarm detection still works
- Local alarm sounds still work
- Just no push notifications when app closed

## Cost Considerations

FCM is **completely free**:
- Unlimited messages
- No monthly fees
- No per-message charges

This is why FCM was chosen over SMS or other notification services.

## Security

### Token Storage
FCM tokens stored in Firestore with security rules:
```javascript
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}
```

### Message Validation
Cloud Function validates alarm data before sending:
```javascript
if (!deviceId || !deviceName) {
  console.log('Invalid alarm data');
  return;
}
```

## Next Steps

1. ✅ FCM service implemented
2. ⏳ Test alarm sound playback integration
3. ⏳ Implement notification action buttons (Dismiss/Snooze)
4. ⏳ Add snooze duration picker
5. ⏳ Update Firestore on dismiss/snooze
6. ⏳ End-to-end testing

## References

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [firebase_messaging package](https://pub.dev/packages/firebase_messaging)
