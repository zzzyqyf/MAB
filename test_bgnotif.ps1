# Test FCM Alarm with App in Background
Write-Host "=== FCM Background Test ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: This test requires app to be in BACKGROUND" -ForegroundColor Yellow
Write-Host ""
Write-Host "Steps:" -ForegroundColor Cyan
Write-Host "1. Press HOME button on your phone (minimize app)" -ForegroundColor White
Write-Host "2. Make sure phone screen is ON and unlocked" -ForegroundColor White
Write-Host "3. Wait for this script to send notification" -ForegroundColor White
Write-Host "4. Notification will appear with action buttons" -ForegroundColor White
Write-Host ""
Write-Host "Ready? Press HOME button on phone now!" -ForegroundColor Red -BackgroundColor White
Write-Host "Then press Enter here to continue..." -ForegroundColor Yellow
Read-Host

Write-Host ""
Write-Host "Sending alarm in 3 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "Sending FCM notification..." -ForegroundColor Cyan
$body = @{
    deviceId = 'E86BEAD0BD78'
    payload = '[70.0,68.0,31.0,18.0,n]'
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri 'https://us-central1-mab-fyp.cloudfunctions.net/testAlarm' -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing
    Write-Host "Response: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
Write-Host "CHECK YOUR PHONE NOW!" -ForegroundColor Cyan -BackgroundColor DarkBlue
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Did notification appear? (y/n): " -ForegroundColor Cyan -NoNewline
$appeared = Read-Host

if ($appeared -eq 'y') {
    Write-Host ""
    Write-Host "SUCCESS! Now check:" -ForegroundColor Green
    Write-Host ""
    Write-Host "1. Do you see Dismiss button? (y/n): " -ForegroundColor White -NoNewline
    $dismiss = Read-Host
    Write-Host "2. Do you see Remind me later button? (y/n): " -ForegroundColor White -NoNewline
    $remind = Read-Host
    Write-Host "3. Did alarm sound play? (y/n): " -ForegroundColor White -NoNewline
    $sound = Read-Host
    
    Write-Host ""
    if ($dismiss -eq 'y' -and $remind -eq 'y' -and $sound -eq 'y') {
        Write-Host "PERFECT! EVERYTHING WORKING!" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "Notification not appearing" -ForegroundColor Red
    Write-Host "Make sure app is minimized, not closed" -ForegroundColor Yellow
}
