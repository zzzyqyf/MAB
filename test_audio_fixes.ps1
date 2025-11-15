# Audio Fix Testing Script
# Tests all audio improvements for alarm sound issues

Write-Host "🔊 AUDIO FIX TESTING SCRIPT" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ Changes Applied:" -ForegroundColor Green
Write-Host "  1. Added audio_session package for audio focus" -ForegroundColor White
Write-Host "  2. Configured AudioSession.music() in main()" -ForegroundColor White
Write-Host "  3. Added native audio focus request in MainActivity.kt" -ForegroundColor White
Write-Host "  4. Re-request audio focus before each beep" -ForegroundColor White
Write-Host "  5. Improved TTS initialization with audio configuration" -ForegroundColor White
Write-Host "  6. Added audio system 'wake up' test in AlarmService" -ForegroundColor White
Write-Host ""

Write-Host "📱 Building and deploying to device..." -ForegroundColor Yellow
flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🧪 TESTING CHECKLIST:" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1️⃣  Check logcat for audio focus messages:" -ForegroundColor Yellow
    Write-Host "    - Look for: '✅ Audio focus GAINED'" -ForegroundColor White
    Write-Host "    - Look for: '🔊 Audio focus request result: GRANTED ✅'" -ForegroundColor White
    Write-Host ""
    Write-Host "2️⃣  Check TTS initialization:" -ForegroundColor Yellow
    Write-Host "    - Look for: '✅ TTS initialized successfully'" -ForegroundColor White
    Write-Host "    - Try speaking any text in the app" -ForegroundColor White
    Write-Host ""
    Write-Host "3️⃣  Check AudioPlayer initialization:" -ForegroundColor Yellow
    Write-Host "    - Look for: '✅ AudioPlayer initialized with ALARM audio context'" -ForegroundColor White
    Write-Host "    - Look for: '✅ Audio system test complete'" -ForegroundColor White
    Write-Host ""
    Write-Host "4️⃣  Test alarm sound:" -ForegroundColor Yellow
    Write-Host "    - Go to Settings > Test Alarm Sound" -ForegroundColor White
    Write-Host "    - Trigger a real alarm by creating critical sensor values" -ForegroundColor White
    Write-Host "    - Sound should play through MEDIA/MUSIC stream" -ForegroundColor White
    Write-Host ""
    Write-Host "5️⃣  Check phone settings:" -ForegroundColor Yellow
    Write-Host "    - Alarm volume should be UP (not muted)" -ForegroundColor White
    Write-Host "    - Media volume should be UP" -ForegroundColor White
    Write-Host "    - Do Not Disturb should be OFF" -ForegroundColor White
    Write-Host ""
    Write-Host "6️⃣  Device-specific checks:" -ForegroundColor Yellow
    Write-Host "    - MIUI: Settings > Apps > MAB > Other permissions > Start in background = ON" -ForegroundColor White
    Write-Host "    - MIUI: Settings > Sound > Alarm volume = UP" -ForegroundColor White
    Write-Host "    - Check Google TTS is installed (Play Store > Google Text-to-Speech Engine)" -ForegroundColor White
    Write-Host ""
    Write-Host "📊 To view logs:" -ForegroundColor Cyan
    Write-Host "    adb logcat | Select-String -Pattern 'AlarmService|AudioSession|TTS'" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "❌ Build failed! Check errors above." -ForegroundColor Red
}
