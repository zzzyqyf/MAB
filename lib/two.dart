import 'package:flutter/material.dart';
import 'package:flutter_application_final/main.dart';
import 'package:flutter_application_final/test.dart';
import 'package:provider/provider.dart';

class DisplayDevicesPage extends StatelessWidget {
  const DisplayDevicesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final devices = Provider.of<DeviceManager>(context).devices;

    return Scaffold(
      appBar: AppBar(title: const Text('Display Devices')),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return ListTile(
            title: Text(device['name']),
            subtitle: Text('Status: ${device['status']}'),
          );
        },
      ),
    );
  }
}