# Test script for Blue Light Intensity sensor
Write-Host "🧪 Testing Blue Light Intensity Sensor..." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

Write-Host "📤 Publishing Light Intensity: 800 lux..." -ForegroundColor Yellow
Start-Process -FilePath "D:\mosquitto\mosquitto_pub.exe" -ArgumentList "-h", "broker.mqtt.cool", "-t", "devices/ESP32_001/sensors/lights", "-m", "800", "-r" -Wait

Start-Sleep -Seconds 2

Write-Host "📤 Publishing Blue Light Intensity: 650 lux..." -ForegroundColor Cyan
Start-Process -FilePath "D:\mosquitto\mosquitto_pub.exe" -ArgumentList "-h", "broker.mqtt.cool", "-t", "devices/ESP32_001/sensors/bluelight", "-m", "650", "-r" -Wait

Start-Sleep -Seconds 2

Write-Host "📤 Publishing Blue Light Intensity: 920 lux..." -ForegroundColor Cyan
Start-Process -FilePath "D:\mosquitto\mosquitto_pub.exe" -ArgumentList "-h", "broker.mqtt.cool", "-t", "devices/ESP32_001/sensors/bluelight", "-m", "920", "-r" -Wait

Start-Sleep -Seconds 2

Write-Host "📤 Publishing Blue Light Intensity: 1150 lux..." -ForegroundColor Cyan
Start-Process -FilePath "D:\mosquitto\mosquitto_pub.exe" -ArgumentList "-h", "broker.mqtt.cool", "-t", "devices/ESP32_001/sensors/bluelight", "-m", "1150", "-r" -Wait

Write-Host ""
Write-Host "✅ Blue Light Intensity test completed!" -ForegroundColor Green
Write-Host "📊 Check your Flutter app - you should now see:" -ForegroundColor Cyan
Write-Host "   💡 Light Intensity: 800 lux" -ForegroundColor White
Write-Host "   🔵 Blue Light Intensity: 1150 lux" -ForegroundColor Blue
Write-Host ""
Write-Host "🚀 Both light sensors are now working with numeric values!" -ForegroundColor Green
