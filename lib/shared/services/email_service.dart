import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Email service for sending OTP emails using EmailJS
class EmailService {
  // EmailJS credentials - REPLACE THESE WITH YOUR OWN
  static const String _serviceId = 'service_mgbf4rh'; // Get from emailjs.com
  static const String _templateId = 'template_5p0feyk'; // Get from emailjs.com
  static const String _publicKey = '5c4uojOOAWi5wQPY4'; // Get from emailjs.com
  
  static const String _privateKey = 'jsYdnxdsYFV7uwpV7k9v1'; // ← REPLACE THIS
  static const String _emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Generate a 6-digit OTP
  static String generateOTP() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }

  /// Send OTP to email address
  /// Returns true if email sent successfully, false otherwise
  static Future<bool> sendOTP({
    required String email,
    required String otp,
  }) async {
    try {
      print('📧 Attempting to send OTP email...');
      print('📧 To: $email');
      print('📧 OTP: $otp');
      print('📧 Service ID: $_serviceId');
      print('📧 Template ID: $_templateId');
      print('📧 Public Key: $_publicKey');
      
      final requestBody = {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'accessToken': _privateKey, // ← ADD THIS LINE for private key authentication
        'template_params': {
          'to_email': email,
          'otp_code': otp,
          'app_name': 'MAB - Mushroom Agriculture',
          'message': 'Your verification code is: $otp',
        },
      };
      
      print('📧 Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('📧 Response status: ${response.statusCode}');
      print('📧 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ OTP email sent successfully to $email');
        return true;
      } else {
        print('❌ Failed to send OTP email: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending OTP email: $e');
      print('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Store OTP in Firestore with expiration time
  static Future<void> storeOTP({
    required String email,
    required String otp,
  }) async {
    try {
      print('🔄 Attempting to store OTP in Firestore for $email');
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));
      
      await FirebaseFirestore.instance
          .collection('otp_verification')
          .doc(email.toLowerCase())
          .set({
        'otp': otp,
        'email': email.toLowerCase(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
      });
      
      print('✅ OTP stored in Firestore for $email');
      print('✅ OTP value: $otp');
    } catch (e) {
      print('❌ Error storing OTP: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Full error: $e');
      rethrow;
    }
  }

  /// Verify OTP from user input
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String inputOtp,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('otp_verification')
          .doc(email.toLowerCase())
          .get();

      if (!doc.exists) {
        return {
          'success': false,
          'message': 'No OTP found for this email. Please request a new one.',
        };
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final verified = data['verified'] as bool;

      // Check if already verified
      if (verified) {
        return {
          'success': false,
          'message': 'This OTP has already been used.',
        };
      }

      // Check if expired
      if (DateTime.now().isAfter(expiresAt)) {
        return {
          'success': false,
          'message': 'OTP has expired. Please request a new one.',
        };
      }

      // Verify OTP
      if (storedOtp == inputOtp) {
        // Mark as verified
        await doc.reference.update({'verified': true});
        
        return {
          'success': true,
          'message': 'Email verified successfully!',
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid OTP. Please try again.',
        };
      }
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Error verifying OTP. Please try again.',
      };
    }
  }

  /// Delete OTP document after successful registration
  static Future<void> deleteOTP(String email) async {
    try {
      await FirebaseFirestore.instance
          .collection('otp_verification')
          .doc(email.toLowerCase())
          .delete();
      print('✅ OTP document deleted for $email');
    } catch (e) {
      print('❌ Error deleting OTP: $e');
    }
  }

  /// Clean up expired OTPs (can be called periodically or use Firebase Functions)
  static Future<void> cleanupExpiredOTPs() async {
    try {
      final now = Timestamp.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('otp_verification')
          .where('expiresAt', isLessThan: now)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Cleaned up ${snapshot.docs.length} expired OTPs');
    } catch (e) {
      print('❌ Error cleaning up OTPs: $e');
    }
  }
}
