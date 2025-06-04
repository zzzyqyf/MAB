import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Project imports
import '../../features/device_management/presentation/viewmodels/deviceMnanger.dart';

class RemoveDevicePage extends StatelessWidget {
  const RemoveDevicePage({Key? key}) : super(key: key);




  @override
  Widget build(BuildContext context) {
    final devices = Provider.of<DeviceManager>(context).devices;

    return Scaffold(
      appBar: AppBar(title: const Text('Remove Devices')),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return ListTile(
            title: Text(device['name']),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Provider.of<DeviceManager>(context, listen: false)
                    .removeDevice(device['id']);
              },
            ),
          );
        },
      ),
    );
  }
}
