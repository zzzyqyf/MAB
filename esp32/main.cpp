#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <Preferences.h>
#include <WebServer.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <ctype.h>

#define MQTT_HOST   "api.milloserver.uk"
#define MQTT_PORT   8883
#define MQTT_USER   "david"
#define MQTT_PASS   "888888"

#define PUBLISH_MS  10000

// ----------- Sensors -----------
#define USE_DHT     1
#define DHT_PIN     4        // DHT data pin
#define LIGHT_PIN   34       // optional digital sensor (digital 0/1)

#if USE_DHT
  #include <DHT.h>
  #define DHT_TYPE DHT22
  static DHT dht(DHT_PIN, DHT_TYPE);
#endif

// ----------- Relays ------------
#define RELAY1_PIN  25        // IN1 (Temp control)
#define RELAY2_PIN  26        // IN2 (Humidity control)
#define BUZZER_PIN  33        // GPIO 33 - Buzzer for alarms
#define RELAY4_PIN  32        // IN4 (mirror of RELAY2)
#define RELAY5_PIN  22        // IN5 (mirror of RELAY1)

// -------- Water Level Switch --------
#define WATER_PIN   27        // Float switch input (closed -> LOW, open -> HIGH)
const unsigned long WATER_DEBOUNCE_MS = 100;  // milliseconds the reading must stay stable
constexpr int WATER_FALLBACK_STATE = 0;       // value to publish while the sensor is untrusted (0 => assume full)
constexpr uint8_t WIFI_RESET_PIN = 0;
constexpr uint32_t WIFI_RESET_HOLD_MS = 3000;

// Threshold defaults (used until overwritten by API fetch)
static float g_tempMinThreshold = 22.0f;
static float g_tempMaxThreshold = 27.0f;
static bool  g_tempThresholdEnabled = true;
static float g_humMinThreshold = 80.0f;
static float g_humMaxThreshold = 83.0f;
static bool  g_humThresholdEnabled = true;

static const char *const CONTROLLER_THRESHOLD_URL = "https://api.milloserver.uk/api/controller-thresholds";
static const int TEMP_SENSOR_ARRANGEMENT = 2;
static const int HUM_SENSOR_ARRANGEMENT = 0;
static unsigned long g_lastThresholdFetch = 0;

// Provisioning / registration flow
static const char *const PROVISION_AP_SSID = "Millometer-Setup";
static const char *const PROVISION_AP_PASS = "setup1234";    // change before shipping
static const unsigned long WIFI_CONNECT_TIMEOUT_MS = 20000;
static const unsigned long WIFI_FAST_RETRY_INTERVAL_MS = 30000;
static const unsigned long WIFI_FAST_RETRY_WINDOW_MS = 5UL * 60UL * 1000UL;
static const unsigned long WIFI_SLOW_RETRY_INTERVAL_MS = 5UL * 60UL * 1000UL;
static const unsigned long REGISTRATION_RETRY_MS = 60000;
static const char *const REGISTRATION_URL = "https://api.milloserver.uk/api/controller/register-user"; // update to your endpoint

WiFiClientSecure tlsClient;
PubSubClient mqtt(tlsClient);
Preferences g_prefs;
WebServer server(80);

unsigned long g_lastPubMs = 0;
char topicBuf[96];
char payload[64];
static String g_controllerId;
static String g_controllerIdCompact;

struct AppConfig {
  String ssid;
  String password;
  String email;
  String controllerName;
  String factoryName;
  bool registered;
};

static AppConfig g_cfg;
static bool g_isProvisioning = false;
static bool g_httpServerStarted = false;
static unsigned long g_lastWiFiReconnectMs = 0;
static unsigned long g_wifiDisconnectedSince = 0;
static int g_wifiFailCount = 0;
static unsigned long g_nextRegistrationAttemptMs = 0;
static int g_registrationAttempts = 0;

// Track last water indicator state to reduce serial spam
bool g_lastWaterOutputOn = false;
int g_lastWaterRaw = WATER_FALLBACK_STATE;
int g_waterPendingRaw = WATER_FALLBACK_STATE;
unsigned long g_waterPendingSince = 0;
bool g_waterValid = false;

// DHT recovery tracking
static bool g_dhtInitialized = false;
static unsigned long g_lastDhtInitTime = 0;
static int g_consecutiveDhtFailures = 0;
static const int DHT_MAX_FAILURES_BEFORE_REINIT = 3;
static const int DHT_MAX_FAILURES_BEFORE_REBOOT = 10;  // ~100 seconds = ~1.7 min
static const unsigned long DHT_REINIT_DELAY_MS = 5000;

// Buzzer alert tracking
static unsigned long g_lastDhtFailureBeepMs = 0;
static const unsigned long DHT_FAILURE_BEEP_INTERVAL_MS = 30000;  // Beep every 30 seconds
static bool g_lastDhtReadSuccess = true;

// Relay hysteresis/default-on behaviour
bool g_relay1On = false;
bool g_relay2On = false;
bool g_relay4On = true;
bool g_relay5On = true;

// Forward declarations
static void setupHttpRoutes();
static void ensureHttpServerStarted();
static void enterProvisioningMode(const char *reason);
static bool connectWiFiWithTimeout(uint32_t timeoutMs);
static void ensureWiFiConnected();
static bool sendRegistrationRequest();
static void handleRegistration();
static String deriveControllerId();

static bool loadConfig();
static bool saveConfig(const String &ssid, const String &password, const String &email, const String &controllerName, const String &factoryName);
static void persistRegisteredFlag(bool value);
static void clearConfig();
static void pollWifiResetButton();
static void wipeWifiCredentials();

// HTML templates for the tiny setup UI
static const char PROVISION_PAGE[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Millometer Setup</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 2rem; }
    form { max-width: 420px; }
    label { display: block; margin-top: 1rem; font-weight: bold; }
    input { width: 100%; padding: 0.5rem; margin-top: 0.25rem; }
    button { margin-top: 1.5rem; padding: 0.6rem 1.2rem; font-size: 1rem; }
    .note { margin-top: 1.5rem; color: #555; font-size: 0.9rem; }
  </style>
</head>
<body>
  <h2>Millometer Controller Setup</h2>
  <p>Connect to hotspot <strong>{APSSID}</strong>, then enter your Wi-Fi, controller, and factory details.</p>
  <form method="post" action="/save">
    <label for="ssid">Home Wi-Fi Name (SSID)</label>
    <input id="ssid" name="ssid" required>

    <label for="password">Home Wi-Fi Password</label>
    <input id="password" name="password" type="password" required>

    <label for="controller_name">Preferred Controller Name</label>
    <input id="controller_name" name="controller_name" required>

    <label for="factory_name">Factory Name</label>
    <input id="factory_name" name="factory_name" required>

    <label for="email">Owner Email</label>
    <input id="email" name="email" type="email" required>

    <button type="submit">Save &amp; Restart</button>
  </form>
  <p class="note">Controller ID (MAC): <strong>{CONTROLLER_ID}</strong>. After restart the controller joins your Wi-Fi and notifies the cloud.</p>
</body>
</html>
)rawliteral";

// ---------- Utility helpers ----------
inline void relayWrite(uint8_t pin, bool on) {
  digitalWrite(pin, on ? HIGH : LOW);
}

static String deriveControllerId() {
  String mac = WiFi.macAddress();
  if (mac.length() == 17) {
    mac.toUpperCase();
    return mac;
  }

  uint64_t raw = ESP.getEfuseMac();
  char buf[18];
  snprintf(buf, sizeof(buf), "%02X:%02X:%02X:%02X:%02X:%02X",
           (uint8_t)(raw >> 40),
           (uint8_t)(raw >> 32),
           (uint8_t)(raw >> 24),
           (uint8_t)(raw >> 16),
           (uint8_t)(raw >> 8),
           (uint8_t)raw);
  return String(buf);
}

static bool loadConfig() {
  if (!g_prefs.begin("millo", true)) {
    Serial.println("Preferences begin failed (read)");
    return false;
  }
  g_cfg.ssid       = g_prefs.getString("ssid", "");
  g_cfg.password   = g_prefs.getString("pass", "");
  g_cfg.email      = g_prefs.getString("email", "");
  g_cfg.controllerName = g_prefs.getString("ctrl_name", "");
  g_cfg.factoryName = g_prefs.getString("factory", "");
  g_cfg.registered = g_prefs.getBool("reg", false);
  g_prefs.end();
  return !g_cfg.ssid.isEmpty() && !g_cfg.password.isEmpty();
}

static bool saveConfig(const String &ssid, const String &password, const String &email, const String &controllerName, const String &factoryName) {
  if (!g_prefs.begin("millo", false)) {
    Serial.println("Preferences begin failed (write)");
    return false;
  }
  size_t wrote = 0;
  wrote += g_prefs.putString("ssid", ssid);
  wrote += g_prefs.putString("pass", password);
  wrote += g_prefs.putString("email", email);
  wrote += g_prefs.putString("ctrl_name", controllerName);
  wrote += g_prefs.putString("factory", factoryName);
  g_prefs.putBool("reg", false);
  g_prefs.end();

  g_cfg.ssid = ssid;
  g_cfg.password = password;
  g_cfg.email = email;
  g_cfg.controllerName = controllerName;
  g_cfg.factoryName = factoryName;
  g_cfg.registered = false;
  g_registrationAttempts = 0;
  g_nextRegistrationAttemptMs = 0;
  return wrote > 0;
}

static void persistRegisteredFlag(bool value) {
  if (!g_prefs.begin("millo", false)) {
    Serial.println("Preferences begin failed (flag)");
    return;
  }
  g_prefs.putBool("reg", value);
  g_prefs.end();
  g_cfg.registered = value;
}

static void clearConfig() {
  if (g_prefs.begin("millo", false)) {
    g_prefs.clear();
    g_prefs.end();
  }
  g_cfg = AppConfig{};
}

static void wipeWifiCredentials() {
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(true, true);
  clearConfig();
  delay(100);
  Serial.println("Wi-Fi credentials cleared. Restarting...");
  ESP.restart();
}

// ---------- Buzzer Functions ----------
static void buzzerBeep(int durationMs) {
  digitalWrite(BUZZER_PIN, HIGH);
  delay(durationMs);
  digitalWrite(BUZZER_PIN, LOW);
}

static void buzzerShortBeep() {
  buzzerBeep(150);  // 150ms short beep
}

static void buzzerErrorPattern() {
  // 3 quick beeps for DHT failure alert
  for (int i = 0; i < 3; i++) {
    buzzerBeep(100);
    delay(150);
  }
  Serial.println("🔔 Buzzer: DHT failure alert (3 beeps)");
}

static void buzzerCriticalAlert() {
  // Long continuous beep before critical reboot
  Serial.println("🚨 Buzzer: CRITICAL - System rebooting!");
  digitalWrite(BUZZER_PIN, HIGH);
  delay(3000);  // 3 second continuous beep
  digitalWrite(BUZZER_PIN, LOW);
}

static void buzzerSuccessBeep() {
  // Single short beep on recovery
  buzzerShortBeep();
  Serial.println("✅ Buzzer: DHT recovery success");
}

static void buzzerWaterEmptyAlert() {
  // 2 short beeps for water empty
  buzzerBeep(200);
  delay(300);
  buzzerBeep(200);
  Serial.println("💧 Buzzer: Water tank empty!");
}

static void pollWifiResetButton() {
  static uint32_t pressStart = 0;
  static bool notified = false;

  const bool pressed = (digitalRead(WIFI_RESET_PIN) == LOW);
  if (pressed) {
    if (pressStart == 0) {
      pressStart = millis();
      Serial.println("Hold BOOT for 3s to erase Wi-Fi (release to cancel)");
    } else if (!notified && (millis() - pressStart) >= WIFI_RESET_HOLD_MS) {
      notified = true;
      Serial.println("Erasing stored Wi-Fi...");
      wipeWifiCredentials();
    }
  } else if (pressStart != 0) {
    if (!notified) {
      Serial.println("Wi-Fi erase aborted");
    }
    pressStart = 0;
    notified = false;
  }
}

// ---------- HTTP handlers ----------
static void handleRoot() {
  if (g_isProvisioning) {
    String page = FPSTR(PROVISION_PAGE);
    page.replace("{APSSID}", PROVISION_AP_SSID);
    page.replace("{CONTROLLER_ID}", g_controllerId);
    server.send(200, "text/html", page);
    return;
  }

  String html;
  html.reserve(1024);
  html += F("<!DOCTYPE html><html><head><meta charset='utf-8'><title>Millometer Status</title><style>body{font-family:Arial;margin:2rem;max-width:640px;}section{margin-bottom:1.5rem;}table{border-collapse:collapse;}td{padding:0.25rem 0.75rem;border-bottom:1px solid #ccc;}</style></head><body>");
  html += F("<h2>Millometer Controller</h2><section><table>");
  html += F("<tr><td>Wi-Fi SSID</td><td>");
  html += g_cfg.ssid.isEmpty() ? F("(not set)") : g_cfg.ssid;
  html += F("</td></tr><tr><td>Owner Email</td><td>");
  html += g_cfg.email.isEmpty() ? F("(not set)") : g_cfg.email;
  html += F("</td></tr><tr><td>Controller Name</td><td>");
  html += g_cfg.controllerName.isEmpty() ? F("(not set)") : g_cfg.controllerName;
  html += F("</td></tr><tr><td>Factory Name</td><td>");
  html += g_cfg.factoryName.isEmpty() ? F("(not set)") : g_cfg.factoryName;
  html += F("</td></tr><tr><td>Controller ID</td><td>");
  html += g_controllerId;
  html += F("</td></tr><tr><td>Registered</td><td>");
  html += g_cfg.registered ? F("yes") : F("no");
  html += F("</td></tr><tr><td>Current IP</td><td>");
  html += (WiFi.status() == WL_CONNECTED) ? WiFi.localIP().toString() : F("(offline)");
  html += F("</td></tr></table></section><section><form method='post' action='/save'><h3>Update Wi-Fi &amp; Details</h3><label>Wi-Fi SSID<input name='ssid' required value='");
  html += g_cfg.ssid;
  html += F("'></label><label>Wi-Fi Password<input name='password' type='password' required value='");
  html += g_cfg.password;
  html += F("'></label><label>Email<input name='email' type='email' required value='");
  html += g_cfg.email;
  html += F("'></label><label>Controller Name<input name='controller_name' required value='");
  html += g_cfg.controllerName;
  html += F("'></label><label>Factory Name<input name='factory_name' required value='");
  html += g_cfg.factoryName;
  html += F("'></label><p style='margin-top:1rem;color:#555;font-size:0.9rem;'>Controller ID (MAC): ");
  html += g_controllerId;
  html += F("</p><button type='submit'>Save &amp; Restart</button></form></section><section><form method='post' action='/factory_reset' onsubmit='return confirm(\"Reset all saved credentials?\");'><button type='submit'>Factory Reset</button></form></section></body></html>");

  server.send(200, "text/html", html);
}

static void handleSave() {
  String ssid = server.arg("ssid");
  String password = server.arg("password");
  String email = server.arg("email");
  String controllerName = server.arg("controller_name");
  String factoryName = server.arg("factory_name");

  if (ssid.isEmpty() || password.isEmpty() || email.isEmpty() || controllerName.isEmpty() || factoryName.isEmpty()) {
    server.send(400, "text/plain", "Missing ssid/password/email/controller/factory");
    return;
  }

  if (!saveConfig(ssid, password, email, controllerName, factoryName)) {
    server.send(500, "text/plain", "Failed to persist credentials");
    return;
  }

  server.send(200, "text/html", "<html><body><h3>Saved! Rebooting...</h3></body></html>");
  delay(750);
  ESP.restart();
}

static void handleConfigGet() {
  String json;
  json.reserve(256);
  json += F("{");
  json += F("\"ssid\":\"");
  json += g_cfg.ssid;
  json += F("\",\"email\":\"");
  json += g_cfg.email;
  json += F("\",\"controller_name\":\"");
  json += g_cfg.controllerName;
  json += F("\",\"factory_name\":\"");
  json += g_cfg.factoryName;
  json += F("\",\"controller_id\":\"");
  json += g_controllerId;
  json += F("\",\"registered\":");
  json += g_cfg.registered ? F("true") : F("false");
  json += F(",\"wifi_status\":\"");
  json += (WiFi.status() == WL_CONNECTED) ? F("connected") : F("disconnected");
  json += F("\"}");
  server.send(200, "application/json", json);
}

static void handleFactoryReset() {
  clearConfig();
  server.send(200, "text/html", "<html><body><h3>Factory data cleared. Rebooting...</h3></body></html>");
  delay(750);
  ESP.restart();
}

static void handleNotFound() {
  server.send(404, "text/plain", "Not found");
}

static void setupHttpRoutes() {
  server.on("/", HTTP_GET, handleRoot);
  server.on("/save", HTTP_POST, handleSave);
  server.on("/config", HTTP_GET, handleConfigGet);
  server.on("/factory_reset", HTTP_POST, handleFactoryReset);
  server.onNotFound(handleNotFound);
  server.enableCORS(true);
}

static void ensureHttpServerStarted() {
  if (!g_httpServerStarted) {
    server.begin();
    g_httpServerStarted = true;
    Serial.println("HTTP server started on port 80");
  }
}

static void enterProvisioningMode(const char *reason) {
  if (g_isProvisioning) {
    return;
  }
  g_isProvisioning = true;
  g_wifiFailCount = 0;
  Serial.printf("Entering provisioning mode: %s\n", reason);
  WiFi.disconnect(true, true);
  WiFi.mode(WIFI_AP);
  if (WiFi.softAP(PROVISION_AP_SSID, PROVISION_AP_PASS)) {
    Serial.printf("Provisioning AP ready. SSID=%s IP=%s\n", PROVISION_AP_SSID, WiFi.softAPIP().toString().c_str());
  } else {
    Serial.println("Failed to start provisioning AP");
  }
  ensureHttpServerStarted();
}

static bool connectWiFiWithTimeout(uint32_t timeoutMs) {
  if (g_cfg.ssid.isEmpty() || g_cfg.password.isEmpty()) {
    return false;
  }

  g_isProvisioning = false;
  WiFi.mode(WIFI_STA);
  WiFi.begin(g_cfg.ssid.c_str(), g_cfg.password.c_str());
  Serial.printf("Connecting Wi-Fi SSID '%s'...\n", g_cfg.ssid.c_str());

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && (millis() - start) < timeoutMs) {
    delay(400);
    Serial.print('.');
  }
  Serial.println();

  g_lastWiFiReconnectMs = millis();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("Wi-Fi connected. IP: %s\n", WiFi.localIP().toString().c_str());
    g_wifiFailCount = 0;
    g_wifiDisconnectedSince = 0;
    return true;
  }

  Serial.println("Wi-Fi connect timed out");
  if (g_wifiDisconnectedSince == 0) {
    g_wifiDisconnectedSince = g_lastWiFiReconnectMs;
  }
  g_wifiFailCount++;
  return false;
}

static void ensureWiFiConnected() {
  if (g_isProvisioning || g_cfg.ssid.isEmpty()) {
    return;
  }
  if (WiFi.status() == WL_CONNECTED) {
    g_wifiDisconnectedSince = 0;
    return;
  }

  unsigned long now = millis();
  if (g_wifiDisconnectedSince == 0) {
    g_wifiDisconnectedSince = now;
  }

  unsigned long offlineMs = now - g_wifiDisconnectedSince;
  unsigned long interval = (offlineMs < WIFI_FAST_RETRY_WINDOW_MS)
                             ? WIFI_FAST_RETRY_INTERVAL_MS
                             : WIFI_SLOW_RETRY_INTERVAL_MS;

  if (g_lastWiFiReconnectMs != 0 && (now - g_lastWiFiReconnectMs) < interval) {
    return;
  }

  Serial.printf("Wi-Fi disconnected (offline %lus); attempting reconnect\n", offlineMs / 1000UL);
  connectWiFiWithTimeout(8000);
}

static bool sendRegistrationRequest() {
  if (g_cfg.email.isEmpty()) {
    Serial.println("Registration skipped (email empty)");
    return false;
  }

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  http.setTimeout(6000);
  if (!http.begin(client, REGISTRATION_URL)) {
    Serial.println("HTTP begin failed for registration");
    return false;
  }

  http.addHeader("Content-Type", "application/json");
  String payload = "{";
  payload += "\"controller_id\":\"" + g_controllerId + "\"";
  payload += ",\"email\":\"" + g_cfg.email + "\"";
  payload += ",\"controller_name\":\"" + g_cfg.controllerName + "\"";
  payload += ",\"factory_name\":\"" + g_cfg.factoryName + "\"";
  payload += "}";
  Serial.println("Sending registration payload: " + payload);
  int code = http.POST(payload);

  if (code <= 0) {
    Serial.printf("Registration HTTP error: %s\n", http.errorToString(code).c_str());
    http.end();
    return false;
  }

  Serial.printf("Registration HTTP status: %d\n", code);
  if (code >= 200 && code < 300) {
    http.end();
    return true;
  }

  Serial.println("Registration server returned non-success status");
  http.end();
  return false;
}

static void handleRegistration() {
  if (g_isProvisioning || g_cfg.registered || g_cfg.email.isEmpty()) {
    return;
  }
  if (g_cfg.controllerName.isEmpty() || g_cfg.factoryName.isEmpty()) {
    return;
  }
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  unsigned long now = millis();
  if (now < g_nextRegistrationAttemptMs) {
    return;
  }

  if (sendRegistrationRequest()) {
    Serial.println("Registration request succeeded");
    persistRegisteredFlag(true);
  } else {
    g_registrationAttempts++;
    g_nextRegistrationAttemptMs = now + REGISTRATION_RETRY_MS;
    Serial.printf("Registration failed (attempt %d). Will retry in %lus\n", g_registrationAttempts, REGISTRATION_RETRY_MS / 1000);
  }
}

// ---------- Wi-Fi / MQTT ----------
static void connectMQTT() {
  if (g_isProvisioning || WiFi.status() != WL_CONNECTED) {
    return;
  }
  if (mqtt.connected()) {
    return;
  }

  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  tlsClient.setInsecure();
  Serial.printf("Connecting MQTT %s:%d\n", MQTT_HOST, MQTT_PORT);

  const unsigned long deadline = millis() + 5000;
  while (!mqtt.connected() && millis() < deadline) {
    String cid = "esp32-" + g_controllerIdCompact;
    if (mqtt.connect(cid.c_str(), MQTT_USER, MQTT_PASS)) {
      Serial.println("MQTT connected");
      break;
    }
    Serial.printf("MQTT failed rc=%d; retrying...\n", mqtt.state());
    delay(500);
  }
}

// returns true on success
static bool readTempHum(int &tC, int &hPct) {
#if USE_DHT
  // DHT22 requires minimum 2 seconds between reads
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  
  // Retry up to 3 times with proper 2.5 second delays
  for (int i = 0; i < 3 && (isnan(h) || isnan(t)); i++) {
    delay(2500);  // DHT22 needs >2 seconds between reads
    h = dht.readHumidity();
    t = dht.readTemperature();
  }
  
  if (isnan(h) || isnan(t)) {
    tC = 0;
    hPct = 0;
    g_consecutiveDhtFailures++;
    Serial.printf("DHT read failed (attempt %d/%d before reboot)\n", 
                  g_consecutiveDhtFailures, DHT_MAX_FAILURES_BEFORE_REBOOT);
    
    // Periodic beep alert for DHT failures (every 30 seconds)
    unsigned long now = millis();
    if (g_consecutiveDhtFailures >= 3 && (now - g_lastDhtFailureBeepMs) >= DHT_FAILURE_BEEP_INTERVAL_MS) {
      buzzerErrorPattern();
      g_lastDhtFailureBeepMs = now;
    }
    
    // Re-initialize DHT if too many consecutive failures
    if (g_consecutiveDhtFailures >= DHT_MAX_FAILURES_BEFORE_REINIT && 
        g_consecutiveDhtFailures < DHT_MAX_FAILURES_BEFORE_REBOOT) {
      if (now - g_lastDhtInitTime >= DHT_REINIT_DELAY_MS) {
        Serial.println("Re-initializing DHT22 sensor...");
        dht.begin();
        g_lastDhtInitTime = now;
        delay(3000);  // Give DHT time to stabilize after re-init
      }
    }
    
    // CRITICAL: Auto-reboot if failures exceed threshold
    if (g_consecutiveDhtFailures >= DHT_MAX_FAILURES_BEFORE_REBOOT) {
      Serial.println("❌ CRITICAL: DHT22 failed 10 times. Initiating automatic reboot...");
      buzzerCriticalAlert();
      delay(500);
      ESP.restart();
    }
    
    g_lastDhtReadSuccess = false;
    return false;
  }
  
  // Success - reset failure counter and beep if recovering from failure
  if (!g_lastDhtReadSuccess && g_consecutiveDhtFailures > 0) {
    buzzerSuccessBeep();
  }
  g_consecutiveDhtFailures = 0;
  g_lastDhtReadSuccess = true;
  tC = static_cast<int>(t + 0.5f);
  hPct = static_cast<int>(h + 0.5f);
  return true;
#else
  tC = 0;
  hPct = 0;
  return false;
#endif
}

static void applyThresholdEntry(const JsonObjectConst &entry) {
  if (!entry.containsKey("arrangement")) {
    return;
  }

  const int arrangement = entry["arrangement"].as<int>();
  const bool enabled = entry["is_enabled"] | false;
  const bool hasMin = !entry["min_threshold"].isNull();
  const bool hasMax = !entry["max_threshold"].isNull();

  const float sensorMin = entry["sensor_min"].isNull() ? 0.0f : entry["sensor_min"].as<float>();
  const float sensorMax = entry["sensor_max"].isNull() ? 0.0f : entry["sensor_max"].as<float>();

  float useMin = sensorMin;
  float useMax = sensorMax;
  if (enabled && hasMin && hasMax) {
    useMin = entry["min_threshold"].as<float>();
    useMax = entry["max_threshold"].as<float>();
  }

  if (arrangement == TEMP_SENSOR_ARRANGEMENT) {
    g_tempMinThreshold = useMin;
    g_tempMaxThreshold = useMax;
    g_tempThresholdEnabled = enabled && hasMin && hasMax;
  } else if (arrangement == HUM_SENSOR_ARRANGEMENT) {
    g_humMinThreshold = useMin;
    g_humMaxThreshold = useMax;
    g_humThresholdEnabled = enabled && hasMin && hasMax;
  }
}

static String urlEncode(const String &value) {
  String encoded;
  char hex[4];
  for (size_t i = 0; i < value.length(); ++i) {
    const unsigned char c = static_cast<unsigned char>(value[i]);
    if (isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') {
      encoded += static_cast<char>(c);
    } else {
      snprintf(hex, sizeof(hex), "%%%02X", c);
      encoded += hex;
    }
  }
  return encoded;
}

static bool fetchControllerThresholds() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Threshold fetch skipped (Wi-Fi disconnected)");
    return false;
  }

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  http.setTimeout(6000);

  String url = String(CONTROLLER_THRESHOLD_URL) + "?controller_id=" + urlEncode(g_controllerIdCompact);
  if (!http.begin(client, url)) {
    Serial.println("Threshold HTTP begin failed");
    return false;
  }

  const int code = http.GET();
  if (code != 200) {
    Serial.printf("Threshold HTTP status %d (%s)\n", code, http.errorToString(code).c_str());
    http.end();
    return false;
  }

  String body = http.getString();
  http.end();
  Serial.printf("Threshold payload (%d bytes): %s\n", body.length(), body.c_str());

  DynamicJsonDocument doc(4096);
  DeserializationError err = deserializeJson(doc, body);

  if (err) {
    Serial.printf("Threshold JSON parse error: %s\n", err.c_str());
    return false;
  }

  if (!doc.containsKey("data")) {
    Serial.println("Threshold response missing data array");
    return false;
  }

  JsonArrayConst arr = doc["data"].as<JsonArrayConst>();
  for (JsonObjectConst entry : arr) {
    applyThresholdEntry(entry);
  }

  g_lastThresholdFetch = millis();
  Serial.printf("Thresholds updated -> Temp %.2f-%.2f (%s), Hum %.2f-%.2f (%s)\n",
                g_tempMinThreshold, g_tempMaxThreshold,
                g_tempThresholdEnabled ? "enabled" : "fallback",
                g_humMinThreshold, g_humMaxThreshold,
                g_humThresholdEnabled ? "enabled" : "fallback");
  return true;
}

// Turn relays based on thresholds (active-HIGH relays)
static void handleRelays(int tC, int hPct) {
  const bool tempHigh = static_cast<float>(tC) > g_tempMaxThreshold;
  const bool tempLow = static_cast<float>(tC) < g_tempMinThreshold;
  const bool humHigh = static_cast<float>(hPct) > g_humMaxThreshold;
  const bool humLow = static_cast<float>(hPct) < g_humMinThreshold;

  bool anyChange = false;

  bool desiredRelay1;
  bool desiredRelay5;

  if (tempLow) {
    desiredRelay1 = false;
    desiredRelay5 = false;
  } else if (tempHigh) {
    desiredRelay1 = true;
    desiredRelay5 = true;
  } else {
    desiredRelay1 = false;
    desiredRelay5 = true;
  }

  if (desiredRelay1 != g_relay1On) {
    relayWrite(RELAY1_PIN, desiredRelay1);
    Serial.printf("Relay1 (Temp NC) -> %s (T=%dC)\n", desiredRelay1 ? "ON" : "OFF", tC);
    g_relay1On = desiredRelay1;
    anyChange = true;
  }

  if (desiredRelay5 != g_relay5On) {
    relayWrite(RELAY5_PIN, desiredRelay5);
    Serial.printf("Relay5 (Temp default ON) -> %s (T=%dC)\n", desiredRelay5 ? "ON" : "OFF", tC);
    g_relay5On = desiredRelay5;
    anyChange = true;
  }

  bool desiredRelay2 = humLow;
  if (desiredRelay2 != g_relay2On) {
    relayWrite(RELAY2_PIN, desiredRelay2);
    Serial.printf("Relay2 (Hum NC) -> %s (H=%d%%)\n", desiredRelay2 ? "ON" : "OFF", hPct);
    g_relay2On = desiredRelay2;
    anyChange = true;
  }

  bool desiredRelay4 = !humHigh;
  if (desiredRelay4 != g_relay4On) {
    relayWrite(RELAY4_PIN, desiredRelay4);
    Serial.printf("Relay4 (Hum default ON) -> %s (H=%d%%)\n", desiredRelay4 ? "ON" : "OFF", hPct);
    g_relay4On = desiredRelay4;
    anyChange = true;
  }

  if (!anyChange) {
    Serial.println("Relays -> no change");
  }
}

// Handle water level float switch: track validity + drive water output
static void handleWaterLevel() {
  static bool lastLoggedValid = false;

  int raw = digitalRead(WATER_PIN);
  unsigned long now = millis();

  if (raw != g_waterPendingRaw) {
    g_waterPendingRaw = raw;
    g_waterPendingSince = now;

    if (raw != g_lastWaterRaw) {
      if (g_waterValid) {
        Serial.printf("Water sensor change detected (raw=%d) -> debouncing\n", raw);
      }
      g_waterValid = false;
    }
  }

  bool stable = (now - g_waterPendingSince) >= WATER_DEBOUNCE_MS;

  if (!g_waterValid && stable) {
    g_lastWaterRaw = g_waterPendingRaw;
    g_waterValid = true;
    Serial.printf("Water sensor stable -> raw=%d\n", g_lastWaterRaw);
  }

  const bool waterFull = g_waterValid && (g_lastWaterRaw == LOW);
  const bool waterEmpty = g_waterValid && !waterFull;

  bool shouldLog = (waterEmpty != g_lastWaterOutputOn) || (g_waterValid != lastLoggedValid);
  if (shouldLog) {
    const char *state = g_waterValid ? (waterFull ? "full" : "EMPTY") : "unknown";
    Serial.printf("Water sensor raw=%d, valid=%s (%s)\n",
                  g_lastWaterRaw,
                  g_waterValid ? "true" : "false",
                  state);
    
    // Trigger buzzer alert when water becomes empty
    if (waterEmpty && !g_lastWaterOutputOn) {
      buzzerWaterEmptyAlert();
    }
    
    g_lastWaterOutputOn = waterEmpty;
    lastLoggedValid = g_waterValid;
  }
}

// Publish your array [humidity, temperature, water]
static void publishArray(int t, int h, int water) {
  // Use REAL sensor data, not random values
  snprintf(payload, sizeof(payload), "[%d,%d,%d]", h, t, water);
  bool ok = mqtt.publish(topicBuf, payload, true);
  Serial.printf("Pub %s : %s -> %s\n", topicBuf, payload, ok ? "OK" : "FAIL");
}

void setup() {
  Serial.begin(115200);
  delay(50);

  pinMode(WIFI_RESET_PIN, INPUT_PULLUP);
  Serial.println(F("Hold BOOT for 3s to clear Wi-Fi credentials"));
  g_controllerId = deriveControllerId();
  g_controllerIdCompact = g_controllerId;
  g_controllerIdCompact.replace(":", "");
  Serial.printf("Controller ID (MAC): %s\n", g_controllerId.c_str());

  pinMode(LIGHT_PIN, INPUT);
  pinMode(WATER_PIN, INPUT_PULLUP);
  pinMode(RELAY1_PIN, OUTPUT);
  pinMode(RELAY2_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RELAY4_PIN, OUTPUT);
  pinMode(RELAY5_PIN, OUTPUT);

  relayWrite(RELAY1_PIN, g_relay1On);
  relayWrite(RELAY2_PIN, g_relay2On);
  relayWrite(RELAY4_PIN, g_relay4On);
  relayWrite(RELAY5_PIN, g_relay5On);
  digitalWrite(BUZZER_PIN, LOW);  // Buzzer off initially

  g_waterPendingRaw = digitalRead(WATER_PIN);
  g_waterPendingSince = millis();
  g_waterValid = false;
  g_lastWaterOutputOn = false;

#if USE_DHT
  Serial.println("Initializing DHT22 sensor...");
  dht.begin();
  g_lastDhtInitTime = millis();
  delay(3000); // Extended delay for DHT22 stabilization (was 2s, now 3s)
  Serial.println("DHT22 initial stabilization complete");
#endif

  setupHttpRoutes();

  bool haveConfig = loadConfig();
  if (!haveConfig) {
    Serial.println("No stored Wi-Fi credentials. Starting provisioning hotspot.");
    enterProvisioningMode("no stored credentials");
    ensureHttpServerStarted();
    g_dhtInitialized = true;  // Mark as initialized even in provisioning mode
    return;
  }

  if (!connectWiFiWithTimeout(WIFI_CONNECT_TIMEOUT_MS)) {
    Serial.println("Failed to join stored Wi-Fi. Will keep retrying in background.");
  }

  // Additional delay after WiFi connection to ensure stable power
  delay(2000);
  Serial.println("Post-WiFi stabilization complete");
  g_dhtInitialized = true;

  ensureHttpServerStarted();
  connectMQTT();
  snprintf(topicBuf, sizeof(topicBuf), "topic/%s", g_controllerIdCompact.c_str());
  
  // Delay first publish to ensure DHT is fully ready after WiFi power surge
  g_lastPubMs = millis() - (PUBLISH_MS - 5000);  // First publish in 5 seconds
}

void loop() {
  pollWifiResetButton();
  server.handleClient();

  if (g_isProvisioning) {
    return;
  }

  ensureWiFiConnected();
  handleRegistration();
  connectMQTT();

  if (mqtt.connected()) {
    mqtt.loop();
  }

  handleWaterLevel();

  unsigned long now = millis();
  if (now - g_lastPubMs >= PUBLISH_MS) {
    g_lastPubMs = now;

    int t = 0, h = 0;
    bool okRead = false;
    
    // Only read DHT if initialization is complete
    if (g_dhtInitialized) {
      okRead = readTempHum(t, h);
    } else {
      Serial.println("DHT not yet initialized, skipping read");
    }

    if (okRead) {
      Serial.printf("Sensors -> T=%dC, H=%d%%\n", t, h);
    } else {
      Serial.println("Sensors -> read failed (T=0, H=0)");
    }

    if (!fetchControllerThresholds()) {
      Serial.println("Using cached thresholds (latest fetch failed)");
    }

    handleRelays(t, h);

    int water = g_waterValid ? (g_lastWaterRaw == LOW ? 1 : 0) : WATER_FALLBACK_STATE;
    const char *waterSrc = g_waterValid ? "sensor" : "default";
    Serial.printf("Water -> %d (0=full,1=needs water, src=%s)\n", water, waterSrc);
    publishArray(t, h, water);
  }
}