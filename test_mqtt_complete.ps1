# MQTT Testing Commands for ESP32_001

echo "Starting MQTT Testing for ESP32_001..."
echo "======================================"

# Test Temperature
Write-Host "📤 Publishing Temperature: 25.5°C" -ForegroundColor Green
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" -m "25.5"
Start-Sleep -Seconds 2

# Test Humidity
Write-Host "📤 Publishing Humidity: 65.2%" -ForegroundColor Green  
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/humidity" -m "65.2"
Start-Sleep -Seconds 2

# Test Light State
Write-Host "📤 Publishing Light State: ON" -ForegroundColor Green
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/lights" -m "1"
Start-Sleep -Seconds 2

# Test Moisture
Write-Host "📤 Publishing Moisture: 78.3%" -ForegroundColor Green
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/moisture" -m "78.3"
Start-Sleep -Seconds 2

# Test Device Status
Write-Host "📤 Publishing Device Status: online" -ForegroundColor Green
mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/status" -m "online"

Write-Host "✅ All test messages published!" -ForegroundColor Yellow
Write-Host "Check your Flutter app for real-time updates" -ForegroundColor Cyan
