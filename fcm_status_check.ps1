# FCM Status Check and Test Guide
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     FCM NOTIFICATION STATUS CHECK     " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ FCM Configuration Found:" -ForegroundColor Green
Write-Host "   - Channel ID: channel_id_5" -ForegroundColor Gray
Write-Host "   - Channel Name: Alarm Notifications High Priority" -ForegroundColor Gray
Write-Host "   - Importance: high" -ForegroundColor Gray
Write-Host "   - Priority: high" -ForegroundColor Gray
Write-Host "   - Sound: enabled (beep.mp3)" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Notification Actions (Buttons):" -ForegroundColor Green
Write-Host "   1. 'Dismiss' - Stops alarm and marks as acknowledged" -ForegroundColor Gray
Write-Host "   2. 'Remind me later' - Shows time picker (5min/15min/30min/1h/2h)" -ForegroundColor Gray
Write-Host ""

Write-Host "❌ Current Problem:" -ForegroundColor Red
Write-Host "   Alarm state is ACTIVE from previous test" -ForegroundColor Yellow
Write-Host "   Cloud Function has 5-minute cooldown to prevent spam" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔧 Solutions:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1 - Wait for cooldown (EASIEST):" -ForegroundColor White
Write-Host "   Wait 5 minutes from last alarm, then run:" -ForegroundColor Gray
Write-Host "   .\test_alarm_simple.ps1" -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 2 - Manually clear state in Firebase Console:" -ForegroundColor White
Write-Host "   1. Go to: https://console.firebase.google.com/project/mab-fyp/firestore" -ForegroundColor Gray
Write-Host "   2. Navigate to: users → DlpiZplOUaVEB0nOjcRIqntlhHI3 → alarmState → E86BEAD0BD78" -ForegroundColor Gray
Write-Host "   3. Set 'alarmActive' field to: false" -ForegroundColor Gray
Write-Host "   4. Run: .\test_alarm_simple.ps1" -ForegroundColor Yellow
Write-Host ""

Write-Host "Option 3 - Test on emulator (if emulator running):" -ForegroundColor White
Write-Host "   Emulator has different FCM token, so no cooldown issue" -ForegroundColor Gray
Write-Host "   But need to login to same account on emulator first" -ForegroundColor Gray
Write-Host ""

Write-Host "📊 To verify FCM is working, check Flutter logs for:" -ForegroundColor Cyan
Write-Host "   [FCM] Foreground message received" -ForegroundColor Yellow
Write-Host "   [FCM] Processing alarm message" -ForegroundColor Yellow
Write-Host "   🚨 ALARM STARTED" -ForegroundColor Yellow
Write-Host ""

Write-Host "Check current alarm state? (y/n):" -ForegroundColor Cyan
$check = Read-Host

if ($check -eq 'y') {
    Write-Host "Checking Firestore..." -ForegroundColor Yellow
    Write-Host "Go to Firebase Console manually to check alarmState" -ForegroundColor Gray
    Write-Host "https://console.firebase.google.com/project/mab-fyp/firestore/data/~2Fusers~2FDlpiZplOUaVEB0nOjcRIqntlhHI3" -ForegroundColor Blue
}
