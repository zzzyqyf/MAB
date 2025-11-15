/*
 * ESP32 Bluetooth Provisioning + MQTT Registration
 * 
 * This code implements:
 * 1. BLE server for receiving WiFi credentials from Flutter app
 * 2. WiFi connection using received credentials
 * 3. MQTT connection and device registration using MAC address
 * 4. Sensor data publishing to device-specific MQTT topics
 * 
 * Hardware: ESP32 DevKit, DHT22, LDR, Moisture Sensor
 * 
 * Author: MAB System
 * Date: 2025
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

// ============================================================================
// BLE UUIDs (must match Flutter app)
// ============================================================================
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define WIFI_CHAR_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ============================================================================
// Hardware Pin Definitions
// ============================================================================
#define DHT_PIN 4
#define DHT_TYPE DHT22
#define WATER_LEVEL_PIN 35  // GPIO 35 (ADC1_CH7) - Water level sensor S pin
#define LED_PIN 2

// Actuator control pins
#define HUMIDIFIER1_PIN 25  // GPIO 25 - Humidifier 1 relay
#define HUMIDIFIER2_PIN 26  // GPIO 26 - Humidifier 2 relay
#define FAN1_PIN 27         // GPIO 27 - Fan 1 relay
#define FAN2_PIN 14         // GPIO 14 - Fan 2 relay
#define BUZZER_PIN 33       // GPIO 33 - Buzzer for alarm

// ============================================================================
// MQTT Configuration - Secure connection to private broker
// ============================================================================
const char* mqtt_server = "api.milloserver.uk";
const int mqtt_port = 8883;  // Secure MQTT port (TLS)
const char* mqtt_username = "zhangyifei";
const char* mqtt_password = "123456";
const char* registration_topic = "system/devices/register";

// ============================================================================
// Global Variables
// ============================================================================
String wifiSSID = "";
String wifiPassword = "";
String deviceMacAddress = "";
String deviceId = "";  // Will be MAC without colons
String deviceName = "";  // Will be "ESP32_XXXXXX"

bool wifiCredentialsReceived = false;
bool wifiConnected = false;
bool mqttConnected = false;
bool deviceRegistered = false;

DHT dht(DHT_PIN, DHT_TYPE);
WiFiClientSecure espClient;  // Use WiFiClientSecure for TLS connection
PubSubClient mqttClient(espClient);

// NTP Client setup
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0, 60000); // UTC, update every 60 seconds

BLEServer* pServer = NULL;
BLECharacteristic* pWifiCharacteristic = NULL;
bool deviceConnected = false;

// Actuator states
bool humidifier1State = false;
bool humidifier2State = false;
bool fan1State = true;  // Fan 1 always on
bool fan2State = false;
bool buzzerState = false;

// Cultivation mode
enum CultivationMode { NORMAL, PINNING };
CultivationMode currentMode = NORMAL;

// Timing
unsigned long lastSensorPublish = 0;
const unsigned long sensorInterval = 5000;  // 5 seconds

// ============================================================================
// Function Forward Declarations
// ============================================================================
void setupBLE();
void connectWiFi();
void connectMQTT();
void registerDevice();
void publishSensorData();
void publishSensorValue(String sensorType, float value, unsigned long timestamp);
float readWaterLevel();

// ============================================================================
// BLE Callback Classes
// ============================================================================
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("📱 BLE Client connected");
      digitalWrite(LED_PIN, HIGH);
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("📱 BLE Client disconnected");
      digitalWrite(LED_PIN, LOW);
      
      // Restart advertising for new connections
      if (!wifiCredentialsReceived) {
        BLEDevice::startAdvertising();
        Serial.println("🔵 BLE Advertising restarted");
      }
    }
};

class WiFiCharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      
      if (value.length() > 0) {
        Serial.println("📩 Received WiFi credentials");
        
        // Parse JSON
        StaticJsonDocument<256> doc;
        DeserializationError error = deserializeJson(doc, value.c_str());
        
        if (error) {
          Serial.print("❌ JSON parse failed: ");
          Serial.println(error.c_str());
          return;
        }
        
        wifiSSID = doc["ssid"].as<String>();
        wifiPassword = doc["password"].as<String>();
        
        Serial.print("   SSID: ");
        Serial.println(wifiSSID);
        Serial.println("   Password: ********");
        
        wifiCredentialsReceived = true;
        
        // Blink LED to indicate success
        for (int i = 0; i < 3; i++) {
          digitalWrite(LED_PIN, HIGH);
          delay(200);
          digitalWrite(LED_PIN, LOW);
          delay(200);
        }
      }
    }
};

// ============================================================================
// Setup Functions
// ============================================================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n");
  Serial.println("===============================================");
  Serial.println("   ESP32 Bluetooth Provisioning System");
  Serial.println("===============================================");
  
  // Initialize LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // Initialize actuator pins as outputs
  pinMode(HUMIDIFIER1_PIN, OUTPUT);
  pinMode(HUMIDIFIER2_PIN, OUTPUT);
  pinMode(FAN1_PIN, OUTPUT);
  pinMode(FAN2_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  
  // Initialize all actuators to OFF (except Fan 1)
  digitalWrite(HUMIDIFIER1_PIN, LOW);
  digitalWrite(HUMIDIFIER2_PIN, LOW);
  digitalWrite(FAN1_PIN, HIGH);  // Fan 1 always ON
  digitalWrite(FAN2_PIN, LOW);
  digitalWrite(BUZZER_PIN, LOW);
  Serial.println("✅ Actuator pins initialized");
  
  // Initialize sensors
  dht.begin();
  Serial.println("✅ DHT22 sensor initialized");
  
  // Get MAC address
  deviceMacAddress = WiFi.macAddress();
  Serial.print("📍 MAC Address: ");
  Serial.println(deviceMacAddress);
  
  // Create device ID (MAC without colons)
  deviceId = deviceMacAddress;
  deviceId.replace(":", "");
  Serial.print("🆔 Device ID: ");
  Serial.println(deviceId);
  
  // Create device name
  String macLast6 = deviceMacAddress.substring(9);  // Get last 6 chars (XX:XX:XX)
  macLast6.replace(":", "");
  deviceName = "ESP32_" + macLast6;
  Serial.print("📛 Device Name: ");
  Serial.println(deviceName);
  
  // Initialize BLE
  setupBLE();
  
  Serial.println("✅ Setup complete - waiting for WiFi credentials via BLE");
  Serial.println("===============================================\n");
}

void setupBLE() {
  Serial.println("🔵 Initializing BLE...");
  
  // Create BLE Device
  BLEDevice::init(deviceName.c_str());
  
  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());
  
  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Create WiFi Characteristic
  pWifiCharacteristic = pService->createCharacteristic(
                          WIFI_CHAR_UUID,
                          BLECharacteristic::PROPERTY_READ |
                          BLECharacteristic::PROPERTY_WRITE
                        );
  
  pWifiCharacteristic->setCallbacks(new WiFiCharacteristicCallbacks());
  pWifiCharacteristic->addDescriptor(new BLE2902());
  
  // Start the service
  pService->start();
  
  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("✅ BLE Server started and advertising");
  Serial.print("   Service UUID: ");
  Serial.println(SERVICE_UUID);
}

// ============================================================================
// WiFi Functions
// ============================================================================
void connectWiFi() {
  if (wifiSSID.length() == 0) {
    return;
  }
  
  Serial.println("\n📡 Connecting to WiFi...");
  Serial.print("   SSID: ");
  Serial.println(wifiSSID);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 40) {  // 20 seconds timeout
    delay(500);
    Serial.print(".");
    attempts++;
    
    // Blink LED while connecting
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    digitalWrite(LED_PIN, HIGH);
    
    Serial.println("\n✅ WiFi connected!");
    Serial.print("   IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("   Signal Strength: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    
    // Initialize NTP client for real timestamps
    timeClient.begin();
    Serial.print("⏰ Synchronizing time with NTP server...");
    int retries = 0;
    while (!timeClient.update() && retries < 10) {
      timeClient.forceUpdate();
      delay(1000);
      Serial.print(".");
      retries++;
    }
    if (retries < 10) {
      Serial.println(" success!");
      Serial.print("   Current time: ");
      Serial.println(timeClient.getFormattedTime());
      Serial.print("   Epoch time: ");
      Serial.println(timeClient.getEpochTime());
    } else {
      Serial.println(" failed! Using fallback");
    }
    
    // Stop BLE to free resources
    BLEDevice::deinit(false);
    Serial.println("🔵 BLE stopped (resources freed)");
    
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    Serial.println("   Please check credentials and try again");
    
    // Reset to receive new credentials
    wifiCredentialsReceived = false;
    wifiSSID = "";
    wifiPassword = "";
  }
}

// ============================================================================
// MQTT Functions
// ============================================================================
void connectMQTT() {
  if (!wifiConnected) return;
  
  // Configure TLS for secure connection
  espClient.setInsecure();  // Skip certificate verification (no custom CA)
  Serial.println("🔒 TLS configured (certificate verification disabled)");
  
  mqttClient.setServer(mqtt_server, mqtt_port);
  
  Serial.println("\n📨 Connecting to MQTT broker...");
  Serial.print("   Broker: ");
  Serial.print(mqtt_server);
  Serial.print(":");
  Serial.println(mqtt_port);
  Serial.print("   User: ");
  Serial.println(mqtt_username);
  
  String clientId = "ESP32_" + deviceId;
  
  int attempts = 0;
  while (!mqttClient.connected() && attempts < 5) {
    Serial.print("   Attempt ");
    Serial.print(attempts + 1);
    Serial.print("/5... ");
    
    // Connect with username and password
    if (mqttClient.connect(clientId.c_str(), mqtt_username, mqtt_password)) {
      mqttConnected = true;
      Serial.println("✅ Connected!");
      Serial.println("✅ Authenticated successfully with secure broker");
      
      // Subscribe to device-specific topics
      String modeTopic = "devices/" + deviceId + "/mode/set";
      mqttClient.subscribe(modeTopic.c_str());
      Serial.print("   Subscribed to: ");
      Serial.println(modeTopic);
      
    } else {
      Serial.print("❌ Failed, rc=");
      Serial.println(mqttClient.state());
      Serial.println("⚠️ Check MQTT credentials and broker availability");
      delay(2000);
    }
    
    attempts++;
  }
}

void registerDevice() {
  if (!mqttConnected || deviceRegistered) return;
  
  Serial.println("\n📝 Registering device on MQTT...");
  
  // Create registration message
  StaticJsonDocument<256> doc;
  doc["macAddress"] = deviceId;
  doc["deviceName"] = deviceName;
  doc["timestamp"] = millis();
  
  String payload;
  serializeJson(doc, payload);
  
  // Publish to global registration topic
  bool published = mqttClient.publish(registration_topic, payload.c_str(), true);
  
  if (published) {
    deviceRegistered = true;
    Serial.println("✅ Device registered successfully!");
    Serial.print("   Topic: ");
    Serial.println(registration_topic);
    Serial.print("   Payload: ");
    Serial.println(payload);
    
    // Blink LED rapidly to indicate success
    for (int i = 0; i < 5; i++) {
      digitalWrite(LED_PIN, HIGH);
      delay(100);
      digitalWrite(LED_PIN, LOW);
      delay(100);
    }
    digitalWrite(LED_PIN, HIGH);
    
  } else {
    Serial.println("❌ Registration failed");
  }
}

void publishSensorData() {
  if (!mqttConnected) return;
  
  // Read sensors
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  float waterLevel = readWaterLevel();
  
  // Check if DHT reading is valid
  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("⚠️ Failed to read from DHT sensor");
    return;
  }
  
  // Get real Unix timestamp (seconds since epoch)
  unsigned long timestamp = timeClient.getEpochTime();
  
  // Publish temperature
  publishSensorValue("temperature", temperature, timestamp);
  delay(100);
  
  // Publish humidity
  publishSensorValue("humidity", humidity, timestamp);
  delay(100);
  
  // Publish water_level
  publishSensorValue("water_level", waterLevel, timestamp);
  
  // Publish actuator states
  String actuatorTopic = "devices/" + deviceId + "/actuators/status";
  StaticJsonDocument<256> actuatorDoc;
  actuatorDoc["humidifier1"] = humidifier1State ? "on" : "off";
  actuatorDoc["humidifier2"] = humidifier2State ? "on" : "off";
  actuatorDoc["fan1"] = fan1State ? "on" : "off";
  actuatorDoc["fan2"] = fan2State ? "on" : "off";
  actuatorDoc["buzzer"] = buzzerState ? "on" : "off";
  actuatorDoc["mode"] = (currentMode == PINNING) ? "pinning" : "normal";
  
  String actuatorPayload;
  serializeJson(actuatorDoc, actuatorPayload);
  mqttClient.publish(actuatorTopic.c_str(), actuatorPayload.c_str());
  
  // Print rounded values to serial (1 decimal place)
  Serial.print("📊 Sensors: ");
  Serial.print("Temp=");
  Serial.print(round(temperature * 10.0) / 10.0, 1);
  Serial.print("°C, Humid=");
  Serial.print(round(humidity * 10.0) / 10.0, 1);
  Serial.print("%, Water=");
  Serial.print(round(waterLevel * 10.0) / 10.0, 1);
  Serial.println("%");
}

void publishSensorValue(String sensorType, float value, unsigned long timestamp) {
  String topic = "devices/" + deviceId + "/sensors/" + sensorType;
  
  // Round value to 1 decimal place
  float roundedValue = round(value * 10.0) / 10.0;
  
  // Create JSON payload with value, timestamp, and device_id (MAC without colons)
  StaticJsonDocument<200> doc;
  doc["value"] = serialized(String(roundedValue, 1));  // Force 1 decimal place (e.g., 29.0)
  doc["timestamp"] = timestamp;
  doc["device_id"] = deviceId;  // MAC without colons (e.g., AABBCCDDEEFF)
  
  String payload;
  serializeJson(doc, payload);
  
  mqttClient.publish(topic.c_str(), payload.c_str());
}

// Function to read water level
float readWaterLevel() {
  int rawValue = analogRead(WATER_LEVEL_PIN);
  // Convert to percentage (0-100%)
  float percentage = (rawValue / 4095.0) * 100.0;
  return percentage;
}

// ============================================================================
// Main Loop
// ============================================================================
void loop() {
  // If credentials received but not connected, try to connect
  if (wifiCredentialsReceived && !wifiConnected) {
    connectWiFi();
  }
  
  // If WiFi connected but MQTT not connected, connect MQTT
  if (wifiConnected && !mqttConnected) {
    connectMQTT();
  }
  
  // If MQTT connected but not registered, register device
  if (mqttConnected && !deviceRegistered) {
    registerDevice();
  }
  
  // Maintain MQTT connection
  if (mqttConnected) {
    mqttClient.loop();
    
    // Publish sensor data periodically
    unsigned long now = millis();
    if (now - lastSensorPublish >= sensorInterval) {
      publishSensorData();
      lastSensorPublish = now;
    }
  }
  
  // Small delay for stability
  delay(10);
}
