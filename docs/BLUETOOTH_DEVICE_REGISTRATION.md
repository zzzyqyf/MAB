# Bluetooth Device Registration Implementation Guide
## MAB - Mushroom Agriculture Monitoring System

---

## 📋 Overview

This document describes the complete implementation of Bluetooth-based ESP32 device registration. The system allows users to configure WiFi credentials on ESP32 devices via Bluetooth Low Energy (BLE), then automatically register the device to their account using MQTT.

---

## 🏗️ System Architecture

### Registration Flow Diagram

```
User's Phone (Flutter App)
    ↓
1. User enters WiFi credentials (registerFour.dart)
    ↓
2. App scans for ESP32 via BLE
    ↓
3. App connects to ESP32 BLE server
    ↓
4. App sends WiFi credentials via BLE characteristic
    ↓
5. ESP32 receives credentials
    ↓
6. App navigates to waiting page (registerFive.dart)
    ↓
7. ESP32 connects to WiFi using received credentials
    ↓
8. ESP32 gets its MAC address (e.g., "AABBCCDDEEFF")
    ↓
9. ESP32 connects to MQTT broker
    ↓
10. ESP32 publishes registration to "system/devices/register"
    ↓
11. App receives MQTT registration message
    ↓
12. App adds device to user's Firestore account
    ↓
13. App adds device to local DeviceManager
    ↓
14. App subscribes to device's MQTT topics
    ↓
15. User sees device in dashboard ✅
```

---

## 🔧 Implementation Components

### Flutter App Components

#### 1. **BluetoothProvisioningService**
**Location**: `lib/shared/services/bluetooth_provisioning_service.dart`

**Purpose**: Handles BLE communication with ESP32

**Key Methods**:
- `initialize()` - Check Bluetooth availability
- `startScan()` - Scan for ESP32 devices (filters by service UUID)
- `connectToDevice()` - Connect to discovered ESP32
- `sendWiFiCredentials()` - Send SSID and password as JSON via BLE characteristic
- `disconnect()` - Cleanup BLE connection

**BLE Configuration**:
- Service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- WiFi Characteristic UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`

#### 2. **DeviceRegistrationService**
**Location**: `lib/shared/services/device_registration_service.dart`

**Purpose**: Listen for MQTT device registration messages

**Key Methods**:
- `startListening()` - Subscribe to `system/devices/register` MQTT topic
- `stopListening()` - Unsubscribe and cleanup
- `onDeviceRegistered` - Stream of registration events

**MQTT Topic**: `system/devices/register`

**Message Format**:
```json
{
  "macAddress": "AABBCCDDEEFF",
  "deviceName": "ESP32_AABBCC",
  "timestamp": 1234567890
}
```

#### 3. **registerFour.dart** (Updated)
**Location**: `lib/features/registration/presentation/pages/registerFour.dart`

**Changes**:
- Added BLE scanning and connection logic
- Removed old UDP-based credential sending
- Added navigation to registerFive.dart after successful credential transmission

**User Flow**:
1. User enters WiFi SSID and password
2. Double-tap "Save" button
3. App scans for ESP32 via BLE (10 seconds)
4. App connects to first discovered device
5. App sends credentials via BLE
6. App navigates to waiting page

#### 4. **registerFive.dart** (New)
**Location**: `lib/features/registration/presentation/pages/registerFive.dart`

**Purpose**: Waiting page with progress indicator

**Features**:
- Real-time elapsed time counter
- Circular progress indicator
- Status messages with TTS support
- Cancel button to abort registration
- Automatic navigation to home on success
- Duplicate device detection
- Error handling with retry option

**States**:
- Waiting: Shows progress, elapsed time
- Success: Shows checkmark, navigates to home
- Error: Shows error message with "Try Again" button

#### 5. **UserDeviceService** (Updated)
**Location**: `lib/shared/services/user_device_service.dart`

**New Method**:
```dart
static Future<bool> deviceMacExists(String macAddress)
```

**Purpose**: Check if a MAC address is already registered to prevent duplicates

---

### ESP32 Components

#### **bluetooth_provisioning_main.cpp**
**Location**: `esp32/bluetooth_provisioning_main.cpp`

**Complete Implementation** with:

1. **BLE Server Setup**
   - Advertises with service UUID
   - Creates WiFi characteristic for receiving credentials
   - Callbacks for connection/disconnection

2. **WiFi Connection**
   - Connects using received SSID/password
   - 20-second timeout
   - Visual feedback via LED

3. **MAC Address Handling**
   - Retrieves MAC via `WiFi.macAddress()`
   - Formats as `AABBCCDDEEFF` (no colons)
   - Creates device name as `ESP32_XXXXXX`

4. **MQTT Registration**
   - Connects to `broker.mqtt.cool:1883`
   - Publishes registration to `system/devices/register`
   - Includes MAC, device name, timestamp

5. **Sensor Data Publishing**
   - Publishes to `devices/{MAC}/sensors/{type}`
   - Types: temperature, humidity, lights, moisture
   - JSON payload with value and timestamp

**Hardware Requirements**:
- ESP32 DevKit
- DHT22 sensor (GPIO 4)
- LDR (GPIO 32)
- Moisture sensor (GPIO 33)
- LED (GPIO 2)

**Libraries Required**:
```ini
knolleary/PubSubClient @ ^2.8
adafruit/DHT sensor library @ ^1.4.4
adafruit/Adafruit Unified Sensor @ ^1.1.4
bblanchon/ArduinoJson @ ^6.21.3
h2zero/NimBLE-Arduino @ ^1.4.1
```

---

## 🔐 Firebase Configuration

### Firestore Structure

```
users/
  {userId}/
    email: string
    role: string
    createdAt: timestamp
    emailVerified: boolean
    devices: array [
      {
        deviceId: string (UUID - internal),
        name: string (e.g., "ESP32_AABBCC"),
        mqttId: string (MAC address "AABBCCDDEEFF"),
        addedAt: timestamp
      }
    ]
```

### Security Rules

**File**: `docs/FIRESTORE_SECURITY_RULES.rules`

**To Apply**:
1. Open Firebase Console
2. Go to Firestore Database
3. Click "Rules" tab
4. Copy and paste rules from `FIRESTORE_SECURITY_RULES.rules`
5. Click "Publish"

**Key Rules**:
- Users can only access their own document
- Device array must contain valid device objects
- Each device requires: deviceId, name, mqttId, addedAt

---

## 📱 Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Bluetooth permissions -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Android 12+ Bluetooth -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

---

## 🚀 Setup Instructions

### Flutter App Setup

1. **Install Dependencies**
```powershell
flutter pub get
```

2. **Request Bluetooth Permissions**
The app will automatically request permissions on first use.

3. **Run the App**
```powershell
flutter run
```

### ESP32 Setup

1. **Install PlatformIO** (if using VS Code)
   - Install PlatformIO IDE extension

2. **Open ESP32 Project**
   - Open `esp32` folder in PlatformIO

3. **Upload Code**
```powershell
# Using PlatformIO CLI
pio run --target upload

# Using Arduino IDE
# 1. Copy bluetooth_provisioning_main.cpp content
# 2. Create new sketch
# 3. Paste and upload
```

4. **Monitor Serial Output**
```powershell
pio device monitor -b 115200
```

---

## 🧪 Testing Guide

### Test Scenario 1: First Device Registration

1. **Prepare ESP32**
   - Upload code
   - Power on device
   - Verify serial output shows "BLE Server started"

2. **In Flutter App**
   - Login to your account
   - Navigate to Add Device page
   - Enter WiFi SSID and password
   - Double-tap "Save"

3. **Expected Behavior**
   - App shows "Scanning for ESP32..."
   - App connects and sends credentials
   - App navigates to waiting page
   - ESP32 connects to WiFi (check serial monitor)
   - ESP32 publishes registration
   - App receives registration
   - App shows "Device added successfully!"
   - App navigates to home
   - Device appears in dashboard

4. **Verify in Firebase Console**
   - Go to Firestore
   - Check your user document
   - Verify `devices` array has new entry with MAC address

### Test Scenario 2: Duplicate Device Detection

1. Try to register the same ESP32 again
2. Expected: Error message "This device is already registered"

### Test Scenario 3: WiFi Connection Failure

1. Enter wrong WiFi password
2. Expected: ESP32 fails to connect, shows error in serial
3. User can go back and try again

### Test Scenario 4: Multiple Users

1. Register device on User A's account
2. Logout, login as User B
3. Try to use the app
4. Verify User B cannot see User A's device

---

## 🐛 Troubleshooting

### Issue: App can't find ESP32

**Solutions**:
- Ensure ESP32 is powered on
- Check BLE is enabled on phone
- Grant Location permissions (required for BLE scan)
- Verify ESP32 serial shows "BLE Server started"
- Try restarting ESP32

### Issue: WiFi connection fails

**Solutions**:
- Double-check SSID and password
- Ensure WiFi is 2.4GHz (ESP32 doesn't support 5GHz)
- Check WiFi signal strength
- Verify ESP32 serial output for error messages

### Issue: MQTT registration not received

**Solutions**:
- Check internet connection on phone
- Verify MQTT broker is accessible (broker.mqtt.cool:1883)
- Check ESP32 serial shows "Device registered successfully"
- Ensure app is on waiting page (not navigated away)
- Check firewall settings

### Issue: "This device is already registered" error

**Solutions**:
- This is expected if device was previously added
- Remove device from account first, then re-add
- Check Firebase Console to verify device in user's devices array

### Issue: Device appears but no sensor data

**Solutions**:
- Check MQTT connection on ESP32
- Verify ESP32 is publishing to correct topics
- Check DeviceManager is subscribed to device topics
- Look for MQTT messages in app debug logs

---

## 🔍 Debug Logs

### Flutter App Logs

Look for these debug prints:

```
🔵 BluetoothProvisioningService: Initializing...
🔍 BluetoothProvisioningService: Starting scan...
📱 BluetoothProvisioningService: Found device: ESP32_XXXXXX
🔗 BluetoothProvisioningService: Connecting to ESP32_XXXXXX...
✅ BluetoothProvisioningService: Connected
📤 BluetoothProvisioningService: Sending WiFi credentials...
✅ BluetoothProvisioningService: Credentials sent

📡 DeviceRegistrationService: Starting to listen...
✅ DeviceRegistrationService: Now listening on system/devices/register
📨 DeviceRegistrationService: Received registration message
✅ DeviceRegistrationService: Parsed registration:
   MAC Address: AABBCCDDEEFF
   Device Name: ESP32_AABBCC
```

### ESP32 Serial Monitor Logs

Expected output:

```
===============================================
   ESP32 Bluetooth Provisioning System
===============================================
📍 MAC Address: AA:BB:CC:DD:EE:FF
🆔 Device ID: AABBCCDDEEFF
📛 Device Name: ESP32_AABBCC
🔵 Initializing BLE...
✅ BLE Server started and advertising
   Service UUID: 4fafc201-1fb5-459e-8fcc-c5c9c331914b
✅ Setup complete - waiting for WiFi credentials via BLE

📱 BLE Client connected
📩 Received WiFi credentials
   SSID: YourWiFiName
   Password: ********

📡 Connecting to WiFi...
   SSID: YourWiFiName
.........
✅ WiFi connected!
   IP Address: 192.168.1.123
   Signal Strength: -45 dBm

📨 Connecting to MQTT broker...
   Broker: broker.mqtt.cool:1883
   Attempt 1/5... ✅ Connected!
   Subscribed to: devices/AABBCCDDEEFF/mode/set

📝 Registering device on MQTT...
✅ Device registered successfully!
   Topic: system/devices/register
   Payload: {"macAddress":"AABBCCDDEEFF","deviceName":"ESP32_AABBCC","timestamp":12345}

📊 Sensors: Temp=25.0°C, Humid=60.0%, Light=0, Moisture=45.5%
```

---

## 📊 Data Flow Summary

### Device Registration Data

**ESP32 → MQTT → App → Firebase**

```
ESP32:
  macAddress = WiFi.macAddress()  // "AA:BB:CC:DD:EE:FF"
  deviceId = macAddress without colons  // "AABBCCDDEEFF"
  deviceName = "ESP32_" + last6chars  // "ESP32_DDEEFF"

MQTT Registration Topic:
  Topic: "system/devices/register"
  Payload: {
    "macAddress": "AABBCCDDEEFF",
    "deviceName": "ESP32_DDEEFF",
    "timestamp": 1234567890
  }

App Storage:
  Firestore (users/{userId}/devices):
    {
      "deviceId": "uuid-generated",  // Internal UUID
      "name": "ESP32_DDEEFF",        // Display name
      "mqttId": "AABBCCDDEEFF",      // MAC for MQTT topics
      "addedAt": Timestamp
    }
    
  Hive Local Storage:
    {
      "id": "uuid-generated",
      "name": "ESP32_DDEEFF",
      "mqttId": "AABBCCDDEEFF",
      "status": "online",
      ...
    }

MQTT Sensor Topics:
  devices/AABBCCDDEEFF/sensors/temperature
  devices/AABBCCDDEEFF/sensors/humidity
  devices/AABBCCDDEEFF/sensors/lights
  devices/AABBCCDDEEFF/sensors/moisture
```

---

## 🎯 Key Benefits of This Implementation

1. ✅ **Zero Manual Configuration** - ESP32 automatically discovers its MAC address
2. ✅ **Unique Device IDs** - MAC addresses are globally unique
3. ✅ **Scalable** - Works with unlimited devices
4. ✅ **User-Friendly** - Simple WiFi credential entry
5. ✅ **Secure** - User-device associations in Firebase
6. ✅ **Real-time** - MQTT for instant registration
7. ✅ **Duplicate Prevention** - Checks for existing devices
8. ✅ **Error Handling** - Clear error messages with retry options
9. ✅ **Accessibility** - TTS support throughout
10. ✅ **Clean Architecture** - Follows project patterns

---

## 📝 Future Enhancements

### Possible Improvements:
- [ ] QR code pairing (ESP32 displays QR, app scans)
- [ ] Multiple WiFi credential storage on ESP32
- [ ] Device firmware update via app
- [ ] Device sharing between users
- [ ] Custom device names during registration
- [ ] Automatic reconnection if WiFi changes
- [ ] Device groups/locations
- [ ] Advanced BLE security with pairing

---

## 📚 Related Documentation

- `docs/USER_DEVICE_ASSOCIATION.md` - User-device architecture
- `docs/MQTT_TESTING_GUIDE.md` - MQTT testing procedures
- `docs/ESP32_IMPLEMENTATION.md` - ESP32 hardware guide
- `docs/SYSTEM_ARCHITECTURE.md` - Overall system design
- `.github/copilot-instructions.md` - Project patterns and conventions

---

## ✅ Verification Checklist

Before deploying to production:

- [ ] Flutter app builds without errors
- [ ] ESP32 code compiles and uploads successfully
- [ ] Firebase security rules are deployed
- [ ] Android permissions are configured
- [ ] BLE scanning works on physical device
- [ ] WiFi credentials are transmitted successfully
- [ ] ESP32 connects to WiFi and MQTT
- [ ] MQTT registration message is received
- [ ] Device appears in user's account
- [ ] Sensor data is published and received
- [ ] Duplicate device detection works
- [ ] Multiple users can each register devices
- [ ] Error handling works for all failure scenarios

---

**Implementation Date**: November 9, 2025  
**Version**: 1.0.0  
**Status**: ✅ Complete and Ready for Testing
