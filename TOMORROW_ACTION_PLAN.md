# Tomorrow's Action Plan - iOS Testing on Mac

## 📅 Date: [Fill in tomorrow's date]
## ⏰ Timeline: 8 hours (9:00 AM - 5:00 PM)

---

## ☀️ Morning Session (9:00 AM - 12:00 PM)

### 🔧 Setup Phase (9:00 - 10:00 AM)
- [ ] **9:00** - Arrive at Mac location
- [ ] **9:05** - Pull latest code from GitHub
- [ ] **9:10** - Run `flutter doctor` to verify setup
- [ ] **9:15** - Open project in Xcode (`open ios/Runner.xcworkspace`)
- [ ] **9:20** - Let Xcode index project (takes 5-10 min)
- [ ] **9:30** - Run `cd ios && pod install` to install CocoaPods dependencies
- [ ] **9:40** - Create Codemagic account (if not already done)
- [ ] **9:50** - Connect GitHub repository to Codemagic

---

### 🔑 APNs Setup (10:00 - 10:30 AM) - CRITICAL
- [ ] **10:00** - Login to [Apple Developer Console](https://developer.apple.com/account)
- [ ] **10:05** - Navigate to Certificates, Identifiers & Profiles → Keys
- [ ] **10:10** - Create new key:
  - Name: "MAB APNs Key"
  - Check: "Apple Push Notifications service (APNs)"
  - Click "Continue" → "Register"
- [ ] **10:15** - Download `.p8` file (SAVE IT - only shown once!)
- [ ] **10:16** - Note Key ID (shown on download page)
- [ ] **10:17** - Note Team ID (top right of Apple Developer page)
- [ ] **10:20** - Login to [Firebase Console](https://console.firebase.google.com)
- [ ] **10:22** - Go to Project Settings → Cloud Messaging → Apple app configuration
- [ ] **10:25** - Click "Upload" and enter:
  - APNs Authentication Key (.p8 file)
  - Key ID
  - Team ID
- [ ] **10:30** - Verify upload successful ✅

**⚠️ If APNs setup fails, STOP and debug - FCM won't work without it!**

---

### 📱 App Identifier Setup (10:30 - 11:00 AM)
- [ ] **10:30** - Go to Apple Developer → Identifiers
- [ ] **10:35** - Find or create: `com.example.flutterApplicationFinal`
- [ ] **10:40** - Enable capabilities:
  - [ ] Push Notifications
  - [ ] Background Modes
    - [ ] Remote notifications
    - [ ] Background fetch
- [ ] **10:45** - Click "Save"
- [ ] **10:50** - Verify capabilities enabled ✅

---

### 🔨 First Build Attempt (11:00 - 12:00 PM)

#### Option A: Local Xcode Build (Faster for debugging)
- [ ] **11:00** - Connect iPhone to Mac via USB
- [ ] **11:05** - Trust computer on iPhone (popup)
- [ ] **11:10** - In Xcode, select your iPhone as target device
- [ ] **11:15** - Click "Signing & Capabilities" tab
- [ ] **11:20** - Select your Apple ID team
- [ ] **11:25** - Click "Product" → "Build" (⌘B)
- [ ] **11:30** - Wait for build to complete (5-10 min)
- [ ] **11:40** - If build succeeds, click "Run" (▶️ button)
- [ ] **11:45** - App should install and launch on iPhone
- [ ] **11:50** - Check for crashes in Xcode console

**✅ If app launches: Proceed to Testing Phase**  
**❌ If build fails: Debug errors, check logs**

#### Option B: Codemagic Build (For CI/CD setup)
- [ ] **11:00** - Go to Codemagic dashboard
- [ ] **11:05** - Click "Start new build"
- [ ] **11:10** - Select "ios-workflow"
- [ ] **11:15** - Wait for build (15-20 min)
- [ ] **11:35** - If build succeeds, download IPA
- [ ] **11:40** - Install IPA via TestFlight or direct install
- [ ] **11:50** - Launch app on iPhone

---

## 🍽️ Lunch Break (12:00 - 1:00 PM)
- Take a break! You've earned it 😊

---

## 🌞 Afternoon Session (1:00 PM - 5:00 PM)

### 🧪 Testing Phase 1: FCM Notifications (1:00 - 2:00 PM)

#### Test 1.1: Permission Request
- [ ] **1:00** - Launch app (fresh install)
- [ ] **1:02** - App should request notification permissions
- [ ] **1:03** - Tap "Allow"
- [ ] **1:05** - Verify permission granted in Settings → MAB → Notifications

**✅ Expected: Notifications enabled**  
**❌ If failed: Check Info.plist has permission keys**

---

#### Test 1.2: FCM Token
- [ ] **1:10** - Open Firebase Console → Firestore
- [ ] **1:12** - Navigate to `users/{yourUserId}`
- [ ] **1:15** - Check for `fcmToken` field
- [ ] **1:17** - Verify token exists (long string starting with random chars)

**✅ Expected: Token saved**  
**❌ If failed: Check APNs key uploaded, bundle ID matches**

---

#### Test 1.3: Test Notification (Foreground)
- [ ] **1:20** - Keep app OPEN in foreground
- [ ] **1:22** - Go to Firebase Console → Cloud Messaging
- [ ] **1:25** - Click "Send test message"
- [ ] **1:27** - Enter your FCM token
- [ ] **1:28** - Add notification:
  - Title: "Test Alert"
  - Body: "This is a test"
- [ ] **1:30** - Click "Test"
- [ ] **1:32** - Check iPhone - notification should appear

**✅ Expected: Notification banner appears with sound**  
**❌ If failed: Check device not in Do Not Disturb, volume up**

---

#### Test 1.4: Test Notification (Background)
- [ ] **1:35** - Close app (swipe up to home screen)
- [ ] **1:37** - Send test notification from Firebase Console (same as above)
- [ ] **1:40** - Check iPhone - notification should appear

**✅ Expected: Notification appears on lock screen**  
**❌ If failed: Check UIBackgroundModes in Info.plist**

---

#### Test 1.5: Test Notification (Terminated)
- [ ] **1:45** - Force quit app (swipe up in app switcher)
- [ ] **1:47** - Send test notification from Firebase Console
- [ ] **1:50** - Check iPhone - notification should appear
- [ ] **1:52** - Tap notification
- [ ] **1:53** - App should launch

**✅ Expected: App opens from notification**  
**❌ If failed: Check FirebaseAppDelegateProxyEnabled = true**

---

### 🧪 Testing Phase 2: Alarm System (2:00 - 3:00 PM)

#### Test 2.1: Alarm Sound Playback
- [ ] **2:00** - Launch app
- [ ] **2:02** - Navigate to a device page
- [ ] **2:05** - Trigger alarm (simulate critical sensor value)
  - Option A: Use Firebase Console to send alarm notification
  - Option B: Manually trigger via test button (if implemented)
- [ ] **2:10** - Verify alarm sound plays through speaker (not earpiece)
- [ ] **2:12** - Check notification actions (Dismiss, Snooze)

**✅ Expected: Loud beep sound, notification with buttons**  
**❌ If failed: Check beep.mp3 in ios/Runner/Resources/**

---

#### Test 2.2: Dismiss Button
- [ ] **2:15** - Trigger alarm again
- [ ] **2:17** - Tap "Dismiss" button on notification
- [ ] **2:18** - Verify alarm stops
- [ ] **2:20** - Check Firestore: `alarmState.{deviceId}.alarmActive = false`

**✅ Expected: Alarm stops, Firestore updated**  
**❌ If failed: Check alarm_service.dart dismissAlarm() function**

---

#### Test 2.3: Snooze Button
- [ ] **2:25** - Trigger alarm again
- [ ] **2:27** - Tap "Snooze" button
- [ ] **2:28** - Select snooze duration (e.g., 5 minutes)
- [ ] **2:30** - Verify alarm stops
- [ ] **2:32** - Wait 5 minutes (or manually advance time if possible)
- [ ] **2:37** - Verify snooze reminder fires

**✅ Expected: Alarm snoozes, reminder notification after duration**  
**❌ If failed: Check snooze scheduling logic**

---

### 🧪 Testing Phase 3: MQTT & Sensors (3:00 - 4:00 PM)

#### Test 3.1: MQTT Connection
- [ ] **3:00** - Ensure ESP32 is powered on and publishing data
- [ ] **3:02** - Launch app
- [ ] **3:05** - Navigate to device list
- [ ] **3:07** - Verify device shows "online" status

**✅ Expected: Device online, green indicator**  
**❌ If failed: Check MQTT broker connection, ESP32 publishing**

---

#### Test 3.2: Real-Time Sensor Updates
- [ ] **3:10** - Open device details page
- [ ] **3:12** - Observe sensor readings (temperature, humidity, etc.)
- [ ] **3:15** - Manually change sensor value (e.g., heat DHT22 sensor)
- [ ] **3:20** - Verify app updates in real-time

**✅ Expected: Values update within 5 seconds**  
**❌ If failed: Check MqttManager subscription, topic structure**

---

#### Test 3.3: Mode Switching
- [ ] **3:25** - Tap "Mode" selector
- [ ] **3:27** - Switch from "Normal" to "Pinning"
- [ ] **3:30** - Verify ESP32 receives mode change (check serial monitor)
- [ ] **3:32** - Verify UI updates to show "Pinning" mode
- [ ] **3:35** - Check environmental control adjusts (humidity range, etc.)

**✅ Expected: Mode switches, ESP32 responds, UI updates**  
**❌ If failed: Check mode_controller_service.dart, MQTT publish**

---

### 🧪 Testing Phase 4: Graph API & UI (4:00 - 4:30 PM)

#### Test 4.1: Historical Data Loading
- [ ] **4:00** - Navigate to device page
- [ ] **4:02** - Tap "View History" or graph icon
- [ ] **4:05** - Verify graph loads historical data from Firestore
- [ ] **4:07** - Check data points render correctly on chart

**✅ Expected: Line graph with historical sensor data**  
**❌ If failed: Check Firestore query, graph_api_viewmodel.dart**

---

#### Test 4.2: Date/Time Selection
- [ ] **4:10** - Tap date picker
- [ ] **4:12** - Select a different date
- [ ] **4:15** - Verify graph updates with new date range
- [ ] **4:17** - Try different time ranges (24h, 7d, 30d)

**✅ Expected: Graph updates smoothly**  
**❌ If failed: Check date_selector_widget.dart**

---

#### Test 4.3: Zoom & Pan Gestures
- [ ] **4:20** - Pinch to zoom on graph
- [ ] **4:22** - Pan left/right to scroll through data
- [ ] **4:25** - Verify gestures work smoothly

**✅ Expected: Responsive gestures**  
**❌ If failed: Check fl_chart configuration**

---

### 🧪 Testing Phase 5: Other Features (4:30 - 5:00 PM)

#### Quick Tests
- [ ] **4:30** - Test authentication (logout, login)
- [ ] **4:35** - Test device registration (add new device)
- [ ] **4:40** - Test settings page
- [ ] **4:45** - Test profile page
- [ ] **4:50** - Test accessibility (TTS, VoiceOver)
- [ ] **4:55** - Test app stability (leave running for 5 min, check for crashes)

---

## 📝 End of Day (5:00 PM)

### Documentation
- [ ] **5:00** - Document any bugs found
- [ ] **5:10** - Take screenshots of working features
- [ ] **5:20** - Record short video demo
- [ ] **5:30** - Update this checklist with results

---

## 📊 Results Summary

### ✅ Passing Tests
(Fill in as you complete tests)
- [ ] FCM Foreground: ___
- [ ] FCM Background: ___
- [ ] FCM Terminated: ___
- [ ] Alarm Sound: ___
- [ ] Alarm Dismiss: ___
- [ ] Alarm Snooze: ___
- [ ] MQTT Connection: ___
- [ ] Real-time Updates: ___
- [ ] Mode Switching: ___
- [ ] Graph Loading: ___
- [ ] Date Selection: ___
- [ ] Gestures: ___

### ❌ Failing Tests
(Document issues here)

1. **Issue:** ___
   - **Error:** ___
   - **Fix Attempted:** ___
   - **Status:** ___

2. **Issue:** ___
   - **Error:** ___
   - **Fix Attempted:** ___
   - **Status:** ___

---

## 🔍 Debug Resources

### Xcode Logs
```bash
# View device logs
Window → Devices and Simulators → Select iPhone → Open Console
```

### Firebase Console
- **Firestore:** Check data structure
- **Authentication:** Verify user signed in
- **Cloud Messaging:** Send test notifications

### MQTT Broker
- **Broker:** api.milloserver.uk:8883
- **Test:** Use MQTT Explorer app on Mac

### ESP32 Serial Monitor
- **Baud Rate:** 115200
- **Check:** Sensor values, MQTT publish status

---

## 🆘 Emergency Contacts

- **Firebase Support:** [https://firebase.google.com/support](https://firebase.google.com/support)
- **Apple Developer Support:** [https://developer.apple.com/support/](https://developer.apple.com/support/)
- **Codemagic Support:** [https://codemagic.io/support/](https://codemagic.io/support/)
- **Flutter Discord:** [https://discord.gg/flutter](https://discord.gg/flutter)

---

## 🎯 Success Criteria

Your day is successful if:
1. ✅ App builds without errors
2. ✅ App installs and launches on iPhone
3. ✅ FCM notifications work (at least foreground)
4. ✅ Alarm sound plays
5. ✅ MQTT connects and shows live data
6. ✅ No critical crashes

**Even if some features fail, you'll have valuable debug info to fix them!**

---

**Good luck! You've got this! 🚀**

---

## 📌 Quick Reference

### File Locations
- **Xcode Project:** `ios/Runner.xcworkspace`
- **Info.plist:** `ios/Runner/Info.plist`
- **Podfile:** `ios/Podfile`
- **FCM Service:** `lib/shared/services/fcm_service.dart`
- **Alarm Service:** `lib/shared/services/alarm_service.dart`

### Terminal Commands
```bash
# Install CocoaPods
cd ios && pod install && cd ..

# Clean build
flutter clean && flutter pub get

# Build iOS
flutter build ios --release

# Run on connected device
flutter run

# View logs
flutter logs
```

### Bundle ID
`com.example.flutterApplicationFinal`

### Firebase Project
`mabb-d5b57`

### MQTT Broker
`api.milloserver.uk:8883` (TLS, auth: zhangyifei/123456)
