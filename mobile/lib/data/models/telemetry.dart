class Telemetry {
  final String vehicleId;
  final DateTime timestamp;
  final double speedKmh;
  final double batterySoc;
  final double steeringAngle;
  final String gear;
  final bool emergencyStop;
  final double motorTempC;
  final double batteryTempC;
  final bool isSimulated;
  final String? activeProfile;

  const Telemetry({
    required this.vehicleId,
    required this.timestamp,
    required this.speedKmh,
    required this.batterySoc,
    required this.steeringAngle,
    required this.gear,
    required this.emergencyStop,
    this.motorTempC = 42.0,
    this.batteryTempC = 36.5,
    this.isSimulated = false,
    this.activeProfile = 'apm_dbw',
  });

  bool get isStale {
    return DateTime.now().difference(timestamp).inSeconds > 5;
  }

  factory Telemetry.fromJson(
    Map<String, dynamic> json, {
    bool isSimulated = false,
  }) {
    // Parse timestamp safely
    DateTime parsedTime;
    final rawTime = json['timestamp'];
    if (rawTime is String) {
      parsedTime = DateTime.tryParse(rawTime) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return Telemetry(
      vehicleId: json['vehicle_id'] as String? ?? 'APM-DBW-01',
      timestamp: parsedTime,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      batterySoc: (json['battery_soc'] as num?)?.toDouble() ?? 0.0,
      steeringAngle: (json['steering_angle'] as num?)?.toDouble() ?? 0.0,
      gear: json['gear'] as String? ?? 'P',
      emergencyStop: json['emergency_stop'] as bool? ?? false,
      motorTempC:
          (json['motor_temp_c'] as num?)?.toDouble() ??
          (json['temperature'] as num?)?.toDouble() ??
          42.0,
      batteryTempC: (json['battery_temp_c'] as num?)?.toDouble() ?? 36.5,
      isSimulated: isSimulated,
      activeProfile: json['active_profile'] as String? ?? 'apm_dbw',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'timestamp': timestamp.toIso8601String(),
      'speed_kmh': speedKmh,
      'battery_soc': batterySoc,
      'steering_angle': steeringAngle,
      'gear': gear,
      'emergency_stop': emergencyStop,
      'motor_temp_c': motorTempC,
      'battery_temp_c': batteryTempC,
      'is_simulated': isSimulated,
      'active_profile': activeProfile,
    };
  }

  Telemetry copyWith({
    String? vehicleId,
    DateTime? timestamp,
    double? speedKmh,
    double? batterySoc,
    double? steeringAngle,
    String? gear,
    bool? emergencyStop,
    double? motorTempC,
    double? batteryTempC,
    bool? isSimulated,
    String? activeProfile,
  }) {
    return Telemetry(
      vehicleId: vehicleId ?? this.vehicleId,
      timestamp: timestamp ?? this.timestamp,
      speedKmh: speedKmh ?? this.speedKmh,
      batterySoc: batterySoc ?? this.batterySoc,
      steeringAngle: steeringAngle ?? this.steeringAngle,
      gear: gear ?? this.gear,
      emergencyStop: emergencyStop ?? this.emergencyStop,
      motorTempC: motorTempC ?? this.motorTempC,
      batteryTempC: batteryTempC ?? this.batteryTempC,
      isSimulated: isSimulated ?? this.isSimulated,
      activeProfile: activeProfile ?? this.activeProfile,
    );
  }
}
