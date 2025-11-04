# Mode Control System Implementation Summary

## Overview
Implemented a two-mode cultivation system (Normal/Pinning) with automatic environmental control via ESP32-controlled humidifiers and fans.

## Files Created/Modified

### Flutter App (lib/)

#### 1. **Updated Phase Model**
- `lib/features/dashboard/presentation/models/mushroom_phase.dart`
  - Changed from 4 phases to 2 modes: `CultivationMode.normal` and `CultivationMode.pinning`
  - Normal Mode: Humidity 80-85%, Temp 25-30°C
  - Pinning Mode: Humidity 90-95%, Temp 18-22°C

#### 2. **New Mode Controller Service**
- `lib/features/dashboard/presentation/services/mode_controller_service.dart`
  - Manages mode state and timer countdown
  - Sends MQTT commands to ESP32: `devices/{deviceId}/mode/set`
  - Receives actuator status: `devices/{deviceId}/actuators/status`
  - Methods:
    - `setNormalMode()` - Switch to normal mode
    - `setPinningMode(int hours)` - Activate pinning with timer
    - `cancelPinningMode()` - Cancel and revert to normal
    - `formattedRemainingTime` - Get countdown display

#### 3. **New Mode Selector Widget**
- `lib/features/dashboard/presentation/widgets/mode_selector_widget.dart`
  - Toggle switch between Normal/Pinning modes
  - Timer picker dialog (1-24 hours slider)
  - Live countdown display
  - Threshold display for each mode
  - Actuator status chips (Humidifier 1/2, Fan 1/2)
  - Text-to-speech announcements

### ESP32 (esp32/)

#### 4. **Updated ESP32 Main Code**
- `esp32/main.cpp`
  - Added 4 relay control pins:
    - GPIO 25: Humidifier 1
    - GPIO 26: Humidifier 2
    - GPIO 27: Fan 1 (always ON)
    - GPIO 14: Fan 2
  - Mode management with timer
  - MQTT subscription to `devices/{deviceId}/mode/set`
  - Automatic control functions:
    - `controlHumidity()` - 3-state humidity control
    - `controlTemperature()` - 2-state temperature control (Fan1 always on)
  - Timer countdown on ESP32 side
  - Publishes actuator states every 5 seconds

## MQTT Topics

### App → ESP32 (Control)
```
devices/{deviceId}/mode/set
Payload: {"mode": "normal"} or {"mode": "pinning", "duration": 3600}
```

### ESP32 → App (Status)
```
devices/{deviceId}/mode/status
Payload: "normal" or "pinning"

devices/{deviceId}/actuators/status
Payload: {
  "humidifier1": "on/off",
  "humidifier2": "on/off",
  "fan1": "on/off",
  "fan2": "on/off",
  "mode": "normal/pinning",
  "pinning_remaining": 3600  // seconds (only if pinning active)
}
```

## Actuator Control Logic

### Humidity Control (3-state)
| Condition | Humidifier 1 | Humidifier 2 |
|-----------|--------------|--------------|
| Below min | ON | ON |
| In range  | ON | OFF |
| Above max | OFF | OFF |

### Temperature Control (2-state)
| Condition | Fan 1 | Fan 2 |
|-----------|-------|-------|
| Below min | ON | OFF |
| In range  | ON | OFF |
| Above max | ON | ON |

**Note**: Fan 1 is ALWAYS ON for continuous air circulation.

## User Flow

1. **Normal Mode** (Default)
   - Device starts in Normal mode
   - ESP32 maintains 80-85% humidity, 25-30°C temp
   - No timer active

2. **Activate Pinning Mode**
   - User toggles switch to Pinning
   - Timer picker dialog appears
   - User selects 1-24 hours using slider
   - Click "Activate" or "Cancel"
   - If activated: ESP32 receives mode + duration
   - Countdown begins immediately

3. **During Pinning Mode**
   - UI shows live countdown (HH:MM:SS)
   - ESP32 maintains 90-95% humidity, 18-22°C temp
   - Actuators adjust automatically every 5 seconds
   - Mode widget shows "Pinning Mode 🍄" with orange theme

4. **Timer Expires**
   - ESP32 automatically reverts to Normal mode
   - App receives mode status update
   - UI updates to show Normal mode
   - Countdown disappears

5. **Manual Cancel**
   - User toggles switch to Normal during Pinning
   - Timer cancelled immediately
   - ESP32 switches to Normal mode
   - TTS announces "Switched to Normal mode"

## Integration into Existing UI

To add the mode selector to a device page:

```dart
import 'package:flutter/material.dart';
import '../widgets/mode_selector_widget.dart';

class DevicePage extends StatelessWidget {
  final String deviceId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... other widgets ...
          
          ModeSelectorWidget(deviceId: deviceId),
          
          // ... other widgets ...
        ],
      ),
    );
  }
}
```

## ESP32 Hardware Wiring

```
ESP32 Pin   →   Component
---------       ---------
GPIO 4      →   DHT22 Data
GPIO 25     →   Relay 1 (Humidifier 1)
GPIO 26     →   Relay 2 (Humidifier 2)
GPIO 27     →   Relay 3 (Fan 1)
GPIO 14     →   Relay 4 (Fan 2)
GPIO 35     →   Water Level Sensor
3.3V        →   Sensor VCC
5V          →   Relay Module VCC
GND         →   Common Ground
```

## Testing Checklist

### Flutter App
- [ ] Toggle switch changes mode
- [ ] Timer picker shows/hides correctly
- [ ] Slider adjusts 1-24 hours
- [ ] Countdown updates every second
- [ ] Cancel button works in picker
- [ ] TTS announces mode changes
- [ ] Actuator chips update in real-time

### ESP32
- [ ] Receives mode commands via MQTT
- [ ] Relays control humidifiers/fans correctly
- [ ] Timer countdown works on ESP32
- [ ] Auto-reverts to Normal after timer
- [ ] Publishes actuator status every 5s
- [ ] Sensor readings still working
- [ ] Fan 1 stays ON always

### Integration
- [ ] Mode persists if app closes/reopens
- [ ] Multiple devices have independent modes
- [ ] Network disconnection doesn't break timer
- [ ] Sensor thresholds trigger correct actuators

## Next Steps

1. **Add to Device Overview Page**
   - Import `ModeSelectorWidget` in `overview.dart`
   - Add widget below sensor cards

2. **Update DeviceManager**
   - Store current mode in device data
   - Add `updateDeviceMode(deviceId, mode)` method

3. **Persistence**
   - Save mode state to Hive box
   - Restore on app restart

4. **Notifications**
   - Alert when Pinning mode activated
   - Notify 5 min before timer expires
   - Alert when auto-reverted to Normal

5. **UI Enhancements**
   - Add progress bar for timer
   - Show mode history/logs
   - Quick timer presets (2h, 4h, 6h, 8h)

## Troubleshooting

**Problem**: Timer doesn't count down
- **Solution**: Check `_updateTimer()` is called in `initState()`
- **Solution**: Verify ESP32 is sending `pinning_remaining` in status

**Problem**: Actuators not responding
- **Solution**: Check relay wiring and pin definitions
- **Solution**: Verify MQTT topic subscription in ESP32
- **Solution**: Check relay module power supply (5V)

**Problem**: Mode doesn't persist after app restart
- **Solution**: Not implemented yet - add Hive persistence
- **Solution**: ESP32 holds mode, app queries on startup

**Problem**: Fan 1 turns off
- **Solution**: Check `fan1State = true` is set in setup
- **Solution**: Verify control logic doesn't turn it off

---

## Summary
✅ Two-mode system (Normal/Pinning) implemented  
✅ ESP32 manages timer and auto-reversion  
✅ Automatic humidity/temperature control  
✅ Live countdown in UI  
✅ Independent per-device modes  
✅ MQTT bidirectional communication  
✅ Actuator status feedback  

**Ready for integration and testing!**
