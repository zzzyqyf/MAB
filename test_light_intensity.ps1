# Test script for light intensity numeric values
Write-Host "🧪 Testing Light Intensity Numeric Values..." -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

Write-Host "📤 Publishing Light Intensity: 450 lux..." -ForegroundColor Yellow
Start-Process -FilePath "D:\mosquitto\mosquitto_pub.exe" -ArgumentList "-h", "broker.mqtt.cool", "-t", "devices/ESP32_001/sensors/lights", "-m", "450", "-r" -Wait

Start-Sleep -Seconds 2

Write-Host "📤 Publishing Light Intensity: 750 lux..." -ForegroundColor Yellow
Start-Process -FilePath "D:\mosquitto\mosquitto_pub.exe" -ArgumentList "-h", "broker.mqtt.cool", "-t", "devices/ESP32_001/sensors/lights", "-m", "750", "-r" -Wait

Start-Sleep -Seconds 2

Write-Host "📤 Publishing Light Intensity: 1200 lux..." -ForegroundColor Yellow
Start-Process -FilePath "D:\mosquitto\mosquitto_pub.exe" -ArgumentList "-h", "broker.mqtt.cool", "-t", "devices/ESP32_001/sensors/lights", "-m", "1200", "-r" -Wait

Write-Host ""
Write-Host "✅ Light intensity test completed!" -ForegroundColor Green
Write-Host "📊 Check your Flutter app - Light Intensity should show:" -ForegroundColor Cyan
Write-Host "   💡 Light Intensity: 1200 lux (instead of ON/OFF)" -ForegroundColor White
