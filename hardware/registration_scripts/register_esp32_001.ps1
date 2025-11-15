# PowerShell script to register ESP32_001 device
Write-Host "🔌 Registering ESP32_001 device with MQTT broker..." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "📡 Broker: api.milloserver.uk:8883 (Secure TLS)" -ForegroundColor Cyan
Write-Host ""

# MQTT broker configuration
$BROKER = "api.milloserver.uk"
$PORT = "8883"
$USERNAME = "zhangyifei"
$PASSWORD = "123456"
$DEVICE_ID = "ESP32_001"

# Base mosquitto command with authentication
$MQTT_CMD = "mosquitto_pub -h $BROKER -p $PORT -u $USERNAME -P $PASSWORD --capath /etc/ssl/certs"

Write-Host "📡 Step 1: Setting device status to online..." -ForegroundColor Yellow
Invoke-Expression "$MQTT_CMD -t 'devices/$DEVICE_ID/status' -m 'online'"

Start-Sleep -Seconds 1

Write-Host "🌡️ Step 2: Publishing temperature data..." -ForegroundColor Yellow
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$payload = "{`"value`": 23.5, `"timestamp`": $timestamp, `"device_id`": `"$DEVICE_ID`"}"
Invoke-Expression "$MQTT_CMD -t 'devices/$DEVICE_ID/sensors/temperature' -m '$payload'"

Start-Sleep -Seconds 1

Write-Host "� Step 3: Publishing humidity data..." -ForegroundColor Yellow
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$payload = "{`"value`": 60.2, `"timestamp`": $timestamp, `"device_id`": `"$DEVICE_ID`"}"
Invoke-Expression "$MQTT_CMD -t 'devices/$DEVICE_ID/sensors/humidity' -m '$payload'"

Start-Sleep -Seconds 1

Write-Host "💦 Step 4: Publishing water level data..." -ForegroundColor Yellow
$timestamp = [int][double]::Parse((Get-Date -UFormat %s))
$payload = "{`"value`": 75.8, `"timestamp`": $timestamp, `"device_id`": `"$DEVICE_ID`"}"
Invoke-Expression "$MQTT_CMD -t 'devices/$DEVICE_ID/sensors/water_level' -m '$payload'"

Write-Host ""
Write-Host "✅ ESP32_001 device registration completed!" -ForegroundColor Green
Write-Host "📊 Device should now appear as ONLINE in your Flutter app" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔄 Starting continuous status updates (every 30 seconds)..." -ForegroundColor Cyan

# Keep device alive with periodic status updates
for ($i = 1; $i -le 20; $i++) {
    Start-Sleep -Seconds 30
    Write-Host "📡 Sending keep-alive signal ($i/20)..." -ForegroundColor Magenta
    Invoke-Expression "$MQTT_CMD -t 'devices/$DEVICE_ID/status' -m 'online'"
    
    # Occasionally update sensor values to simulate real device
    if ($i % 3 -eq 0) {
        $temp = [math]::Round(23.5 + ($i * 0.3), 1)
        $humidity = [math]::Round(60.2 + ($i * 0.5), 1)
        $water = [math]::Round(75.8 - ($i * 0.2), 1)
        $timestamp = [int][double]::Parse((Get-Date -UFormat %s))
        
        $tempPayload = "{`"value`": $temp, `"timestamp`": $timestamp, `"device_id`": `"$DEVICE_ID`"}"
        $humidPayload = "{`"value`": $humidity, `"timestamp`": $timestamp, `"device_id`": `"$DEVICE_ID`"}"
        $waterPayload = "{`"value`": $water, `"timestamp`": $timestamp, `"device_id`": `"$DEVICE_ID`"}"
        
        Invoke-Expression "$MQTT_CMD -t 'devices/$DEVICE_ID/sensors/temperature' -m '$tempPayload'"
        Invoke-Expression "$MQTT_CMD -t 'devices/$DEVICE_ID/sensors/humidity' -m '$humidPayload'"
        Invoke-Expression "$MQTT_CMD -t 'devices/$DEVICE_ID/sensors/water_level' -m '$waterPayload'"
        
        Write-Host "📊 Updated sensors: Temp=$temp°C, Humidity=$humidity%, Water=$water%" -ForegroundColor Green
    }
}

Write-Host "🏁 Registration and monitoring completed!" -ForegroundColor Green
