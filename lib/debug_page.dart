import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'shared/services/user_device_service.dart';
import 'shared/services/TextToSpeech.dart';
import 'features/device_management/presentation/viewmodels/deviceManager.dart';

/// Debug page to check Firebase backend status
class DebugFirebasePage extends StatefulWidget {
  const DebugFirebasePage({Key? key}) : super(key: key);

  @override
  State<DebugFirebasePage> createState() => _DebugFirebasePageState();
}

class _DebugFirebasePageState extends State<DebugFirebasePage> {
  bool _isLoading = false;
  String _status = 'Not checked yet';
  List<String> _logs = [];
  
  User? _currentUser;
  DocumentSnapshot? _userDoc;
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _checkFirebase();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    debugPrint('🔍 DEBUG: $message');
  }

  Future<void> _checkFirebase() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _status = 'Checking...';
    });

    try {
      // 1. Check Firebase Auth
      _addLog('Checking Firebase Authentication...');
      _currentUser = FirebaseAuth.instance.currentUser;
      
      if (_currentUser == null) {
        _addLog('❌ No user logged in!');
        setState(() {
          _status = 'ERROR: Not logged in';
          _isLoading = false;
        });
        return;
      }
      
      _addLog('✅ User logged in: ${_currentUser!.email}');
      _addLog('   User ID: ${_currentUser!.uid}');

      // 2. Check Firestore Connection
      _addLog('Checking Firestore connection...');
      final firestore = FirebaseFirestore.instance;
      
      // 3. Check user document exists
      _addLog('Fetching user document from Firestore...');
      _userDoc = await firestore.collection('users').doc(_currentUser!.uid).get();
      
      if (!_userDoc!.exists) {
        _addLog('❌ User document does NOT exist in Firestore!');
        _addLog('   Creating user document...');
        
        // Create user document
        await firestore.collection('users').doc(_currentUser!.uid).set({
          'email': _currentUser!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'devices': [],
        });
        
        _addLog('✅ User document created successfully');
        
        // Fetch again
        _userDoc = await firestore.collection('users').doc(_currentUser!.uid).get();
      } else {
        _addLog('✅ User document exists in Firestore');
      }

      // 4. Check devices array
      final data = _userDoc!.data() as Map<String, dynamic>?;
      if (data == null) {
        _addLog('⚠️ User document has no data');
      } else {
        _addLog('📄 User document fields: ${data.keys.join(', ')}');
        
        if (data.containsKey('devices')) {
          final devicesData = data['devices'];
          _addLog('✅ Devices field exists (type: ${devicesData.runtimeType})');
          
          if (devicesData is List) {
            _addLog('✅ Devices is a List with ${devicesData.length} items');
            _devices = devicesData.cast<Map<String, dynamic>>();
            
            for (int i = 0; i < _devices.length; i++) {
              final device = _devices[i];
              _addLog('   Device $i:');
              _addLog('      ID: ${device['id']}');
              _addLog('      Name: ${device['name']}');
              _addLog('      MQTT ID: ${device['mqttId']}');
              _addLog('      Status: ${device['status'] ?? 'unknown'}');
            }
          }
        } else {
          _addLog('⚠️ No "devices" field in user document');
          _addLog('   Adding devices field...');
          
          await firestore.collection('users').doc(_currentUser!.uid).update({
            'devices': [],
          });
          
          _addLog('✅ Devices field added');
        }
      }

      // 5. Test UserDeviceService
      _addLog('Testing UserDeviceService.getUserDevices()...');
      final serviceDevices = await UserDeviceService.getUserDevices();
      _addLog('✅ UserDeviceService returned ${serviceDevices.length} devices');

      setState(() {
        _status = _devices.isEmpty 
            ? 'Backend OK - No devices registered yet' 
            : 'Backend OK - ${_devices.length} devices found';
        _isLoading = false;
      });

      TextToSpeech.speak(_status);

    } catch (e, stackTrace) {
      _addLog('❌ ERROR: $e');
      _addLog('Stack trace: $stackTrace');
      setState(() {
        _status = 'ERROR: $e';
        _isLoading = false;
      });
      TextToSpeech.speak('Error checking Firebase: $e');
    }
  }

  Future<void> _clearLocalCache() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _status = 'Clearing cache...';
    });

    try {
      _addLog('Starting local cache cleanup...');

      // Get device manager
      final deviceManager = Provider.of<DeviceManager>(context, listen: false);

      // 1. Check Hive before clearing
      final deviceBox = Hive.box('devices');
      final deviceCount = deviceBox.length;
      _addLog('📦 Found $deviceCount devices in Hive local cache');
      
      if (deviceCount > 0) {
        _addLog('   Device IDs in cache:');
        for (var key in deviceBox.keys) {
          final device = deviceBox.get(key);
          _addLog('   - $key: ${device['name']} (MQTT: ${device['mqttId']})');
        }
      }

      // 2. Clear Hive
      _addLog('🗑️ Clearing Hive local storage...');
      await deviceBox.clear();
      _addLog('✅ Hive cache cleared');

      // 3. Clean duplicates from Firebase
      _addLog('🧹 Cleaning duplicate devices from Firebase...');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          final List<dynamic> devices = userDoc.data()?['devices'] ?? [];
          _addLog('   Found ${devices.length} devices in Firebase');
          
          // Group devices by MQTT ID to find duplicates
          final Map<String, List<dynamic>> devicesByMqttId = {};
          for (var device in devices) {
            final mqttId = device['mqttId'] as String;
            devicesByMqttId.putIfAbsent(mqttId, () => []);
            devicesByMqttId[mqttId]!.add(device);
          }
          
          // Find duplicates
          final List<dynamic> uniqueDevices = [];
          int duplicatesRemoved = 0;
          for (var entry in devicesByMqttId.entries) {
            final mqttId = entry.key;
            final deviceList = entry.value;
            
            if (deviceList.length > 1) {
              _addLog('   ⚠️ Found ${deviceList.length} duplicates for MQTT ID: $mqttId');
              // Keep only the first one (most recent)
              uniqueDevices.add(deviceList.first);
              duplicatesRemoved += (deviceList.length - 1);
            } else {
              uniqueDevices.add(deviceList.first);
            }
          }
          
          if (duplicatesRemoved > 0) {
            // Update Firebase with cleaned devices list
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({'devices': uniqueDevices});
            _addLog('✅ Removed $duplicatesRemoved duplicate devices from Firebase');
          } else {
            _addLog('✅ No duplicates found in Firebase');
          }
        }
      }

      // 4. Reload from Firestore
      _addLog('☁️ Reloading devices from Firestore...');
      await deviceManager.loadUserDevicesFromFirestore();
      
      // 5. Verify
      final newDeviceCount = deviceBox.length;
      _addLog('✅ Devices reloaded from Firestore');
      _addLog('📊 Devices after reload: $newDeviceCount');

      if (newDeviceCount == 0) {
        _addLog('⚠️ No devices in Firestore - register a device first');
        setState(() {
          _status = 'Cache cleared - No devices in Firestore';
        });
      } else {
        _addLog('✅ Successfully synchronized $newDeviceCount unique devices');
        setState(() {
          _status = 'Cache cleared - Loaded $newDeviceCount devices';
        });
      }

      TextToSpeech.speak('Cleared cache and removed duplicates. Loaded $newDeviceCount devices from Firestore');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed duplicates → Loaded $newDeviceCount unique devices'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e, stackTrace) {
      _addLog('❌ ERROR: $e');
      _addLog('Stack trace: $stackTrace');
      setState(() {
        _status = 'ERROR: $e';
      });
      TextToSpeech.speak('Error clearing cache: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing cache: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              color: _status.contains('ERROR') 
                  ? Colors.red.shade50 
                  : _status.contains('OK') 
                      ? Colors.green.shade50 
                      : Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Icon(
                        _status.contains('ERROR') 
                            ? Icons.error 
                            : _status.contains('OK') 
                                ? Icons.check_circle 
                                : Icons.info,
                        color: _status.contains('ERROR') 
                            ? Colors.red 
                            : _status.contains('OK') 
                                ? Colors.green 
                                : Colors.grey,
                        size: 40,
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User Info
            if (_currentUser != null) ...[
              Text(
                'Logged in as:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Email: ${_currentUser!.email}'),
              Text('UID: ${_currentUser!.uid}'),
              const SizedBox(height: 16),
            ],
            
            // Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkFirebase,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearLocalCache,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear Cache'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Logs
            Text(
              'Debug Logs:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: log.contains('❌') 
                              ? Colors.red.shade300
                              : log.contains('✅') 
                                  ? Colors.green.shade300
                                  : log.contains('⚠️')
                                      ? Colors.orange.shade300
                                      : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
