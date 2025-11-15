# MQTT Testing & Monitoring Guide

## 📡 Overview

Your ESP32 publishes sensor data and actuator status to MQTT topics. You can monitor all of this via terminal using `mosquitto_sub` and `mosquitto_pub`.

**Broker Information:**
- Host: `api.milloserver.uk`
- Port: `8883` (TLS/SSL)
- Username: `zhangyifei`
- Password: `123456`
- Certificate: Uses system CA certificates (no custom CA required)

---

## 🛠️ Installation

### Windows (PowerShell)

**Option 1: Using Chocolatey**
```powershell
choco install mosquitto -y
```

**Option 2: Manual Download**
- Download from: https://mosquitto.org/download/
- Extract and add to PATH
- Or run from installation directory

**Option 3: Using WSL (Windows Subsystem for Linux)**
```bash
wsl
sudo apt-get install mosquitto-clients
```

### Verify Installation
```powershell
mosquitto_sub --version
mosquitto_pub --version
```

---

## 📊 MQTT Topics Your ESP32 Publishes

### Sensor Data Topics

```
devices/ESP32_001/sensors/temperature
devices/ESP32_001/sensors/humidity
devices/ESP32_001/sensors/water_level
```

**Example Payloads:**
```json
{"value": 24.6, "timestamp": 1762155444, "device_id": "ESP32_001"}
{"value": 53.2, "timestamp": 1762155444, "device_id": "ESP32_001"}
{"value": 65.0, "timestamp": 1762155444, "device_id": "ESP32_001"}
```

### Actuator Status Topic

```
devices/ESP32_001/actuators/status
```

**Example Payload:**
```json
{
  "humidifier1": "on",
  "humidifier2": "off",
  "fan1": "on",
  "fan2": "off",
  "buzzer": "off",
  "mode": "normal",
  "pinning_remaining": 0
}
```

### Mode Status Topic

```
devices/ESP32_001/status/mode
```

**Example Payloads:**
```json
"normal"
"pinning"
```

### Device Status Topic

```
devices/ESP32_001/status
```

**Example Payload:**
```
online
offline
```

### Combined Test Data Topic

```
esp32/test
```

**Example Payload:**
```json
{
  "temperature": 24.6,
  "humidity": 53.2,
  "water_level": 65.0,
  "timestamp": 1762155444,
  "device_id": "ESP32_001"
}
```

---

## 🎯 Subscribe to Topics (Receive Data)

### Monitor Single Topic

**Temperature:**
```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature"
```

**Output:**
```
{"value":24.6,"timestamp":1762155444,"device_id":"ESP32_001"}
{"value":25.1,"timestamp":1762155450,"device_id":"ESP32_001"}
{"value":24.9,"timestamp":1762155456,"device_id":"ESP32_001"}
```

**Humidity:**
```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/humidity"
```

**Water Level:**
```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/water_level"
```

**Actuator Status:**
```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/actuators/status"
```

**Mode Status:**
```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/status/mode"
```

### Monitor ALL Sensors

Use wildcard `#` to subscribe to all subtopics:

```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/#" -v
```

**Output (with `-v` for verbose):**
```
devices/ESP32_001/sensors/temperature {"value":24.6,"timestamp":1762155444,"device_id":"ESP32_001"}
devices/ESP32_001/sensors/humidity {"value":53.2,"timestamp":1762155444,"device_id":"ESP32_001"}
devices/ESP32_001/sensors/water_level {"value":65.0,"timestamp":1762155444,"device_id":"ESP32_001"}
```

### Monitor ALL Device Topics

```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/#" -v
```

**Output:**
```
devices/ESP32_001/sensors/temperature {"value":24.6,"timestamp":1762155444,"device_id":"ESP32_001"}
devices/ESP32_001/sensors/humidity {"value":53.2,"timestamp":1762155444,"device_id":"ESP32_001"}
devices/ESP32_001/sensors/water_level {"value":65.0,"timestamp":1762155444,"device_id":"ESP32_001"}
devices/ESP32_001/actuators/status {"humidifier1":"on","humidifier2":"off","fan1":"on","fan2":"off","buzzer":"off","mode":"normal"}
devices/ESP32_001/status/mode normal
devices/ESP32_001/status online
```

### Monitor EVERYTHING (All Topics)

```powershell
mosquitto_sub -h broker.mqtt.cool -t "#" -v
```

⚠️ **Warning**: This will show ALL messages on the broker (may be noisy!)

### Useful Options

```powershell
# -v: Verbose (shows topic name)
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/#" -v

# -n: Print only count of messages (no payload)
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/#" -n

# -q: Set QoS level
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/#" -q 1

# -C: Print N most recent messages retained on broker
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/#" -C 3

# -F: Output format (JSON, CSV, etc)
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/#" -F "Time: %t, Topic: %T, Payload: %p"
```

---

## 📤 Publish to Topics (Send Data)

### Test Temperature Reading

```powershell
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" \
  -m '{"value":25.5,"timestamp":1762155500,"device_id":"ESP32_001"}'
```

### Test Humidity Reading

```powershell
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/humidity" \
  -m '{"value":82.0,"timestamp":1762155500,"device_id":"ESP32_001"}'
```

### Test Water Level Reading

```powershell
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/water_level" \
  -m '{"value":45.0,"timestamp":1762155500,"device_id":"ESP32_001"}'
```

### Send Mode Command to ESP32

**Switch to Normal Mode:**
```powershell
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/mode/set" \
  -m '{"mode":"normal"}'
```

**Switch to Pinning Mode for 60 minutes:**
```powershell
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/mode/set" \
  -m '{"mode":"pinning","duration":3600}'
```

### Retain a Message (Persistent)

Messages are remembered by broker until replaced:

```powershell
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/status" \
  -m "online" -r
```

The `-r` flag makes the message "retained" on the broker.

---

## 🔍 Real-World Testing Scenarios

### Scenario 1: Monitor Live Sensor Data

**Terminal 1 - Subscribe to all sensors:**
```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/#" -v
```

**Expected Output (updates every 5 seconds):**
```
devices/ESP32_001/sensors/temperature {"value":24.6,"timestamp":1762155444,"device_id":"ESP32_001"}
devices/ESP32_001/sensors/humidity {"value":53.2,"timestamp":1762155450,"device_id":"ESP32_001"}
devices/ESP32_001/sensors/water_level {"value":65.0,"timestamp":1762155456,"device_id":"ESP32_001"}
devices/ESP32_001/sensors/temperature {"value":24.7,"timestamp":1762155505,"device_id":"ESP32_001"}
devices/ESP32_001/sensors/humidity {"value":53.5,"timestamp":1762155511,"device_id":"ESP32_001"}
```

### Scenario 2: Test Mode Switching

**Terminal 1 - Monitor mode changes:**
```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/status/mode" -v
```

**Terminal 2 - Send commands:**
```powershell
# Switch to Pinning
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/mode/set" \
  -m '{"mode":"pinning","duration":60}'

# Wait 60 seconds, then switch back to Normal
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/mode/set" \
  -m '{"mode":"normal"}'
```

**Expected Output in Terminal 1:**
```
devices/ESP32_001/status/mode pinning
devices/ESP32_001/status/mode normal
```

### Scenario 3: Test Temperature Alarm

**Terminal 1 - Monitor actuators:**
```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/actuators/status" -v
```

**Terminal 2 - Publish high temperature:**
```powershell
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" \
  -m '{"value":31.0,"timestamp":1762155600,"device_id":"ESP32_001"}'
```

**Expected Output in Terminal 1:**
```
devices/ESP32_001/actuators/status {"humidifier1":"on","humidifier2":"off","fan1":"on","fan2":"off","buzzer":"off","mode":"normal"}
devices/ESP32_001/actuators/status {"humidifier1":"on","humidifier2":"off","fan1":"on","fan2":"on","buzzer":"on","mode":"normal"}
```

(Notice: `fan2` changed from "off" to "on", `buzzer` activated)

### Scenario 4: Monitor Complete Device Status

**Terminal 1 - Watch everything for this device:**
```powershell
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/#" -v
```

This shows:
- All sensor readings
- Actuator status
- Mode changes
- Connection status

---

## 🎯 Common Testing Commands

### Get Last Message Retained

```powershell
# Get most recent sensor values
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/#" -C 1

# Get actuator status
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/actuators/status" -C 1
```

### Save to File

```powershell
# Save all messages to file
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/#" -v | Tee-Object -FilePath mqtt_log.txt

# View file
Get-Content mqtt_log.txt
```

### Count Messages

```powershell
# Count messages received in 10 seconds
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/#" -C 100 | Measure-Object -Line
```

### Pretty Print JSON

```powershell
# Subscribe and format JSON nicely
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" | ConvertFrom-Json
```

---

## 📋 Troubleshooting

### "mosquitto_sub: Unknown option"

**Problem**: Command not found or mosquitto not in PATH

**Solution**: 
```powershell
# Add to PATH in PowerShell
$env:Path += ";C:\Program Files\mosquitto"

# Or use full path
"C:\Program Files\mosquitto\mosquitto_sub.exe" -h broker.mqtt.cool -t "devices/ESP32_001/#"
```

### "Connection refused" or "Connection Timeout"

**Problem**: Can't connect to broker

**Solutions**:
```powershell
# Check connectivity
Test-NetConnection broker.mqtt.cool -Port 1883

# Try different port (if 1883 doesn't work)
mosquitto_sub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_001/#"

# Check if broker is online
ping broker.mqtt.cool
```

### No Messages Received

**Problem**: Subscribed but no output

**Solutions**:
1. ESP32 may not be publishing yet
2. Check if device ID is correct (should be "ESP32_001")
3. Monitor all topics to see if any messages exist:
   ```powershell
   mosquitto_sub -h broker.mqtt.cool -t "#" -v
   ```
4. Check ESP32 serial monitor for connection issues

### Too Many Messages

**Problem**: Overwhelmed with output

**Solution**: Monitor specific sensor only
```powershell
# Instead of all topics:
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" -v
```

---

## 🚀 Advanced Monitoring

### Real-time Dashboard with PowerShell

```powershell
# Monitor and refresh every 5 seconds
while($true) {
  Clear-Host
  Write-Host "=== MAB Device Monitoring ===" -ForegroundColor Cyan
  Write-Host "Last Update: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Yellow
  
  # Get last sensor values
  $temp = mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" -C 1
  $humid = mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/humidity" -C 1
  $water = mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/water_level" -C 1
  
  Write-Host "🌡️  Temperature: $temp"
  Write-Host "💧 Humidity: $humid"
  Write-Host "💦 Water: $water"
  
  Start-Sleep -Seconds 5
}
```

### Filter Messages by Condition

```powershell
# Show only critical temperature readings (>30°C)
mosquitto_sub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" | `
  Where-Object { $_ -match '"value":\s*(3[0-9]|[4-9][0-9])' }
```

---

## 📊 What You Can Get via MQTT

| Data | Topic | Frequency | Format |
|------|-------|-----------|--------|
| 🌡️ Temperature | `sensors/temperature` | Every 5s | JSON |
| 💧 Humidity | `sensors/humidity` | Every 5s | JSON |
| 💦 Water Level | `sensors/water_level` | Every 5s | JSON |
| 🎛️ Actuator Status | `actuators/status` | Every 5s | JSON |
| 🍄 Mode Status | `status/mode` | On change | String |
| 📡 Device Status | `status` | On connect | String |
| 📨 Combined Data | `esp32/test` | Every 5s | JSON |

---

## ✅ Summary

You can now:
- ✅ Monitor all sensor data in real-time
- ✅ Watch actuator status changes
- ✅ Test mode switching commands
- ✅ Simulate sensor readings
- ✅ Verify alarm triggers
- ✅ Debug communication issues
- ✅ Verify data formats

**Key Broker**: `broker.mqtt.cool:1883`
**Device ID**: `ESP32_001`

Start monitoring now! 🚀
