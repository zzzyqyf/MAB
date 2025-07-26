# System Architecture Documentation
**MAB - Mushroom Agriculture Monitoring System**

## Overview

The MAB system implements a modern IoT architecture combining mobile application technology with embedded sensor hardware for real-time environmental monitoring in agricultural applications.

## High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   ESP32 Sensors │◄──►│  MQTT Broker    │◄──►│  Flutter App    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│ Physical Sensors│    │  Message Queue  │    │   Firebase      │
│ DHT22, LDR, etc │    │   & Routing     │    │   Backend       │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Component Architecture

### 1. Hardware Layer (ESP32)
**Responsibilities:**
- Environmental data collection
- Sensor interfacing and calibration
- WiFi connectivity management
- MQTT client implementation
- Data preprocessing and validation

**Technologies:**
- **Microcontroller**: ESP32 DevKit v1
- **Sensors**: DHT22, Photoresistor, Moisture sensor
- **Communication**: WiFi 802.11 b/g/n
- **Protocol**: MQTT with JSON payloads
- **Programming**: Arduino C++ framework

**Data Flow:**
```
Sensors → ADC/Digital Read → Data Validation → JSON Encoding → MQTT Publish
```

### 2. Middleware Layer (MQTT Broker)
**Responsibilities:**
- Message routing and delivery
- Client connection management
- Topic-based message filtering
- Retained message storage
- Quality of Service (QoS) handling

**Technologies:**
- **Broker**: broker.mqtt.cool (public MQTT broker)
- **Protocol**: MQTT v3.1.1
- **Port**: 1883 (unencrypted)
- **QoS Levels**: 0 (fire and forget), 1 (at least once)
- **Topics**: Hierarchical structure `devices/{deviceId}/sensors/{sensorType}`

**Message Flow:**
```
Publisher (ESP32) → Broker → Subscriber (Flutter App)
```

### 3. Application Layer (Flutter)
**Responsibilities:**
- User interface and experience
- Real-time data visualization
- MQTT client management
- Data persistence and caching
- User authentication and profiles
- Notification and alerting

**Technologies:**
- **Framework**: Flutter (Dart language)
- **State Management**: Provider pattern
- **MQTT Client**: mqtt_client package
- **UI Components**: Material Design
- **Charts**: fl_chart package
- **Text-to-Speech**: flutter_tts package

**Architecture Pattern:**
```
UI Layer → Provider State → Service Layer → Data Layer
```

### 4. Backend Services (Firebase)
**Responsibilities:**
- User authentication
- Historical data storage
- User preferences and settings
- Push notifications
- Analytics and reporting

**Technologies:**
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage (if needed)
- **Analytics**: Firebase Analytics
- **Messaging**: Firebase Cloud Messaging

## Data Architecture

### MQTT Topic Structure
```
devices/
├── {deviceId}/
│   ├── sensors/
│   │   ├── temperature
│   │   ├── humidity
│   │   ├── lights
│   │   ├── bluelight
│   │   ├── co2
│   │   └── moisture
│   ├── status
│   ├── heartbeat
│   └── control
```

### Data Payload Format
```json
{
  "value": 25.5,
  "timestamp": 1753091366200,
  "device_id": "ESP32_001",
  "location": "Greenhouse A"
}
```

### Database Schema (Firestore)
```
Users Collection:
├── userId
│   ├── profile (name, email, preferences)
│   ├── devices (associated device list)
│   └── settings (notifications, thresholds)

Devices Collection:
├── deviceId
│   ├── metadata (name, location, type)
│   ├── sensors (configuration, calibration)
│   └── status (online, last_seen, version)

SensorData Collection:
├── documentId
│   ├── device_id
│   ├── sensor_type
│   ├── value
│   ├── timestamp
│   └── location
```

## Security Architecture

### Network Security
- **WiFi**: WPA2/WPA3 encryption
- **MQTT**: Username/password authentication (configurable)
- **Firebase**: OAuth 2.0 authentication
- **SSL/TLS**: Optional for MQTT (port 8883)

### Data Security
- **Local Storage**: Encrypted shared preferences
- **Transit**: JSON over MQTT (can be encrypted)
- **Rest**: Firebase security rules
- **Authentication**: Multi-factor support via Firebase

### Access Control
- **Device Level**: Unique device IDs and credentials
- **User Level**: Firebase user authentication
- **Data Level**: Firestore security rules
- **API Level**: Topic-based access control

## Performance Architecture

### Scalability Considerations
- **Horizontal Scaling**: Multiple ESP32 devices per user
- **Vertical Scaling**: Enhanced sensor capabilities
- **Load Distribution**: MQTT broker handles multiple clients
- **Data Partitioning**: Time-based data archiving

### Performance Metrics
- **Latency**: < 1 second for real-time updates
- **Throughput**: 100+ messages/minute per device
- **Reliability**: 99.9% uptime target
- **Battery Life**: 24+ hours on battery (with optimization)

### Optimization Strategies
- **ESP32**: Deep sleep modes for battery operation
- **MQTT**: Retained messages for latest values
- **Flutter**: Efficient state management and rebuilds
- **Firebase**: Optimized query patterns

## Deployment Architecture

### Development Environment
```
Developer Machine → Git Repository → Local Testing
```

### Production Environment
```
ESP32 Devices → Public MQTT Broker → Mobile App Stores
```

### Continuous Integration
- **Version Control**: Git with branch-based development
- **Testing**: Unit tests, widget tests, integration tests
- **Building**: Flutter build system for multiple platforms
- **Distribution**: Google Play Store, Apple App Store

## Monitoring and Maintenance

### System Monitoring
- **Device Health**: Heartbeat messages every 30 seconds
- **Connection Status**: MQTT connection state monitoring
- **Data Quality**: Sensor reading validation
- **Performance**: App performance metrics via Firebase

### Maintenance Procedures
- **Firmware Updates**: OTA updates for ESP32 (future)
- **App Updates**: Store-based distribution
- **Configuration**: Remote configuration via MQTT control topics
- **Debugging**: Serial monitoring and MQTT message inspection

## Future Architecture Considerations

### Planned Enhancements
- **Edge Computing**: Local data processing on ESP32
- **Mesh Networking**: ESP-NOW for device-to-device communication
- **Machine Learning**: Predictive analytics for optimal conditions
- **Cloud Integration**: AWS IoT or Azure IoT Hub integration

### Scalability Roadmap
- **Enterprise Features**: Multi-tenant architecture
- **Advanced Analytics**: Big data processing pipeline
- **Mobile Gateway**: ESP32 as WiFi access point
- **Integration APIs**: RESTful APIs for third-party integration

---

This architecture provides a solid foundation for IoT agricultural monitoring while maintaining flexibility for future enhancements and scaling requirements.
