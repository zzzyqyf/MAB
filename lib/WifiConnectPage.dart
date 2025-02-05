import 'package:flutter/material.dart';
import 'package:flutter_application_final/main.dart';
import 'package:flutter_application_final/registerFour.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'DashboardPage.dart';  // Replace with the actual path to your dashboard page

class WifiConnectPage extends StatefulWidget {
  final String ssid;

  WifiConnectPage({required this.ssid});

  @override
  _WifiConnectPageState createState() => _WifiConnectPageState();
}

class _WifiConnectPageState extends State<WifiConnectPage> {
  bool _isLoading = true;

  Future<void> _connectToWifi() async {
    try {
      // Use the connect method without the timeout parameter
      bool success = await WiFiForIoTPlugin.connect(
        widget.ssid,
        password: "",  // Leave password empty or provide if needed
        joinOnce: true, // Connect once
        withInternet: false, // Disable default internet connection management
      );

      if (success) {
        // Wait for a brief moment to simulate loading
        await Future.delayed(Duration(seconds: 2));

        // Navigate to the Dashboard after successful connection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Register4Widget(id: '',),

          ),
        );
      } else {
        // Show error message if connection fails
        setState(() {
          _isLoading = false;
        });

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Connection Failed"),
              content: Text("Could not connect to ${widget.ssid}. Please try again."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Go back to the previous screen
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle errors (e.g., permission issues, incorrect configurations)
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("An error occurred: $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to the previous screen
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _connectToWifi();  // Start connection when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connecting to Wi-Fi")),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator()  // Show a loading spinner while connecting
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Failed to connect, try again!'),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);  // Go back to the previous page
                      },
                      child: Text('Back'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
