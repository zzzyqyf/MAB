# Quick: Clear Alarm State

## Open Firebase Console:
https://console.firebase.google.com/project/mab-fyp/firestore/data/~2Fusers~2FDlpiZplOUaVEB0nOjcRIqntlhHI3

## Then:
1. Look for field: `alarmState`
2. Expand it
3. Find: `E86BEAD0BD78`
4. Find field: `alarmActive`
5. Change from: `true`
6. Change to: `false`
7. Click: "Update"

## Then run:
.\test_bgnotif.ps1

## Make sure:
- App is MINIMIZED (HOME button pressed)
- Phone screen ON and unlocked
- Then you'll see notification with "Dismiss" and "Remind me later" buttons!
