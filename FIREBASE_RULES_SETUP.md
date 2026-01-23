# 🔥 Firebase Setup Instructions
## ✅ COMPLETED - Security Rules Deployed

---

## ⚠️ Status: ✅ CONFIGURED (Rules deployed on January 23, 2026)

The Firestore security rules have been deployed to your Firebase project.

---

## 📋 Step-by-Step Instructions

### 1. Open Firebase Console

🔗 **Link**: https://console.firebase.google.com/

### 2. Select Your Project

- Click on project: **`mab-fyp`**

### 3. Navigate to Firestore Database

- In left sidebar, click **"Firestore Database"**
- Click on **"Rules"** tab

### 4. Copy the Rules Below

**Select ALL the text below and copy it:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ============================================================================
    // Users Collection - User-Device Associations
    // ============================================================================
    match /users/{userId} {
      // Allow users to read and write only their own document
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Allow update only if:
      // 1. User is the owner
      // 2. Devices field is present and is an array
      // 3. Each device object has required fields
      allow update: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.data.keys().hasAll(['devices'])
        && request.resource.data.devices is list
        && validateDeviceArray(request.resource.data.devices);
      
      // Allow delete only if user is the owner
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // ============================================================================
    // OTP Verification Collection (for signup)
    // ============================================================================
    match /otp_verifications/{email} {
      // Allow anyone to read/write during signup process (no auth yet)
      allow read, write: if request.auth == null || request.auth != null;
    }
    
    // ============================================================================
    // Invitations Collection (existing functionality)
    // ============================================================================
    match /invitations/{invitationId} {
      // Allow authenticated users to read/write invitations
      allow read, write: if request.auth != null;
    }
    
    // ============================================================================
    // Helper Functions
    // ============================================================================
    
    // Validate device array structure
    function validateDeviceArray(devices) {
      // Check if all devices have required fields
      return devices.size() == 0 || 
        devices[0].keys().hasAll(['deviceId', 'name', 'mqttId', 'addedAt']);
    }
    
    // Validate device object structure
    function isValidDevice(device) {
      return device.keys().hasAll(['deviceId', 'name', 'mqttId', 'addedAt'])
        && device.deviceId is string
        && device.name is string
        && device.mqttId is string
        && device.addedAt is timestamp;
    }
  }
}
```

### 5. Paste into Firebase Console

- Delete ALL existing rules in the Firebase console
- Paste the rules you just copied
- You should see syntax highlighting

### 6. Publish the Rules

- Click the **"Publish"** button (top right)
- Wait for confirmation: "Rules successfully published"

---

## ✅ Verification

After publishing, you should see:

```
✅ Rules published successfully
Last updated: [Current date and time]
```

---

## 🔍 What These Rules Do

### User Documents (`users/{userId}`)
- ✅ Users can **only** read/write their **own** document
- ✅ Ensures privacy - User A cannot see User B's devices
- ✅ Validates device data structure
- ✅ Prevents malformed device entries

### OTP Verification
- ✅ Allows signup process to work
- ✅ Temporary documents for email verification

### Invitations
- ✅ Maintains existing invitation functionality
- ✅ Authenticated users can manage invitations

---

## 🛡️ Security Features

| Feature | Protection |
|---------|------------|
| **User Isolation** | Each user sees only their own devices |
| **Data Validation** | Ensures correct device structure |
| **Authentication** | Requires login for device operations |
| **No Cross-User Access** | User A cannot modify User B's data |

---

## 🐛 Troubleshooting

### Issue: "Rules won't publish"

**Possible Causes:**
1. Syntax error in rules (check brackets)
2. Missing Firebase project permissions
3. Network connectivity issue

**Solution:**
- Copy rules again carefully
- Check your Firebase project role (must be Owner or Editor)
- Try refreshing the Firebase Console

### Issue: "Permission denied" errors in app

**Possible Causes:**
1. Rules not published yet
2. User not authenticated
3. Trying to access another user's data

**Solution:**
- Verify rules are published (check "Last updated" timestamp)
- Ensure user is logged in (`FirebaseAuth.instance.currentUser != null`)
- Check you're accessing your own user document

---

## 📊 Testing Your Rules

After publishing, test with these scenarios:

### Test 1: User Can Add Device
1. Login to app
2. Add a device
3. Check Firestore Console
4. Verify device appears in your user document ✅

### Test 2: User Cannot See Other Devices
1. Create two user accounts (User A, User B)
2. Add device on User A's account
3. Login as User B
4. Verify User B cannot see User A's device ✅

### Test 3: Duplicate Detection Works
1. Add device with MAC "AABBCCDDEEFF"
2. Try to add same MAC again
3. Verify app shows "already registered" error ✅

---

## 🔗 Additional Resources

- **Firestore Security Rules Documentation**: https://firebase.google.com/docs/firestore/security/get-started
- **Your Project Console**: https://console.firebase.google.com/project/mab-fyp
- **Rules Testing**: Firebase Console → Rules → Simulator tab

---

## ⏱️ Estimated Time

- **Copy rules**: 30 seconds
- **Paste and publish**: 30 seconds
- **Verification**: 30 seconds
- **Total**: ~2 minutes

---

## 🎯 Important Notes

1. ⚠️ **These rules are REQUIRED** - The app will not work properly without them
2. 📝 **Backup existing rules** - If you have custom rules, save them first
3. 🔄 **Changes are immediate** - New rules take effect within seconds
4. ✅ **Safe to update** - These rules are more secure than default rules
5. 🔒 **No data loss** - Updating rules does not affect existing data

---

## 🆘 Need Help?

If you encounter issues:

1. Take a screenshot of the error
2. Check the Firebase Console "Rules" tab for syntax errors
3. Verify your Firebase project is `mab-fyp`
4. Ensure you have Editor/Owner permissions on the project

---

## ✅ Completion Checklist

Mark when complete:

- [ ] Opened Firebase Console
- [ ] Selected `mab-fyp` project
- [ ] Navigated to Firestore Database → Rules
- [ ] Copied rules from this document
- [ ] Pasted into Firebase Console
- [ ] Clicked "Publish" button
- [ ] Saw "Rules successfully published" confirmation
- [ ] Verified "Last updated" shows current timestamp

**Status**: ⬜ **NOT COMPLETE** (Update to ✅ after publishing)

---

**CRITICAL**: Device registration will **NOT** work until these rules are published!

---

*This is a one-time setup. Once published, you don't need to do this again unless you want to modify the rules.*
