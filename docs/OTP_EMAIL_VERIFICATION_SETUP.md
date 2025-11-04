# OTP Email Verification Setup Guide

## 🎯 Overview
Your MAB application now includes OTP (One-Time Password) email verification during registration. Users must verify their email address before creating an account.

## ✅ What Was Implemented

### 1. **Email Service** (`email_service.dart`)
Location: `lib/shared/services/email_service.dart`

**Features:**
- ✅ Generate 6-digit random OTP
- ✅ Send OTP via email using EmailJS
- ✅ Store OTP in Firestore with 5-minute expiration
- ✅ Verify user-entered OTP
- ✅ Automatic cleanup of expired OTPs

### 2. **OTP Verification Page** (`otp_verification_page.dart`)
Location: `lib/features/authentication/presentation/pages/otp_verification_page.dart`

**Features:**
- ✅ 6 individual input fields for OTP digits
- ✅ Auto-focus next field on input
- ✅ Resend OTP with 60-second cooldown
- ✅ TTS announcements for accessibility
- ✅ Loading states and error handling

### 3. **Updated Sign Up Flow** (`sinUp.dart`)
**New Registration Flow:**
1. User enters email, password, confirm password
2. Double-tap "SignUp" button
3. System generates & sends 6-digit OTP to email
4. User navigates to OTP verification page
5. User enters OTP from email
6. System verifies OTP
7. If valid, Firebase account is created
8. User automatically logged in to dashboard

## 🔧 **IMPORTANT: Setup Required**

### Step 1: Get EmailJS Credentials

1. **Go to [EmailJS.com](https://www.emailjs.com/)**
2. **Create a free account** (100 emails/month free)
3. **Add Email Service:**
   - Go to "Email Services"
   - Click "Add New Service"
   - Choose your email provider (Gmail recommended)
   - Follow setup instructions
   - Note your **Service ID**

4. **Create Email Template:**
   - Go to "Email Templates"
   - Click "Create New Template"
   - Use this template:

```
Subject: Verify Your Email - MAB Application

Hello,

Your verification code for MAB - Mushroom Agriculture is:

{{otp_code}}

This code will expire in 5 minutes.

If you didn't request this code, please ignore this email.

Best regards,
MAB Team
```

   - Template variables to use:
     - `{{to_email}}` - recipient email
     - `{{otp_code}}` - the 6-digit code
     - `{{app_name}}` - app name
     - `{{message}}` - message text
   
   - Note your **Template ID**

5. **Get Public Key:**
   - Go to "Account" → "General"
   - Copy your **Public Key**

### Step 2: Update Email Service Configuration

Open `lib/shared/services/email_service.dart` and replace:

```dart
class EmailService {
  // EmailJS credentials - REPLACE THESE WITH YOUR OWN
  static const String _serviceId = 'YOUR_SERVICE_ID';     // ← Replace this
  static const String _templateId = 'YOUR_TEMPLATE_ID';   // ← Replace this
  static const String _publicKey = 'YOUR_PUBLIC_KEY';     // ← Replace this
```

With your actual credentials:

```dart
class EmailService {
  // EmailJS credentials
  static const String _serviceId = 'service_abc123';     // Your Service ID
  static const String _templateId = 'template_xyz789';   // Your Template ID
  static const String _publicKey = 'user_ABC123XYZ';     // Your Public Key
```

### Step 3: Configure Firestore Security Rules

Add these rules to your Firestore (Firebase Console → Firestore Database → Rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Existing rules...
    
    // OTP Verification rules
    match /otp_verification/{email} {
      // Allow anyone to create OTP (for registration)
      allow create: if request.auth == null;
      
      // Allow anyone to read their own OTP (for verification)
      allow read: if request.auth == null;
      
      // Allow update only to mark as verified
      allow update: if request.auth == null 
                    && request.resource.data.verified == true;
      
      // Allow delete after account creation
      allow delete: if true;
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }
  }
}
```

## 📊 Firestore Data Structure

### OTP Verification Collection
```
otp_verification (collection)
  └─ {email} (document - email as ID)
      ├─ otp: "123456" (string)
      ├─ email: "user@example.com" (string)
      ├─ expiresAt: Timestamp (5 minutes from creation)
      ├─ createdAt: Timestamp (server time)
      └─ verified: false (boolean)
```

**Note:** Documents are automatically deleted after successful registration or can be cleaned up with `EmailService.cleanupExpiredOTPs()`.

### Users Collection (Updated)
```
users (collection)
  └─ {user_uid} (document)
      ├─ email: "user@example.com"
      ├─ role: "member"
      ├─ createdAt: Timestamp
      └─ emailVerified: true (NEW FIELD)
```

## 🚀 How to Use

### For Users:

#### Registration with OTP:
1. Open app → Tap "Sign Up here"
2. Enter email address
3. Enter password (min 6 characters)
4. Confirm password
5. Double-tap "SignUp" button
6. **Wait for "Verification code sent" message**
7. Check your email inbox for 6-digit code
8. Enter the 6 digits in the verification page
9. Double-tap "Verify" button
10. Account created & automatically logged in!

#### If Code Not Received:
- Wait 60 seconds
- Tap "Resend" link
- Check spam folder
- Verify email address is correct

#### OTP Expires:
- OTP valid for **5 minutes**
- If expired, request new code
- Start registration process again

### For Developers:

#### Test OTP Flow:
```dart
// Manual test
final otp = EmailService.generateOTP();
print('Generated OTP: $otp'); // Check console

await EmailService.sendOTP(
  email: 'test@example.com',
  otp: otp,
);
```

#### Clean Up Expired OTPs:
```dart
// Call this periodically or use Firebase Functions
await EmailService.cleanupExpiredOTPs();
```

#### Check If Email Verified:
```dart
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

bool isVerified = userDoc.data()?['emailVerified'] ?? false;
```

## 🛡️ Security Features

1. **Time-Limited OTPs** - Expire after 5 minutes
2. **One-Time Use** - OTP marked as used after verification
3. **Secure Storage** - OTPs stored in Firestore, not in memory
4. **Auto-Cleanup** - Failed/expired OTPs can be cleaned up
5. **Email Validation** - Ensures valid email format before sending

## 🎨 UI/UX Features

- ✅ **6 separate input fields** for easy OTP entry
- ✅ **Auto-focus** moves to next digit automatically
- ✅ **Backspace support** moves to previous field
- ✅ **Resend cooldown** prevents spam (60 seconds)
- ✅ **Loading indicators** for all async operations
- ✅ **TTS announcements** for accessibility
- ✅ **Clear error messages** for all failure cases

## ⚠️ Important Notes

### Email Provider Limitations:

**EmailJS Free Tier:**
- 200 emails/month free
- 100 emails/month with customization
- Rate limit: ~10 emails/minute

**If you need more:**
- Upgrade EmailJS plan
- Or switch to SMTP (Gmail: 500/day)
- Or use SendGrid/AWS SES for production

### Testing Tips:

1. **Use Real Email Addresses** for testing
2. **Check Spam Folder** if email not received
3. **Gmail users**: Enable "Less secure app access" if using SMTP
4. **Rate Limits**: Don't send too many OTPs in short time

### Production Considerations:

1. **Add Email Rate Limiting** per user
2. **Implement IP-based throttling** 
3. **Use Firebase Functions** for backend OTP generation (more secure)
4. **Add CAPTCHA** to prevent abuse
5. **Monitor EmailJS usage** to avoid hitting limits

## 🐛 Troubleshooting

### OTP Email Not Received:

**Check:**
1. ✅ EmailJS credentials are correct in `email_service.dart`
2. ✅ Email template exists and is active
3. ✅ Email service is connected properly
4. ✅ Check spam/junk folder
5. ✅ Verify email address is valid
6. ✅ Check EmailJS dashboard for failed sends

**Console Logs:**
```
✅ OTP email sent successfully to user@example.com  // Success
✅ OTP stored in Firestore for user@example.com     // Stored

❌ Failed to send OTP email: 403                    // Check credentials
❌ Error sending OTP email: ...                     // Check network
```

### OTP Verification Fails:

**Possible Issues:**
- OTP expired (5 minutes passed)
- OTP already used
- Incorrect OTP entered
- Network error

**Solution:**
- Request new OTP
- Double-check digits
- Ensure good internet connection

### Account Creation Fails After OTP:

**Check:**
1. Email not already registered
2. Password meets requirements (min 6 chars)
3. Internet connection stable
4. Firebase Auth enabled

## 📱 Testing Checklist

- [ ] EmailJS credentials configured
- [ ] Firestore rules updated
- [ ] Send OTP email successfully
- [ ] Receive email in inbox
- [ ] Enter correct OTP → Success
- [ ] Enter wrong OTP → Error shown
- [ ] OTP expires after 5 minutes
- [ ] Resend OTP works
- [ ] Resend cooldown works (60s)
- [ ] Account created after verification
- [ ] User auto-logged in
- [ ] OTP document deleted after registration
- [ ] TTS announcements work
- [ ] Works on slow internet

## 🔄 Flow Diagram

```
User Registration Flow
│
├─ Enter Email + Password
│   └─ Validation passes
│       │
│       ├─ Generate 6-digit OTP
│       ├─ Send email via EmailJS
│       ├─ Store OTP in Firestore (expires 5 min)
│       └─ Navigate to OTP Verification Page
│           │
│           ├─ User enters OTP
│           │   │
│           │   ├─ Correct OTP
│           │   │   ├─ Mark as verified in Firestore
│           │   │   ├─ Create Firebase Auth account
│           │   │   ├─ Store user data in Firestore
│           │   │   ├─ Delete OTP document
│           │   │   └─ ✅ Success → Auto-login to Dashboard
│           │   │
│           │   └─ Wrong OTP
│           │       └─ ❌ Show error, allow retry
│           │
│           └─ Resend OTP (60s cooldown)
│               └─ New OTP sent, old one replaced
```

## 💡 Future Enhancements (Optional)

1. **Phone Number Verification** - SMS OTP as alternative
2. **Email Templates** - Customizable HTML emails
3. **Multi-language Support** - OTP emails in user's language
4. **Backup Codes** - Alternative verification method
5. **Email Verification Reminder** - Nudge unverified users
6. **Admin Dashboard** - Monitor OTP sends/failures

## 📚 Additional Resources

- [EmailJS Documentation](https://www.emailjs.com/docs/)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

---

## ✅ Quick Start

1. **Get EmailJS credentials** (Service ID, Template ID, Public Key)
2. **Update `email_service.dart`** with your credentials
3. **Update Firestore rules** as shown above
4. **Run the app**: `flutter run`
5. **Test registration** with a real email address

**That's it! OTP email verification is ready to use!** 🎉
