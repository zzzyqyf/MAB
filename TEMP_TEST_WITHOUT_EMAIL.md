# Temporary Test Without Email (For Development Only)

If you want to test OTP flow without fixing EmailJS right now:

## Option 1: Always Return True (Skip Email)

In `lib/shared/services/email_service.dart`, temporarily change:

```dart
static Future<bool> sendOTP({
  required String email,
  required String otp,
}) async {
  print('⚠️ TESTING MODE: Email not actually sent');
  print('📧 OTP for $email is: $otp');
  print('⚠️ Check console for OTP code!');
  return true; // Always return success
}
```

Then the OTP will be printed in the console, and you can copy it from there!

## Option 2: Use Fixed OTP for Testing

Change to always use "123456":

```dart
static String generateOTP() {
  return '123456'; // Fixed OTP for testing
}
```

**Remember to revert these changes before production!**
