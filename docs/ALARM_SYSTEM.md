# Alarm System Documentation

## Overview
The MAB app now includes an automatic alarm system that triggers when sensor readings reach critical/urgent levels. The alarm provides both audible (beeping sound) and visual (red banner) alerts to warn users of dangerous conditions.

## Features

### 🚨 Automatic Detection
The alarm automatically monitors sensor data and triggers when ANY of the following conditions occur:

1. **Humidity** - Outside safe range for current mode:
   - Normal Mode: < 80% or > 85%
   - Pinning Mode: < 90% or > 95%

2. **Temperature** - Above critical threshold:
   - > 30°C (too hot)

3. **Water Level** - Below minimum:
   - < 30% (too dry)

### 🔊 Alarm Behavior

**When Triggered:**
- Plays a beep sound every 2 seconds continuously
- Shows a red alert banner at the top of the overview page
- Announces the reason via Text-to-Speech once
- Displays which sensor(s) are in critical state

**Beep Sound:**
- Uses system alarm tone (Android ToneGenerator)
- Fallback to haptic feedback if sound unavailable
- Volume controlled by device alarm volume

**Visual Alert:**
- Red banner with warning icon
- Shows device name and critical sensor details
- Mute button to stop the alarm manually

### 📱 User Interface

**Alert Banner Components:**
```
🚨 URGENT ALERT                           [🔇 Mute]
Device Name: Temperature is critical: 32.5°C
```

- **Warning Icon**: Amber warning symbol
- **Title**: "🚨 URGENT ALERT" in bold white text
- **Message**: Device name and specific sensor issue(s)
- **Mute Button**: Stops the alarm (icon changes to volume_off)

### 🎯 Automatic Resolution
The alarm **automatically stops** when:
- All sensor readings return to safe ranges
- User navigates away from the overview page
- User manually mutes the alarm

## Implementation Details

### Files Modified/Created

1. **`lib/shared/services/alarm_service.dart`** (NEW)
   - Singleton service managing alarm state
   - Beep playback via platform channel
   - TTS announcements
   - Sensor status checking

2. **`lib/features/dashboard/presentation/pages/overview.dart`** (MODIFIED)
   - Integrated AlarmService
   - Added alarm banner UI
   - Automatic sensor monitoring

3. **`android/app/src/main/kotlin/.../MainActivity.kt`** (MODIFIED)
   - Platform channel for playing system beep
   - Uses Android ToneGenerator for alarm sound

### Architecture

```
Overview Page (TentPage)
    ↓
ModeControllerService ← Provides current mode
    ↓
SensorStatusService ← Determines if sensors are urgent (red)
    ↓
AlarmService ← Triggers/stops alarm based on status
    ↓
Platform Channel → Android ToneGenerator (beep sound)
```

### Key Classes

**AlarmService**
- `startAlarm(String reason)` - Begin beeping and show reason
- `stopAlarm()` - Stop beeping
- `checkSensorAlarm(...)` - Evaluate sensor data and trigger/stop alarm
- `isAlarmActive` - Current alarm state
- `currentAlarmReason` - Description of critical condition

**Platform Channel**
- Channel name: `"alarm_channel"`
- Method: `"playBeep"` - Plays system alarm tone

## Testing

### Test Scenario 1: Temperature Too High
1. Open a device's overview page
2. Simulate ESP32 publishing temperature > 30°C:
   ```bash
   mosquitto_pub -h broker.mqtt.cool \
     -t "devices/ESP32_001/sensors/temperature" \
     -m '{"value": 32.5, "timestamp": 1234567890}'
   ```
3. **Expected**: Alarm beeps, red banner shows "Temperature is critical: 32.5°C"

### Test Scenario 2: Humidity Out of Range (Normal Mode)
1. Ensure device is in Normal Mode (80-85% range)
2. Publish humidity < 80% or > 85%:
   ```bash
   mosquitto_pub -h broker.mqtt.cool \
     -t "devices/ESP32_001/sensors/humidity" \
     -m '{"value": 70.0, "timestamp": 1234567890}'
   ```
3. **Expected**: Alarm beeps, red banner shows "Humidity is critical: 70.0%"

### Test Scenario 3: Multiple Critical Sensors
1. Publish multiple urgent values:
   ```bash
   # High temperature
   mosquitto_pub -h broker.mqtt.cool \
     -t "devices/ESP32_001/sensors/temperature" \
     -m '{"value": 35.0, "timestamp": 1234567890}'
   
   # Low water
   mosquitto_pub -h broker.mqtt.cool \
     -t "devices/ESP32_001/sensors/moisture" \
     -m '{"value": 20.0, "timestamp": 1234567890}'
   ```
3. **Expected**: Alarm beeps, banner shows both issues:
   "Temperature is critical: 35.0°C, Water level is critical: 20.0%"

### Test Scenario 4: Manual Mute
1. Trigger alarm (any critical condition)
2. Tap the mute button (🔇) in the alert banner
3. **Expected**: Beeping stops immediately, banner remains visible but muted

### Test Scenario 5: Auto-Clear
1. Trigger alarm with critical temperature
2. Publish normal temperature:
   ```bash
   mosquitto_pub -h broker.mqtt.cool \
     -t "devices/ESP32_001/sensors/temperature" \
     -m '{"value": 25.0, "timestamp": 1234567890}'
   ```
3. **Expected**: Alarm stops automatically, banner disappears, TTS says "Alert cleared"

## Accessibility

The alarm system is fully accessible:

- **Audible Alert**: Beep sound for hearing users
- **Haptic Feedback**: Vibration fallback if sound unavailable
- **Text-to-Speech**: Announces the alert reason
- **Visual Banner**: High-contrast red alert for visual users
- **Semantics**: Mute button has proper label and tooltip

## Configuration

### Beep Interval
Modify in `alarm_service.dart`:
```dart
// Current: 2 seconds
_beepTimer = Timer.periodic(const Duration(seconds: 2), ...);

// To change: 
_beepTimer = Timer.periodic(const Duration(seconds: 1), ...); // 1 second
```

### Alarm Volume
Controlled by device's alarm volume setting (Android AudioManager.STREAM_ALARM)

### Beep Sound Type
Modify in `MainActivity.kt`:
```kotlin
// Current: TONE_CDMA_ALERT_CALL_GUARD
toneGenerator?.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 200)

// Other options:
// TONE_CDMA_EMERGENCY_RINGBACK
// TONE_CDMA_ABBR_ALERT
// TONE_PROP_BEEP
```

## Troubleshooting

### No Sound Playing
1. Check device alarm volume is not muted
2. Verify app has permission to play sounds
3. Check LogCat for "BEEP_ERROR" messages
4. Fallback haptic feedback should still work

### Alarm Doesn't Stop
1. Check sensor values are actually returning to safe range
2. Verify `getSensorStatusColor()` is returning `Colors.green`
3. Check for errors in console logs

### Banner Not Showing
1. Verify alarm is actually active: `_alarmService.isAlarmActive`
2. Check if `checkSensorAlarm()` is being called
3. Ensure `setState()` is called after alarm state changes

## Future Enhancements

- [ ] Configurable alarm thresholds per device
- [ ] Snooze functionality (silence for 5/10/15 minutes)
- [ ] Alarm history log
- [ ] Different beep patterns for different severity levels
- [ ] Push notifications when app is in background
- [ ] Email alerts for critical conditions
- [ ] Customizable alarm sounds

## Notes

- Alarm only activates when viewing the device's overview page
- Only one alarm can be active at a time (per AlarmService singleton)
- Navigating away from overview page automatically stops the alarm
- Alarm state is NOT persisted - resets when page is revisited
