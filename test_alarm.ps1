# MAB Alarm System - Real Phone Test
# Simple test script to trigger alarm and verify it works

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  MAB Alarm Test - Real Phone" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nBEFORE TESTING - Check your phone:" -ForegroundColor Yellow
Write-Host "  1. Settings -> Sound -> Alarm Volume = MAX" -ForegroundColor White
Write-Host "  2. Settings -> Apps -> MAB -> Notifications = ON" -ForegroundColor White
Write-Host "  3. Do Not Disturb = OFF" -ForegroundColor White
Write-Host "  4. Phone NOT on Silent mode" -ForegroundColor White
Write-Host "  5. App is running on your phone" -ForegroundColor White

Write-Host "`nPress Enter when ready to test..." -ForegroundColor Green
Read-Host

Write-Host "`nTriggering alarm..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" -Method POST -Headers @{"Content-Type"="application/json"} -Body '{"deviceId":"E86BEAD0BD78","payload":"[75.0,45.0,31.0,25.0,n]"}' -TimeoutSec 10
    
    Write-Host "Success! Alarm triggered." -ForegroundColor Green
    Write-Host "`n>>> CHECK YOUR PHONE NOW! <<<" -ForegroundColor Magenta
    Write-Host "`nExpected within 5-10 seconds:" -ForegroundColor Yellow
    Write-Host "  - Notification appears" -ForegroundColor White
    Write-Host "  - Sound plays (beep every 2 seconds)" -ForegroundColor White
    Write-Host "  - Phone vibrates" -ForegroundColor White
    
} catch {
    Write-Host "Failed to trigger alarm: $_" -ForegroundColor Red
    Write-Host "Check your internet connection." -ForegroundColor Yellow
}

Write-Host "`nWaiting 15 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Did notification appear? (y/n): " -NoNewline -ForegroundColor Yellow
$notification = Read-Host

if ($notification -ne 'y') {
    Write-Host "`nNotification did NOT appear!" -ForegroundColor Red
    Write-Host "`nPossible fixes:" -ForegroundColor Yellow
    Write-Host "  1. Run: flutter run --release" -ForegroundColor White
    Write-Host "  2. Check Firestore: users/{uid}/fcmToken exists" -ForegroundColor White
    Write-Host "  3. Enable notifications: Settings -> Apps -> MAB" -ForegroundColor White
    exit
}

Write-Host "`nDid you HEAR sound? (y/n): " -NoNewline -ForegroundColor Yellow
$sound = Read-Host

if ($sound -ne 'y') {
    Write-Host "`nNo sound! This is the issue." -ForegroundColor Red
    Write-Host "`nMOST COMMON FIX:" -ForegroundColor Yellow
    Write-Host "  1. Press Volume UP button on phone" -ForegroundColor White
    Write-Host "  2. Tap the settings icon" -ForegroundColor White
    Write-Host "  3. Turn ALARM volume slider to MAX" -ForegroundColor White
    Write-Host "  4. Test: Open Clock app, set alarm for 1 min" -ForegroundColor White
    Write-Host "`nOther checks:" -ForegroundColor Yellow
    Write-Host "  - Settings -> Apps -> MAB -> Notifications -> Alarm channel -> Sound = Default" -ForegroundColor White
    Write-Host "  - Turn OFF Do Not Disturb mode" -ForegroundColor White
    Write-Host "  - Phone NOT on Silent mode" -ForegroundColor White
} else {
    Write-Host "`nSUCCESS! Alarm is working!" -ForegroundColor Green
    Write-Host "  - Notification: Working" -ForegroundColor Green
    Write-Host "  - Sound: Working" -ForegroundColor Green
    Write-Host "`nNext: Test Dismiss and Snooze buttons" -ForegroundColor Cyan
}

Write-Host "`nTest complete!" -ForegroundColor Cyan
