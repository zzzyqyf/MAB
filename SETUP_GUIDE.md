# MAB System Setup Guide
**Complete Installation and Configuration Instructions**

## 📋 Prerequisites

### Software Requirements
- **Flutter SDK**: Version 3.0.0 or higher
- **Dart SDK**: Included with Flutter
- **Android Studio**: For Android development
- **VS Code**: Recommended IDE with Flutter extensions
- **Git**: Version control system
- **Arduino IDE**: For ESP32 programming

### Hardware Requirements
- **ESP32 Development Board** (DevKit v1 recommended)
- **DHT22 Sensor** (Temperature/Humidity)
- **Photoresistor (LDR)** for light measurement
- **Soil Moisture Sensor**
- **Breadboard and Jumper Wires**
- **Resistors**: 10kΩ, 220Ω
- **USB Cable** for ESP32 programming

### System Requirements
- **Operating System**: Windows 10/11, macOS 10.14+, or Ubuntu 18.04+
- **RAM**: Minimum 8GB (16GB recommended)
- **Storage**: At least 10GB free space
- **Internet Connection**: Required for dependencies and MQTT

## 🚀 Quick Installation

### 1. Flutter Environment Setup

**Install Flutter SDK:**
```bash
# Download Flutter SDK from https://flutter.dev/docs/get-started/install
# Extract to your preferred location
# Add Flutter to your PATH

# Verify installation
flutter --version
flutter doctor
```

**Install VS Code Extensions:**
- Flutter
- Dart
- Flutter Widget Snippets

### 2. Clone and Setup Project

```bash
# Clone the repository
git clone <repository-url>
cd MAB

# Install Flutter dependencies
flutter pub get

# Verify everything is working
flutter doctor -v
```

### 3. Firebase Configuration

**Prerequisites:**
- Create a Firebase project at https://console.firebase.google.com
- Enable Authentication and Cloud Firestore

**Android Setup:**
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/` directory

**iOS Setup:**
1. Download `GoogleService-Info.plist` from Firebase Console  
2. Add it to `ios/Runner/` directory

### 4. ESP32 Hardware Setup

**Install Arduino IDE:**
1. Download Arduino IDE from https://arduino.cc
2. Install ESP32 board package via Board Manager
3. Install required libraries

**Required Libraries:**
```
WiFi (ESP32 built-in)
PubSubClient (by Nick O'Leary)
ArduinoJson (by Benoit Blanchon)
DHT sensor library (by Adafruit)
```

## 🔧 Detailed Configuration

### Flutter App Configuration

**1. Update Dependencies**
```yaml
# pubspec.yaml - verify these dependencies exist
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  mqtt_client: ^10.0.0
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  fl_chart: ^0.66.0
  flutter_tts: ^3.8.3
```

**2. Configure MQTT Settings**
```dart
// lib/shared/services/mqtt_manager.dart
static const String brokerHost = 'broker.mqtt.cool';
static const int brokerPort = 1883;
static const String topicPrefix = 'devices';
```

**3. Firebase Initialization**
Ensure `main.dart` includes:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### ESP32 Configuration

**1. Hardware Wiring**
```
ESP32 Pin  →  Component
GPIO 4     →  DHT22 Data Pin
GPIO 32    →  LDR + 10kΩ resistor
GPIO 33    →  Moisture Sensor Signal
GPIO 2     →  Status LED + 220Ω resistor
3.3V       →  Sensor VCC pins
GND        →  Common Ground
```

**2. Code Configuration**
Update these values in the ESP32 Arduino code:
```cpp
// Network credentials
const char* ssid = "YOUR_WIFI_NETWORK";
const char* password = "YOUR_WIFI_PASSWORD";

// Device identification
const char* DEVICE_ID = "ESP32_001";  // Make unique per device
const char* DEVICE_NAME = "Your Device Name";
const char* DEVICE_LOCATION = "Installation Location";
```

**3. Upload ESP32 Code**
1. Connect ESP32 via USB
2. Select correct board: "ESP32 Dev Module"
3. Select correct port
4. Upload the code from `hardware/esp32_sensor_code/`

## 📱 Running the Application

### Mobile App Deployment

**Android:**
```bash
# Connect Android device or start emulator
flutter devices

# Run on connected device
flutter run

# Build APK for distribution
flutter build apk --release
```

**iOS (macOS only):**
```bash
# Open iOS simulator
open -a Simulator

# Run on iOS
flutter run

# Build for App Store
flutter build ios --release
```

**Desktop (Windows/Linux/macOS):**
```bash
# Enable desktop support
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
flutter config --enable-macos-desktop

# Run on desktop
flutter run -d windows
flutter run -d linux
flutter run -d macos
```

### ESP32 Deployment

1. **Power on ESP32** with sensors connected
2. **Monitor Serial Output** at 115200 baud rate
3. **Verify WiFi Connection** - should show IP address
4. **Confirm MQTT Connection** - status messages in serial
5. **Check Data Publishing** - sensor readings every 5 seconds

## ✅ Verification Steps

### 1. System Health Check

**Flutter App:**
- [ ] App starts without errors
- [ ] Firebase connection established
- [ ] MQTT service connects to broker
- [ ] Dashboard loads sensor cards
- [ ] No compilation errors in debug console

**ESP32 Hardware:**
- [ ] WiFi connects successfully
- [ ] MQTT broker connection established
- [ ] Sensor readings appear in serial monitor
- [ ] Status LED indicates connection state
- [ ] Data publishes every 5 seconds

### 2. Data Flow Verification

1. **ESP32 Serial Monitor** should show:
   ```
   MAB ESP32 Sensor Node Starting...
   Pins initialized
   Sensors initialized
   Connected! IP: 192.168.x.x
   Connecting to MQTT broker... Connected!
   Device announced online
   Reading sensors...
   Published temperature: 25.5
   Published humidity: 60.2
   ```

2. **Flutter App** should display:
   - Real-time temperature and humidity values
   - Timestamp updates every 5 seconds
   - Sensor cards showing ESP32 data
   - Connection status indicators

### 3. MQTT Testing (Optional)

Use MQTT client tool to verify data flow:
```bash
# Subscribe to all device topics
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/+"

# Expected output:
# devices/ESP32_001/sensors/temperature {"value":25.5,"timestamp":1234567890}
# devices/ESP32_001/sensors/humidity {"value":60.2,"timestamp":1234567890}
```

## 🔍 Troubleshooting

### Common Issues

**Flutter App Issues:**
```bash
# Clear Flutter cache
flutter clean
flutter pub get

# Update Flutter
flutter upgrade

# Check for issues
flutter doctor -v
```

**ESP32 Connection Issues:**
- Verify WiFi credentials (case-sensitive)
- Check 2.4GHz network (ESP32 doesn't support 5GHz)
- Ensure MQTT port 1883 is not blocked by firewall
- Verify sensor wiring and power connections

**Firebase Issues:**
- Verify `google-services.json` is in correct location
- Check Firebase project configuration
- Ensure authentication rules allow your usage

### Debug Commands

**Flutter Debug:**
```dart
// Add to code for debugging
print('MQTT Connection State: ${client.connectionState}');
print('Received data: $payload');
```

**ESP32 Debug:**
```cpp
// Add to ESP32 code
Serial.println("WiFi Status: " + String(WiFi.status()));
Serial.println("MQTT State: " + String(client.state()));
Serial.println("Free Memory: " + String(ESP.getFreeHeap()));
```

### Performance Optimization

**Flutter App:**
- Use `flutter run --release` for better performance
- Enable code splitting for smaller app size
- Optimize images in `assets/` folder

**ESP32:**
- Adjust sensor reading intervals based on needs
- Implement deep sleep for battery-powered operation
- Use appropriate QoS levels for MQTT messages

## 🎯 Next Steps

Once everything is running:

1. **Monitor System Performance** - Check data consistency and timing
2. **Customize Sensor Thresholds** - Set appropriate ranges for your environment
3. **Enable Notifications** - Configure alerts for optimal growing conditions
4. **Add Multiple Devices** - Scale to monitor multiple growing environments
5. **Implement Data Analytics** - Use historical data for pattern analysis

## 📞 Support

If you encounter issues during setup:

1. **Check Documentation** - Review all markdown files in `docs/`
2. **Verify Prerequisites** - Ensure all requirements are met
3. **Run Flutter Doctor** - Address any issues found
4. **Check Serial Monitor** - ESP32 debug output provides valuable information
5. **Review MQTT Topics** - Ensure topic structure matches expectations

---

**Congratulations!** Your MAB system should now be operational and monitoring environmental conditions in real-time. 🍄📱✨
