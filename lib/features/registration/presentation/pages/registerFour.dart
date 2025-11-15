import 'package:flutter/material.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/services/bluetooth_provisioning_service.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/buttom.dart';
import 'registerOne.dart';
import 'registerFive.dart';

class Register4Widget extends StatefulWidget {
  final String id;
  const Register4Widget({Key? key, required this.id}) : super(key: key);

  @override
  State<Register4Widget> createState() => _Register4WidgetState();
}

class _Register4WidgetState extends State<Register4Widget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _passwordVisible = false;
  String? _errorMessage;
  bool _isScanning = false;
  bool _isSendingCredentials = false;
  
  BluetoothProvisioningService? _bluetoothService;
  
  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }
  
  Future<void> _initBluetooth() async {
    _bluetoothService = BluetoothProvisioningService();
    final initialized = await _bluetoothService!.initialize();
    
    if (!initialized && mounted) {
      setState(() {
        _errorMessage = _bluetoothService!.error ?? 'Failed to initialize Bluetooth';
      });
      TextToSpeech.speak(_errorMessage!);
    }
  }
  
  //get id => null;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _bluetoothService?.dispose();
    super.dispose();
  }

  Future<void> _scanAndConnectESP32() async {
    if (_bluetoothService == null) {
      setState(() {
        _errorMessage = 'Bluetooth service not initialized';
      });
      return;
    }
    
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });
    
    TextToSpeech.speak('Scanning for ESP32 devices');
    
    // Start scanning
    await _bluetoothService!.startScan(timeout: const Duration(seconds: 10));
    
    setState(() {
      _isScanning = false;
    });
    
    // Check if any devices found
    if (_bluetoothService!.discoveredDevices.isEmpty) {
      setState(() {
        _errorMessage = 'No ESP32 devices found. Make sure your device is powered on and in pairing mode.';
      });
      TextToSpeech.speak(_errorMessage!);
      return;
    }
    
    // Connect to first discovered device
    final device = _bluetoothService!.discoveredDevices.first;
    TextToSpeech.speak('Found device. Connecting...');
    
    final connected = await _bluetoothService!.connectToDevice(device);
    
    if (!connected && mounted) {
      setState(() {
        _errorMessage = _bluetoothService!.error ?? 'Failed to connect to device';
      });
      TextToSpeech.speak(_errorMessage!);
    }
  }

  Future<void> _sendWiFiCredentials() async {
    String ssid = _ssidController.text.trim();
    String password = _passwordController.text.trim();
    
    if (ssid.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter WiFi SSID';
      });
      TextToSpeech.speak(_errorMessage!);
      return;
    }
    
    if (_bluetoothService == null || !_bluetoothService!.isConnected) {
      // Need to scan and connect first
      await _scanAndConnectESP32();
      
      if (!_bluetoothService!.isConnected) {
        return; // Error already shown
      }
    }
    
    setState(() {
      _isSendingCredentials = true;
      _errorMessage = null;
    });
    
    TextToSpeech.speak('Sending WiFi credentials to device');
    
    // Send credentials via Bluetooth
    final success = await _bluetoothService!.sendWiFiCredentials(ssid, password);
    
    setState(() {
      _isSendingCredentials = false;
    });
    
    if (success) {
      TextToSpeech.speak('Credentials sent. Waiting for device to connect...');
      
      // Disconnect Bluetooth
      await _bluetoothService!.disconnect();
      
      // Navigate to waiting page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterFiveWidget(
              ssid: ssid,
            ),
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = _bluetoothService!.error ?? 'Failed to send credentials';
      });
      TextToSpeech.speak(_errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: BasePage(
          title: 'WiFi Setup via Bluetooth',
          showBackButton: true,
          onBackPressed: () {
            // Navigate back to previous registration step (Activate Device page)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Register2Widget()),
            );
          },
        ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 20.0, 15.0, 100.0), // Bottom padding for button
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Trigger text-to-speech when the text is tapped
                          TextToSpeech.speak('Enter your WiFi credentials below. The app will connect to your ESP32 device via Bluetooth and send the WiFi details automatically. There are two fields, WiFi name and password.');
                        },
                        child: const Text(
                          'Enter WiFi Credentials\n'
                          'Bluetooth will send them to ESP32',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                            letterSpacing: 0.0,
                        ),
                      ),
                      ),
                      const SizedBox(height: 20),
                      // SSID Field
                      TextFormField(
                        controller: _ssidController,
                        decoration: InputDecoration(
                          labelText: 'SSID',
                          labelStyle: const TextStyle(
                            color: Color(0xFF57636C),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFFE0E3E7), width: 2),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(24),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                            color: Color(0xFF57636C),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFFE0E3E7), width: 2),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(24),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFF57636C),
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                        ),
                        cursorColor: const Color.fromARGB(255, 60, 57, 239),
                      ),
                      const SizedBox(height: 10),
                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
              // The Save Button should be placed in the body of the widget tree
              Positioned(
                bottom: 20.0,
                left: 16.0,
                right: 16.0,
                child: ReusableBottomButton(
                  buttonText: 'Send via Bluetooth',
                  padding: 16.0,
                  fontSize: 18.0,
                  onPressed: () {
                    TextToSpeech.speak('Send via Bluetooth Button');
                  },
                  onDoubleTap: () async {
                    // Double tap action - send credentials via Bluetooth
                    await _sendWiFiCredentials();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}