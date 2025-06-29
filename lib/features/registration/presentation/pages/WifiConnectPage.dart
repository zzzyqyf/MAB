import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';

// Project imports
import 'registerFour.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/Navbar.dart';
import '../../../profile/presentation/pages/ProfilePage.dart';
import '../../../notifications/presentation/pages/notification.dart';

class WifiConnectPage extends StatefulWidget {
  final String ssid;

  const WifiConnectPage({super.key, required this.ssid});

  @override
  _WifiConnectPageState createState() => _WifiConnectPageState();
}

class _WifiConnectPageState extends State<WifiConnectPage> {
  bool _isLoading = true;
  int _selectedIndex = 1; // WiFi Connect page is index 1

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate to Profile page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
      case 1:
        // Already on WiFi Connect page, do nothing
        break;
      case 2:
        // Navigate to Notifications page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationPage()),
        );
        break;
    }
  }

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
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to the Dashboard after successful connection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Register4Widget(id: '',),

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
              title: const Text("Connection Failed"),
              content: Text("Could not connect to ${widget.ssid}. Please try again."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Go back to the previous screen
                  },
                  child: const Text("OK"),
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
            title: const Text("Error"),
            content: Text("An error occurred: $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to the previous screen
                },
                child: const Text("OK"),
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
      appBar: const BasePage(
        title: "WiFi Connect",
        showBackButton: true,
      ),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      'Connecting to ${widget.ssid.isEmpty ? "WiFi" : widget.ssid}...',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to connect, try again!'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);  // Go back to the previous page
                      },
                      child: const Text('Back'),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
