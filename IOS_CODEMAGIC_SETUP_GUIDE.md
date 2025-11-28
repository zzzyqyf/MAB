# iOS Codemagic Setup Guide for MAB Project

## ✅ Pre-Flight Checklist (What's Already Done)

### 1. ✅ Firebase Configuration Files
- **GoogleService-Info.plist** exists in `ios/Runner/`
- Bundle ID: `com.example.flutterApplicationFinal`
- All Firebase services configured (Auth, Firestore, FCM)

### 2. ✅ iOS Permissions (Info.plist)
- ✅ UIBackgroundModes: `fetch`, `remote-notification`
- ✅ FirebaseAppDelegateProxyEnabled: `true`
- ✅ NSAppTransportSecurity configured
- ✅ Camera, Microphone, Local Network permissions added
- ✅ NSBonjourServices for MQTT

### 3. ✅ Podfile Configuration
- ✅ Platform: iOS 11.0+
- ✅ Firebase/Core
- ✅ Firebase/Messaging (FCM)
- ✅ Firebase/Auth
- ✅ Firebase/Firestore
- ✅ Post-install script for deployment target

### 4. ✅ FCM Service (Dart)
- ✅ iOS foreground notification presentation options
- ✅ iOS permission requests (alert, badge, sound, critical)
- ✅ Platform-specific notification channel handling
- ✅ Background message handler

### 5. ✅ Alarm Sound Files
- ✅ `beep.mp3` copied to `ios/Runner/Resources/`
- ✅ Asset registered in `pubspec.yaml`
- ✅ AudioPlayer configured for iOS with `defaultToSpeaker`

### 6. ✅ Bundle ID Consistency
- ✅ project.pbxproj: `com.example.flutterApplicationFinal`
- ✅ GoogleService-Info.plist: `com.example.flutterApplicationFinal`
- ✅ All configurations match

---

## 🚨 CRITICAL: What You MUST Do Before Codemagic

### 1. **Apple Developer Account**
You need:
- [ ] Apple Developer account (paid, $99/year)
- [ ] Access to Apple Developer portal
- [ ] Team ID

### 2. **APNs Authentication Key (REQUIRED for FCM)**
⚠️ **WITHOUT THIS, FCM WILL NOT WORK ON iOS**

Steps:
1. Go to [Apple Developer Console](https://developer.apple.com/account/resources/authkeys/list)
2. Create new APNs Authentication Key:
   - Click **+** to create key
   - Check **Apple Push Notifications service (APNs)**
   - Download `.p8` key file (ONLY SHOWN ONCE - save it!)
   - Note the Key ID
   - Note your Team ID
3. Upload to Firebase Console:
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Under **Apple app configuration**, click **Upload**
   - Enter Key ID and Team ID
   - Upload the `.p8` file

### 3. **App Identifier & Capabilities**
1. Go to [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Create/verify App ID: `com.example.flutterApplicationFinal`
3. Enable capabilities:
   - [ ] Push Notifications
   - [ ] Background Modes (Remote notifications)
   - [ ] Associated Domains (if needed)

### 4. **Provisioning Profiles**
You'll need:
- **Development Profile** (for testing)
- **Distribution Profile** (for TestFlight/App Store)

---

## 📱 Codemagic Configuration

### Step 1: Connect Repository
1. Sign up/login to [Codemagic](https://codemagic.io)
2. Connect your GitHub/GitLab/Bitbucket repository
3. Select the MAB project

### Step 2: Configure iOS Build

Create `codemagic.yaml` in project root:

```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      ios_signing:
        distribution_type: app_store
        bundle_identifier: com.example.flutterApplicationFinal
      vars:
        BUNDLE_ID: "com.example.flutterApplicationFinal"
        APP_STORE_CONNECT_ISSUER_ID: YOUR_ISSUER_ID
        APP_STORE_CONNECT_KEY_IDENTIFIER: YOUR_KEY_ID
        APP_STORE_CONNECT_PRIVATE_KEY: YOUR_PRIVATE_KEY
      flutter: stable
      xcode: latest
      cocoapods: default
    scripts:
      - name: Set up code signing
        script: |
          keychain initialize
      - name: Get Flutter packages
        script: |
          flutter packages pub get
      - name: Install CocoaPods dependencies
        script: |
          cd ios
          pod install
      - name: Flutter analyze
        script: |
          flutter analyze
      - name: Build iOS
        script: |
          flutter build ios --release --no-codesign
      - name: Build IPA
        script: |
          xcode-project build-ipa \
            --workspace ios/Runner.xcworkspace \
            --scheme Runner
    artifacts:
      - build/ios/ipa/*.ipa
      - /tmp/xcodebuild_logs/*.log
      - flutter_drive.log
    publishing:
      email:
        recipients:
          - your.email@example.com
      app_store_connect:
        api_key: $APP_STORE_CONNECT_PRIVATE_KEY
        key_id: $APP_STORE_CONNECT_KEY_IDENTIFIER
        issuer_id: $APP_STORE_CONNECT_ISSUER_ID
```

### Step 3: Environment Variables in Codemagic
1. Go to Codemagic → Your App → Environment variables
2. Add:
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_PRIVATE_KEY`
   - `CERTIFICATE_PRIVATE_KEY` (if using manual signing)

### Step 4: Code Signing in Codemagic
Choose one:

#### Option A: Automatic (Recommended)
1. In Codemagic, go to **Code signing identities**
2. Click **iOS code signing**
3. Connect your Apple Developer account
4. Codemagic will auto-manage certificates and profiles

#### Option B: Manual
1. Export certificates from Xcode:
   - Open Xcode → Preferences → Accounts
   - Select your Apple ID → Manage Certificates
   - Right-click certificate → Export
2. Upload to Codemagic:
   - Certificate (.p12)
   - Provisioning Profile (.mobileprovision)

---

## 🧪 Testing Strategy

### Phase 1: Local Testing (Windows - Limited)
✅ Already done:
- `flutter pub get`
- `flutter analyze`
- Code review for iOS compatibility

### Phase 2: Codemagic Build (Mac)
Tomorrow you'll test:
1. **Build Success**
   - CocoaPods installation
   - Xcode compilation
   - IPA generation

2. **Download IPA**
   - From Codemagic artifacts
   - Install via TestFlight or direct (if dev profile)

### Phase 3: Real Device Testing
Test on physical iPhone:
1. **FCM Push Notifications**
   - Foreground: App open, receive notification
   - Background: App minimized, tap notification
   - Terminated: App closed, tap notification opens app
   - Test alarm sound plays

2. **MQTT Connectivity**
   - Device discovery
   - Real-time sensor data
   - Status updates

3. **Graph API**
   - Historical data loading
   - Chart rendering

4. **Alarm System**
   - Alarm sound playback
   - Notification actions (Dismiss, Snooze)
   - Persistent notification

5. **Accessibility**
   - Text-to-Speech (TTS)
   - VoiceOver compatibility
   - High contrast mode

---

## 🐛 Common Issues & Fixes

### Issue 1: CocoaPods Installation Fails
```bash
# Fix in Codemagic script
cd ios
pod repo update
pod install --repo-update
```

### Issue 2: Code Signing Error
- Verify bundle ID matches everywhere
- Check provisioning profile includes all devices
- Ensure certificates are not expired

### Issue 3: FCM Not Working
- ✅ Check APNs key is uploaded to Firebase
- ✅ Verify bundle ID in Firebase matches Xcode
- ✅ Test notification from Firebase Console (Cloud Messaging → Send test message)
- Check device token is saved to Firestore

### Issue 4: Alarm Sound Not Playing
- ✅ Verify `beep.mp3` exists in `ios/Runner/Resources/`
- Check iOS device is not in silent mode (alarm should override)
- Test with AudioSession configuration in `main.dart`

### Issue 5: Background Notifications Not Working
- ✅ Verify `UIBackgroundModes` in Info.plist
- ✅ Check `FirebaseAppDelegateProxyEnabled` is `true`
- Ensure app has notification permissions

---

## 📋 Tomorrow's Action Plan

### Morning (9:00 AM)
1. ☐ Push code to GitHub
2. ☐ Set up Codemagic account
3. ☐ Connect repository
4. ☐ Upload APNs key to Firebase Console
5. ☐ Configure App Identifier in Apple Developer

### Midday (12:00 PM)
6. ☐ Configure Codemagic workflow
7. ☐ Add environment variables
8. ☐ Set up code signing
9. ☐ Trigger first build

### Afternoon (3:00 PM)
10. ☐ Download IPA from Codemagic
11. ☐ Install on test iPhone via TestFlight
12. ☐ Test FCM notifications
13. ☐ Test MQTT connectivity
14. ☐ Test alarm system
15. ☐ Test all other features

### Evening (6:00 PM)
16. ☐ Document any issues found
17. ☐ Fix critical bugs
18. ☐ Re-build and re-test
19. ☐ Prepare demo for presentation

---

## 🔗 Important Links

- [Firebase Console](https://console.firebase.google.com/)
- [Apple Developer Portal](https://developer.apple.com/account/)
- [Codemagic](https://codemagic.io/)
- [TestFlight](https://testflight.apple.com/)

---

## 📞 Emergency Contacts

If you encounter issues:
1. Check Codemagic build logs (very detailed)
2. Firebase Console → Cloud Messaging → Send test notification
3. Xcode device logs (Console app on Mac)
4. Firebase Crashlytics (if enabled)

---

## ✅ Pre-Push Checklist

Before pushing to GitHub:
- [ ] All files saved
- [ ] `flutter pub get` runs successfully
- [ ] `flutter analyze` shows no errors
- [ ] `GoogleService-Info.plist` is present
- [ ] Bundle ID is consistent everywhere
- [ ] APNs key is ready to upload to Firebase

---

## 🎯 Success Criteria

Your iOS app is ready when:
1. ✅ Build completes on Codemagic without errors
2. ✅ IPA installs on test device
3. ✅ FCM notifications work (foreground + background)
4. ✅ Alarm sound plays when notification received
5. ✅ MQTT connects and shows live sensor data
6. ✅ All features work as on Android

---

**Good luck tomorrow! 🚀 You're 95% ready - just need the Mac and APNs key!**
