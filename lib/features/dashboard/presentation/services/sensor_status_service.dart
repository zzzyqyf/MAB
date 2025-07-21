import 'package:flutter/material.dart';

// Model imports
import '../models/mushroom_phase.dart';

class SensorStatusService {
  final MushroomPhase currentPhase;

  const SensorStatusService(this.currentPhase);

  // Phase-aware sensor status system
  Color getSensorStatusColor(String sensorType, dynamic value) {
    if (value == null) return Colors.grey; // No data
    
    final numValue = double.tryParse(value.toString()) ?? 0.0;
    final thresholds = phaseThresholds[currentPhase]!;
    
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        if (numValue < thresholds.minTemp || numValue > thresholds.maxTemp) {
          return Colors.red; // Urgent - outside phase range
        }
        if (numValue < thresholds.minTemp + 2 || numValue > thresholds.maxTemp - 2) {
          return Colors.orange; // Concern - close to limits
        }
        return Colors.green; // Normal - within phase range
        
      case 'humidity':
        if (numValue < thresholds.minHumidity || numValue > thresholds.maxHumidity) {
          return Colors.red; // Urgent - outside phase range
        }
        if (numValue < thresholds.minHumidity + 3 || numValue > thresholds.maxHumidity - 3) {
          return Colors.orange; // Concern - close to limits
        }
        return Colors.green; // Normal - within phase range
        
      case 'light':
        final lightValue = numValue; // Assuming light is in lux
        if (lightValue < thresholds.minLight || lightValue > thresholds.maxLight) {
          return Colors.red; // Urgent - outside phase range
        }
        if (lightValue < thresholds.minLight + 50 || lightValue > thresholds.maxLight - 50) {
          return Colors.orange; // Concern - close to limits
        }
        return Colors.green; // Normal - within phase range
        
      case 'water':
        // For water/moisture, we use humidity thresholds as a proxy
        if (numValue < 30) return Colors.red;      // Urgent - too dry
        if (numValue < 40) return Colors.orange;   // Concern - low
        return Colors.green; // Normal
        
      default:
        return Colors.grey;
    }
  }

  String getSensorStatusText(String sensorType, dynamic value) {
    if (value == null) return 'No Data';
    
    final numValue = double.tryParse(value.toString()) ?? 0.0;
    final thresholds = phaseThresholds[currentPhase]!;
    
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        if (numValue < thresholds.minTemp || numValue > thresholds.maxTemp) {
          return 'Urgent';
        }
        if (numValue < thresholds.minTemp + 2 || numValue > thresholds.maxTemp - 2) {
          return 'Concern';
        }
        return 'Optimal';
        
      case 'humidity':
        if (numValue < thresholds.minHumidity || numValue > thresholds.maxHumidity) {
          return 'Urgent';
        }
        if (numValue < thresholds.minHumidity + 3 || numValue > thresholds.maxHumidity - 3) {
          return 'Concern';
        }
        return 'Optimal';
        
      case 'light':
        final lightValue = numValue;
        if (lightValue < thresholds.minLight || lightValue > thresholds.maxLight) {
          return 'Urgent';
        }
        if (lightValue < thresholds.minLight + 50 || lightValue > thresholds.maxLight - 50) {
          return 'Concern';
        }
        return 'Optimal';
        
      case 'water':
        if (numValue < 30) return 'Urgent';
        if (numValue < 40) return 'Concern';
        return 'Good';
        
      default:
        return 'Unknown';
    }
  }
}
