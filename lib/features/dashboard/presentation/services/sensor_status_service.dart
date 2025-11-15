import 'package:flutter/material.dart';

// Model imports
import '../models/mushroom_phase.dart';

class SensorStatusService {
  final CultivationMode currentMode;

  const SensorStatusService(this.currentMode);

  // Mode-aware sensor status system
  Color getSensorStatusColor(String sensorType, dynamic value) {
    if (value == null) return Colors.grey; // No data
    
    final numValue = double.tryParse(value.toString()) ?? 0.0;
    
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        // Only show Urgent when above 30°C, otherwise Good
        if (numValue > 30.0) {
          return Colors.red; // Urgent - too hot
        }
        return Colors.green; // Good
        
      case 'humidity':
        // Good if within range, Urgent if outside
        // Pinning mode: 90-95%, Normal mode: 80-85%
        debugPrint('🔍 Humidity Status Check:');
        debugPrint('   Current Mode: $currentMode');
        debugPrint('   Sensor Value: $numValue%');
        if (currentMode == CultivationMode.pinning) {
          debugPrint('   Min Threshold: 90.0%');
          debugPrint('   Max Threshold: 95.0%');
          debugPrint('   Within Range: ${numValue >= 90.0 && numValue <= 95.0}');
          if (numValue >= 90.0 && numValue <= 95.0) {
            return Colors.green; // Good - within Pinning range
          }
        } else {
          // Normal mode
          debugPrint('   Min Threshold: 80.0%');
          debugPrint('   Max Threshold: 85.0%');
          debugPrint('   Within Range: ${numValue >= 80.0 && numValue <= 85.0}');
          if (numValue >= 80.0 && numValue <= 85.0) {
            return Colors.green; // Good - within Normal range
          }
        }
        return Colors.red; // Urgent - outside mode range
        
      case 'light':
        // Light status is not mode-dependent in the new system
        final lightValue = numValue; // Assuming light is in lux
        if (lightValue >= 100) {
          return Colors.green; // Good
        }
        return Colors.red; // Urgent - too dark
        
      case 'water':
        // For water/moisture - binary: 0 = Low (no water), 1 = High (has water)
        if (numValue == 1) {
          return Colors.green; // High - has water
        } else if (numValue == 0) {
          return Colors.red; // Low - no water (urgent)
        }
        // Fallback for non-binary values (old system)
        if (numValue >= 30) {
          return Colors.green; // Good
        }
        return Colors.red; // Urgent - too dry
        
      default:
        return Colors.grey;
    }
  }

  String getSensorStatusText(String sensorType, dynamic value) {
    if (value == null) return 'No Data';
    
    final numValue = double.tryParse(value.toString()) ?? 0.0;
    
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        // Only show Urgent when above 30°C, otherwise Good
        if (numValue > 30.0) {
          return 'Urgent';
        }
        return 'Good';
        
      case 'humidity':
        // Good if within range, Urgent if outside
        // Pinning mode: 90-95%, Normal mode: 80-85%
        debugPrint('📊 Humidity Status Text Check:');
        debugPrint('   Current Mode: $currentMode');
        debugPrint('   Sensor Value: $numValue%');
        if (currentMode == CultivationMode.pinning) {
          debugPrint('   Expected Range: 90-95%');
          if (numValue >= 90.0 && numValue <= 95.0) {
            debugPrint('   Result: Good ✅');
            return 'Good';
          }
        } else {
          // Normal mode
          debugPrint('   Expected Range: 80-85%');
          if (numValue >= 80.0 && numValue <= 85.0) {
            debugPrint('   Result: Good ✅');
            return 'Good';
          }
        }
        debugPrint('   Result: Urgent ⚠️');
        return 'Urgent';
        
      case 'light':
        final lightValue = numValue;
        if (lightValue >= 100) {
          return 'Good';
        }
        return 'Urgent';
        
      case 'water':
        // Binary water level: 0 = Low (no water), 1 = High (has water)
        if (numValue == 1) {
          return 'High'; // Has water
        } else if (numValue == 0) {
          return 'Low'; // No water (urgent)
        }
        // Fallback for non-binary values (old system)
        if (numValue >= 30) {
          return 'Good';
        }
        return 'Urgent';
        
      default:
        return 'Unknown';
    }
  }
}
