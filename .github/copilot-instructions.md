# MAB - Mushroom Agriculture Monitoring System
**AI Coding Agent Instructions**

## Project Overview
MAB is an IoT-based Flutter application for real-time environmental monitoring in mushroom agriculture. The system bridges ESP32 hardware sensors with a cross-platform mobile app via MQTT, featuring live sensor data visualization, device management, and accessibility features.

**Tech Stack**: Flutter (Dart) • Firebase (Auth, Firestore) • MQTT • ESP32 (Arduino C++) • Hive (local storage) • Provider (state management)

## Architecture Patterns

### Clean Architecture with Feature-First Organization
The codebase follows **Clean Architecture** principles with feature-based modules:

```
lib/
├── core/                    # Shared abstractions (errors, usecases, constants)
├── features/                # Feature modules (dashboard, device_management, etc.)
│   └── {feature}/
│       ├── data/           # Data sources, repositories, models
│       ├── domain/         # Entities, repositories (abstract), use cases
│       └── presentation/   # ViewModels, pages, widgets
└── shared/                  # Cross-feature services and widgets
    ├── services/           # MQTT, TTS, device discovery
    └── widgets/            # Reusable UI components
```

**Critical Pattern**: Device management uses Either<Failure, T> from `dartz` for error handling. All use cases return `Either<Failure, Result>` - always check Left (failure) vs Right (success).

### Dependency Injection (GetIt)
- `injection_container.dart` registers all dependencies at startup
- Use `sl<Type>()` to resolve dependencies, never instantiate directly
- Hive boxes must be opened in `initializeHive()` before access
- ViewModels are registered as factories, repositories as lazy singletons

**Example**:
```dart
// ✅ Correct
final deviceRepo = sl<DeviceRepository>();

// ❌ Wrong - breaks DI
final deviceRepo = DeviceRepositoryImpl(localDataSource: ...);
```

### State Management: Provider + ChangeNotifier
- Global state: `DeviceManager` (device list, MQTT subscriptions)
- Feature state: ViewModels (e.g., `DeviceViewModel` for Clean Architecture operations)
- Providers initialized in `main.dart` MultiProvider
- Always call `notifyListeners()` after state mutations in ChangeNotifier classes

## Critical Service Architecture

### Centralized MQTT: MqttManager Singleton
**Do NOT create multiple MQTT clients.** Use the singleton `MqttManager.instance`:

```dart
// Device-specific services register with central manager
await MqttManager.instance.registerDevice(deviceId, handleMessage);

// Publish via manager
await MqttManager.instance.publishMessage(topic, payload);

// Unregister on disposal
MqttManager.instance.unregisterDevice(deviceId);
```

**Topic Structure**: `devices/{deviceId}/sensors/{sensorType}` (temperature, humidity, lights, moisture, co2, bluelight)

**Payload Format**: JSON with ESP32 timestamp:
```json
{"value": 25.5, "timestamp": 1753091366200}
```

### Device Data Flow
1. ESP32 publishes sensor data to MQTT topics
2. `MqttManager` receives message, routes to registered device callbacks
3. `MqttService` (per-device) parses JSON, updates local state
4. Callback triggers `DeviceManager.updateSensorData(deviceId, data)`
5. UI updates via Provider `Consumer<DeviceManager>`

### Hive Local Storage
- **Device persistence**: `deviceBox` stores device metadata (id, name, status, cultivationPhase)
- **Notifications**: `notificationsBox` for local notification history
- **Graph data**: `graphDataBoxKey` caches historical sensor readings
- Boxes defined in `AppConstants`, opened in `injection_container.dart`

## Development Workflows

### Running the App
```powershell
flutter pub get
flutter run
# For release build
flutter build apk --release
```

### Firebase Setup Required
- Place `google-services.json` in `android/app/`
- Place `GoogleService-Info.plist` in `ios/Runner/`
- Firebase initialized in `main.dart` before runApp()

### Testing MQTT Without ESP32
Use an MQTT client to publish test data:
```bash
# Install mosquitto clients
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" \
  -m '{"value": 25.5, "timestamp": 1234567890}'
```

### Debugging Device Connections
- Check `MqttManager` connection: `MqttManager.instance.isConnected`
- Device status updates via `onDeviceConnectionStatusChange` callback
- Enable debug prints: Look for `📨`, `🌡️`, `💧` emoji prefixes in logs
- Serial monitor ESP32 at 115200 baud for hardware debugging

## Project-Specific Conventions

### Accessibility First
- **Text-to-Speech**: Use `TextToSpeech.speak(message)` for user feedback
- **Semantics**: Wrap interactive widgets with `Semantics(label:, hint:)`
- **High Contrast**: App theme enforces `boldText: true` and `textScaleFactor: 1.2`
- **Device reporting**: `_reportDeviceIssues()` in `main.dart` provides TTS status updates

### Device Status Indicators
Three states: `online`, `offline`, `connecting`
- **online**: Data received within last 60 seconds
- **offline**: No data for >60 seconds
- **connecting**: Initial state or reconnection attempt

### Cultivation Phase Tracking
Two cultivation modes with automatic environmental control:
- **Normal Mode** (default): Humidity 80-85%, Temp 25-30°C
- **Pinning Mode** (timed 1-24 hours): Humidity 90-95%, Temp 18-22°C

**Actuator Control Logic** (ESP32 automatic):
- Humidity: Both humidifiers ON if below range, one ON if in range, both OFF if above
- Temperature: Fan1 always ON, Fan2 ON only when above temp range
- Timer managed by ESP32, auto-reverts to Normal mode when expired

### Responsive UI
- Grid layout: `crossAxisCount = mediaQuery.size.width > 600 ? 3 : 2`
- Use `mediaQuery.size.width *` percentage for sizing
- Cards use gradient backgrounds with status-based colors

## Common Pitfalls

❌ **Creating new MQTT clients per device** → Use `MqttManager.instance.registerDevice()`  
❌ **Not parsing JSON timestamps from ESP32** → Use `_parseJsonPayload()` helper  
❌ **Forgetting to unregister MQTT on dispose** → Call `MqttManager.instance.unregisterDevice()`  
❌ **Direct repository instantiation** → Always use `sl<Type>()` from GetIt  
❌ **Missing notifyListeners()** → State won't update in Provider consumers  
❌ **Hardcoding device IDs** → Reference via `device['id']` from DeviceManager list  

## Key Files Reference

- **main.dart**: App entry, MultiProvider setup, home dashboard with device grid
- **injection_container.dart**: GetIt registration, Hive box initialization
- **lib/shared/services/mqtt_manager.dart**: Centralized MQTT singleton
- **lib/shared/services/mqttservice.dart**: Per-device MQTT handler
- **lib/features/device_management/**: Clean Architecture device CRUD operations
- **lib/features/dashboard/presentation/services/mode_controller_service.dart**: Mode & timer management
- **lib/features/dashboard/presentation/widgets/mode_selector_widget.dart**: Mode toggle UI with timer picker
- **lib/features/dashboard/presentation/models/mushroom_phase.dart**: Mode definitions (Normal/Pinning)
- **lib/core/constants/app_constants.dart**: All magic strings/values
- **esp32/main.cpp**: ESP32 sensor + actuator control with timer
- **docs/SYSTEM_ARCHITECTURE.md**: Full system design and data flow diagrams
- **docs/MODE_CONTROL_IMPLEMENTATION.md**: Complete mode system documentation
- **SETUP_GUIDE.md**: Complete setup including ESP32 hardware configuration

## ESP32 Integration Notes

**Hardware**: ESP32 DevKit v1 with DHT22 (GPIO 4), LDR (GPIO 32), moisture sensor (GPIO 33)  
**WiFi**: 2.4GHz only, credentials in Arduino code  
**Broker**: broker.mqtt.cool:1883 (public, no auth)  
**Data Rate**: Publishes every 5 seconds  
**Code Location**: Expected in `hardware/esp32_sensor_code/` (currently empty - Arduino .ino files)

## Testing Strategy

- **Widget tests**: `test/widget_test.dart` (currently basic counter test - needs updating)
- **MQTT testing**: Use mosquitto_pub/sub for message verification
- **Device simulation**: Publish to device topics without physical hardware
- **Firebase**: Use emulators for local testing (not yet configured)

---

**When adding features**: Follow Clean Architecture layers (data → domain → presentation), register in DI container, use Either for error handling, and ensure MQTT messages route through MqttManager singleton.
