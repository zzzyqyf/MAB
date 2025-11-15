# Clear FCM alarm state and test
Write-Host "=== FCM Alarm Test with State Clear ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Clearing alarm state..." -ForegroundColor Yellow
# Clear alarm state by setting alarmActive to false
$clearBody = @{
    userId = "DlpiZplOUaVEB0nOjcRIqntlhHI3"
    deviceId = "E86BEAD0BD78"
    action = "clear"
} | ConvertTo-Json

Write-Host "Calling clearAlarm endpoint..." -ForegroundColor Gray
try {
    $clearResponse = Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/clearAlarmState" -Method POST -ContentType "application/json" -Body $clearBody -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Alarm state cleared" -ForegroundColor Green
} catch {
    Write-Host "⚠️ clearAlarmState endpoint might not exist, continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Waiting 2 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "Step 3: Sending test alarm..." -ForegroundColor Yellow
$testBody = @{
    userId = "DlpiZplOUaVEB0nOjcRIqntlhHI3"
    mqttId = "E86BEAD0BD78"
} | ConvertTo-Json

$testResponse = Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" -Method POST -ContentType "application/json" -Body $testBody -UseBasicParsing

Write-Host "✅ Test Response: $($testResponse.StatusCode)" -ForegroundColor Green
Write-Host "Body: $($testResponse.Content)"

Write-Host ""
Write-Host "Waiting 10 seconds for notification..." -ForegroundColor Yellow
Write-Host "Check Flutter terminal for FCM logs!" -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Did notification appear? (y/n):" -ForegroundColor Cyan
$result = Read-Host

if ($result -eq 'y') {
    Write-Host "🎉 SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Did you see 'Dismiss' and 'Remind me later' buttons? (y/n):" -ForegroundColor Cyan
    $buttons = Read-Host
    if ($buttons -eq 'y') {
        Write-Host "✅ Notification buttons working!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Buttons not showing - check AndroidNotificationDetails" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Check logs" -ForegroundColor Red
    Write-Host "Run: firebase functions:log --only testAlarm -n 10" -ForegroundColor Yellow
}
