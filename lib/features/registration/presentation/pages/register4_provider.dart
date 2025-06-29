import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Project imports
import '../../../device_management/presentation/viewmodels/deviceManager.dart';
import 'registerFour.dart';

/// This is a wrapper class to ensure DeviceManager provider is available
/// to the Register4Widget even when navigating directly to it.
class Register4ProviderWidget extends StatelessWidget {
  final String id;

  const Register4ProviderWidget({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      // Get the existing DeviceManager from the provider tree
      final existingDeviceManager = Provider.of<DeviceManager>(context, listen: false);
      print("Register4ProviderWidget: DeviceManager provider found");
      
      // Use ChangeNotifierProvider.value to reuse the existing provider
      return ChangeNotifierProvider.value(
        value: existingDeviceManager,
        child: Register4Widget(id: id),
      );
    } catch (e) {
      print("Register4ProviderWidget ERROR: $e");
      
      // Fallback in case the provider is not available
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Provider Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Could not find DeviceManager. Please restart the app and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
