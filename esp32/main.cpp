#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

// DHT22 sensor setup
#define DHTPIN 4        // GPIO4 pin connected to DHT22
#define DHTTYPE DHT22   // DHT 22 (AM2302)
DHT dht(DHTPIN, DHTTYPE);

// Water level sensor setup
#define WATER_LEVEL_PIN 35  // GPIO 35 (ADC1_CH7) - Water level sensor S pin

// Actuator control pins
#define HUMIDIFIER1_PIN 25  // GPIO 25 - Humidifier 1 relay
#define HUMIDIFIER2_PIN 26  // GPIO 26 - Humidifier 2 relay
#define FAN1_PIN 27         // GPIO 27 - Fan 1 relay
#define FAN2_PIN 14         // GPIO 14 - Fan 2 relay
#define BUZZER_PIN 33       // GPIO 33 - Buzzer for alarm

// NTP Client setup
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0, 60000); // UTC, update every 60 seconds

// Device configuration
const char* deviceId = "ESP32_001";

// Replace with your WiFi credentials
const char* ssid = "dlwlrma";
const char* password = "00000000";

// MQTT broker configuration
const char* mqtt_server = "broker.mqtt.cool";  // Public MQTT broker
const int mqtt_port = 1883;                    // MQTT port

WiFiClient espClient;
PubSubClient client(espClient);

// Cultivation mode and timer
enum CultivationMode { NORMAL, PINNING };
CultivationMode currentMode = NORMAL;
unsigned long pinningEndTime = 0;  // Epoch time when pinning mode should end
bool pinningModeActive = false;

// Mode thresholds
struct ModeThresholds {
  float minHumidity;
  float maxHumidity;
  float minTemp;
  float maxTemp;
};

ModeThresholds normalMode = {80.0, 85.0, 18.0, 30.0};   // Humidity 80-85%, Temp 18-30°C
ModeThresholds pinningMode = {90.0, 95.0, 18.0, 30.0};  // Humidity 90-95%, Temp 18-30°C

// Actuator states
bool humidifier1State = false;
bool humidifier2State = false;
bool fan1State = true;  // Fan 1 always on
bool fan2State = false;
bool buzzerState = false;  // Buzzer alarm state

void setup_wifi() {
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
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void setup_time() {
  timeClient.begin();
  Serial.print("Synchronizing time with NTP server...");
  
  int retries = 0;
  while (!timeClient.update() && retries < 10) {
    timeClient.forceUpdate();
    delay(1000);
    Serial.print(".");
    retries++;
  }
  
  if (retries < 10) {
    Serial.println(" success!");
    Serial.print("Current time: ");
    Serial.println(timeClient.getFormattedTime());
    Serial.print("Epoch time: ");
    Serial.println(timeClient.getEpochTime());
  } else {
    Serial.println(" failed! Using millis() as fallback");
  }
}

unsigned long getCurrentTimestamp() {
  if (timeClient.isTimeSet()) {
    timeClient.update(); // Update time periodically
    return timeClient.getEpochTime();
  } else {
    // Fallback to millis if NTP failed
    return millis() / 1000; // Convert to seconds
  }
}

// Function to read water level
float readWaterLevel() {
  int rawValue = analogRead(WATER_LEVEL_PIN);
  // Convert to percentage (0-100%)
  float percentage = (rawValue / 4095.0) * 100.0;
  return percentage;
}

// Control actuators based on pin state
void setActuator(int pin, bool state, const char* name) {
  digitalWrite(pin, state ? HIGH : LOW);
  Serial.print(name);
  Serial.println(state ? " ON" : " OFF");
}

// Get current mode thresholds
ModeThresholds getCurrentThresholds() {
  return (currentMode == PINNING) ? pinningMode : normalMode;
}

// Automatic control logic for humidity
void controlHumidity(float humidity) {
  ModeThresholds thresholds = getCurrentThresholds();
  
  if (humidity < thresholds.minHumidity) {
    // Below range: both humidifiers ON
    if (!humidifier1State) {
      humidifier1State = true;
      setActuator(HUMIDIFIER1_PIN, true, "Humidifier 1");
    }
    if (!humidifier2State) {
      humidifier2State = true;
      setActuator(HUMIDIFIER2_PIN, true, "Humidifier 2");
    }
  } else if (humidity >= thresholds.minHumidity && humidity <= thresholds.maxHumidity) {
    // Within range: humidifier 1 ON, humidifier 2 OFF
    if (!humidifier1State) {
      humidifier1State = true;
      setActuator(HUMIDIFIER1_PIN, true, "Humidifier 1");
    }
    if (humidifier2State) {
      humidifier2State = false;
      setActuator(HUMIDIFIER2_PIN, false, "Humidifier 2");
    }
  } else {
    // Above range: both humidifiers OFF
    if (humidifier1State) {
      humidifier1State = false;
      setActuator(HUMIDIFIER1_PIN, false, "Humidifier 1");
    }
    if (humidifier2State) {
      humidifier2State = false;
      setActuator(HUMIDIFIER2_PIN, false, "Humidifier 2");
    }
  }
}

// Automatic control logic for temperature (with fans)
void controlTemperature(float temperature) {
  // Fan 1 always ON (constant air circulation)
  if (!fan1State) {
    fan1State = true;
    setActuator(FAN1_PIN, true, "Fan 1");
  }
  
  // Fan 2 only turns ON when temperature exceeds 30°C (critical threshold)
  // This is independent of cultivation mode - both modes use same temp threshold
  if (temperature > 30.0) {
    // Temperature too high: both fans ON for maximum cooling
    if (!fan2State) {
      fan2State = true;
      setActuator(FAN2_PIN, true, "Fan 2");
      Serial.print("⚠️ High temperature detected: ");
      Serial.print(temperature);
      Serial.println("°C - Activating Fan 2 for emergency cooling");
    }
  } else {
    // Temperature safe (≤30°C): only Fan 1 ON
    if (fan2State) {
      fan2State = false;
      setActuator(FAN2_PIN, false, "Fan 2");
      Serial.print("✅ Temperature normal: ");
      Serial.print(temperature);
      Serial.println("°C - Fan 2 deactivated");
    }
  }
}

// Check if sensor data is within safe thresholds and control buzzer alarm
void checkAlarmConditions(float temperature, float humidity, float waterLevel) {
  ModeThresholds thresholds = getCurrentThresholds();
  bool alarmNeeded = false;
  String alarmReason = "";
  
  // Check temperature (critical if > 30°C)
  if (temperature > 30.0) {
    alarmNeeded = true;
    alarmReason += "Temperature critical (" + String(temperature, 1) + "°C > 30°C); ";
  }
  
  // Check humidity (must be within mode range)
  if (humidity < thresholds.minHumidity) {
    alarmNeeded = true;
    alarmReason += "Humidity too low (" + String(humidity, 1) + "% < " + String(thresholds.minHumidity, 0) + "%); ";
  } else if (humidity > thresholds.maxHumidity) {
    alarmNeeded = true;
    alarmReason += "Humidity too high (" + String(humidity, 1) + "% > " + String(thresholds.maxHumidity, 0) + "%); ";
  }
  
  // Check water level (critical if < 30%)
  if (waterLevel < 30.0) {
    alarmNeeded = true;
    alarmReason += "Water level low (" + String(waterLevel, 1) + "% < 30%); ";
  }
  
  // Control buzzer based on alarm conditions
  if (alarmNeeded && !buzzerState) {
    // Activate buzzer alarm
    buzzerState = true;
    digitalWrite(BUZZER_PIN, HIGH);
    Serial.println("🚨 ALARM ACTIVATED!");
    Serial.print("Reason: ");
    Serial.println(alarmReason);
  } else if (!alarmNeeded && buzzerState) {
    // Deactivate buzzer alarm
    buzzerState = false;
    digitalWrite(BUZZER_PIN, LOW);
    Serial.println("✅ ALARM CLEARED - All sensors within safe range");
  }
}

// Check and handle pinning mode timer
void checkPinningTimer() {
  if (pinningModeActive && getCurrentTimestamp() >= pinningEndTime) {
    Serial.println("Pinning mode timer expired, switching to Normal mode");
    currentMode = NORMAL;
    pinningModeActive = false;
    
    // Publish mode change
    String topic = "devices/" + String(deviceId) + "/mode/status";
    client.publish(topic.c_str(), "normal");
  }
}

// MQTT callback for incoming messages
void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  Serial.println(message);
  
  String topicStr = String(topic);
  
  // Handle mode control: devices/{deviceId}/mode/set
  if (topicStr.endsWith("/mode/set")) {
    DynamicJsonDocument doc(256);
    DeserializationError error = deserializeJson(doc, message);
    
    if (!error) {
      String mode = doc["mode"];
      
      if (mode == "normal") {
        currentMode = NORMAL;
        pinningModeActive = false;
        Serial.println("Mode set to: NORMAL");
      } else if (mode == "pinning") {
        currentMode = PINNING;
        pinningModeActive = true;
        
        // Get timer duration in seconds
        unsigned long durationSeconds = doc["duration"];
        pinningEndTime = getCurrentTimestamp() + durationSeconds;
        
        Serial.print("Mode set to: PINNING for ");
        Serial.print(durationSeconds / 3600);
        Serial.println(" hours");
        Serial.print("End time (epoch): ");
        Serial.println(pinningEndTime);
      }
      
      // Acknowledge mode change
      String statusTopic = "devices/" + String(deviceId) + "/mode/status";
      client.publish(statusTopic.c_str(), mode.c_str());
    }
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection to ");
    Serial.print(mqtt_server);
    Serial.print(":");
    Serial.print(mqtt_port);
    Serial.print("...");
    if (client.connect(deviceId)) {  // Use deviceId for client identifier
      Serial.println("connected");
      
      // Subscribe to mode control topic
      String modeTopic = "devices/" + String(deviceId) + "/mode/set";
      client.subscribe(modeTopic.c_str());
      Serial.print("Subscribed to: ");
      Serial.println(modeTopic);
      
      // Publish status as online when connected
      String statusTopic = "devices/" + String(deviceId) + "/status";
      client.publish(statusTopic.c_str(), "online");
      Serial.println("Status published: online");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.print(" WiFi status: ");
      Serial.print(WiFi.status());
      Serial.print(" IP: ");
      Serial.println(WiFi.localIP());
      delay(5000);
    }
  }
}

// Function to publish sensor data with real timestamp
void publishSensorData(const char* sensorType, float value) {
  // Create topic: devices/ESP32_001/sensors/temperature
  String topic = "devices/" + String(deviceId) + "/sensors/" + String(sensorType);
  
  // Create JSON payload with value and real timestamp
  DynamicJsonDocument doc(250);
  doc["value"] = value;
  doc["timestamp"] = getCurrentTimestamp(); // Use real Unix timestamp
  doc["device_id"] = deviceId;
  
  String payload;
  serializeJson(doc, payload);
  
  // Publish to MQTT
  client.publish(topic.c_str(), payload.c_str());
  Serial.println("Published: " + topic + " -> " + payload);
}

void setup() {
  Serial.begin(115200);
  Serial.println();
  Serial.println("ESP32 MQTT DHT22 Sensor Starting...");
  
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
  digitalWrite(BUZZER_PIN, LOW);  // Buzzer OFF initially
  Serial.println("Actuator pins initialized");
  
  dht.begin();              // Initialize DHT22 sensor
  Serial.println("DHT22 sensor initialized");
  
  setup_wifi();
  setup_time();             // Initialize NTP time client
  
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);  // Set MQTT callback for incoming messages
  Serial.print("MQTT broker: ");
  Serial.print(mqtt_server);
  Serial.print(":");
  Serial.println(mqtt_port);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  
  // Check pinning mode timer
  if (pinningModeActive) {
    checkPinningTimer();
  }

  // Read temperature and humidity from DHT22
  float temperature = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  // Read water level
  float waterLevel = readWaterLevel();
  
  // Check if readings are valid
  if (!isnan(temperature) && !isnan(humidity)) {
    // Check alarm conditions FIRST (before controlling actuators)
    checkAlarmConditions(temperature, humidity, waterLevel);
    
    // Control actuators based on sensor readings
    controlHumidity(humidity);
    controlTemperature(temperature);
    
    // Publish individual sensor data with real timestamps
    publishSensorData("temperature", temperature);
    delay(100); // Small delay between publishes
    publishSensorData("humidity", humidity);
    delay(100);
    publishSensorData("water_level", waterLevel);
    
    // Publish actuator states
    String actuatorTopic = "devices/" + String(deviceId) + "/actuators/status";
    DynamicJsonDocument actuatorDoc(256);
    actuatorDoc["humidifier1"] = humidifier1State ? "on" : "off";
    actuatorDoc["humidifier2"] = humidifier2State ? "on" : "off";
    actuatorDoc["fan1"] = fan1State ? "on" : "off";
    actuatorDoc["fan2"] = fan2State ? "on" : "off";
    actuatorDoc["buzzer"] = buzzerState ? "on" : "off";  // Include buzzer status
    actuatorDoc["mode"] = (currentMode == PINNING) ? "pinning" : "normal";
    if (pinningModeActive) {
      actuatorDoc["pinning_remaining"] = pinningEndTime - getCurrentTimestamp();
    }
    
    String actuatorPayload;
    serializeJson(actuatorDoc, actuatorPayload);
    client.publish(actuatorTopic.c_str(), actuatorPayload.c_str());
    
    // Also publish combined data for backward compatibility with real timestamp
    DynamicJsonDocument combinedDoc(300);
    combinedDoc["temperature"] = temperature;
    combinedDoc["humidity"] = humidity;
    combinedDoc["water_level"] = waterLevel;
    combinedDoc["timestamp"] = getCurrentTimestamp(); // Real Unix timestamp
    combinedDoc["device_id"] = deviceId;
    
    String combinedPayload;
    serializeJson(combinedDoc, combinedPayload);
    
    client.publish("esp32/test", combinedPayload.c_str());
    Serial.println("Combined data sent: " + combinedPayload);
    
    // Print sensor readings and mode
    Serial.print("Mode: ");
    Serial.println((currentMode == PINNING) ? "PINNING" : "NORMAL");
    Serial.print("Temperature: ");
    Serial.print(temperature);
    Serial.println("°C");
    Serial.print("Humidity: ");
    Serial.print(humidity);
    Serial.println("%");
    Serial.print("Water Level: ");
    Serial.print(waterLevel);
    Serial.println("%");
  } else {
    Serial.println("Failed to read from DHT22 sensor!");
  }
  
  delay(5000);
}
