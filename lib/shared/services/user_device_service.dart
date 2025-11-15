import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to manage user-device associations in Firestore
/// Each user has a devices array containing their registered devices
class UserDeviceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's UID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Add a device to the current user's devices array in Firestore
  /// 
  /// Parameters:
  /// - deviceId: The unique ID of the device (UUID)
  /// - deviceName: The display name of the device
  /// - mqttId: The MQTT identifier (MAC address or ESP32 name)
  static Future<bool> addDeviceToUser({
    required String deviceId,
    required String deviceName,
    String? mqttId,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('❌ UserDeviceService: No user logged in');
        return false;
      }

      debugPrint('📝 UserDeviceService: Adding device to user $userId');
      debugPrint('   Device ID: $deviceId');
      debugPrint('   Device Name: $deviceName');
      debugPrint('   MQTT ID: $mqttId');

      // Check if user document exists, create if it doesn't
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        debugPrint('⚠️ UserDeviceService: User document does not exist, creating it...');
        await _firestore.collection('users').doc(userId).set({
          'email': _auth.currentUser?.email,
          'createdAt': FieldValue.serverTimestamp(),
          'devices': [],
        });
        debugPrint('✅ UserDeviceService: User document created');
      }

      // 🔥 Check if device with same MQTT ID already exists
      final data = userDoc.data();
      if (data != null && data.containsKey('devices')) {
        final List<dynamic> existingDevices = data['devices'] ?? [];
        for (var device in existingDevices) {
          if (device['mqttId'] == mqttId) {
            debugPrint('⚠️ UserDeviceService: Device with MQTT ID $mqttId already exists in Firestore');
            debugPrint('   Existing device: ${device['name']} (ID: ${device['deviceId']})');
            return false; // Don't add duplicate
          }
        }
      }

      // Add device to user's devices array
      // Note: Cannot use FieldValue.serverTimestamp() inside arrayUnion()
      // Use DateTime.now() instead
      await _firestore.collection('users').doc(userId).update({
        'devices': FieldValue.arrayUnion([
          {
            'deviceId': deviceId,
            'name': deviceName,
            'mqttId': mqttId ?? deviceName,
            'addedAt': DateTime.now().toIso8601String(), // Use ISO string instead of serverTimestamp
          }
        ])
      });

      debugPrint('✅ UserDeviceService: Device added to Firestore successfully');
      return true;
    } catch (e) {
      debugPrint('❌ UserDeviceService: Error adding device to user: $e');
      return false;
    }
  }

  /// Remove a device from the current user's devices array in Firestore
  /// 
  /// Parameters:
  /// - deviceId: The unique ID of the device to remove
  static Future<bool> removeDeviceFromUser(String deviceId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('❌ UserDeviceService: No user logged in');
        return false;
      }

      debugPrint('🗑️ UserDeviceService: Removing device $deviceId from user $userId');

      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('❌ UserDeviceService: User document not found');
        return false;
      }

      // Get current devices array
      final List<dynamic> devices = userDoc.data()?['devices'] ?? [];
      
      // Find and remove the device with matching deviceId
      final updatedDevices = devices.where((device) {
        return device['deviceId'] != deviceId;
      }).toList();

      // Update Firestore with new devices array
      await _firestore.collection('users').doc(userId).update({
        'devices': updatedDevices,
      });

      debugPrint('✅ UserDeviceService: Device removed from Firestore successfully');
      return true;
    } catch (e) {
      debugPrint('❌ UserDeviceService: Error removing device from user: $e');
      return false;
    }
  }

  /// Get all devices for the current user from Firestore
  /// 
  /// Returns: List of device maps or empty list if no user logged in
  static Future<List<Map<String, dynamic>>> getUserDevices() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('❌❌❌ UserDeviceService: No user logged in');
        return [];
      }

      print('📥📥📥 UserDeviceService: Loading devices for user $userId');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('❌❌❌ UserDeviceService: User document not found');
        return [];
      }

      final List<dynamic> devices = userDoc.data()?['devices'] ?? [];
      final deviceList = devices.map((device) => Map<String, dynamic>.from(device)).toList();

      print('✅✅✅ UserDeviceService: Loaded ${deviceList.length} devices');
      return deviceList;
    } catch (e) {
      print('❌❌❌ UserDeviceService: Error loading user devices: $e');
      return [];
    }
  }

  /// Check if a device belongs to the current user
  /// 
  /// Parameters:
  /// - deviceId: The unique ID of the device to check
  /// 
  /// Returns: true if device belongs to user, false otherwise
  static Future<bool> userOwnsDevice(String deviceId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return false;
      }

      final List<dynamic> devices = userDoc.data()?['devices'] ?? [];
      return devices.any((device) => device['deviceId'] == deviceId);
    } catch (e) {
      debugPrint('❌ UserDeviceService: Error checking device ownership: $e');
      return false;
    }
  }

  /// Check if a device with given MAC address already exists for current user
  /// 
  /// Parameters:
  /// - macAddress: The MAC address (mqttId) to check
  /// 
  /// Returns: true if MAC already registered, false otherwise
  static Future<bool> deviceMacExists(String macAddress) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('❌ UserDeviceService: No user logged in');
        return false;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return false;
      }

      final List<dynamic> devices = userDoc.data()?['devices'] ?? [];
      
      // Check if any device has matching mqttId (MAC address)
      final exists = devices.any((device) => device['mqttId'] == macAddress);
      
      if (exists) {
        debugPrint('⚠️ UserDeviceService: Device with MAC $macAddress already exists');
      }
      
      return exists;
    } catch (e) {
      debugPrint('❌ UserDeviceService: Error checking MAC existence: $e');
      return false;
    }
  }

  /// Update device name in Firestore
  /// 
  /// Parameters:
  /// - deviceId: The unique ID of the device
  /// - newName: The new name for the device
  static Future<bool> updateDeviceName(String deviceId, String newName) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('❌ UserDeviceService: No user logged in');
        return false;
      }

      debugPrint('✏️ UserDeviceService: Updating device name for $deviceId');

      // Get user document
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('❌ UserDeviceService: User document not found');
        return false;
      }

      // Get current devices array
      final List<dynamic> devices = userDoc.data()?['devices'] ?? [];
      
      // Update the device name
      final updatedDevices = devices.map((device) {
        if (device['deviceId'] == deviceId) {
          device['name'] = newName;
        }
        return device;
      }).toList();

      // Update Firestore with new devices array
      await _firestore.collection('users').doc(userId).update({
        'devices': updatedDevices,
      });

      debugPrint('✅ UserDeviceService: Device name updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ UserDeviceService: Error updating device name: $e');
      return false;
    }
  }
}
