#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// DHT22 sensor setup
#define DHTPIN 4        // GPIO4 pin connected to DHT22
#define DHTTYPE DHT22   // DHT 22 (AM2302)
DHT dht(DHTPIN, DHTTYPE);

// Water level sensor setup
#define WATER_LEVEL_PIN 35  // GPIO 35 (ADC1_CH7) - Water level sensor S pin

// LED pin for BLE status indication
#define LED_PIN 2

// Actuator control pins
#define HUMIDIFIER1_PIN 25  // GPIO 25 - Humidifier 1 relay
#define HUMIDIFIER2_PIN 26  // GPIO 26 - Humidifier 2 relay
#define FAN1_PIN 27         // GPIO 27 - Fan 1 relay
#define FAN2_PIN 14         // GPIO 14 - Fan 2 relay
#define BUZZER_PIN 33       // GPIO 33 - Buzzer for alarm

// NTP Client setup
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0, 60000); // UTC, update every 60 seconds

// ============================================================================
// BLE Configuration (for WiFi provisioning)
// ============================================================================
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define WIFI_CHAR_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pWifiCharacteristic = NULL;
bool bleDeviceConnected = false;

// Device configuration (MAC-based for multi-device support)
String deviceMacAddress = "";
String deviceId = "";  // Will be MAC without colons (e.g., "AABBCCDDEEFF")
String deviceName = "";  // Will be "ESP32_XXXXXX"

// WiFi credentials
String wifiSSID = "";
String wifiPassword = "";
bool wifiCredentialsReceived = false;
bool wifiConnected = false;

// MQTT broker configuration - Secure connection to private broker
const char* mqtt_server = "api.milloserver.uk";  // Private MQTT broker
const int mqtt_port = 8883;                       // Secure MQTT port (TLS)
const char* mqtt_username = "zhangyifei";         // MQTT username
const char* mqtt_password = "123456";             // MQTT password

WiFiClientSecure espClient;  // Use WiFiClientSecure for TLS connection
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

// Alarm tracking to prevent spam
bool alarmActive = false;
String lastAlarmReason = "";

// Forward declarations
void publishAlarmData(float humidity, float temperature, float waterLevel);
float getRandomLight();

// ============================================================================
// BLE Callback Classes
// ============================================================================
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      bleDeviceConnected = true;
      Serial.println("📱 BLE Client connected");
      digitalWrite(LED_PIN, HIGH);
      delay(100);  // Small delay for connection stability
    };

    void onDisconnect(BLEServer* pServer) {
      bleDeviceConnected = false;
      Serial.println("📱 BLE Client disconnected");
      digitalWrite(LED_PIN, LOW);
      
      // Restart advertising for new connections
      if (!wifiCredentialsReceived) {
        delay(500);  // Wait before restarting advertising
        pServer->startAdvertising();
        Serial.println("🔵 BLE Advertising restarted");
      }
    }
};

class WiFiCharacteristicCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      
      if (value.length() > 0) {
        Serial.println("📩 Received WiFi credentials via BLE");
        Serial.print("   Raw data length: ");
        Serial.println(value.length());
        
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
        
        // Trim whitespace from SSID and password
        wifiSSID.trim();
        wifiPassword.trim();
        
        Serial.print("   SSID: '");
        Serial.print(wifiSSID);
        Serial.println("'");
        Serial.print("   SSID length: ");
        Serial.println(wifiSSID.length());
        Serial.print("   Password: '");
        Serial.print(wifiPassword);  // TEMPORARY: Print password for debugging
        Serial.println("'");
        Serial.print("   Password length: ");
        Serial.println(wifiPassword.length());
        
        wifiCredentialsReceived = true;
        
        // Blink LED to indicate success
        for (int i = 0; i < 3; i++) {
          digitalWrite(LED_PIN, HIGH);
          delay(200);
          digitalWrite(LED_PIN, LOW);
          delay(200);
        }
        digitalWrite(LED_PIN, HIGH);
      }
    }
};

// ============================================================================
// Setup Functions
// ============================================================================
void setupBLE() {
  Serial.println("🔵 Initializing BLE for WiFi provisioning...");
  
  // Create BLE Device with increased MTU
  BLEDevice::init(deviceName.c_str());
  BLEDevice::setMTU(517);  // Set maximum MTU size for better compatibility
  
  // Create BLE Server with connection parameters
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());
  
  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Create WiFi Characteristic with WRITE_NR for better reliability
  pWifiCharacteristic = pService->createCharacteristic(
                          WIFI_CHAR_UUID,
                          BLECharacteristic::PROPERTY_READ |
                          BLECharacteristic::PROPERTY_WRITE |
                          BLECharacteristic::PROPERTY_WRITE_NR  // Write without response
                        );
  
  pWifiCharacteristic->setCallbacks(new WiFiCharacteristicCallbacks());
  pWifiCharacteristic->addDescriptor(new BLE2902());
  
  // Start the service
  pService->start();
  
  // Configure advertising with better parameters
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // Connection interval min
  pAdvertising->setMaxPreferred(0x12);  // Connection interval max
  
  // Start advertising
  BLEDevice::startAdvertising();
  
  Serial.println("✅ BLE Server started and advertising");
  Serial.print("   Device Name: ");
  Serial.println(deviceName);
  Serial.print("   Service UUID: ");
  Serial.println(SERVICE_UUID);
  Serial.println("   Waiting for BLE connection to receive WiFi credentials...");
}

void setup_wifi() {
  if (wifiSSID.length() == 0) {
    Serial.println("\n⚠️ No WiFi credentials available. Please use BLE to send credentials.");
    return;
  }
  
  Serial.println("\n📡 Connecting to WiFi...");
  Serial.print("   SSID: ");
  Serial.println(wifiSSID);
  Serial.print("   SSID length: ");
  Serial.println(wifiSSID.length());
  Serial.print("   Password length: ");
  Serial.println(wifiPassword.length());
  
  // Disconnect any existing connection first
  WiFi.disconnect(true);
  delay(1000);
  
  // Set WiFi mode to Station (client)
  WiFi.mode(WIFI_STA);
  delay(100);
  
  Serial.println("   WiFi mode set to STA");
  Serial.println("   Starting connection...");

  WiFi.begin(wifiSSID.c_str(), wifiPassword.c_str());
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 60) {  // 30 seconds timeout
    delay(500);
    yield();  // Feed the watchdog
    Serial.print(".");
    attempts++;
    
    // Blink LED while connecting
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
    
    // Print status code every 10 attempts
    if (attempts % 10 == 0) {
      Serial.println();
      Serial.print("   WiFi Status Code: ");
      Serial.print(WiFi.status());
      Serial.print(" (");
      switch(WiFi.status()) {
        case WL_IDLE_STATUS: Serial.print("IDLE"); break;
        case WL_NO_SSID_AVAIL: Serial.print("NO_SSID_AVAILABLE"); break;
        case WL_SCAN_COMPLETED: Serial.print("SCAN_COMPLETED"); break;
        case WL_CONNECTED: Serial.print("CONNECTED"); break;
        case WL_CONNECT_FAILED: Serial.print("CONNECT_FAILED"); break;
        case WL_CONNECTION_LOST: Serial.print("CONNECTION_LOST"); break;
        case WL_DISCONNECTED: Serial.print("DISCONNECTED"); break;
        default: Serial.print("UNKNOWN"); break;
      }
      Serial.println(")");
      Serial.print("   ");
    }
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    
    Serial.println("");
    Serial.println("✅ WiFi connected!");
    Serial.print("   IP address: ");
    Serial.println(WiFi.localIP());
    Serial.print("   Signal strength (RSSI): ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    
    // Stop BLE to free resources after successful WiFi connection
    BLEDevice::deinit(false);
    Serial.println("🔵 BLE stopped (resources freed)");
    
    // Re-initialize LED pin and turn it ON (BLE deinit might have affected GPIO)
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, HIGH);
    Serial.println("💡 LED turned ON to indicate WiFi connected");
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    Serial.print("   Final WiFi Status Code: ");
    Serial.print(WiFi.status());
    Serial.print(" (");
    switch(WiFi.status()) {
      case WL_IDLE_STATUS: Serial.print("IDLE"); break;
      case WL_NO_SSID_AVAIL: Serial.print("NO_SSID_AVAILABLE - Router not found"); break;
      case WL_SCAN_COMPLETED: Serial.print("SCAN_COMPLETED"); break;
      case WL_CONNECT_FAILED: Serial.print("CONNECT_FAILED - Wrong password?"); break;
      case WL_CONNECTION_LOST: Serial.print("CONNECTION_LOST"); break;
      case WL_DISCONNECTED: Serial.print("DISCONNECTED"); break;
      default: Serial.print("UNKNOWN"); break;
    }
    Serial.println(")");
    Serial.println("   Please check:");
    Serial.println("   1. Router is powered on and within range");
    Serial.println("   2. SSID is correct (case-sensitive)");
    Serial.println("   3. Password is correct");
    Serial.println("   4. Router is 2.4GHz (ESP32 doesn't support 5GHz)");
    digitalWrite(LED_PIN, LOW);
    
    // Reset credentials to allow retry
    wifiCredentialsReceived = false;
  }
}

void setup_time() {
  timeClient.begin();
  Serial.print("Synchronizing time with NTP server...");
  
  int retries = 0;
  while (!timeClient.update() && retries < 10) {
    timeClient.forceUpdate();
    delay(1000);
    yield();  // Feed the watchdog
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
  
  // Check water level (critical if < 30% OR > 70%)
  if (waterLevel < 30.0) {
    alarmNeeded = true;
    alarmReason += "Water level low (" + String(waterLevel, 1) + "% < 30%); ";
  } else if (waterLevel > 70.0) {
    alarmNeeded = true;
    alarmReason += "Water level high (" + String(waterLevel, 1) + "% > 70%); ";
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
  
  // Publish to alarm topic only when alarm state changes (good -> bad)
  if (alarmNeeded && !alarmActive) {
    publishAlarmData(humidity, temperature, waterLevel);
    alarmActive = true;
    lastAlarmReason = alarmReason;
  } else if (!alarmNeeded && alarmActive) {
    // Reset alarm state when sensors return to normal
    alarmActive = false;
    lastAlarmReason = "";
    Serial.println("✅ Alarm state reset - sensors back to normal");
  }
}

// Publish alarm data to trigger Cloud Function
void publishAlarmData(float humidity, float temperature, float waterLevel) {
  // Round values to 1 decimal place
  float roundedHumidity = round(humidity * 10.0) / 10.0;
  float roundedTemp = round(temperature * 10.0) / 10.0;
  float roundedWater = round(waterLevel * 10.0) / 10.0;
  float randomLight = getRandomLight();
  
  // Get current mode as single character
  char modeChar = (currentMode == PINNING) ? 'p' : 'n';
  
  // Create alarm topic: topic/{deviceId}/alarm
  String topic = "topic/" + deviceId + "/alarm";
  
  // Create payload: [humidity,light,temp,water,mode]
  String payload = "[" + String(roundedHumidity, 1) + "," + 
                         String(randomLight, 1) + "," + 
                         String(roundedTemp, 1) + "," + 
                         String(roundedWater, 1) + "," + 
                         String(modeChar) + "]";
  
  // Publish to MQTT
  bool success = client.publish(topic.c_str(), payload.c_str());
  
  if (success) {
    Serial.println("🚨 ALARM PUBLISHED: " + topic + " -> " + payload);
    Serial.print("   Reason: ");
    Serial.println(lastAlarmReason);
  } else {
    Serial.println("❌ Failed to publish alarm");
  }
}

// Check and handle pinning mode timer
void checkPinningTimer() {
  if (pinningModeActive && getCurrentTimestamp() >= pinningEndTime) {
    Serial.println("⏱️ Pinning mode timer expired, switching to Normal mode");
    currentMode = NORMAL;
    pinningModeActive = false;
    
    // Publish mode change to topic/{deviceId}/mode/status
    String topic = "topic/" + deviceId + "/mode/status";
    client.publish(topic.c_str(), "n");
    Serial.println("📢 Published mode change: " + topic + " -> n");
  }
}

// Publish countdown for pinning mode (every 60 seconds)
unsigned long lastCountdownPublish = 0;
void publishPinningCountdown() {
  if (!pinningModeActive) {
    return;  // Only publish when in pinning mode
  }
  
  unsigned long now = millis();
  if (now - lastCountdownPublish >= 60000) {  // Every 60 seconds
    unsigned long remaining = pinningEndTime - getCurrentTimestamp();
    
    // Create topic: topic/{deviceId}/countdown
    String topic = "topic/" + deviceId + "/countdown";
    String payload = String(remaining);
    
    bool success = client.publish(topic.c_str(), payload.c_str());
    if (success) {
      Serial.println("⏱️ Countdown published: " + topic + " -> " + payload + " seconds");
    }
    
    lastCountdownPublish = now;
  }
}

// MQTT callback for incoming messages
void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.print("📨 Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  Serial.println(message);
  
  String topicStr = String(topic);
  
  // Handle mode control: topic/{deviceId}/mode/set
  if (topicStr.endsWith("/mode/set")) {
    // Expected format: "p,3600" or "n,0"
    int commaIndex = message.indexOf(',');
    if (commaIndex > 0) {
      String mode = message.substring(0, commaIndex);
      unsigned long durationSeconds = message.substring(commaIndex + 1).toInt();
      
      if (mode == "n") {
        currentMode = NORMAL;
        pinningModeActive = false;
        Serial.println("✅ Mode set to: NORMAL");
      } else if (mode == "p") {
        currentMode = PINNING;
        pinningModeActive = true;
        pinningEndTime = getCurrentTimestamp() + durationSeconds;
        
        Serial.print("✅ Mode set to: PINNING for ");
        Serial.print(durationSeconds / 3600);
        Serial.println(" hours");
        Serial.print("   End time (epoch): ");
        Serial.println(pinningEndTime);
      }
      
      // Acknowledge mode change: topic/{deviceId}/mode/status
      String statusTopic = "topic/" + deviceId + "/mode/status";
      String statusPayload = (mode == "p") ? "p" : "n";
      client.publish(statusTopic.c_str(), statusPayload.c_str());
      Serial.println("📢 Acknowledged: " + statusTopic + " -> " + statusPayload);
    }
  }
}

// Publish device registration message for Flutter app discovery
void publishDeviceRegistration() {
  Serial.println("📢 Publishing device registration...");
  
  // Create registration JSON payload
  StaticJsonDocument<200> doc;
  doc["macAddress"] = deviceMacAddress;  // MAC with colons (e.g., "E8:6B:EA:D0:BD:78")
  doc["deviceName"] = deviceName;         // Device name (e.g., "ESP32_D0BD78")
  doc["timestamp"] = getCurrentTimestamp(); // Unix timestamp
  
  String payload;
  serializeJson(doc, payload);
  
  // Publish to system/devices/register topic (NOT topic/system/devices/register!)
  const char* registrationTopic = "system/devices/register";
  bool success = client.publish(registrationTopic, payload.c_str(), true); // Retained message
  
  if (success) {
    Serial.println("✅ Device registration published:");
    Serial.print("   Topic: ");
    Serial.println(registrationTopic);
    Serial.print("   Payload: ");
    Serial.println(payload);
  } else {
    Serial.println("❌ Failed to publish device registration");
  }
}

void reconnect() {
  // Try to connect only once per call, don't block in a while loop
  if (!client.connected()) {
    Serial.print("Attempting MQTT connection to ");
    Serial.print(mqtt_server);
    Serial.print(":");
    Serial.print(mqtt_port);
    Serial.print("...");
    
    // Use device ID as client identifier
    String clientId = "ESP32_" + deviceId;
    
    // Connect with username and password authentication
    if (client.connect(clientId.c_str(), mqtt_username, mqtt_password)) {
      Serial.println("connected");
      Serial.println("✅ Authenticated successfully with secure broker");
      
      // Subscribe to mode control topic: topic/{deviceId}/mode/set
      String modeTopic = "topic/" + deviceId + "/mode/set";
      client.subscribe(modeTopic.c_str());
      Serial.print("📬 Subscribed to: ");
      Serial.println(modeTopic);
      
      // Publish device registration (so Flutter app can discover it)
      publishDeviceRegistration();
      
      // Publish initial mode status: topic/{deviceId}/mode/status
      String modeStatusTopic = "topic/" + deviceId + "/mode/status";
      char modeChar = (currentMode == PINNING) ? 'p' : 'n';
      client.publish(modeStatusTopic.c_str(), String(modeChar).c_str());
      Serial.print("📢 Initial mode published: ");
      Serial.println(modeChar == 'p' ? "PINNING" : "NORMAL");
      
      // Publish status as online when connected: topic/{deviceId}/status
      String statusTopic = "topic/" + deviceId + "/status";
      client.publish(statusTopic.c_str(), "online");
      Serial.println("📢 Status published: online");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.print(" WiFi status: ");
      Serial.print(WiFi.status());
      Serial.print(" IP: ");
      Serial.println(WiFi.localIP());
      Serial.println("⚠️ Check MQTT credentials and broker availability");
      // Don't delay here, let loop() handle the timing
    }
  }
}

// Generate random light value (0-100) - placeholder for future light sensor
float getRandomLight() {
  return random(0, 101);  // Returns 0-100
}

// Publish unified sensor data: topic/{deviceId} with payload [humidity,light,temp,water,mode]
void publishSensorData(float humidity, float temperature, float waterLevel) {
  // Round values to 1 decimal place
  float roundedHumidity = round(humidity * 10.0) / 10.0;
  float roundedTemp = round(temperature * 10.0) / 10.0;
  float roundedWater = round(waterLevel * 10.0) / 10.0;
  float randomLight = getRandomLight();
  
  // Get current mode as single character
  char modeChar = (currentMode == PINNING) ? 'p' : 'n';
  
  // Create topic: topic/{deviceId}
  String topic = "topic/" + deviceId;
  
  // Create payload: [humidity,light,temp,water,mode]
  String payload = "[" + String(roundedHumidity, 1) + "," + 
                         String(randomLight, 1) + "," + 
                         String(roundedTemp, 1) + "," + 
                         String(roundedWater, 1) + "," + 
                         String(modeChar) + "]";
  
  // Publish to MQTT
  client.publish(topic.c_str(), payload.c_str());
  Serial.println("📊 Published: " + topic + " -> " + payload);
}

void setup() {
  Serial.begin(115200);
  Serial.println();
  Serial.println("===============================================");
  Serial.println("   ESP32 Mushroom Monitoring System");
  Serial.println("   with BLE WiFi Provisioning");
  Serial.println("===============================================");
  
  // Initialize LED
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // Get MAC address and create device ID
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
  Serial.println("✅ Actuator pins initialized");
  
  dht.begin();              // Initialize DHT22 sensor
  Serial.println("✅ DHT22 sensor initialized");
  
  // Initialize BLE for WiFi provisioning
  setupBLE();
  
  Serial.println("\n⏳ Waiting for WiFi credentials via BLE...");
  Serial.println("   Use your Flutter app to scan and send WiFi credentials");
  Serial.println("===============================================\n");
}

void loop() {
  // BLE State Machine: If credentials received but WiFi not connected, try to connect
  if (wifiCredentialsReceived && !wifiConnected) {
    setup_wifi();
    if (wifiConnected) {
      setup_time();  // Initialize NTP after WiFi connection
      
      // Configure TLS for secure MQTT connection
      espClient.setInsecure();  // Skip certificate verification (no custom CA)
      Serial.println("🔒 TLS configured (certificate verification disabled)");
      
      client.setServer(mqtt_server, mqtt_port);
      client.setCallback(callback);
      
      Serial.println("✅ System ready!");
      Serial.print("   MQTT broker: ");
      Serial.print(mqtt_server);
      Serial.print(":");
      Serial.println(mqtt_port);
      Serial.print("   MQTT user: ");
      Serial.println(mqtt_username);
    }
  }
  
  // Only proceed with MQTT and sensors if WiFi is connected
  if (!wifiConnected) {
    delay(100);  // Reduced delay to avoid WDT timeout
    yield();     // Feed the watchdog
    return;
  }
  
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  
  // Check pinning mode timer
  if (pinningModeActive) {
    checkPinningTimer();
    publishPinningCountdown();  // Publish countdown every 60 seconds
  }
  
  // Ensure LED stays ON (in case it was turned off somehow)
  digitalWrite(LED_PIN, HIGH);

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
    
    // Publish unified sensor data: topic/{deviceId} -> [humidity,light,temp,water,mode]
    publishSensorData(humidity, temperature, waterLevel);
    
    // Print sensor readings and mode (rounded to 1 decimal)
    Serial.print("🌿 Mode: ");
    Serial.println((currentMode == PINNING) ? "PINNING" : "NORMAL");
    Serial.print("   Temperature: ");
    Serial.print(round(temperature * 10.0) / 10.0, 1);
    Serial.println("°C");
    Serial.print("   Humidity: ");
    Serial.print(round(humidity * 10.0) / 10.0, 1);
    Serial.println("%");
    Serial.print("   Water Level: ");
    Serial.print(round(waterLevel * 10.0) / 10.0, 1);
    Serial.println("%");
    
    // Print actuator status with icons
    Serial.print("   Actuators: 💧H1:");
    Serial.print(humidifier1State ? "ON" : "OFF");
    Serial.print(" 💧H2:");
    Serial.print(humidifier2State ? "ON" : "OFF");
    Serial.print(" 🌀F1:");
    Serial.print(fan1State ? "ON" : "OFF");
    Serial.print(" 🌀F2:");
    Serial.print(fan2State ? "ON" : "OFF");
    Serial.print(" 🚨BZ:");
    Serial.println(buzzerState ? "ON" : "OFF");
  } else {
    Serial.println("❌ Failed to read from DHT22 sensor!");
  }
  
  // Use shorter delays with yield to prevent WDT timeout
  for (int i = 0; i < 50; i++) {
    delay(100);  // 50 x 100ms = 5000ms total
    yield();     // Feed the watchdog
  }
}
