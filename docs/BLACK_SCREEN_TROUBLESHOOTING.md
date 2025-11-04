# Black Screen Troubleshooting Guide

## Quick Checklist

### 1. **Check Firebase Console - Firestore Database**

**Steps:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Firestore Database** in left sidebar
4. **You should see one of these:**
   - ✅ Database created with "Start collection" button
   - ✅ Database with some collections already
   - ❌ "Get started" button (means Firestore not enabled)

**If you see "Get started" button:**
- Click it
- Choose **Test mode**
- Select region (e.g., `us-central`)
- Click **Enable**

**You do NOT need to manually create the `otp_verification` collection - it will be created automatically when the app runs!**

### 2. **Check Console Logs**

Run the app and watch the terminal/console for these messages:

**Expected Success Flow:**
```
📝 About to store OTP in Firestore...
🔄 Attempting to store OTP in Firestore for user@example.com
✅ OTP stored in Firestore for user@example.com
✅ OTP value: 123456
✅ OTP stored successfully, navigating to verification page...
🚀 Navigating to OTP verification page...
🎨 Building OTP Verification Page for email: user@example.com
```

**If you see ERROR:**
```
❌ Error storing OTP: [firebase_auth/...] ...
❌ Firestore error: ...
```

This means there's a Firebase configuration issue.

### 3. **Common Issues & Solutions**

#### Issue: Black Screen Appears
**Possible Causes:**
1. **Firestore not enabled** in Firebase Console
2. **Firestore rules blocking writes**
3. **Internet connection issue**
4. **Firebase not initialized properly**

**Solutions:**

**A. Enable Firestore (if not done):**
- Firebase Console → Firestore Database → Create Database → Test Mode

**B. Update Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow OTP operations for testing
    match /otp_verification/{email} {
      allow read, write: if true;
    }
    
    // Allow users collection
    match /users/{userId} {
      allow read, write: if true; // For testing only
    }
  }
}
```

**C. Check Internet Connection:**
- Make sure device/emulator has internet
- Check if Firebase is reachable

**D. Verify Firebase Initialization:**
- Check `lib/main.dart` has `await Firebase.initializeApp()`
- Ensure `google-services.json` is in `android/app/`

### 4. **Test Firestore Connection**

Add this test to verify Firestore is working:

**In terminal, run:**
```powershell
flutter run
```

**Then in your app, add a test button (temporary):**
```dart
ElevatedButton(
  onPressed: () async {
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'message': 'Hello Firestore',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('✅ Firestore write successful!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore connected!')),
      );
    } catch (e) {
      print('❌ Firestore error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore error: $e')),
      );
    }
  },
  child: Text('Test Firestore'),
)
```

If this works, Firestore is properly set up!

### 5. **Debugging Steps**

**Step 1: Run with logs**
```powershell
flutter run -v
```

**Step 2: Watch for these specific errors:**
- `Permission denied` → Check Firestore rules
- `Not found` → Firestore not enabled
- `Network error` → Internet connection issue

**Step 3: Check Firebase Console → Firestore**
- After signup, check if `otp_verification` collection appears
- If it appears with a document, Firestore is working!

### 6. **Expected Behavior**

**What should happen:**
1. User fills signup form
2. Double-taps "SignUp"
3. Loading spinner appears
4. OTP sent to email
5. **Loading spinner closes**
6. **Navigation to OTP verification page (white screen with 6 input boxes)**
7. User enters 6-digit code
8. Verification succeeds
9. Account created

**If you see black screen at step 6:**
- Check console logs for errors
- Verify Firestore is enabled
- Check Firestore rules

### 7. **Quick Fix - Test Without Firestore First**

To test if the issue is Firestore, temporarily comment out the Firestore storage:

**In `sinUp.dart`, comment out Step 2:**
```dart
// Step 2: Store OTP in Firestore
print('📝 Skipping Firestore storage for testing...');
// try {
//   await EmailService.storeOTP(
//     email: email,
//     otp: otp,
//   );
//   print('✅ OTP stored successfully...');
// } catch (firestoreError) {
//   ...
// }
```

Then modify OTP verification to skip Firestore check temporarily.

If the page loads now, the issue is definitely Firestore configuration.

---

## Next Steps

1. **Enable Firestore** in Firebase Console (Test mode)
2. **Run the app** with `flutter run`
3. **Try signup** and watch console logs
4. **Report back** what error messages you see

The logs will tell us exactly what's wrong!
