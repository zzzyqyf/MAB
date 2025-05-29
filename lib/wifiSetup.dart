import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'WifiConnectPage.dart';  // Import the second screen

class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  _WifiPageState createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  List<WifiNetwork?> _wifiNetworks = [];

  Future<void> _scanWifi() async {
    List<WifiNetwork?>? networks = await WiFiForIoTPlugin.loadWifiList();
    setState(() {
      _wifiNetworks = networks ?? [];
    });
  }

  Future<void> _connectAndNavigate(String ssid) async {
    // Navigate to the loading page before attempting connection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WifiConnectPage(ssid: ssid),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scanWifi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Wi-Fi Networks")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Select a Wi-Fi Network to Connect',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _wifiNetworks.length,
                  itemBuilder: (context, index) {
                    String ssid = _wifiNetworks[index]?.ssid ?? "Unknown";
                    return ListTile(
                      title: Text(ssid),
                      onTap: () => _connectAndNavigate(ssid),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _scanWifi,
                child: const Text("Refresh Networks"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
