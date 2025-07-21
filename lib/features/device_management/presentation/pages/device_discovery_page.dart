import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

// Shared imports
import '../../../../shared/services/device_discovery_service.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/app_button.dart';

// Project imports
import '../viewmodels/deviceManager.dart';

class DeviceDiscoveryPage extends StatefulWidget {
  const DeviceDiscoveryPage({Key? key}) : super(key: key);

  @override
  State<DeviceDiscoveryPage> createState() => _DeviceDiscoveryPageState();
}

class _DeviceDiscoveryPageState extends State<DeviceDiscoveryPage> {
  bool _isScanning = false;
  List<DeviceInfo> _discoveredDevices = [];

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isScanning = true;
    });

    final deviceManager = Provider.of<DeviceManager>(context, listen: false);
    final discoveryService = deviceManager.discoveryService;
    
    if (discoveryService != null) {
      // Listen to discovered devices
      discoveryService.deviceRegistered.listen((deviceInfo) {
        if (mounted) {
          setState(() {
            if (!_discoveredDevices.any((d) => d.deviceId == deviceInfo.deviceId)) {
              _discoveredDevices.add(deviceInfo);
            }
          });
        }
      });

      // Start discovery
      await discoveryService.discoverDevices();
      
      // Stop scanning after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }
      });
    }
  }

  Future<void> _addDevice(DeviceInfo deviceInfo) async {
    final deviceManager = Provider.of<DeviceManager>(context, listen: false);
    
    try {
      // Add device to device manager
      deviceManager.addDeviceWithId(deviceInfo.deviceId, deviceInfo.deviceName, deviceInfo.deviceId);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device ${deviceInfo.deviceName} added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add device: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BasePage(
        title: 'Discover Devices',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.getResponsivePadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'ESP32 Device Discovery',
                style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppDimensions.spacing8),
              Text(
                'Searching for ESP32 devices on your network...',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppDimensions.spacing24),

              // Scanning indicator
              if (_isScanning) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppDimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      SizedBox(width: AppDimensions.spacing12),
                      Text(
                        'Scanning for devices...',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimensions.spacing24),
              ],

              // Discovered devices list
              Text(
                'Discovered Devices (${_discoveredDevices.length})',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppDimensions.spacing16),

              Expanded(
                child: _discoveredDevices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _discoveredDevices.length,
                        itemBuilder: (context, index) {
                          final device = _discoveredDevices[index];
                          return _buildDeviceCard(device);
                        },
                      ),
              ),

              // Actions
              SizedBox(height: AppDimensions.spacing16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Refresh',
                      onPressed: _isScanning ? null : _startDiscovery,
                      type: AppButtonType.secondary,
                      icon: Icons.refresh,
                    ),
                  ),
                  SizedBox(width: AppDimensions.spacing12),
                  Expanded(
                    child: AppButton(
                      text: 'Manual Add',
                      onPressed: () => _showManualAddDialog(),
                      type: AppButtonType.primary,
                      icon: Icons.add,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: AppColors.onSurfaceVariant,
          ),
          SizedBox(height: AppDimensions.spacing16),
          Text(
            _isScanning ? 'Searching for devices...' : 'No devices found',
            style: AppTextStyles.textTheme.titleMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppDimensions.spacing8),
          Text(
            _isScanning 
                ? 'Make sure your ESP32 devices are powered on and connected to the same network.'
                : 'Make sure your ESP32 devices are online and try refreshing.',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(DeviceInfo device) {
    final deviceManager = Provider.of<DeviceManager>(context);
    final isAlreadyAdded = deviceManager.devices.any((d) => d['id'] == device.deviceId);

    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.spacing12),
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: deviceManager.discoveryService?.isDeviceOnline(device.deviceId) == true
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
                SizedBox(width: AppDimensions.spacing8),
                Expanded(
                  child: Text(
                    device.deviceName,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isAlreadyAdded)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing8,
                      vertical: AppDimensions.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Text(
                      'Added',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppDimensions.spacing8),
            Text(
              'Device ID: ${device.deviceId}',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (device.location.isNotEmpty && device.location != 'Unknown') ...[
              SizedBox(height: AppDimensions.spacing4),
              Text(
                'Location: ${device.location}',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: AppDimensions.spacing4),
            Text(
              'Firmware: ${device.firmware}',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppDimensions.spacing4),
            Text(
              'Capabilities: ${device.capabilities.join(', ')}',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppDimensions.spacing12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: isAlreadyAdded ? 'Already Added' : 'Add Device',
                onPressed: isAlreadyAdded ? null : () => _addDevice(device),
                type: isAlreadyAdded ? AppButtonType.secondary : AppButtonType.primary,
                size: AppButtonSize.small,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualAddDialog() {
    final deviceIdController = TextEditingController();
    final deviceNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add Device Manually',
            style: AppTextStyles.textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deviceIdController,
                decoration: const InputDecoration(
                  labelText: 'Device ID',
                  hintText: 'e.g., ESP32_001',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: AppDimensions.spacing16),
              TextField(
                controller: deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'e.g., Greenhouse Monitor 1',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            AppButton(
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
              type: AppButtonType.secondary,
              size: AppButtonSize.small,
            ),
            AppButton(
              text: 'Add',
              onPressed: () {
                if (deviceIdController.text.isNotEmpty && deviceNameController.text.isNotEmpty) {
                  final deviceManager = Provider.of<DeviceManager>(context, listen: false);
                  deviceManager.addDeviceWithId(deviceIdController.text, deviceNameController.text, deviceIdController.text);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Close discovery page too
                }
              },
              type: AppButtonType.primary,
              size: AppButtonSize.small,
            ),
          ],
        );
      },
    );
  }
}
