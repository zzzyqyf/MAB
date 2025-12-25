import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/services/device_registration_service.dart';
import '../../../../shared/services/user_device_service.dart';
import '../../../device_management/presentation/viewmodels/deviceManager.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/buttom.dart';
import '../../../../main.dart';

class RegisterFiveWidget extends StatefulWidget {
  final String ssid;
  
  const RegisterFiveWidget({
    Key? key,
    required this.ssid,
  }) : super(key: key);

  @override
  State<RegisterFiveWidget> createState() => _RegisterFiveWidgetState();
}

class _RegisterFiveWidgetState extends State<RegisterFiveWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  DeviceRegistrationService? _registrationService;
  StreamSubscription? _registrationSubscription;
  
  bool _isWaiting = true;
  bool _isSuccess = false;
  String _statusMessage = 'Waiting for device to connect to WiFi and register...';
  String? _errorMessage;
  
  Timer? _timeoutWarningTimer;
  int _elapsedSeconds = 0;
  
  @override
  void initState() {
    super.initState();
    _startListeningForRegistration();
    _startElapsedTimer();
  }
  
  void _startElapsedTimer() {
    _timeoutWarningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }
  
  Future<void> _startListeningForRegistration() async {
    _registrationService = DeviceRegistrationService();
    
    // Start listening for registration messages
    final started = await _registrationService!.startListening();
    
    if (!started) {
      if (mounted) {
        setState(() {
          _errorMessage = _registrationService!.error ?? 'Failed to start listening for device';
          _isWaiting = false;
        });
        TextToSpeech.speak(_errorMessage!);
      }
      return;
    }
    
    // Listen to registration stream
    _registrationSubscription = _registrationService!.onDeviceRegistered.listen(
      _handleDeviceRegistration,
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error receiving registration: $error';
            _isWaiting = false;
          });
          TextToSpeech.speak(_errorMessage!);
        }
      },
    );
    
    TextToSpeech.speak('Listening for device registration. This may take up to one minute.');
  }
  
  Future<void> _handleDeviceRegistration(DeviceRegistrationData registration) async {
    debugPrint('📱 RegisterFive: Received device registration');
    debugPrint('   MAC: ${registration.macAddress}');
    debugPrint('   Name: ${registration.deviceName}');
    
    setState(() {
      _statusMessage = 'Device found! Adding to your account...';
    });
    
    TextToSpeech.speak('Device found. Adding to your account.');
    
    // Check if device already exists
    final alreadyExists = await _checkIfDeviceExists(registration.macAddress);
    
    if (alreadyExists) {
      setState(() {
        _errorMessage = 'This device is already registered to your account';
        _isWaiting = false;
      });
      TextToSpeech.speak(_errorMessage!);
      return;
    }
    
    // Add device to user's account
    final success = await _addDeviceToAccount(registration);
    
    if (success) {
      setState(() {
        _isSuccess = true;
        _isWaiting = false;
        _statusMessage = 'Device added successfully!';
      });
      TextToSpeech.speak('Device added successfully');
      
      // Wait a moment then navigate to home
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage(title: 'PlantCare Hubs')),
          (route) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage = '';
        _isWaiting = false;
      });
      TextToSpeech.speak(_errorMessage!);
    }
  }
  
  Future<bool> _checkIfDeviceExists(String macAddress) async {
    try {
      final devices = await UserDeviceService.getUserDevices();
      return devices.any((device) => device['mqttId'] == macAddress);
    } catch (e) {
      debugPrint('❌ Error checking device existence: $e');
      return false;
    }
  }
  
  Future<bool> _addDeviceToAccount(DeviceRegistrationData registration) async {
    try {
      final deviceManager = Provider.of<DeviceManager>(context, listen: false);
      
      // Generate UUID for internal device ID
      final uuid = const Uuid();
      final deviceId = uuid.v4();
      
      // Use MAC address as mqttId (remove colons if present)
      final mqttId = registration.macAddress.replaceAll(':', '');
      
      debugPrint('🔄 RegisterFive: Starting device registration...');
      debugPrint('   Device ID: $deviceId');
      debugPrint('   Device Name: ${registration.deviceName}');
      debugPrint('   MQTT ID: $mqttId');
      
      // Add device to DeviceManager (this also adds to Firestore via UserDeviceService)
      // Now properly await the async operation
      final success = await deviceManager.addDeviceWithId(
        deviceId,
        registration.deviceName,
        mqttId,
      );
      
      if (success) {
        debugPrint('✅ Device registration completed successfully: ID=$deviceId, Name=${registration.deviceName}, MAC=$mqttId');
      } else {
        debugPrint('❌ Device registration failed: ID=$deviceId');
      }
      
      return success;
      
    } catch (e) {
      debugPrint('❌ Error adding device: $e');
      return false;
    }
  }
  
  void _cancelRegistration() {
    TextToSpeech.speak('Cancelling device registration');
    
    // Stop listening
    _registrationSubscription?.cancel();
    _registrationService?.stopListening();
    _timeoutWarningTimer?.cancel();
    
    // Navigate back
    Navigator.of(context).pop();
  }
  
  @override
  void dispose() {
    _registrationSubscription?.cancel();
    _registrationService?.stopListening();
    _registrationService?.dispose();
    _timeoutWarningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _cancelRegistration();
        return false;
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: BasePage(
          title: 'Device Registration',
          showBackButton: false, // Prevent accidental back
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Icon
                if (_isWaiting)
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                else if (_isSuccess)
                  const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  )
                else
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                
                const SizedBox(height: 32),
                
                // Status Message
                GestureDetector(
                  onTap: () {
                    TextToSpeech.speak(_errorMessage ?? _statusMessage);
                  },
                  child: Text(
                    _errorMessage ?? _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _errorMessage != null ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Elapsed Time
                if (_isWaiting)
                  Text(
                    'Elapsed time: $_elapsedSeconds seconds',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Instructions
                if (_isWaiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Make sure your ESP32 device is powered on and attempting to connect to the WiFi network.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 48),
                
                // Action Buttons
                if (_isWaiting)
                  ReusableBottomButton(
                    buttonText: 'Cancel',
                    padding: 16.0,
                    fontSize: 18.0,
                    onPressed: () {
                      TextToSpeech.speak('Cancel');
                    },
                    onDoubleTap: _cancelRegistration,
                  )
                else if (!_isSuccess)
                  Column(
                    children: [
                      ReusableBottomButton(
                        buttonText: 'Try Again',
                        padding: 16.0,
                        fontSize: 18.0,
                        onPressed: () {
                          TextToSpeech.speak('Try Again');
                        },
                        onDoubleTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const MyHomePage(title: 'PlantCare Hubs')),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Go to Home',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
