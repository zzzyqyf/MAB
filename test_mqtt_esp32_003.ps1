# MQTT Test Script for ESP32_003
# This script tests the MQTT pub/sub functionality with device-specific topics

Write-Host "=== MQTT Testing for ESP32_003 ===" -ForegroundColor Green

# Test if mosquitto_pub is available
try {
    $mosquittoTest = & mosquitto_pub --help 2>$null
    Write-Host "✅ Mosquitto tools are available" -ForegroundColor Green
    
    Write-Host "`n📡 Publishing test sensor data for ESP32_003..." -ForegroundColor Yellow
    
    # Publish temperature data
    & mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_003/sensors/temperature" -m "24.5"
    Write-Host "  📤 Temperature: 24.5°C" -ForegroundColor Cyan
    
    # Publish humidity data
    & mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_003/sensors/humidity" -m "58.3"
    Write-Host "  📤 Humidity: 58.3%" -ForegroundColor Cyan
    
    # Publish light state
    & mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_003/sensors/lights" -m "1"
    Write-Host "  📤 Light State: ON" -ForegroundColor Cyan
    
    # Publish moisture data
    & mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_003/sensors/moisture" -m "42.7"
    Write-Host "  📤 Moisture: 42.7%" -ForegroundColor Cyan
    
    # Publish device status
    & mosquitto_pub -h broker.mqtt.cool -p 1883 -t "devices/ESP32_003/status" -m "online"
    Write-Host "  📤 Device Status: online" -ForegroundColor Cyan
    
    Write-Host "`n✅ All test messages published successfully!" -ForegroundColor Green
    Write-Host "Check your Flutter app to see if the data appears." -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Mosquitto tools not found. Please install mosquitto:" -ForegroundColor Red
    Write-Host "   1. Install via Chocolatey: choco install mosquitto" -ForegroundColor White
    Write-Host "   2. Or download from: https://mosquitto.org/download/" -ForegroundColor White
    Write-Host "`n📝 Manual test commands:" -ForegroundColor Yellow
    Write-Host "mosquitto_pub -h broker.mqtt.cool -p 1883 -t `"devices/ESP32_003/sensors/temperature`" -m `"24.5`"" -ForegroundColor White
    Write-Host "mosquitto_pub -h broker.mqtt.cool -p 1883 -t `"devices/ESP32_003/sensors/humidity`" -m `"58.3`"" -ForegroundColor White
    Write-Host "mosquitto_pub -h broker.mqtt.cool -p 1883 -t `"devices/ESP32_003/sensors/lights`" -m `"1`"" -ForegroundColor White
    Write-Host "mosquitto_pub -h broker.mqtt.cool -p 1883 -t `"devices/ESP32_003/sensors/moisture`" -m `"42.7`"" -ForegroundColor White
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
