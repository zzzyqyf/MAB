# PowerShell script to register ESP32_001 device
Write-Host "🔌 Registering ESP32_001 device with MQTT broker..." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

Write-Host "📡 Step 1: Setting device status to online..." -ForegroundColor Yellow
& mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/status" -m "online"

Start-Sleep -Seconds 1

Write-Host "🌡️ Step 2: Publishing temperature data..." -ForegroundColor Yellow
& mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" -m "23.5"

Start-Sleep -Seconds 1

Write-Host "💧 Step 3: Publishing humidity data..." -ForegroundColor Yellow
& mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/humidity" -m "60.2"

Start-Sleep -Seconds 1

Write-Host "💡 Step 4: Publishing light status..." -ForegroundColor Yellow
& mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/lights" -m "0"

Start-Sleep -Seconds 1

Write-Host "🌱 Step 5: Publishing moisture data..." -ForegroundColor Yellow
& mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/moisture" -m "75.8"

Write-Host ""
Write-Host "✅ ESP32_001 device registration completed!" -ForegroundColor Green
Write-Host "📊 Device should now appear as ONLINE in your Flutter app" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔄 Starting continuous status updates (every 30 seconds)..." -ForegroundColor Cyan

# Keep device alive with periodic status updates
for ($i = 1; $i -le 20; $i++) {
    Start-Sleep -Seconds 30
    Write-Host "📡 Sending keep-alive signal ($i/20)..." -ForegroundColor Magenta
    & mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/status" -m "online"
    
    # Occasionally update sensor values to simulate real device
    if ($i % 3 -eq 0) {
        $temp = [math]::Round(23.5 + ($i * 0.3), 1)
        $humidity = [math]::Round(60.2 + ($i * 0.5), 1)
        $moisture = [math]::Round(75.8 - ($i * 0.2), 1)
        
        & mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/temperature" -m "$temp"
        & mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/humidity" -m "$humidity"
        & mosquitto_pub -h broker.mqtt.cool -t "devices/ESP32_001/sensors/moisture" -m "$moisture"
        
        Write-Host "📊 Updated sensors: Temp=$temp°C, Humidity=$humidity%, Moisture=$moisture%" -ForegroundColor Green
    }
}

Write-Host "🏁 Registration and monitoring completed!" -ForegroundColor Green
