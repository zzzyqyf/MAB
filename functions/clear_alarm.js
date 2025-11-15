const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./mab-fyp-firebase-adminsdk-9g1xz-2bd3e81c19.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function clearAlarmState() {
  try {
    console.log('Clearing alarm state...');
    
    const userRef = db.collection('users').doc('DlpiZplOUaVEB0nOjcRIqntlhHI3');
    
    await userRef.update({
      'alarmState.E86BEAD0BD78.alarmActive': false,
      'alarmState.E86BEAD0BD78.alarmAcknowledged': false,
    });
    
    console.log('✅ Alarm state cleared successfully!');
    console.log('You can now run the test script.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

clearAlarmState();
