#!/usr/bin/env pwsh
# PowerShell Script to Test CO2 Sensor MQTT Publishing
# Usage: .\test_co2.ps1

Write-Host "🌫️ Testing CO2 Sensor MQTT Publishing" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# CO2 sensor test values (in ppm)
$co2Values = @(
    @{ value = "400"; description = "Normal outdoor air" },
    @{ value = "800"; description = "Typical indoor air" },
    @{ value = "1200"; description = "Stuffy room" },
    @{ value = "1800"; description = "Poor ventilation" },
    @{ value = "3000"; description = "Unhealthy levels" },
    @{ value = "600"; description = "Back to normal" }
)

Write-Host "📡 Publishing CO2 sensor values to devices/ESP32_001/sensors/co2" -ForegroundColor Green
Write-Host ""

foreach ($test in $co2Values) {
    $command = "mosquitto_pub -h broker.mqtt.cool -t `"devices/ESP32_001/sensors/co2`" -m `"$($test.value)`""
    
    Write-Host "🌫️ Publishing CO2: $($test.value) ppm ($($test.description))" -ForegroundColor Yellow
    Write-Host "   Command: $command" -ForegroundColor Gray
    
    try {
        Invoke-Expression $command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Successfully published!" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Failed to publish (exit code: $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2
}

Write-Host "🏁 CO2 sensor testing completed!" -ForegroundColor Cyan
Write-Host "💡 Check your Flutter app to see if CO2 values are displayed" -ForegroundColor Yellow
