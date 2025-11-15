Write-Host "Quick Test - Run after clearing alarm state in Firebase" -ForegroundColor Cyan
Write-Host ""
Write-Host "Did you:" -ForegroundColor Yellow
Write-Host "1. Set alarmActive = false in Firebase Console? (y/n): " -NoNewline
$cleared = Read-Host
if ($cleared -ne 'y') {
    Write-Host "Please clear it first at:" -ForegroundColor Red
    Write-Host "https://console.firebase.google.com/project/mab-fyp/firestore" -ForegroundColor Blue
    exit
}

Write-Host "2. Press HOME button on phone (app minimized)? (y/n): " -NoNewline
$minimized = Read-Host
if ($minimized -ne 'y') {
    Write-Host "Press HOME button now, then run script again!" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Sending notification in 3 seconds..." -ForegroundColor Green
Start-Sleep -Seconds 3

$body = @{
    deviceId = 'E86BEAD0BD78'
    payload = '[70.0,68.0,31.0,18.0,n]'
} | ConvertTo-Json

Invoke-WebRequest -Uri 'https://us-central1-mab-fyp.cloudfunctions.net/testAlarm' -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing | Out-Null

Write-Host "Sent! Check phone in 10 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Did notification appear on phone? (y/n): " -NoNewline
$appeared = Read-Host

if ($appeared -eq 'y') {
    Write-Host ""
    Write-Host "Do you see TWO buttons in the notification?" -ForegroundColor Green
    Write-Host "1. Dismiss" -ForegroundColor White
    Write-Host "2. Remind me later" -ForegroundColor White
    Write-Host ""
    Write-Host "Are both visible? (y/n): " -NoNewline
    $buttons = Read-Host
    
    if ($buttons -eq 'y') {
        Write-Host ""
        Write-Host "SUCCESS! Try tapping 'Remind me later' button now!" -ForegroundColor Green
        Write-Host "It should open a time picker dialog." -ForegroundColor Cyan
    }
} else {
    Write-Host "Still not appearing - alarm cooldown may not be cleared yet" -ForegroundColor Yellow
}
