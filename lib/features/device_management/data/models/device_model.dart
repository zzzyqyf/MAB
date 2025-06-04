import '../../domain/entities/device.dart';

class DeviceModel extends Device {
  const DeviceModel({
    required super.id,
    required super.name,
    required super.status,
    required super.sensorStatus,
    required super.lastUpdated,
    super.sensorData,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      sensorStatus: json['sensorStatus'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      sensorData: json['sensorData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'sensorStatus': sensorStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
      'sensorData': sensorData,
    };
  }

  factory DeviceModel.fromHiveMap(Map<dynamic, dynamic> map) {
    return DeviceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      status: map['status'] as String,
      sensorStatus: map['sensorStatus'] as String,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      sensorData: map['sensorData'] != null
          ? Map<String, dynamic>.from(map['sensorData'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'sensorStatus': sensorStatus,
      'lastUpdated': lastUpdated.toIso8601String(),
      'sensorData': sensorData,
    };
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? status,
    String? sensorStatus,
    DateTime? lastUpdated,
    Map<String, dynamic>? sensorData,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      sensorStatus: sensorStatus ?? this.sensorStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sensorData: sensorData ?? this.sensorData,
    );
  }
}
