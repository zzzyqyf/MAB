# New MQTT Broker Testing Guide

## 📡 Broker Information

**Migration from old broker (broker.mqtt.cool:1883) to secure private broker:**

- **Host**: `api.milloserver.uk`
- **Port**: `8883` (TLS/SSL encrypted)
- **Username**: `zhangyifei`
- **Password**: `123456`
- **TLS**: Secure connection with system CA certificates (no custom CA required)
- **Timestamps**: Unix epoch in **seconds** (10-digit, e.g., 1753091366)

---

## 🛠️ Installing Mosquitto Clients

### Windows (PowerShell)

**Option 1: Using Chocolatey (Recommended)**
```powershell
# Install Chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Mosquitto
choco install mosquitto -y
```

**Option 2: Manual Download**
1. Download from: https://mosquitto.org/download/
2. Choose "Windows 64-bit" installer
3. Install to `C:\Program Files\mosquitto`
4. Add to PATH: `C:\Program Files\mosquitto`
5. Restart PowerShell

**Option 3: Using WSL (Windows Subsystem for Linux)**
```bash
wsl
sudo apt-get update
sudo apt-get install mosquitto-clients -y
```

### Linux
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install mosquitto-clients -y

# Fedora/RHEL
sudo dnf install mosquitto -y

# Arch
sudo pacman -S mosquitto
```

### macOS
```bash
# Using Homebrew
brew install mosquitto
```

### Verify Installation
```powershell
mosquitto_sub --help
mosquitto_pub --help
```

---

## 🧪 Testing Connection to New Broker

### Test 1: Subscribe to All Topics (Monitor Everything)

**PowerShell:**
```powershell
mosquitto_sub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "#" -v
```

**Linux/macOS:**
```bash
mosquitto_sub -h api.milloserver.uk -p 8883 \
  -u zhangyifei -P 123456 \
  --capath /etc/ssl/certs \
  -t "#" -v
```

**Expected Output:**
- If successful, you'll see live MQTT messages
- If ESP32 is running, you'll see sensor data every 5 seconds
- Press `Ctrl+C` to stop

### Test 2: Subscribe to Device-Specific Topics

**Monitor specific ESP32 device (replace E86BEAD0BD78 with your device ID):**
```powershell
mosquitto_sub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "devices/E86BEAD0BD78/#" -v
```

### Test 3: Publish Test Data

**Send fake temperature data:**
```powershell
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "devices/TEST_DEVICE/sensors/temperature" `
  -m '{"value": 25.5, "timestamp": 1753091366, "device_id": "TEST_DEVICE"}'
```

**Important**: Replace `1753091366` with current Unix timestamp in seconds:
```powershell
# PowerShell - Get current timestamp in seconds
[int][double]::Parse((Get-Date -UFormat %s))
```

```bash
# Linux/macOS - Get current timestamp in seconds
date +%s
```

---

## 📊 MQTT Topic Structure

### Sensor Topics (ESP32 → Flutter)
```
devices/{deviceId}/sensors/temperature
devices/{deviceId}/sensors/humidity
devices/{deviceId}/sensors/water_level
```

**Payload Format:**
```json
{
  "value": 25.5,
  "timestamp": 1753091366,
  "device_id": "E86BEAD0BD78"
}
```

### Status Topics
```
devices/{deviceId}/status              → "online" | "offline"
devices/{deviceId}/mode/status         → "normal" | "pinning"
```

### Control Topics (Flutter → ESP32)
```
devices/{deviceId}/mode/set
```

**Example Payloads:**
```json
// Normal Mode
{"mode": "normal"}

// Pinning Mode (with timer)
{"mode": "pinning", "duration": 3600}
```

### Actuator Status (ESP32 → Flutter)
```
devices/{deviceId}/actuators/status
```

**Payload:**
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

### Registration Topic (ESP32 → Flutter)
```
system/devices/register
```

**Payload:**
```json
{
  "macAddress": "E8:6B:EA:D0:BD:78",
  "deviceName": "ESP32_D0BD78",
  "timestamp": 1753091366
}
```

---

## 🎯 Common Testing Scenarios

### Scenario 1: Simulate ESP32 Device Registration

```powershell
# Get current timestamp
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))

# Publish registration
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "system/devices/register" `
  -m "{`"macAddress`": `"E8:6B:EA:D0:BD:78`", `"deviceName`": `"ESP32_D0BD78`", `"timestamp`": $timestamp}"
```

### Scenario 2: Simulate Sensor Data Stream

```powershell
# Continuous sensor data simulation
while ($true) {
    $timestamp = [int][double]::Parse((Get-Date -UFormat %s))
    $temp = [math]::Round((Get-Random -Minimum 20.0 -Maximum 30.0), 1)
    $humid = [math]::Round((Get-Random -Minimum 50.0 -Maximum 90.0), 1)
    $water = [math]::Round((Get-Random -Minimum 30.0 -Maximum 100.0), 1)
    
    $tempPayload = "{`"value`": $temp, `"timestamp`": $timestamp, `"device_id`": `"TEST_DEVICE`"}"
    $humidPayload = "{`"value`": $humid, `"timestamp`": $timestamp, `"device_id`": `"TEST_DEVICE`"}"
    $waterPayload = "{`"value`": $water, `"timestamp`": $timestamp, `"device_id`": `"TEST_DEVICE`"}"
    
    mosquitto_pub -h api.milloserver.uk -p 8883 -u zhangyifei -P 123456 --capath /etc/ssl/certs -t "devices/TEST_DEVICE/sensors/temperature" -m $tempPayload
    mosquitto_pub -h api.milloserver.uk -p 8883 -u zhangyifei -P 123456 --capath /etc/ssl/certs -t "devices/TEST_DEVICE/sensors/humidity" -m $humidPayload
    mosquitto_pub -h api.milloserver.uk -p 8883 -u zhangyifei -P 123456 --capath /etc/ssl/certs -t "devices/TEST_DEVICE/sensors/water_level" -m $waterPayload
    
    Write-Host "📊 Published: Temp=$temp°C, Humid=$humid%, Water=$water% at timestamp=$timestamp"
    Start-Sleep -Seconds 5
}
```

### Scenario 3: Test Mode Control (App → ESP32)

```powershell
# Switch to Pinning Mode for 1 hour
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "devices/E86BEAD0BD78/mode/set" `
  -m '{"mode": "pinning", "duration": 3600}'

# Switch back to Normal Mode
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "devices/E86BEAD0BD78/mode/set" `
  -m '{"mode": "normal"}'
```

### Scenario 4: Monitor App-ESP32 Communication

**Terminal 1 - Subscribe to sensor data:**
```powershell
mosquitto_sub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "devices/E86BEAD0BD78/sensors/#" -v
```

**Terminal 2 - Subscribe to mode commands:**
```powershell
mosquitto_sub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "devices/E86BEAD0BD78/mode/#" -v
```

**Terminal 3 - Subscribe to actuator status:**
```powershell
mosquitto_sub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "devices/E86BEAD0BD78/actuators/status" -v
```

---

## 🐛 Troubleshooting

### Error: "Connection refused"
**Cause**: Firewall blocking port 8883, or incorrect broker address  
**Solution**:
- Verify broker is `api.milloserver.uk`
- Check port is `8883` (not 1883)
- Ensure firewall allows outbound connections on port 8883

### Error: "Authentication failed"
**Cause**: Incorrect username or password  
**Solution**:
- Username must be: `zhangyifei`
- Password must be: `123456`
- Check for typos or extra spaces

### Error: "SSL handshake failed" or "Certificate verify failed"
**Cause**: Missing CA certificates or incorrect path  
**Solution**:
- **Windows**: Use `--insecure` flag (skips certificate verification):
  ```powershell
  mosquitto_sub -h api.milloserver.uk -p 8883 `
    -u zhangyifei -P 123456 `
    --insecure `
    -t "#" -v
  ```
- **Linux/macOS**: Install ca-certificates:
  ```bash
  sudo apt-get install ca-certificates
  ```

### Error: "No messages received"
**Cause**: ESP32 not connected or publishing to different topics  
**Solution**:
- Check ESP32 serial monitor for connection status
- Verify device ID matches subscription topic
- Use wildcard `#` to see all messages: `-t "#"`

### Flutter App Not Receiving Data
**Checklist**:
1. ✅ ESP32 is connected to WiFi (check serial monitor)
2. ✅ ESP32 connected to MQTT broker (see "connected" message)
3. ✅ Flutter app is running and MQTT service initialized
4. ✅ Device is registered in the app
5. ✅ Timestamps are in **seconds** (10-digit), not milliseconds

**Debug Steps**:
```powershell
# 1. Verify ESP32 is publishing
mosquitto_sub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --insecure `
  -t "devices/#" -v

# 2. Check if Flutter can publish (send test command)
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --insecure `
  -t "test/flutter" `
  -m "Flutter app test"

# 3. Monitor test topic
mosquitto_sub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --insecure `
  -t "test/flutter" -v
```

---

## 📝 Quick Command Reference

### Windows PowerShell
```powershell
# Base command with authentication (copy this!)
$MQTT_BASE = "mosquitto_sub -h api.milloserver.uk -p 8883 -u zhangyifei -P 123456 --insecure"

# Subscribe to all topics
& $MQTT_BASE -t "#" -v

# Subscribe to specific device
& $MQTT_BASE -t "devices/YOUR_DEVICE_ID/#" -v

# Publish test data
mosquitto_pub -h api.milloserver.uk -p 8883 -u zhangyifei -P 123456 --insecure -t "test/topic" -m "test message"
```

### Linux/macOS Bash
```bash
# Base command with authentication (copy this!)
MQTT_BASE="mosquitto_sub -h api.milloserver.uk -p 8883 -u zhangyifei -P 123456 --capath /etc/ssl/certs"

# Subscribe to all topics
$MQTT_BASE -t "#" -v

# Subscribe to specific device
$MQTT_BASE -t "devices/YOUR_DEVICE_ID/#" -v

# Publish test data
mosquitto_pub -h api.milloserver.uk -p 8883 -u zhangyifei -P 123456 --capath /etc/ssl/certs -t "test/topic" -m "test message"
```

---

## ✅ Testing Checklist

Before considering the migration complete, test:

- [ ] ESP32 can connect to new broker
- [ ] ESP32 publishes sensor data with timestamps in seconds
- [ ] Flutter app receives sensor data from ESP32
- [ ] Flutter app can send mode commands to ESP32
- [ ] ESP32 responds to mode commands
- [ ] Device registration works (appears in app)
- [ ] Automatic reconnection works (disconnect/reconnect WiFi)
- [ ] Multiple devices can connect simultaneously
- [ ] Actuator control works (humidifiers, fans, buzzer)
- [ ] Alarm system triggers correctly
- [ ] Timestamps display correctly in app (not in year 1970 or 2055)

---

## 🔐 Security Notes

- **TLS Encryption**: All data is encrypted in transit (port 8883)
- **Authentication**: Username/password prevents unauthorized access
- **Private Broker**: Not a public broker, only authorized users can connect
- **Certificate**: Uses system CA certificates (no custom CA needed)
- **Credentials**: Keep username/password secure (currently in code for testing)

---

## 📞 Support

If you encounter issues:
1. Check ESP32 serial monitor output
2. Verify firewall allows port 8883
3. Test with `mosquitto_sub` to isolate Flutter vs ESP32 issues
4. Check timestamps are in **seconds** (10-digit), not milliseconds
5. Ensure device ID matches between ESP32 and Flutter app

---

**Last Updated**: November 10, 2025  
**Broker**: api.milloserver.uk:8883 (Secure TLS)
