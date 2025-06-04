class Device {
  final String id;
  final String name;
  final String status;
  final String sensorStatus;
  final DateTime lastUpdated;
  final Map<String, dynamic>? sensorData;

  const Device({
    required this.id,
    required this.name,
    required this.status,
    required this.sensorStatus,
    required this.lastUpdated,
    this.sensorData,
  });

  Device copyWith({
    String? id,
    String? name,
    String? status,
    String? sensorStatus,
    DateTime? lastUpdated,
    Map<String, dynamic>? sensorData,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      sensorStatus: sensorStatus ?? this.sensorStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sensorData: sensorData ?? this.sensorData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device &&
        other.id == id &&
        other.name == name &&
        other.status == status &&
        other.sensorStatus == sensorStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        status.hashCode ^
        sensorStatus.hashCode;
  }

  @override
  String toString() {
    return 'Device(id: $id, name: $name, status: $status, sensorStatus: $sensorStatus)';
  }
}
