# ESP32 Arduino Code for Device-Specific MQTT Topics

This document provides the ESP32 Arduino code template that works with the new device-specific MQTT architecture.

## Required Libraries
```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
```

## Complete ESP32 Code Example

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT broker settings
const char* mqtt_server = "broker.mqtt.cool";
const int mqtt_port = 1883;

// Device configuration
const char* DEVICE_ID = "ESP32_001";  // UNIQUE for each device
const char* DEVICE_NAME = "Greenhouse Monitor 1";
const char* DEVICE_LOCATION = "Greenhouse A";
const char* FIRMWARE_VERSION = "v1.2.3";

// Sensor pins
#define DHT_PIN 4
#define DHT_TYPE DHT22
#define LIGHT_SENSOR_PIN A0
#define MOISTURE_SENSOR_PIN A1
#define LED_PIN 2

// Sensor objects
DHT dht(DHT_PIN, DHT_TYPE);
WiFiClient espClient;
PubSubClient client(espClient);

// Timing variables
unsigned long lastSensorRead = 0;
unsigned long lastHeartbeat = 0;
const unsigned long SENSOR_INTERVAL = 5000;  // 5 seconds
const unsigned long HEARTBEAT_INTERVAL = 30000;  // 30 seconds

// Sensor data
float temperature = 0;
float humidity = 0;
int lightState = 0;
float moisture = 0;

void setup() {
  Serial.begin(115200);
  
  // Initialize pins
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // Initialize sensors
  dht.begin();
  
  // Connect to WiFi
  setupWiFi();
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(mqttCallback);
  
  // Connect to MQTT
  connectMQTT();
  
  // Announce device
  announceDevice();
}

void loop() {
  if (!client.connected()) {
    connectMQTT();
  }
  client.loop();
  
  unsigned long now = millis();
  
  // Read sensors periodically
  if (now - lastSensorRead > SENSOR_INTERVAL) {
    readSensors();
    publishSensorData();
    lastSensorRead = now;
  }
  
  // Send heartbeat periodically
  if (now - lastHeartbeat > HEARTBEAT_INTERVAL) {
    sendHeartbeat();
    lastHeartbeat = now;
  }
  
  delay(100);
}

void setupWiFi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void connectMQTT() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    String clientId = "ESP32Client_";
    clientId += DEVICE_ID;
    
    if (client.connect(clientId.c_str())) {
      Serial.println("connected");
      
      // Subscribe to device-specific topics
      subscribeToTopics();
      
      // Set device status to online
      publishStatus("online");
      
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void subscribeToTopics() {
  // Subscribe to device-specific command and config topics
  String configTopic = "devices/" + String(DEVICE_ID) + "/config/set";
  String commandTopic = "devices/" + String(DEVICE_ID) + "/commands";
  String discoveryTopic = "system/devices/discovery";
  
  client.subscribe(configTopic.c_str());
  client.subscribe(commandTopic.c_str());
  client.subscribe(discoveryTopic.c_str());
  
  Serial.println("Subscribed to device topics");
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  Serial.println(message);
  
  String topicStr = String(topic);
  
  // Handle different topic types
  if (topicStr.endsWith("/commands")) {
    handleCommand(message);
  } else if (topicStr.endsWith("/config/set")) {
    handleConfiguration(message);
  } else if (topicStr == "system/devices/discovery") {
    // Respond to discovery request
    announceDevice();
  }
}

void handleCommand(String message) {
  StaticJsonDocument<200> doc;
  deserializeJson(doc, message);
  
  String command = doc["command"];
  
  if (command == "lights") {
    String state = doc["parameters"]["state"];
    if (state == "on") {
      digitalWrite(LED_PIN, HIGH);
      lightState = 1;
    } else {
      digitalWrite(LED_PIN, LOW);
      lightState = 0;
    }
    Serial.println("Light command executed: " + state);
  }
  else if (command == "calibrate_moisture") {
    // Handle moisture sensor calibration
    float dryValue = doc["parameters"]["dry_value"];
    float wetValue = doc["parameters"]["wet_value"];
    // Implement calibration logic here
    Serial.println("Moisture calibration: dry=" + String(dryValue) + ", wet=" + String(wetValue));
  }
  else if (command == "reboot") {
    Serial.println("Rebooting device...");
    ESP.restart();
  }
}

void handleConfiguration(String message) {
  StaticJsonDocument<200> doc;
  deserializeJson(doc, message);
  
  if (doc.containsKey("sensor_interval")) {
    // Update sensor reading interval
    unsigned long newInterval = doc["sensor_interval"];
    // Implement configuration change
    Serial.println("Sensor interval updated to: " + String(newInterval));
  }
  
  // Send configuration response
  sendConfigurationResponse();
}

void readSensors() {
  // Read DHT22 sensor
  temperature = dht.readTemperature();
  humidity = dht.readHumidity();
  
  // Read light sensor (0-1023 mapped to 0-100%)
  int lightRaw = analogRead(LIGHT_SENSOR_PIN);
  lightState = map(lightRaw, 0, 1023, 0, 100);
  
  // Read moisture sensor (0-1023 mapped to 0-100%)
  int moistureRaw = analogRead(MOISTURE_SENSOR_PIN);
  moisture = map(moistureRaw, 0, 1023, 0, 100);
  
  // Check for sensor errors
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Failed to read from DHT sensor!");
    return;
  }
  
  Serial.println("Sensors read - Temp: " + String(temperature) + 
                "°C, Humidity: " + String(humidity) + 
                "%, Light: " + String(lightState) + 
                "%, Moisture: " + String(moisture) + "%");
}

void publishSensorData() {
  // Publish each sensor reading to device-specific topics
  String baseTopic = "devices/" + String(DEVICE_ID) + "/sensors/";
  
  client.publish((baseTopic + "temperature").c_str(), String(temperature).c_str());
  client.publish((baseTopic + "humidity").c_str(), String(humidity).c_str());
  client.publish((baseTopic + "lights").c_str(), String(lightState).c_str());
  client.publish((baseTopic + "moisture").c_str(), String(moisture).c_str());
}

void publishStatus(String status) {
  String statusTopic = "devices/" + String(DEVICE_ID) + "/status";
  client.publish(statusTopic.c_str(), status.c_str());
}

void announceDevice() {
  // Create device info JSON
  StaticJsonDocument<400> doc;
  doc["deviceId"] = DEVICE_ID;
  doc["deviceName"] = DEVICE_NAME;
  doc["location"] = DEVICE_LOCATION;
  doc["firmware"] = FIRMWARE_VERSION;
  doc["lastSeen"] = ""; // Will be set by server
  
  JsonArray capabilities = doc.createNestedArray("capabilities");
  capabilities.add("temperature");
  capabilities.add("humidity");
  capabilities.add("lights");
  capabilities.add("moisture");
  
  JsonObject metadata = doc.createNestedObject("metadata");
  metadata["type"] = "ESP32";
  metadata["ip"] = WiFi.localIP().toString();
  metadata["rssi"] = WiFi.RSSI();
  
  String output;
  serializeJson(doc, output);
  
  // Publish to system registration topic
  client.publish("system/devices/register", output.c_str());
  
  // Also publish to device-specific info topic
  String infoTopic = "devices/" + String(DEVICE_ID) + "/info";
  client.publish(infoTopic.c_str(), output.c_str());
  
  Serial.println("Device announced: " + output);
}

void sendHeartbeat() {
  StaticJsonDocument<100> doc;
  doc["deviceId"] = DEVICE_ID;
  doc["timestamp"] = millis();
  doc["uptime"] = millis() / 1000;
  doc["freeHeap"] = ESP.getFreeHeap();
  
  String output;
  serializeJson(doc, output);
  
  client.publish("system/devices/heartbeat", output.c_str());
}

void sendConfigurationResponse() {
  StaticJsonDocument<200> doc;
  doc["deviceId"] = DEVICE_ID;
  doc["sensor_interval"] = SENSOR_INTERVAL;
  doc["firmware"] = FIRMWARE_VERSION;
  doc["timestamp"] = millis();
  
  String output;
  serializeJson(doc, output);
  
  String responseTopic = "devices/" + String(DEVICE_ID) + "/config/response";
  client.publish(responseTopic.c_str(), output.c_str());
}
```

## Key Changes from Previous Version

### 1. Device-Specific Topics
- **OLD**: `esp32/temperature` (all devices publish here)
- **NEW**: `devices/ESP32_001/sensors/temperature` (device-specific)

### 2. Device Registration
- Devices announce themselves on startup
- Automatic discovery by Flutter app
- Heartbeat mechanism for health monitoring

### 3. Remote Control
- Device-specific command topics
- Configuration management
- Real-time control capabilities

## Topic Structure Summary

### Device publishes to:
```
devices/{DEVICE_ID}/sensors/temperature    - Temperature readings
devices/{DEVICE_ID}/sensors/humidity       - Humidity readings  
devices/{DEVICE_ID}/sensors/lights         - Light sensor readings
devices/{DEVICE_ID}/sensors/moisture       - Moisture readings
devices/{DEVICE_ID}/status                 - Device status (online/offline)
devices/{DEVICE_ID}/info                   - Device metadata
devices/{DEVICE_ID}/config/response        - Configuration responses
system/devices/register                    - Device registration
system/devices/heartbeat                   - Keep-alive messages
```

### Device subscribes to:
```
devices/{DEVICE_ID}/commands               - Control commands
devices/{DEVICE_ID}/config/set             - Configuration updates
system/devices/discovery                   - Discovery requests
```

## Installation Instructions

1. Install required libraries in Arduino IDE:
   - WiFi (built-in)
   - PubSubClient by Nick O'Leary
   - ArduinoJson by Benoit Blanchon
   - DHT sensor library by Adafruit

2. Update the following in the code:
   - `DEVICE_ID`: Make unique for each ESP32 (e.g., "ESP32_001", "ESP32_002")
   - `DEVICE_NAME`: Descriptive name for the device
   - `ssid` and `password`: Your WiFi credentials
   - Pin assignments based on your hardware setup

3. Upload to ESP32

4. The device will automatically:
   - Connect to WiFi
   - Connect to MQTT broker
   - Announce itself to the Flutter app
   - Start publishing sensor data to device-specific topics

## Troubleshooting

- **Device not discovered**: Check WiFi connection and MQTT broker connectivity
- **No sensor data**: Verify pin assignments and sensor connections
- **Commands not working**: Check MQTT topic subscriptions and message format
- **Multiple devices interfering**: Ensure each device has a unique `DEVICE_ID`
