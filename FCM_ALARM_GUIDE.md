# FCM Alarm System - Complete Guide

## ✅ What We've Confirmed:
1. **FCM is configured and working** - You heard the sound!
2. **Channel configuration is correct** - channel_id_5 with high priority
3. **"Remind me later" button exists** - It's the snooze action button

## 🎯 Current Situation:
- Sound plays ✅ (proves FCM works)
- Notification visual not showing ❌ 
- Action buttons not visible ❌

## 📱 Why No Notification Visual?

### When App is OPEN (Foreground):
- ✅ Sound plays
- ❌ NO notification banner appears
- ❌ NO action buttons visible
- **This is NORMAL Android behavior**

### When App is MINIMIZED (Background):
- ✅ Sound plays
- ✅ Notification appears in notification bar
- ✅ Action buttons: "Dismiss" and "Remind me later"

## 🔧 How to Test Properly:

### Step 1: Clear Alarm State
Go to Firebase Console and set:
`users/DlpiZplOUaVEB0nOjcRIqntlhHI3/alarmState/E86BEAD0BD78/alarmActive = false`

Or wait 5 minutes for cooldown to expire.

### Step 2: Minimize App
- Press HOME button (not close/swipe away)
- App should still be in recent apps list
- Phone screen ON and unlocked

### Step 3: Trigger Alarm
Run: `.\test_bgnotif.ps1`

### Step 4: Check Notification
You should see:
- Notification banner at top of screen
- Title: "🚨 Sensor Alert"  
- Body: Device name + sensor issues
- Two buttons:
  1. **Dismiss** - Stops alarm immediately
  2. **Remind me later** - Opens time picker

### Step 5: Test "Remind me later"
- Tap "Remind me later" button
- Select time: 5min / 15min / 30min / 1hr / 2hr
- Alarm will re-trigger after selected time

## 🐛 Troubleshooting:

### "Alarm already active, skipping"
- **Cause**: Cooldown period (5 minutes)
- **Solution**: Clear alarm state in Firebase OR wait 5 minutes

### "No notification but sound plays"
- **Cause**: App in foreground
- **Solution**: Minimize app before testing

### "No FCM logs in terminal"
- **Check**: Look for `[FCM] Foreground message received` in logs
- **If missing**: FCM not reaching app (check FCM token)

## 📊 What to Look for in Logs:

### Cloud Function (success):
```
✅ FCM notification sent successfully: projects/mab-fyp/messages/...
```

### Flutter App (foreground):
```
🔔 [FCM Foreground] Message received: ...
📋 [FCM Foreground] Title: 🚨 Sensor Alert
🚨 [FCM] Processing alarm message...
🚨 ALARM STARTED: ESP32_D0BD78
```

### Flutter App (background):
- No logs when app minimized (normal)
- Notification appears automatically
- Tap notification to open app

## ✅ Final Test Checklist:

- [ ] Alarm state cleared in Firebase
- [ ] App running on phone  
- [ ] App MINIMIZED (HOME button pressed)
- [ ] Phone screen ON and unlocked
- [ ] Run `.\test_bgnotif.ps1`
- [ ] Notification appears in 10 seconds
- [ ] "Dismiss" button visible
- [ ] "Remind me later" button visible
- [ ] Sound plays
- [ ] Tap "Remind me later" opens time picker

## 🎉 Success Criteria:
When you tap "Remind me later" and select a time, the notification should disappear and the alarm will re-trigger after that duration. This proves the full FCM notification system with action buttons is working correctly!
