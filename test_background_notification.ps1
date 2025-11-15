# Test FCM Alarm with App in Background
Write-Host "=== FCM Background Test ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: This test requires app to be in BACKGROUND" -ForegroundColor Yellow
Write-Host ""
Write-Host "Steps:" -ForegroundColor Cyan
Write-Host "1. Press HOME button on your phone (do not close app, just minimize)" -ForegroundColor White
Write-Host "2. Make sure phone screen is ON and unlocked" -ForegroundColor White
Write-Host "3. Wait for this script to send notification" -ForegroundColor White
Write-Host "4. Notification will appear with Dismiss and Remind me later buttons" -ForegroundColor White
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
    payload = '[70.0,68.0,31.0,18.0,n]'  # Multiple sensors out of range
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri 'https://us-central1-mab-fyp.cloudfunctions.net/testAlarm' -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing
    Write-Host "✅ Cloud Function Response: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Body: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host "Check Cloud Function logs: firebase functions:log -n 10" -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Waiting 10 seconds..." -ForegroundColor Yellow
Write-Host "CHECK YOUR PHONE NOW - notification should appear!" -ForegroundColor Cyan -BackgroundColor DarkBlue
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Did notification appear on lock screen/notification bar? (y/n): " -ForegroundColor Cyan -NoNewline
$appeared = Read-Host

if ($appeared -eq 'y') {
    Write-Host ""
    Write-Host "🎉 EXCELLENT! Now check the notification:" -ForegroundColor Green
    Write-Host ""
    Write-Host "1. Do you see 'Dismiss' button? (y/n): " -ForegroundColor White -NoNewline
    $dismiss = Read-Host
    Write-Host "2. Do you see 'Remind me later' button? (y/n): " -ForegroundColor White -NoNewline
    $remind = Read-Host
    Write-Host "3. Did alarm sound play? (y/n): " -ForegroundColor White -NoNewline
    $sound = Read-Host
    
    Write-Host ""
    if ($dismiss -eq 'y' -and $remind -eq 'y' -and $sound -eq 'y') {
        Write-Host "✅✅✅ PERFECT! EVERYTHING WORKING!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Now test the 'Remind me later' button:" -ForegroundColor Cyan
        Write-Host "1. Tap 'Remind me later' on the notification" -ForegroundColor White
        Write-Host "2. You should see a time picker dialog" -ForegroundColor White
        Write-Host "3. Select a time (e.g., 5 minutes)" -ForegroundColor White
        Write-Host "4. Alarm will snooze and re-trigger after that time" -ForegroundColor White
        Write-Host ""
        Write-Host "Did the time picker appear? (y/n): " -ForegroundColor Cyan -NoNewline
        $picker = Read-Host
        if ($picker -eq 'y') {
            Write-Host "🎉 FULLY FUNCTIONAL!" -ForegroundColor Green
        }
    } elseif ($sound -eq 'y') {
        Write-Host "⚠️ Sound works but buttons not visible" -ForegroundColor Yellow
        Write-Host "This means app was in FOREGROUND" -ForegroundColor Yellow
        Write-Host "Try again with app minimized (HOME button)" -ForegroundColor Yellow
    } else {
        Write-Host "⚠️ Partial functionality" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "❌ Notification not appearing" -ForegroundColor Red
    Write-Host ""
    Write-Host "But you said you heard sound earlier, so FCM is working!" -ForegroundColor Yellow
    Write-Host "The issue is: Foreground vs Background behavior" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "When app is OPEN (foreground):" -ForegroundColor Cyan
    Write-Host "  - Sound plays ✅" -ForegroundColor White
    Write-Host "  - NO notification banner ❌" -ForegroundColor White
    Write-Host "  - This is normal Android behavior" -ForegroundColor White
    Write-Host ""
    Write-Host "When app is MINIMIZED (background):" -ForegroundColor Cyan
    Write-Host "  - Sound plays ✅" -ForegroundColor White
    Write-Host "  - Notification appears ✅" -ForegroundColor White
    Write-Host "  - Action buttons visible ✅" -ForegroundColor White
    Write-Host ""
    Write-Host "Try again? (y/n): " -ForegroundColor Yellow -NoNewline
    $retry = Read-Host
    if ($retry -eq 'y') {
        Write-Host ""
        Write-Host "Make sure to:" -ForegroundColor Cyan
        Write-Host "1. Press HOME button (do not close app)" -ForegroundColor White
        Write-Host "2. Clear alarm state in Firebase Console first" -ForegroundColor White
        Write-Host "3. Run this script again" -ForegroundColor White
    }
}
