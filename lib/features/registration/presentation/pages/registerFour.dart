import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data'; // Import for Uint8List
import 'dart:io'; // Import for RawDatagramSocket

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../device_management/presentation/viewmodels/deviceMnanger.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/buttom.dart';
//import 'test.dart'; // Import your DeviceManager

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
  
  //get id => null;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> sendCredentials(String ssid, String password) async {
    try {
      print("Attempting to send credentials: SSID = $ssid, Password = $password");  // Debug print

      // Create a UDP socket
      RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      print("Socket created");  // Debug print to check socket creation

      // Prepare SSID and password to send
      String credentials = '$ssid\n$password';
      socket.send(Uint8List.fromList(credentials.codeUnits), InternetAddress('192.168.4.1'), 8080); // Replace with ESP32's AP IP and port
      print("Credentials sent to ESP32");  // Debug print to confirm sending

      // Close the socket after sending
      socket.close();
      print("Socket closed after sending");  // Debug print to confirm socket closure

      // Show success message only if credentials are sent successfully
      ScaffoldMessenger.of(context).showSnackBar(
        
        const SnackBar(content: Text('Credentials sent successfully! ESP32 will now try to connect.')),
        
      );
    } catch (e) {
      print("Error sending credentials: $e");  // Debug error
      // Handle error and display error message
      setState(() {
        _errorMessage = 'Failed to send credentials: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: const BasePage(
          title: 'Connect to Wifi',
          showBackButton: true,
        ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 20.0, 15.0, 5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Trigger text-to-speech when the text is tapped
                        TextToSpeech.speak('Fill in the Wi-Fi Details below there are two fields wifi name and password');
                      },
                      child: const Text(
                        'Fill in the Wi-Fi Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                          letterSpacing: 0.0,
                      ),
                    ),
                    ),
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
                    const SizedBox(height: 300),
                  ],
                ),
              ),
              // The Save Button should be placed in the body of the widget tree
              Positioned(
                bottom: 20.0,
                left: 16.0,
                right: 16.0,
                child: ReusableBottomButton(
                  buttonText: 'Save',
                  padding: 16.0,
                  fontSize: 18.0,
                onPressed: () async {
  // Retrieve SSID and password
            TextToSpeech.speak('Save Button');

},
onDoubleTap: () async{
    // Double tap action
    String ssid = _ssidController.text.trim();
  String password = _passwordController.text.trim();

  // Send credentials to ESP32
  await sendCredentials(ssid, password);

  // Access DeviceManager
  final deviceManager = Provider.of<DeviceManager>(context, listen: false);

  // Check if the device already exists by its ID
  final existingDevice = deviceManager.getDeviceById(widget.id);

  if (existingDevice != null) {
    print("Device ID '${widget.id}' exists for device '$ssid': $existingDevice");
  } else {
    print("Device ID '${widget.id}' does not exist. Adding a new device.");
    // Add the device if not found
    deviceManager.addDevice(widget.id); // Use SSID as the name for the new device
  }

  // Navigate to the next screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) =>const MyApp(),

//MaterialPageRoute(builder: (context) => NameWidget(deviceId: widget.id),
),  
);
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