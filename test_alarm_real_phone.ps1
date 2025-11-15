# Test Alarm on Real Phone - Troubleshooting Script
# Run this after building app with: flutter run --release

Write-Host @"
╔═══════════════════════════════════════════════════╗
║   MAB Alarm System - Real Phone Test Script      ║
╚═══════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`n⚠️  BEFORE TESTING - CHECK YOUR PHONE:" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════" -ForegroundColor Yellow

# Interactive checklist
$checks = @(
    "📱 Phone Settings → Sound → Alarm Volume = MAX",
    "🔔 Settings → Apps → MAB → Notifications = Enabled",
    "⏰ Notification channel 'Alarm' sound = Alarm/Default (NOT Silent)",
    "🔋 Settings → Battery → MAB = Don't optimize",
    "🚫 Do Not Disturb mode = OFF",
    "📲 Phone NOT on Silent/Vibrate mode",
    "📱 App is running on your phone"
)

foreach ($check in $checks) {
    Write-Host "  $check" -ForegroundColor White
}

Write-Host "`n❓ Have you checked all the above? (y/n): " -NoNewline -ForegroundColor Cyan
$confirmed = Read-Host

if ($confirmed -ne 'y') {
    Write-Host "`n⚠️  Please check all items above before testing!" -ForegroundColor Yellow
    Write-Host "   The most common issue is ALARM VOLUME being muted.`n" -ForegroundColor Yellow
    exit
}

Write-Host "`n✅ Great! Starting test sequence...`n" -ForegroundColor Green

# Test 1: Trigger alarm
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "TEST 1: Triggering Test Alarm" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`n📤 Sending alarm trigger to Cloud Function..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest `
        -Uri "https://us-central1-mab-fyp.cloudfunctions.net/testAlarm" `
        -Method POST `
        -Headers @{"Content-Type"="application/json"} `
        -Body '{"deviceId":"E86BEAD0BD78","payload":"[75.0,45.0,31.0,25.0,n]"}' `
        -TimeoutSec 10
    
    Write-Host "✅ Alarm triggered successfully (HTTP $($response.StatusCode))" -ForegroundColor Green
    
    Write-Host "`n┌──────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "│  📱 CHECK YOUR PHONE NOW!                    │" -ForegroundColor Magenta
    Write-Host "│                                              │" -ForegroundColor Magenta
    Write-Host "│  Expected within 5-10 seconds:               │" -ForegroundColor White
    Write-Host "│  • Notification appears                      │" -ForegroundColor White
    Write-Host "│  • Sound plays (beep every 2 seconds)        │" -ForegroundColor White
    Write-Host "│  • Phone vibrates                            │" -ForegroundColor White
    Write-Host "└──────────────────────────────────────────────┘" -ForegroundColor Magenta
    
} catch {
    Write-Host "❌ Failed to trigger alarm: $_" -ForegroundColor Red
    Write-Host "   Check your internet connection and try again.`n" -ForegroundColor Yellow
    exit
}

# Wait for user feedback
Write-Host "`n⏳ Waiting 15 seconds for notification...`n" -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "RESULTS CHECK" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`n❓ Did the NOTIFICATION appear on your phone? (y/n): " -NoNewline -ForegroundColor Yellow
$notificationShown = Read-Host

if ($notificationShown -ne 'y') {
    Write-Host "`n❌ NOTIFICATION DID NOT APPEAR" -ForegroundColor Red
    Write-Host "`nPossible causes:" -ForegroundColor Yellow
    Write-Host "  1. App not running in release mode" -ForegroundColor White
    Write-Host "     → Close app, run: flutter run --release" -ForegroundColor Gray
    Write-Host "  2. FCM token not saved" -ForegroundColor White
    Write-Host "     → Check Firestore: users/{uid}/fcmToken exists" -ForegroundColor Gray
    Write-Host "  3. Notification permissions denied" -ForegroundColor White
    Write-Host "     → Settings → Apps → MAB → Notifications → Enable" -ForegroundColor Gray
    Write-Host "  4. Battery optimization killed app" -ForegroundColor White
    Write-Host "     → Settings → Battery → MAB → Don't optimize" -ForegroundColor Gray
    Write-Host "`n📊 Check Cloud Function logs:" -ForegroundColor Cyan
    Write-Host "   firebase functions:log --only testAlarm -n 20`n" -ForegroundColor Gray
    exit
}

Write-Host "`n✅ Notification appeared!" -ForegroundColor Green

Write-Host "`n❓ Did you HEAR the alarm sound? (y/n): " -NoNewline -ForegroundColor Yellow
$soundPlayed = Read-Host

if ($soundPlayed -ne 'y') {
    Write-Host "`n❌ SOUND DID NOT PLAY" -ForegroundColor Red
    Write-Host "`nThis is the issue! Let's diagnose:" -ForegroundColor Yellow
    
    Write-Host "`n🔍 DIAGNOSIS STEPS:" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
    
    Write-Host "`n1️⃣  Test your phone's alarm volume:" -ForegroundColor Yellow
    Write-Host "   a) Press VOLUME UP button on your phone" -ForegroundColor White
    Write-Host "   b) Tap the ⚙️ icon to see all volume sliders" -ForegroundColor White
    Write-Host "   c) Turn ALARM volume slider to MAX" -ForegroundColor White
    Write-Host "   d) Open Clock app → Set alarm for 1 min → Verify it rings" -ForegroundColor White
    
    Write-Host "`n2️⃣  Check notification channel sound:" -ForegroundColor Yellow
    Write-Host "   a) Settings → Apps → MAB → Notifications" -ForegroundColor White
    Write-Host "   b) Tap 'Alarm Notifications' or 'alarm_channel'" -ForegroundColor White
    Write-Host "   c) Sound should be 'Default' or 'Alarm sound'" -ForegroundColor White
    Write-Host "   d) If it's 'Silent' or 'None', change it!" -ForegroundColor White
    
    Write-Host "`n3️⃣  Check Do Not Disturb:" -ForegroundColor Yellow
    Write-Host "   a) Swipe down from top of phone" -ForegroundColor White
    Write-Host "   b) Check if 'Do Not Disturb' icon is active" -ForegroundColor White
    Write-Host "   c) If active, tap to disable it" -ForegroundColor White
    
    Write-Host "`n4️⃣  Check phone is not on Silent:" -ForegroundColor Yellow
    Write-Host "   a) Check physical mute switch (if your phone has one)" -ForegroundColor White
    Write-Host "   b) Swipe down and check if 'Silent mode' is enabled" -ForegroundColor White
    
    Write-Host "`n5️⃣  Reinstall app with fresh notification channel:" -ForegroundColor Yellow
    Write-Host "   a) Uninstall MAB from phone" -ForegroundColor White
    Write-Host "   b) Run: flutter clean" -ForegroundColor White
    Write-Host "   c) Run: flutter run --release" -ForegroundColor White
    Write-Host "   d) Grant notification permission when prompted" -ForegroundColor White
    Write-Host "   e) Test alarm again" -ForegroundColor White
    
    Write-Host "`n📝 After fixing, run this script again to retest.`n" -ForegroundColor Cyan
    
} else {
    Write-Host "`n✅ SOUND PLAYED!" -ForegroundColor Green
    
    Write-Host "`n❓ Did you feel VIBRATION? (y/n): " -NoNewline -ForegroundColor Yellow
    $vibrationFelt = Read-Host
    
    if ($vibrationFelt -eq 'y') {
        Write-Host "`n╔═══════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║  🎉 SUCCESS! ALARM SYSTEM FULLY WORKING! 🎉  ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════╝" -ForegroundColor Green
        
        Write-Host "`n✅ Notification: Working" -ForegroundColor Green
        Write-Host "✅ Sound: Working" -ForegroundColor Green
        Write-Host "✅ Vibration: Working" -ForegroundColor Green
        
        Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
        Write-Host "  • Test Dismiss button (tap notification)" -ForegroundColor White
        Write-Host "  • Test Snooze button" -ForegroundColor White
        Write-Host "  • Test with real ESP32 sensor data" -ForegroundColor White
        Write-Host "  • Test all 3 app states (foreground/background/terminated)" -ForegroundColor White
        
    } else {
        Write-Host "`n⚠️  Vibration not working (but sound works!)" -ForegroundColor Yellow
        Write-Host "   Check Settings → Apps → MAB → Permissions → Vibration`n" -ForegroundColor White
    }
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "`n📊 View detailed logs:" -ForegroundColor Yellow
Write-Host "   Cloud Function: firebase functions:log --only testAlarm -n 20" -ForegroundColor Gray
Write-Host "   Flutter: (check your terminal where app is running)`n" -ForegroundColor Gray
