# MAB - Mushroom Agriculture Monitoring System
**Final Year Project - IoT Environmental Monitoring Solution**

## 🍄 Project Overview

The **Mushroom Agriculture Monitoring (MAB)** system is an innovative IoT solution designed to monitor and optimize environmental conditions for mushroom cultivation. This system integrates ESP32 hardware sensors with a Flutter mobile application, providing real-time environmental data through MQTT communication.

## 🎯 Project Objectives

- **Real-time Environmental Monitoring**: Track temperature, humidity, light intensity, and CO2 levels
- **Mobile-First Interface**: Cross-platform Flutter application for iOS and Android
- **IoT Integration**: ESP32 sensors with WiFi connectivity and MQTT communication
- **Data Visualization**: Interactive graphs and real-time sensor data display
- **Alert System**: Notifications for optimal growing conditions
- **Scalable Architecture**: Support for multiple sensor devices and environments

## 🏗️ System Architecture

```
[ESP32 Sensors] ←→ [MQTT Broker] ←→ [Flutter App] ←→ [Firebase]
```

### Technology Stack

**Mobile Application:**
- **Framework**: Flutter (Dart)
- **State Management**: Provider Pattern
- **Communication**: MQTT Client
- **Backend**: Firebase (Authentication, Cloud Firestore)
- **UI/UX**: Material Design with custom accessibility features

**Hardware:**
- **Microcontroller**: ESP32 DevKit
- **Sensors**: DHT22 (Temperature/Humidity), LDR (Light), CO2 sensor
- **Communication**: WiFi + MQTT Protocol
- **Power**: USB/Battery powered

**Infrastructure:**
- **MQTT Broker**: broker.mqtt.cool
- **Cloud Services**: Firebase Suite
- **Platforms**: Android, iOS, Web, Windows, macOS, Linux

## 📱 Key Features

### Environmental Monitoring
- ✅ **Temperature Monitoring** - DHT22 sensor with ±0.5°C accuracy
- ✅ **Humidity Tracking** - Real-time humidity percentage
- ✅ **Light Intensity** - Photoresistor-based light measurement
- ✅ **CO2 Levels** - Carbon dioxide concentration monitoring
- ✅ **Moisture Detection** - Soil/substrate moisture levels
- ✅ **Blue Light Monitoring** - Specialized light spectrum tracking

### Mobile Application
- 📊 **Real-time Dashboard** - Live sensor data with timestamp
- 📈 **Interactive Graphs** - Historical data visualization
- 🔔 **Smart Notifications** - Alert system for optimal conditions
- 👤 **User Profiles** - Personal settings and preferences
- 📱 **Cross-platform** - Native performance on all devices
- ♿ **Accessibility** - Text-to-speech and visual accommodations

### IoT Integration
- 🌐 **WiFi Connectivity** - Wireless sensor network
- 📡 **MQTT Communication** - Lightweight, real-time messaging
- ⏱️ **Timestamp Synchronization** - ESP32 and app time coordination
- 🔄 **Auto-reconnection** - Robust connection handling
- 📍 **Device Management** - Multiple sensor device support

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (≥3.0.0)
- Android Studio / VS Code
- ESP32 Development Board
- DHT22 Sensor
- Arduino IDE

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd MAB
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Configure Firebase project settings

4. **Run the application**
   ```bash
   flutter run
   ```

5. **Set up ESP32 hardware**
   - Flash the Arduino code from `hardware/esp32_sensor_code/`
   - Configure WiFi credentials
   - Connect sensors according to wiring diagram

## 📊 Live Data Flow

Current system status: **✅ OPERATIONAL**

The system is successfully collecting and displaying:
- **Temperature**: 33.2°C (from DHT22 sensor)
- **Humidity**: 54.8% (from DHT22 sensor)
- **Real-time Updates**: Every 5 seconds
- **MQTT Topics**: `devices/ESP32_001/sensors/{sensor_type}`

## 🔧 Configuration

### MQTT Settings
- **Broker**: broker.mqtt.cool:1883
- **Topic Pattern**: `devices/{deviceName}/sensors/{sensorType}`
- **Data Format**: JSON with timestamp
- **QoS Level**: 1 (At least once delivery)

### Sensor Thresholds
- **Temperature**: 18°C - 24°C (optimal for mushrooms)
- **Humidity**: 80% - 95% (high humidity required)
- **CO2**: 400-1000 ppm (controlled atmosphere)
- **Light**: Low light conditions preferred

## 📁 Project Structure

```
MAB/
├── lib/                          # Flutter application source
│   ├── main.dart                 # Application entry point
│   ├── features/                 # Feature-based modules
│   │   ├── authentication/       # User login/register
│   │   ├── dashboard/            # Main sensor dashboard
│   │   ├── profile/              # User profile management
│   │   └── reports/              # Data reports and graphs
│   └── shared/                   # Shared services and widgets
│       ├── services/             # MQTT, Firebase services
│       └── widgets/              # Reusable UI components
├── hardware/                     # ESP32 implementation
├── docs/                         # Technical documentation
└── test/                         # Flutter test suite
```

## 🔬 Technical Implementation

### Real-time Data Processing
- **JSON Payload Format**: `{"value": 25.5, "timestamp": 1753091366200}`
- **Timestamp Handling**: ESP32 millis() + Flutter DateTime parsing
- **Data Validation**: Type checking and range validation
- **Error Handling**: Automatic reconnection and retry logic

### UI/UX Design
- **Responsive Cards**: Sensor data displayed in organized cards
- **Color Coding**: Visual indicators for optimal/warning ranges
- **Accessibility**: Screen reader support and large text options
- **Dark/Light Themes**: User preference based theming

## 🎓 Academic Context

This project represents a comprehensive final year capstone demonstrating:

- **Software Engineering**: Clean architecture, design patterns, testing
- **IoT Development**: Hardware integration, sensor programming, wireless communication
- **Mobile Development**: Cross-platform app development, state management
- **Systems Integration**: MQTT protocols, cloud services, real-time data
- **Project Management**: Version control, documentation, professional presentation

## 👥 Contributors

- **Student**: [ZHANG YIFEI]
- **Supervisor**: [DR.NG KENG YAP]

## 📄 License

This project is submitted as part of academic requirements. All rights reserved.

## 📞 Contact

- **Email**: [213853@student.upm.edu.my]
- **Student ID**: [213853/ZHANG YIFEI]

---

**MAB System** - Revolutionizing mushroom agriculture through IoT innovation 🍄📱⚡
