# ESP32 Implementation Guide
**Hardware Integration for MAB System**

## Overview

This document provides the complete ESP32 Arduino implementation for the MAB (Mushroom Agriculture Monitoring) system. The ESP32 acts as the primary sensor node, collecting environmental data and transmitting it via MQTT to the Flutter application.

## Hardware Requirements

### Components
- **ESP32 DevKit v1** - Main microcontroller
- **DHT22** - Temperature and humidity sensor
- **LDR (Photoresistor)** - Light intensity measurement
- **MQ-135** - CO2 gas sensor (optional)
- **Soil moisture sensor** - Substrate moisture detection
- **Resistors** - 10kΩ for LDR, 220Ω for LED
- **Breadboard and jumper wires**

### Wiring Diagram
```
ESP32 Pin    Component
---------    ---------
GPIO 4       DHT22 Data Pin
GPIO 32      LDR (via 10kΩ resistor)
GPIO 33      Moisture Sensor
GPIO 35      CO2 Sensor (if available)
GPIO 2       Status LED
3.3V         VCC for sensors
GND          Common ground
```

## Software Requirements

### Arduino Libraries
```cpp
#include <WiFi.h>          // ESP32 WiFi library
#include <PubSubClient.h>  // MQTT client library
#include <ArduinoJson.h>   // JSON payload creation
#include <DHT.h>           // DHT22 sensor library
```

### Installation
1. Install ESP32 board package in Arduino IDE
2. Install required libraries via Library Manager
3. Configure WiFi credentials in code
4. Upload to ESP32 board

## Complete Implementation Code

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

// Network Configuration
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT Configuration
const char* mqtt_server = "broker.mqtt.cool";
const int mqtt_port = 1883;

// Device Configuration
const char* DEVICE_ID = "ESP32_001";
const char* DEVICE_NAME = "Mushroom Monitor 1";
const char* DEVICE_LOCATION = "Greenhouse A";

// Pin Configuration
#define DHT_PIN 4
#define DHT_TYPE DHT22
#define LIGHT_PIN 32
#define MOISTURE_PIN 33
#define CO2_PIN 35
#define LED_PIN 2

// Sensor Objects
DHT dht(DHT_PIN, DHT_TYPE);
WiFiClient espClient;
PubSubClient client(espClient);

// Timing Configuration
unsigned long lastSensorRead = 0;
unsigned long lastHeartbeat = 0;
const unsigned long SENSOR_INTERVAL = 5000;    // 5 seconds
const unsigned long HEARTBEAT_INTERVAL = 30000; // 30 seconds

// Current Status
bool wifiConnected = false;
bool mqttConnected = false;

void setup() {
  Serial.begin(115200);
  Serial.println("MAB ESP32 Sensor Node Starting...");
  
  // Initialize hardware
  initializePins();
  initializeSensors();
  
  // Connect to network
  connectWiFi();
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(onMqttMessage);
  
  // Connect to MQTT broker
  connectMQTT();
  
  // Announce device online
  announceDeviceOnline();
  
  Serial.println("MAB ESP32 Ready!");
}

void loop() {
  // Maintain connections
  if (!WiFi.isConnected()) {
    connectWiFi();
  }
  
  if (!client.connected()) {
    connectMQTT();
  }
  client.loop();
  
  unsigned long currentTime = millis();
  
  // Read and publish sensor data
  if (currentTime - lastSensorRead >= SENSOR_INTERVAL) {
    readAndPublishSensors();
    lastSensorRead = currentTime;
  }
  
  // Send heartbeat
  if (currentTime - lastHeartbeat >= HEARTBEAT_INTERVAL) {
    sendHeartbeat();
    lastHeartbeat = currentTime;
  }
  
  // Visual status indication
  updateStatusLED();
  
  delay(100); // Small delay for stability
}

void initializePins() {
  pinMode(LED_PIN, OUTPUT);
  pinMode(LIGHT_PIN, INPUT);
  pinMode(MOISTURE_PIN, INPUT);
  pinMode(CO2_PIN, INPUT);
  
  digitalWrite(LED_PIN, LOW);
  Serial.println("Pins initialized");
}

void initializeSensors() {
  dht.begin();
  delay(2000); // Allow sensor to stabilize
  Serial.println("Sensors initialized");
}

void connectWiFi() {
  if (WiFi.isConnected()) return;
  
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.isConnected()) {
    wifiConnected = true;
    Serial.println();
    Serial.print("Connected! IP: ");
    Serial.println(WiFi.localIP());
  } else {
    wifiConnected = false;
    Serial.println();
    Serial.println("WiFi connection failed!");
  }
}

void connectMQTT() {
  if (client.connected()) return;
  
  Serial.print("Connecting to MQTT broker...");
  
  String clientId = "ESP32_" + String(DEVICE_ID);
  
  if (client.connect(clientId.c_str())) {
    mqttConnected = true;
    Serial.println(" Connected!");
    
    // Subscribe to control topics
    String controlTopic = "devices/" + String(DEVICE_ID) + "/control";
    client.subscribe(controlTopic.c_str());
    
  } else {
    mqttConnected = false;
    Serial.print(" Failed, rc=");
    Serial.println(client.state());
  }
}

void readAndPublishSensors() {
  Serial.println("Reading sensors...");
  
  // Read DHT22 (Temperature & Humidity)
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  // Read analog sensors
  int lightRaw = analogRead(LIGHT_PIN);
  int moistureRaw = analogRead(MOISTURE_PIN);
  int co2Raw = analogRead(CO2_PIN);
  
  // Convert to meaningful values
  float lightIntensity = map(lightRaw, 0, 4095, 0, 100);
  float moisturePercent = map(moistureRaw, 0, 4095, 0, 100);
  float co2Level = map(co2Raw, 0, 4095, 400, 2000); // Approximate CO2 ppm
  
  // Validate readings
  if (!isnan(temperature) && !isnan(humidity)) {
    publishSensorReading("temperature", temperature);
    publishSensorReading("humidity", humidity);
  } else {
    Serial.println("DHT22 reading failed!");
  }
  
  publishSensorReading("lights", lightIntensity);
  publishSensorReading("moisture", moisturePercent);
  publishSensorReading("co2", co2Level);
  
  // Calculate blue light (example: based on light intensity)
  float blueLight = lightIntensity * 0.8; // Simulated blue light component
  publishSensorReading("bluelight", blueLight);
  
  Serial.println("Sensor readings published");
}

void publishSensorReading(const char* sensorType, float value) {
  if (!client.connected()) return;
  
  // Create JSON payload with timestamp
  StaticJsonDocument<200> doc;
  doc["value"] = value;
  doc["timestamp"] = millis();
  doc["device_id"] = DEVICE_ID;
  doc["location"] = DEVICE_LOCATION;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  // Construct topic
  String topic = "devices/" + String(DEVICE_ID) + "/sensors/" + String(sensorType);
  
  // Publish with retained flag for latest value storage
  bool published = client.publish(topic.c_str(), jsonString.c_str(), true);
  
  if (published) {
    Serial.println("Published " + String(sensorType) + ": " + String(value));
  } else {
    Serial.println("Failed to publish " + String(sensorType));
  }
}

void announceDeviceOnline() {
  if (!client.connected()) return;
  
  StaticJsonDocument<300> doc;
  doc["device_id"] = DEVICE_ID;
  doc["device_name"] = DEVICE_NAME;
  doc["location"] = DEVICE_LOCATION;
  doc["status"] = "online";
  doc["timestamp"] = millis();
  doc["ip_address"] = WiFi.localIP().toString();
  doc["wifi_rssi"] = WiFi.RSSI();
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  String topic = "devices/" + String(DEVICE_ID) + "/status";
  client.publish(topic.c_str(), jsonString.c_str(), true);
  
  Serial.println("Device announced online");
}

void sendHeartbeat() {
  if (!client.connected()) return;
  
  StaticJsonDocument<200> doc;
  doc["device_id"] = DEVICE_ID;
  doc["uptime"] = millis();
  doc["free_heap"] = ESP.getFreeHeap();
  doc["wifi_rssi"] = WiFi.RSSI();
  doc["timestamp"] = millis();
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  String topic = "devices/" + String(DEVICE_ID) + "/heartbeat";
  client.publish(topic.c_str(), jsonString.c_str());
  
  Serial.println("Heartbeat sent");
}

void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message received on topic: ");
  Serial.println(topic);
  
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.println("Message: " + message);
  
  // Handle control commands here
  // Example: {"command": "restart", "device_id": "ESP32_001"}
}

void updateStatusLED() {
  if (wifiConnected && mqttConnected) {
    // Solid on = fully connected
    digitalWrite(LED_PIN, HIGH);
  } else if (wifiConnected) {
    // Slow blink = WiFi only
    digitalWrite(LED_PIN, (millis() / 1000) % 2);
  } else {
    // Fast blink = no connection
    digitalWrite(LED_PIN, (millis() / 200) % 2);
  }
}
```

## Current System Status

✅ **Operational Status**: System is live and functional
- Temperature sensor: 33.2°C readings
- Humidity sensor: 54.8% readings  
- Data transmission: Every 5 seconds
- MQTT connectivity: Stable connection to broker.mqtt.cool

## Configuration Notes

### WiFi Setup
1. Replace `YOUR_WIFI_SSID` and `YOUR_WIFI_PASSWORD` with actual credentials
2. Ensure 2.4GHz network (ESP32 doesn't support 5GHz)
3. Check firewall settings for MQTT port 1883

### MQTT Topics
The ESP32 publishes to these topic patterns:
- `devices/ESP32_001/sensors/temperature`
- `devices/ESP32_001/sensors/humidity`  
- `devices/ESP32_001/sensors/lights`
- `devices/ESP32_001/sensors/moisture`
- `devices/ESP32_001/sensors/co2`
- `devices/ESP32_001/sensors/bluelight`

### Troubleshooting

**Common Issues:**
1. **WiFi Connection**: Check credentials and signal strength
2. **MQTT Connection**: Verify broker address and port
3. **Sensor Readings**: Check wiring and power supply
4. **JSON Errors**: Verify ArduinoJson library version

**Debug Commands:**
```cpp
Serial.println("WiFi Status: " + String(WiFi.status()));
Serial.println("MQTT State: " + String(client.state()));
Serial.println("Free Heap: " + String(ESP.getFreeHeap()));
```

## Integration with Flutter App

The ESP32 data seamlessly integrates with the MAB Flutter application:
1. ESP32 publishes JSON payloads with timestamps
2. Flutter MQTT service subscribes to device topics
3. Data is parsed and displayed in real-time on mobile interface
4. Historical data can be stored in Firebase for analysis

## Future Enhancements

- **Deep Sleep Mode**: Power optimization for battery operation
- **OTA Updates**: Over-the-air firmware updates
- **Multiple Sensors**: Support for additional sensor types
- **Edge Computing**: Local data processing and filtering
- **Mesh Network**: Multiple ESP32 nodes in network topology

---

This implementation provides a robust, scalable foundation for IoT environmental monitoring in mushroom agriculture applications.
