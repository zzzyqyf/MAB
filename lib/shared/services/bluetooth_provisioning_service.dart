import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service for provisioning ESP32 devices via Bluetooth Low Energy (BLE)
/// Handles scanning, connecting, and sending WiFi credentials
class BluetoothProvisioningService extends ChangeNotifier {
  // BLE Service and Characteristic UUIDs (must match ESP32 code)
  static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String wifiCharacteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  
  // Connection state
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  String? _error;
  
  // Discovered devices
  final List<BluetoothDevice> _discoveredDevices = [];
  
  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  String? get error => _error;
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  BluetoothDevice? get connectedDevice => _connectedDevice;
  
  /// Initialize Bluetooth adapter
  Future<bool> initialize() async {
    try {
      debugPrint('🔵 BluetoothProvisioningService: Initializing...');
      
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        _error = 'Bluetooth not supported on this device';
        debugPrint('❌ BluetoothProvisioningService: $_error');
        notifyListeners();
        return false;
      }
      
      // Check if Bluetooth is turned on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _error = 'Please turn on Bluetooth';
        debugPrint('❌ BluetoothProvisioningService: $_error');
        notifyListeners();
        return false;
      }
      
      debugPrint('✅ BluetoothProvisioningService: Initialized successfully');
      return true;
    } catch (e) {
      _error = 'Failed to initialize Bluetooth: $e';
      debugPrint('❌ BluetoothProvisioningService: $_error');
      notifyListeners();
      return false;
    }
  }
  
  /// Scan for ESP32 devices advertising the provisioning service
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    try {
      debugPrint('🔍 BluetoothProvisioningService: Starting scan...');
      
      _isScanning = true;
      _discoveredDevices.clear();
      _error = null;
      notifyListeners();
      
      // Start scanning with service UUID filter
      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUUID)],
        timeout: timeout,
      );
      
      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Add unique devices only
          if (!_discoveredDevices.any((d) => d.remoteId == result.device.remoteId)) {
            debugPrint('📱 BluetoothProvisioningService: Found device: ${result.device.platformName}');
            _discoveredDevices.add(result.device);
            notifyListeners();
          }
        }
      });
      
      // Wait for scan to complete
      await Future.delayed(timeout);
      
      // Stop scan
      await FlutterBluePlus.stopScan();
      subscription.cancel();
      
      _isScanning = false;
      debugPrint('✅ BluetoothProvisioningService: Scan completed. Found ${_discoveredDevices.length} devices');
      notifyListeners();
      
    } catch (e) {
      _isScanning = false;
      _error = 'Scan failed: $e';
      debugPrint('❌ BluetoothProvisioningService: $_error');
      notifyListeners();
    }
  }
  
  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ BluetoothProvisioningService: Error stopping scan: $e');
    }
  }
  
  /// Connect to an ESP32 device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      debugPrint('🔗 BluetoothProvisioningService: Connecting to ${device.platformName}...');
      
      _error = null;
      notifyListeners();
      
      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      
      // Wait for connection
      await device.connectionState
          .where((state) => state == BluetoothConnectionState.connected)
          .first
          .timeout(const Duration(seconds: 15));
      
      _connectedDevice = device;
      _isConnected = true;
      
      debugPrint('✅ BluetoothProvisioningService: Connected to ${device.platformName}');
      notifyListeners();
      return true;
      
    } catch (e) {
      _error = 'Connection failed: $e';
      debugPrint('❌ BluetoothProvisioningService: $_error');
      notifyListeners();
      return false;
    }
  }
  
  /// Send WiFi credentials to ESP32
  Future<bool> sendWiFiCredentials(String ssid, String password) async {
    if (_connectedDevice == null || !_isConnected) {
      _error = 'Not connected to any device';
      debugPrint('❌ BluetoothProvisioningService: $_error');
      notifyListeners();
      return false;
    }
    
    try {
      debugPrint('📤 BluetoothProvisioningService: Sending WiFi credentials...');
      debugPrint('   SSID: $ssid');
      
      // Discover services
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      // Find our service
      BluetoothService? targetService;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          targetService = service;
          break;
        }
      }
      
      if (targetService == null) {
        _error = 'Provisioning service not found on device';
        debugPrint('❌ BluetoothProvisioningService: $_error');
        notifyListeners();
        return false;
      }
      
      // Find WiFi characteristic
      BluetoothCharacteristic? wifiCharacteristic;
      for (var characteristic in targetService.characteristics) {
        if (characteristic.uuid.toString().toLowerCase() == wifiCharacteristicUUID.toLowerCase()) {
          wifiCharacteristic = characteristic;
          break;
        }
      }
      
      if (wifiCharacteristic == null) {
        _error = 'WiFi characteristic not found';
        debugPrint('❌ BluetoothProvisioningService: $_error');
        notifyListeners();
        return false;
      }
      
      // Prepare credentials as JSON
      final credentials = jsonEncode({
        'ssid': ssid,
        'password': password,
      });
      
      // Send credentials
      await wifiCharacteristic.write(
        utf8.encode(credentials),
        withoutResponse: false,
      );
      
      debugPrint('✅ BluetoothProvisioningService: Credentials sent successfully');
      return true;
      
    } catch (e) {
      _error = 'Failed to send credentials: $e';
      debugPrint('❌ BluetoothProvisioningService: $_error');
      notifyListeners();
      return false;
    }
  }
  
  /// Disconnect from current device
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        debugPrint('🔌 BluetoothProvisioningService: Disconnecting...');
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _isConnected = false;
        notifyListeners();
        debugPrint('✅ BluetoothProvisioningService: Disconnected');
      } catch (e) {
        debugPrint('⚠️ BluetoothProvisioningService: Error disconnecting: $e');
      }
    }
  }
  
  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
