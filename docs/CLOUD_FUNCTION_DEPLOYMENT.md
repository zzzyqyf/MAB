# Firebase Cloud Function Deployment Guide

## Overview
This guide walks through deploying the MQTT alarm monitoring Cloud Function for the MAB system.

---

## Prerequisites

### 1. Firebase CLI Installation
```powershell
# Install Firebase CLI globally
npm install -g firebase-tools

# Verify installation
firebase --version
```

### 2. Firebase Project Setup
```powershell
# Login to Firebase
firebase login

# Navigate to your project directory
cd d:\fyp\Backup\MAB

# Initialize Firebase (if not already done)
firebase init functions

# Select:
# - Use existing project: [Your MAB project]
# - Language: JavaScript
# - ESLint: No (optional)
# - Install dependencies: Yes
```

### 3. Upgrade to Blaze Plan
**IMPORTANT**: Cloud Functions require Blaze (pay-as-you-go) plan.

1. Go to: https://console.firebase.google.com
2. Select your MAB project
3. Click gear icon → **Usage and billing**
4. Click **Modify plan**
5. Select **Blaze plan**
6. Add payment method (credit card)
7. Set spending limit: **$5/month** (optional but recommended)

**Don't worry**: Free tier includes:
- 125K function invocations/month
- 40K GB-seconds compute time
- With our usage (~100-500 invocations/month), cost will be **$0**

---

## Deployment Steps

### Step 1: Install Dependencies
```powershell
cd d:\fyp\Backup\MAB\functions
npm install
```

This installs:
- `firebase-admin`: Admin SDK for Firestore/FCM
- `firebase-functions`: Cloud Functions SDK
- `mqtt`: MQTT client library

### Step 2: Deploy to Firebase
```powershell
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:mqttAlarmMonitor
```

**Expected output:**
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/your-project/overview
Function URL (mqttAlarmMonitor): https://us-central1-your-project.cloudfunctions.net/mqttAlarmMonitor
```

### Step 3: Verify Deployment
```powershell
# Check function logs
firebase functions:log --only mqttAlarmMonitor

# Test function is running
curl https://us-central1-your-project.cloudfunctions.net/mqttAlarmMonitor
```

---

## Configuration

### MQTT Broker Credentials
Located in `functions/index.js`:
```javascript
const MQTT_BROKER = 'mqtts://api.milloserver.uk:8883';
const MQTT_USERNAME = 'zhangyifei';
const MQTT_PASSWORD = '123456';
```

⚠️ **Security Note**: For production, use environment variables:
```powershell
firebase functions:config:set mqtt.broker="mqtts://api.milloserver.uk:8883"
firebase functions:config:set mqtt.username="zhangyifei"
firebase functions:config:set mqtt.password="123456"
```

Then update code:
```javascript
const MQTT_BROKER = functions.config().mqtt.broker;
const MQTT_USERNAME = functions.config().mqtt.username;
const MQTT_PASSWORD = functions.config().mqtt.password;
```

### Sensor Thresholds
Modify in `functions/index.js`:
```javascript
const THRESHOLDS = {
  temperature: { max: 30 },
  humidityNormal: { min: 80, max: 85 },
  humidityPinning: { min: 90, max: 95 },
  waterLevel: { min: 30, max: 70 },
};
```

---

## Testing the Cloud Function

### Option 1: ESP32 Triggers Real Alarm
1. Upload updated ESP32 code
2. Manually trigger sensor to exceed threshold:
   - Heat DHT22 sensor above 30°C (use hair dryer)
   - Or modify ESP32 code to send test values
3. Check Cloud Function logs:
   ```powershell
   firebase functions:log --only mqttAlarmMonitor
   ```

### Option 2: HTTP Test Endpoint
```powershell
# Test alarm manually
curl -X POST https://us-central1-your-project.cloudfunctions.net/testAlarm `
  -H "Content-Type: application/json" `
  -d '{\"deviceId\":\"94B97EC04AD4\",\"payload\":\"[72.2,47.0,31.5,60.5,n]\"}'
```

### Option 3: MQTT Test Publisher
```powershell
# Install mosquitto clients
# Publish test alarm
mosquitto_pub -h api.milloserver.uk -p 8883 `
  -u zhangyifei -P 123456 `
  --capath /etc/ssl/certs `
  -t "topic/94B97EC04AD4/alarm" `
  -m "[72.2,47.0,31.5,60.5,n]"
```

---

## Monitoring & Debugging

### View Live Logs
```powershell
# Tail logs in real-time
firebase functions:log --only mqttAlarmMonitor

# View last 100 lines
firebase functions:log --limit 100
```

### Firebase Console
1. Go to: https://console.firebase.google.com
2. Select your project
3. Click **Functions** in left menu
4. Click **mqttAlarmMonitor**
5. View:
   - Invocations graph
   - Execution time
   - Error rate
   - Logs

### Expected Log Output
```
🔌 Connecting to MQTT broker: mqtts://api.milloserver.uk:8883
✅ MQTT connected successfully
📬 Subscribed to topic/+/alarm

📨 MQTT message received: topic/94B97EC04AD4/alarm -> [72.2,47.0,31.5,60.5,n]
🚨 ========== ALARM MESSAGE RECEIVED ==========
Device ID: 94B97EC04AD4
📊 Sensor Data: { humidity: 72.2, light: 47, temperature: 31.5, water: 60.5, mode: 'n' }
⚠️ 1 sensor(s) out of range: [ { sensor: 'temperature', value: 31.5, threshold: 30, message: '...' } ]
📱 Device Data: { userId: 'abc123', deviceName: 'Mushroom Farm', mode: 'normal', ... }
✅ User FCM token found
📤 Sending FCM notification...
✅ FCM notification sent successfully
✅ Device alarm state updated
========== ALARM PROCESSING COMPLETE ==========
```

---

## Troubleshooting

### Issue: "Billing account not configured"
**Solution**: Upgrade to Blaze plan (see Prerequisites)

### Issue: "Function deployment failed"
**Solution**:
```powershell
# Reinstall dependencies
cd functions
rm -rf node_modules
npm install

# Redeploy
firebase deploy --only functions
```

### Issue: "MQTT connection timeout"
**Solution**:
- Check MQTT broker is online: `ping api.milloserver.uk`
- Verify credentials in code
- Check Cloud Function has internet access (Blaze plan required)

### Issue: "Device not found in Firestore"
**Solution**:
- Ensure `devices/{deviceId}` collection exists
- Run migration script (see ALARM_FIRESTORE_STRUCTURE.md)
- Check deviceId matches MQTT MAC address (without colons)

### Issue: "User has no FCM token"
**Solution**:
- Ensure Flutter app has requested notification permissions
- Verify FCM token is saved to `users/{userId}/fcmToken`
- Check Firebase Cloud Messaging is enabled in Firebase Console

### Issue: "Cold starts (function not responding)"
**Solution**:
Cloud Functions sleep after inactivity. Options:
1. **Accept it**: First alarm after inactivity may take 10-30 seconds
2. **Keep-alive ping**: Schedule function to run every 5 minutes:
   ```javascript
   exports.keepAlive = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
     console.log('Keep-alive ping');
     return null;
   });
   ```
3. **Upgrade to Cloud Run**: Always-on service (higher cost)

---

## Cost Management

### Set Spending Limit
1. Firebase Console → Settings → Usage and billing
2. Set **Budget alert** at $5
3. Set **Hard limit** at $10 (prevents surprise charges)

### Monitor Usage
- **Dashboard**: https://console.firebase.google.com → Usage and billing
- **Metrics**:
  - Function invocations: Should be ~100-500/month
  - GB-seconds: Should be <1 GB-sec/month
  - Estimated cost: $0/month

### Reduce Costs Further
1. **Optimize function memory**: 256MB → 128MB (if possible)
2. **Reduce timeout**: 540s → 300s
3. **Add cooldown logic**: Already implemented (5-minute cooldown)
4. **Batch notifications**: If multiple sensors fail, send one notification

---

## Updating the Function

### Make Code Changes
1. Edit `functions/index.js`
2. Test locally (optional):
   ```powershell
   firebase emulators:start --only functions
   ```
3. Deploy:
   ```powershell
   firebase deploy --only functions:mqttAlarmMonitor
   ```

### Common Updates
- **Change thresholds**: Modify `THRESHOLDS` object
- **Update MQTT topics**: Change `ALARM_TOPIC` constant
- **Modify notification text**: Edit `alarmTitle` and `alarmBody`
- **Add cooldown logic**: Update deduplication checks

---

## Security Best Practices

### 1. Use Environment Variables for Secrets
```powershell
firebase functions:config:set mqtt.password="your-secure-password"
```

### 2. Restrict Function Access
```javascript
// Add CORS and authentication
const cors = require('cors')({origin: true});

exports.testAlarm = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    // Verify API key or Firebase Auth token
    const apiKey = req.headers['x-api-key'];
    if (apiKey !== 'your-secret-key') {
      res.status(401).send('Unauthorized');
      return;
    }
    // ... rest of code
  });
});
```

### 3. Enable Function Identity
Firebase Console → Functions → Settings → Enable **Cloud Functions Service Account**

---

## Next Steps

After deployment:
1. ✅ Test with ESP32 sensor exceeding threshold
2. ✅ Verify FCM notification received on Flutter app
3. ✅ Test "Dismiss" and "Snooze" functionality
4. ✅ Monitor costs in Firebase Console for first week
5. ✅ Set up budget alerts

**Deployment complete!** 🎉

For Flutter FCM setup, see: **FLUTTER_FCM_SETUP.md** (next step)
