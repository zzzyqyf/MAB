# Graph API Real Data Implementation Analysis

## Current Status ✅

Mock data has been **disabled**. The app is now configured to use real API data from `https://api.milloserver.uk`.

## How It Works Now

### 1. API Configuration
- **Endpoint**: `GET /api/millometer/by-controller`
- **Authentication**: Bearer token (email: jasontkh.2016@gmail.com)
- **Parameters**:
  - `controller_id`: 94B97EC04AD4 (your ESP32 MAC address without colons)
  - `from`: Start date in ISO 8601 format
  - `to`: End date in ISO 8601 format
  - `limit`: 1000 (max data points per request)
  - `page`: 1

### 2. Data Flow
```
User selects date → App calls API → API returns data → Parse into separate sensor arrays → Display on graph
```

### 3. Expected API Response Format
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "controller_id": "94B97EC04AD4",
      "temperature": 25.5,
      "humidity": 81.0,
      "water_level": 50.0,
      "timestamp": "2025-11-25T12:00:00.000Z",
      "created_at": "2025-11-25T12:00:00.000Z",
      "updated_at": "2025-11-25T12:00:00.000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 24
  }
}
```

### 4. Data Parsing
The `GraphDataModel.fromJson()` method now:
- Reads the `data` array from API response
- Extracts each sensor value (temperature, humidity, water_level) from each data point
- Creates separate arrays for each sensor type
- Converts to `SensorGraphData` domain entity with `DataPoint` objects

## Why No Real Data Yet ❌

The API database is **empty** because:

1. **ESP32 only sends to MQTT**: Your ESP32 device currently publishes sensor data to MQTT topics only:
   - `topic/94B97EC04AD4` → Real-time data for the dashboard

2. **No API upload**: ESP32 does **NOT** upload historical data to the API server database

3. **Two separate systems**:
   - **MQTT** = Real-time data (working ✅)
   - **API database** = Historical data for graphs (empty ❌)

## Solution: Configure ESP32 to Upload Data

### Option 1: Direct HTTP POST (Recommended)
Modify ESP32 code to periodically POST sensor readings to the API:

```cpp
// Add to your ESP32 code (Arduino C++)
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char* apiUrl = "https://api.milloserver.uk/api/millometer";
const char* apiEmail = "jasontkh.2016@gmail.com";
const char* apiPassword = "1234abcd";
String bearerToken = "";

// Login to get bearer token (call once at startup)
void apiLogin() {
  HTTPClient http;
  http.begin(apiUrl + "/login");
  http.addHeader("Content-Type", "application/json");
  
  StaticJsonDocument<200> loginDoc;
  loginDoc["email"] = apiEmail;
  loginDoc["password"] = apiPassword;
  
  String loginBody;
  serializeJson(loginDoc, loginBody);
  
  int httpCode = http.POST(loginBody);
  if (httpCode == 200) {
    DynamicJsonDocument responseDoc(1024);
    deserializeJson(responseDoc, http.getString());
    bearerToken = responseDoc["token"].as<String>();
    Serial.println("✅ API login successful");
  }
  http.end();
}

// Upload sensor data (call every 5 minutes)
void uploadSensorData(float temp, float humidity, float waterLevel) {
  if (bearerToken == "") {
    apiLogin(); // Get token if not available
  }
  
  HTTPClient http;
  http.begin(apiUrl);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", "Bearer " + bearerToken);
  
  StaticJsonDocument<300> doc;
  doc["controller_id"] = "94B97EC04AD4";
  doc["temperature"] = temp;
  doc["humidity"] = humidity;
  doc["water_level"] = waterLevel;
  doc["timestamp"] = millis(); // Or use NTP time
  
  String requestBody;
  serializeJson(doc, requestBody);
  
  int httpCode = http.POST(requestBody);
  if (httpCode == 200 || httpCode == 201) {
    Serial.println("✅ Data uploaded to API");
  } else if (httpCode == 401) {
    bearerToken = ""; // Token expired, will re-login next time
  }
  http.end();
}

// In your main loop, upload every 5 minutes
unsigned long lastUpload = 0;
const unsigned long uploadInterval = 300000; // 5 minutes

void loop() {
  // ... existing sensor reading code ...
  
  if (millis() - lastUpload >= uploadInterval) {
    uploadSensorData(temperature, humidity, moisturePercent);
    lastUpload = millis();
  }
}
```

### Option 2: Server-Side Bridge
Create a Node.js/Python service that:
1. Subscribes to MQTT topics
2. Receives sensor data
3. Uploads to API database

### Option 3: Cloud Function
Use Firebase Cloud Functions to:
1. Listen to Firestore writes
2. Forward data to API server

## Testing Without ESP32 Changes

If you want to test the graph functionality immediately without modifying ESP32:

1. **Re-enable mock data**:
   ```dart
   // In graph_api_remote_datasource.dart line 21
   static const bool _useMockData = true;
   ```

2. **Or manually insert test data** using API endpoint (if available)

3. **Or use mosquitto_pub** with a bridge service

## Files Modified

1. **lib/features/graph_api/data/datasources/graph_api_remote_datasource.dart**
   - Line 21: `_useMockData = false` (disabled mock mode)
   - Lines 96-100: Mock data generation (ready to re-enable if needed)
   - Lines 133-139: Enhanced debug logging for API responses

2. **lib/features/graph_api/data/models/graph_data_model.dart**
   - Lines 13-57: Updated `fromJson()` to parse actual API format
   - Each data point contains all three sensor values
   - Extracts into separate arrays for each sensor type

## Next Steps

1. **Immediate**: Wait for ESP32 to be configured to upload data
2. **Short-term**: Test with 24+ hours of uploaded data
3. **Long-term**: Consider data retention policies (how long to keep historical data)

## Monitoring

Check terminal logs when navigating to graph page:
```
📊 Using MOCK DATA for testing (API database is empty)  ← Should NOT appear now
📊 Graph data response status: 200                      ← API responding
📊 Data array length: 0                                  ← Empty database
📊 First data point structure: {...}                    ← Will appear when data exists
📊 Humidity points: 24                                  ← Number of data points found
```

## Contact API Provider

If the API endpoint structure is different than documented, contact the API provider (api.milloserver.uk) to:
1. Confirm the correct POST endpoint for uploading sensor data
2. Verify the expected data format
3. Check if there's existing documentation for data upload
