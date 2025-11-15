# Simple Alarm Test Script
Write-Host "=== MAB Alarm Notification Test ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pre-checks:" -ForegroundColor Yellow
Write-Host "1. App running on phone? (Check flutter logs showing 'online')"
Write-Host "2. Phone screen unlocked?"
Write-Host "3. Do Not Disturb OFF?"
Write-Host ""
Write-Host "Triggering alarm in 3 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "Sending FCM notification..." -ForegroundColor Cyan
$response = Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" -Method POST -ContentType "application/json" -Body '{"deviceId":"E86BEAD0BD78","payload":"[75.0,45.0,31.0,25.0,n]"}' -UseBasicParsing

Write-Host "✅ Cloud Function Response: $($response.StatusCode)" -ForegroundColor Green
Write-Host "Response: $($response.Content)"
Write-Host ""
Write-Host "Waiting 10 seconds for notification..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Did the notification appear on your phone? (y/n)" -ForegroundColor Cyan
$result = Read-Host
if ($result -eq 'y') {
    Write-Host "✅ SUCCESS! Notification working!" -ForegroundColor Green
    Write-Host "Did you hear the alarm sound? (y/n)" -ForegroundColor Cyan
    $sound = Read-Host
    if ($sound -eq 'y') {
        Write-Host "🎉 PERFECT! Everything working!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Notification appeared but no sound" -ForegroundColor Yellow
        Write-Host "Check: Settings → Apps → MAB → Notifications → 'Alarm Notifications High Priority' → Sound enabled?"
    }
} else {
    Write-Host "❌ Notification not appearing" -ForegroundColor Red
    Write-Host "Check flutter logs in other terminal"
}
