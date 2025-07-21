
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Project imports
import '../../features/device_management/presentation/viewmodels/deviceManager.dart';


//import 'test.dart';

class AddDevicePage extends StatelessWidget {
  const AddDevicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Device')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Provider.of<DeviceManager>(context, listen: false)
                      .removeDevice(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Device'),
            ),
          ],
        ),
      ),
    );
  }
}