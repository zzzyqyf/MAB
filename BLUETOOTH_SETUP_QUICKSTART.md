# Quick Setup: Bluetooth Device Registration
## 🚀 Get Started in 5 Minutes

---

## ✅ What You Need to Do

### 1. **Update Firebase Security Rules** (REQUIRED)

1. Open Firebase Console: https://console.firebase.google.com/
2. Select your project: `mab-fyp`
3. Go to **Firestore Database** → **Rules** tab
4. Copy the rules from: `docs/FIRESTORE_SECURITY_RULES.rules`
5. Paste into Firebase Console
6. Click **"Publish"**

**Why?** This ensures users can only access their own devices.

---

### 2. **Install Flutter Dependencies**

```powershell
cd d:\fyp\Backup\MAB
flutter pub get
```

**New Package Added**: `flutter_blue_plus: ^1.32.0`

---

### 3. **Run Flutter App**

```powershell
flutter run
```

**Note**: Android permissions for Bluetooth are already configured in `AndroidManifest.xml`

---

### 4. **Upload ESP32 Code**

#### Option A: Using PlatformIO (Recommended)

```powershell
cd d:\fyp\Backup\MAB\esp32
pio run --target upload
pio device monitor -b 115200
```

#### Option B: Using Arduino IDE

1. Open Arduino IDE
2. Copy content from `esp32/bluetooth_provisioning_main.cpp`
3. Create new sketch and paste
4. Install required libraries:
   - PubSubClient
   - DHT sensor library
   - Adafruit Unified Sensor
   - ArduinoJson
   - NimBLE-Arduino
5. Select board: **ESP32 Dev Module**
6. Click **Upload**
7. Open **Serial Monitor** at **115200 baud**

---

## 📱 How to Use

### User Registration Flow:

1. **Open App** → Login/Signup
2. **Navigate to** "Add Device" page
3. **Enter WiFi Credentials**:
   - SSID: Your WiFi network name
   - Password: Your WiFi password
4. **Double-tap "Save"** button
5. **Wait for device** (shows progress indicator)
6. **Device appears** in dashboard ✅

---

## 🔍 Verification Steps

### Check ESP32 Serial Monitor:

You should see:
```
✅ BLE Server started and advertising
📱 BLE Client connected
📩 Received WiFi credentials
✅ WiFi connected!
✅ Device registered successfully!
```

### Check Flutter App Debug Console:

You should see:
```
🔵 BluetoothProvisioningService: Found device: ESP32_XXXXXX
✅ BluetoothProvisioningService: Credentials sent
📨 DeviceRegistrationService: Received registration message
✅ Device added: ID=..., MAC=AABBCCDDEEFF
```

### Check Firebase Console:

1. Go to Firestore Database
2. Open your user document
3. Check `devices` array
4. You should see:
```json
{
  "deviceId": "uuid-here",
  "name": "ESP32_XXXXXX",
  "mqttId": "AABBCCDDEEFF",
  "addedAt": "timestamp"
}
```

---

## 🐛 Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| **App can't find ESP32** | • Power on ESP32<br>• Enable Bluetooth on phone<br>• Grant Location permission |
| **WiFi fails** | • Check SSID/password<br>• Use 2.4GHz WiFi (not 5GHz)<br>• Check signal strength |
| **MQTT not connecting** | • Check internet connection<br>• Verify broker: api.milloserver.uk:8883<br>• Check MQTT credentials (zhangyifei/123456)<br>• Ensure TLS port 8883 is accessible |
| **"Already registered" error** | • This is correct if device was added before<br>• Remove device first, then re-add |

---

## 📊 System Status Indicators

### ESP32 LED:
- **Slow blink**: Searching for BLE connection
- **Steady ON**: Connected to BLE client
- **Fast blink**: Connecting to WiFi
- **Rapid blink**: Device registered successfully

### App UI:
- **Scanning...**: Looking for ESP32 via Bluetooth
- **Connecting...**: Establishing BLE connection
- **Sending credentials...**: Transmitting WiFi info
- **Waiting for device...**: ESP32 connecting to WiFi/MQTT
- **Device added!**: Success ✅

---

## 📚 Full Documentation

For complete details, see: `docs/BLUETOOTH_DEVICE_REGISTRATION.md`

---

## ⚠️ Important Notes

1. **First-time users**: Grant all permissions when app requests them
2. **ESP32 must be powered on** and showing "BLE Server started" in serial monitor
3. **WiFi must be 2.4GHz** - ESP32 doesn't support 5GHz networks
4. **Location permission** is required by Android for BLE scanning (system requirement)
5. **Each device can only be registered once** per user account

---

## ✅ Success Criteria

You've successfully set up the system when:
- ✅ ESP32 serial shows "Device registered successfully"
- ✅ App shows "Device added successfully"
- ✅ Device appears in app dashboard
- ✅ Sensor data is visible in real-time
- ✅ Device is in your Firestore user document

---

## 🎯 Next Steps After Setup

1. Test with multiple devices (each will have unique MAC)
2. Verify sensor data is updating
3. Test device removal and re-registration
4. Try with multiple user accounts

---

**Setup Time**: ~5 minutes  
**Difficulty**: Easy  
**Status**: ✅ Ready to Use

Need help? Check `docs/BLUETOOTH_DEVICE_REGISTRATION.md` for detailed troubleshooting.
