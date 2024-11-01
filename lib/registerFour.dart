import 'package:flutter/material.dart';
import 'dart:typed_data'; // Import for Uint8List
import 'dart:io'; // Import for RawDatagramSocket
import 'basePage.dart';
import 'buttom.dart';
import 'loadingO.dart';

class Register4Widget extends StatefulWidget {
  const Register4Widget({Key? key}) : super(key: key);

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

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> sendCredentials(String ssid, String password) async {
    try {
      // Create a UDP socket
      RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

      // Send SSID and password to the ESP32
      String credentials = '$ssid\n$password';
      socket.send(Uint8List.fromList(credentials.codeUnits),
       InternetAddress('192.168.4.1'), 1234); // Replace with your ESP32's AP IP and port

      // Close the socket after sending
      socket.close();

      // Provide user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Credentials sent successfully!')),
      );
    } catch (e) {
      // Handle error
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
        appBar: BasePage(
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
                    const Text(
                      'Fill in the Wi-Fi Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        letterSpacing: 0.0,
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
                        style: TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 300),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: ReusableBottomButton(
          buttonText: 'Save',
          padding: 16.0,
          fontSize: 18.0,
          onPressed: () {
            String ssid = _ssidController.text.trim();
            String password = _passwordController.text.trim();
            sendCredentials(ssid, password); // Send credentials to ESP32

            // Navigate to Loading screen (or other actions)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoadingWidget()),
            );
          },
        ),
      ),
    );
  }
}


/*
void loop() {
  // Check if there are any incoming packets
  int packetSize = udp.parsePacket();
  if (packetSize) {
    // Buffer to hold incoming data
    char incomingPacket[255];
    int len = udp.read(incomingPacket, 255);
    if (len > 0) {
      incomingPacket[len] = '\0'; // Null-terminate the string
      String credentials = String(incomingPacket);

      // Split credentials into SSID and password
      int separatorIndex = credentials.indexOf('\n');
      if (separatorIndex != -1) {
        String receivedSSID = credentials.substring(0, separatorIndex);
        String receivedPassword = credentials.substring(separatorIndex + 1);

        // Attempt to connect to Wi-Fi
        WiFi.begin(receivedSSID.c_str(), receivedPassword.c_str());
        Serial.println("Connecting to WiFi...");

        // Wait for connection
        while (WiFi.status() != WL_CONNECTED) {
          delay(1000);
          Serial.print(".");
        }
        
        // Print connected IP address
        Serial.println("\nConnected to WiFi!");
        Serial.print("IP Address: ");
        Serial.println(WiFi.localIP()); // Print the IP address after connection
      }
    }
  }
}
*/