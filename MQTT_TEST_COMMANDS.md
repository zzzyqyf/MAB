# MQTT Testing Commands

## Prerequisites
1. Install mosquitto clients:
   ```
   # Windows (using Chocolatey)
   choco install mosquitto
   
   # Or download from: https://mosquitto.org/download/
   ```

## Test MQTT Broker Connection

### 1. Test Basic Connection
```bash
# Test if broker is reachable
mosquitto_pub -h broker.mqtt.cool -p 1883 -t "test/connection" -m "hello"
```

### 2. Subscribe to Device Topics
```bash
# Subscribe to all device topics (run in separate terminal)
mosquitto_sub -h broker.mqtt.cool -p 1883 -t "devices/+/sensors/+"

# Subscribe to specific device temperature
mosquitto_sub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_001/sensors/temperature"

# Subscribe to discovery topics
mosquitto_sub -h broker.mqtt.cool -p 1883 -t "system/discovery/+"
```

### 3. Publish Test Sensor Data
```bash
# Simulate ESP32 device publishing temperature
mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_001/sensors/temperature" -m "25.5"

# Simulate humidity data
mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_001/sensors/humidity" -m "60.2"

# Simulate light state
mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_001/sensors/lights" -m "1"

# Simulate moisture data
mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_001/sensors/moisture" -m "45.8"
```

### 4. Test Device Discovery
```bash
# Simulate device announcement
mosquitto_pub -h broker.mqtt.cool -p 1883 -t "system/discovery/announce" -m '{"deviceId":"ESP32_001","deviceName":"Test Device","ipAddress":"192.168.1.100","sensors":["temperature","humidity","lights","moisture"]}'

# Request device discovery
mosquitto_pub -h broker.mqtt.cool -p 1883 -t "system/discovery/request" -m "discover"
```

### 5. Test Device Status
```bash
# Simulate device online status
mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_001/status" -m "online"

# Simulate device heartbeat
mosquitto_pub -h broker.mqtt.cool -p 1883 -t "system/heartbeat" -m '{"deviceId":"ESP32_001","timestamp":"2024-01-01T12:00:00Z"}'
```

### 6. Monitor All Traffic
```bash
# Monitor all MQTT traffic (useful for debugging)
mosquitto_sub -h broker.mqtt.cool -p 1883 -t "#" -v
```

## Expected Behavior

### When Flutter App is Running:
1. **Subscription Setup**: App should subscribe to `devices/+/sensors/+`
2. **Data Reception**: Published sensor data should appear in the app UI
3. **Device Discovery**: Device announcements should be received and processed

### Testing Flow:
1. Start the Flutter app
2. Run the subscription command in terminal
3. Publish test sensor data
4. Verify data appears in both terminal and Flutter app
5. Test device discovery by publishing announcement
6. Check if device appears in app's device list

## Troubleshooting

### If Connection Fails:
- Check internet connectivity
- Verify broker.mqtt.cool is accessible
- Try alternative broker: `test.mosquitto.org`

### If Messages Not Received:
- Check topic naming (case sensitive)
- Verify QoS settings
- Check if client is properly subscribed

### Common Issues:
- **Firewall**: Ensure port 1883 is not blocked
- **Network**: Some networks block MQTT traffic
- **Topic Format**: Ensure exact topic structure matches app expectations
