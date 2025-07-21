import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Project imports
import '../../features/device_management/presentation/viewmodels/deviceManager.dart';

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