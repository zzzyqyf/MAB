/**
 * MAB Alarm System - Firebase Cloud Function
 * 
 * This function:
 * 1. Subscribes to MQTT broker for alarm events: topic/+/alarm
 * 2. Parses sensor data: [humidity, light, temp, water, mode]
 * 3. Checks thresholds based on cultivation mode
 * 4. Queries Firestore for device owner
 * 5. Checks alarm state (deduplication)
 * 6. Sends FCM notification to user
 * 7. Updates alarm state in Firestore
 * 
 * Deployment:
 *   firebase deploy --only functions:mqttAlarmMonitor
 * 
 * Logs:
 *   firebase functions:log
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const mqtt = require('mqtt');

// Initialize Firebase Admin
admin.initializeApp();

// MQTT Broker Configuration
const MQTT_BROKER = 'mqtts://api.milloserver.uk:8883';
const MQTT_USERNAME = 'zhangyifei';
const MQTT_PASSWORD = '123456';
const ALARM_TOPIC = 'topic/+/alarm';

// Threshold Configuration
const THRESHOLDS = {
  temperature: { max: 30 }, // Above 30°C triggers alarm
  humidityNormal: { min: 80, max: 85 },
  humidityPinning: { min: 90, max: 95 },
  waterLevel: { min: 30, max: 70 }, // 30-70% is safe
};

// MQTT Client (persistent connection)
let mqttClient = null;

/**
 * Initialize MQTT connection on function cold start
 * Cloud Functions maintain state between invocations for ~10 minutes
 */
function initializeMqtt() {
  if (mqttClient && mqttClient.connected) {
    console.log('✅ MQTT client already connected');
    return mqttClient;
  }

  console.log('🔌 Connecting to MQTT broker:', MQTT_BROKER);
  
  mqttClient = mqtt.connect(MQTT_BROKER, {
    username: MQTT_USERNAME,
    password: MQTT_PASSWORD,
    clientId: `mab-cloud-function-${Date.now()}`,
    clean: true,
    reconnectPeriod: 5000,
    connectTimeout: 30000,
    rejectUnauthorized: false, // Skip certificate verification
  });

  mqttClient.on('connect', () => {
    console.log('✅ MQTT connected successfully');
    mqttClient.subscribe(ALARM_TOPIC, { qos: 1 }, (err) => {
      if (err) {
        console.error('❌ MQTT subscription error:', err);
      } else {
        console.log(`📬 Subscribed to ${ALARM_TOPIC}`);
      }
    });
  });

  mqttClient.on('error', (error) => {
    console.error('❌ MQTT connection error:', error);
  });

  mqttClient.on('message', async (topic, message) => {
    try {
      console.log(`📨 MQTT message received: ${topic} -> ${message.toString()}`);
      await handleAlarmMessage(topic, message.toString());
    } catch (error) {
      console.error('❌ Error handling MQTT message:', error);
    }
  });

  mqttClient.on('close', () => {
    console.log('⚠️ MQTT connection closed');
  });

  return mqttClient;
}

/**
 * Parse alarm payload: [humidity, light, temp, water, mode]
 * Example: "[72.2,47.0,31.5,60.5,n]"
 */
function parseAlarmPayload(payload) {
  try {
    // Remove brackets
    let cleaned = payload.trim();
    if (cleaned.startsWith('[')) cleaned = cleaned.substring(1);
    if (cleaned.endsWith(']')) cleaned = cleaned.substring(0, cleaned.length - 1);
    
    const parts = cleaned.split(',');
    if (parts.length < 5) {
      throw new Error(`Invalid payload format: expected 5 values, got ${parts.length}`);
    }
    
    return {
      humidity: parseFloat(parts[0].trim()),
      light: parseFloat(parts[1].trim()),
      temperature: parseFloat(parts[2].trim()),
      water: parseFloat(parts[3].trim()),
      mode: parts[4].trim(), // 'n' or 'p'
    };
  } catch (error) {
    console.error('❌ Error parsing alarm payload:', error);
    return null;
  }
}

/**
 * Determine which sensors exceeded thresholds
 */
function checkThresholds(data) {
  const issues = [];
  
  // Check temperature
  if (data.temperature > THRESHOLDS.temperature.max) {
    issues.push({
      sensor: 'temperature',
      value: data.temperature,
      threshold: THRESHOLDS.temperature.max,
      message: `Temperature critical (${data.temperature.toFixed(1)}°C > ${THRESHOLDS.temperature.max}°C)`,
    });
  }
  
  // Check humidity based on mode
  const humidityThreshold = data.mode === 'p' 
    ? THRESHOLDS.humidityPinning 
    : THRESHOLDS.humidityNormal;
  
  if (data.humidity < humidityThreshold.min) {
    issues.push({
      sensor: 'humidity',
      value: data.humidity,
      threshold: humidityThreshold.min,
      message: `Humidity too low (${data.humidity.toFixed(1)}% < ${humidityThreshold.min}%)`,
    });
  } else if (data.humidity > humidityThreshold.max) {
    issues.push({
      sensor: 'humidity',
      value: data.humidity,
      threshold: humidityThreshold.max,
      message: `Humidity too high (${data.humidity.toFixed(1)}% > ${humidityThreshold.max}%)`,
    });
  }
  
  // Check water level
  if (data.water < THRESHOLDS.waterLevel.min) {
    issues.push({
      sensor: 'water',
      value: data.water,
      threshold: THRESHOLDS.waterLevel.min,
      message: `Water level low (${data.water.toFixed(1)}% < ${THRESHOLDS.waterLevel.min}%)`,
    });
  } else if (data.water > THRESHOLDS.waterLevel.max) {
    issues.push({
      sensor: 'water',
      value: data.water,
      threshold: THRESHOLDS.waterLevel.max,
      message: `Water level high (${data.water.toFixed(1)}% > ${THRESHOLDS.waterLevel.max}%)`,
    });
  }
  
  return issues;
}

/**
 * Handle incoming alarm MQTT message
 */
async function handleAlarmMessage(topic, message) {
  console.log(`\n🚨 ========== ALARM MESSAGE RECEIVED ==========`);
  console.log(`Topic: ${topic}`);
  console.log(`Payload: ${message}`);
  
  // Extract device ID from topic: topic/{deviceId}/alarm
  const topicParts = topic.split('/');
  if (topicParts.length < 3 || topicParts[0] !== 'topic' || topicParts[2] !== 'alarm') {
    console.error('❌ Invalid topic format:', topic);
    return;
  }
  
  const deviceId = topicParts[1];
  console.log(`Device ID: ${deviceId}`);
  
  // Parse sensor data
  const sensorData = parseAlarmPayload(message);
  if (!sensorData) {
    console.error('❌ Failed to parse sensor data');
    return;
  }
  
  console.log('📊 Sensor Data:', sensorData);
  
  // Check which sensors exceeded thresholds
  const issues = checkThresholds(sensorData);
  if (issues.length === 0) {
    console.log('✅ All sensors within safe range (false alarm?)');
    return;
  }
  
  console.log(`⚠️ ${issues.length} sensor(s) out of range:`, issues);
  
  // Query Firestore for device - devices are stored as subcollections under users
  // Structure: users/{userId}/devices (array) where each device has mqttId
  console.log('🔍 Searching for device in users collection...');
  
  const usersSnapshot = await admin.firestore().collection('users').get();
  let userDoc = null;
  let deviceData = null;
  
  // Find which user owns this device
  for (const doc of usersSnapshot.docs) {
    const userData = doc.data();
    if (userData.devices && Array.isArray(userData.devices)) {
      const device = userData.devices.find(d => d.mqttId === deviceId);
      if (device) {
        userDoc = doc;
        deviceData = device;
        break;
      }
    }
  }
  
  if (!userDoc || !deviceData) {
    console.error(`❌ Device ${deviceId} not found in any user's devices`);
    return;
  }
  
  const userId = userDoc.id;
  const userData = userDoc.data();
  
  console.log('📱 Device found:', {
    userId: userId,
    deviceId: deviceData.deviceId,
    mqttId: deviceData.mqttId,
    deviceName: deviceData.name,
  });
  
  // Check if alarm should be sent (deduplication)
  // Note: Alarm state is stored in user document, not device subdocument
  const alarmState = userData.alarmState?.[deviceId] || {};
  
  if (alarmState.alarmActive) {
    console.log('⏸️ Alarm already active, skipping');
    return;
  }
  
  if (alarmState.alarmAcknowledged) {
    console.log('⏸️ Alarm already acknowledged by user, skipping');
    return;
  }
  
  if (alarmState.snoozeUntil) {
    const snoozeUntil = alarmState.snoozeUntil.toDate();
    if (snoozeUntil > new Date()) {
      console.log(`⏸️ Alarm snoozed until ${snoozeUntil.toISOString()}, skipping`);
      return;
    }
  }
  
  // Check 5-minute cooldown
  if (alarmState.lastAlarm) {
    const lastAlarm = alarmState.lastAlarm.toDate();
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
    if (lastAlarm > fiveMinutesAgo) {
      console.log(`⏸️ Last alarm sent ${Math.floor((Date.now() - lastAlarm.getTime()) / 1000)}s ago (5min cooldown), skipping`);
      return;
    }
  }
  
  // Check FCM token
  if (!userData.fcmToken) {
    console.error(`❌ User ${userId} has no FCM token`);
    return;
  }
  
  console.log('✅ User FCM token found');
  
  // Build notification message
  const alarmTitle = '🚨 Sensor Alert';
  const alarmBody = `${deviceData.name}: ${issues.map(i => i.message).join(', ')}`;
  
  const fcmMessage = {
    token: userData.fcmToken,
    notification: {
      title: alarmTitle,
      body: alarmBody,
    },
    data: {
      deviceId: deviceData.mqttId, // MQTT ID (MAC address)
      deviceName: deviceData.name || 'Unknown Device',
      alarmType: issues[0].sensor, // Primary issue
      value: String(issues[0].value),
      threshold: String(issues[0].threshold),
      mode: sensorData.mode === 'p' ? 'pinning' : 'normal',
      allIssues: JSON.stringify(issues),
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'alarm_channel',
      },
    },
  };
  
  console.log('📤 Sending FCM notification...');
  
  try {
    const response = await admin.messaging().send(fcmMessage);
    console.log('✅ FCM notification sent successfully:', response);
    
    // Update alarm state in user document
    const userRef = admin.firestore().collection('users').doc(userId);
    await userRef.update({
      [`alarmState.${deviceId}.lastAlarm`]: admin.firestore.FieldValue.serverTimestamp(),
      [`alarmState.${deviceId}.alarmActive`]: true,
      [`alarmState.${deviceId}.alarmAcknowledged`]: false,
      fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log('✅ Alarm state updated in user document');
    console.log(`========== ALARM PROCESSING COMPLETE ==========\n`);
    
  } catch (error) {
    console.error('❌ Error sending FCM notification:', error);
  }
}

/**
 * Cloud Function that runs continuously
 * Maintains MQTT connection and listens for alarms
 * 
 * Note: This uses "Background Functions" which have limitations:
 * - Cold starts every ~10 minutes if no activity
 * - Consider using Cloud Run for always-on service if needed
 */
exports.mqttAlarmMonitor = functions
  .runWith({
    timeoutSeconds: 540, // Max 9 minutes
    memory: '256MB',
  })
  .https.onRequest(async (req, res) => {
    // Initialize MQTT connection
    initializeMqtt();
    
    // Keep function alive
    res.status(200).send({
      status: 'MQTT Alarm Monitor running',
      connected: mqttClient ? mqttClient.connected : false,
      subscribed: ALARM_TOPIC,
    });
  });

/**
 * HTTP endpoint to manually trigger alarm for testing
 * POST /testAlarm
 * Body: { deviceId: "94B97EC04AD4", payload: "[72.2,47.0,31.5,60.5,n]" }
 */
exports.testAlarm = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }
  
  const { deviceId, payload } = req.body;
  if (!deviceId || !payload) {
    res.status(400).send('Missing deviceId or payload');
    return;
  }
  
  try {
    const topic = `topic/${deviceId}/alarm`;
    await handleAlarmMessage(topic, payload);
    res.status(200).send({ success: true, message: 'Alarm test triggered' });
  } catch (error) {
    console.error('Test alarm error:', error);
    res.status(500).send({ success: false, error: error.message });
  }
});

/**
 * Scheduled function to keep MQTT connection alive
 * Runs every 5 minutes to prevent cold starts
 * 
 * To deploy: firebase deploy --only functions:keepAlive
 */
exports.keepAlive = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    console.log('🔄 Keep-alive ping - maintaining MQTT connection');
    
    // Initialize/maintain MQTT connection
    initializeMqtt();
    
    // Log connection status
    if (mqttClient && mqttClient.connected) {
      console.log('✅ MQTT connection is healthy');
      return { status: 'healthy', connected: true };
    } else {
      console.log('⚠️ MQTT connection lost, reconnecting...');
      return { status: 'reconnecting', connected: false };
    }
  });
