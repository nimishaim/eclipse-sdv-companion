class Vehicle {
  final String id;
  final String name;
  final String profile; // e.g. 'apm_dbw', 'model3'
  final String vin;
  final String
  hardwarePlatform; // e.g. 'VIRYA APM genericx86-64 / Eclipse Leda'
  final bool isOnline;
  final List<String> supportedCapabilities;
  final Map<String, dynamic> metadata;

  const Vehicle({
    required this.id,
    required this.name,
    required this.profile,
    required this.vin,
    required this.hardwarePlatform,
    this.isOnline = true,
    this.supportedCapabilities = const [
      'Vehicle.Speed',
      'Vehicle.Powertrain.TractionBattery.StateOfCharge.Current',
      'Vehicle.Chassis.SteeringWheel.Angle',
      'Vehicle.Powertrain.Transmission.CurrentGear',
      'emergency_stop',
      'apm_dbw.control',
    ],
    this.metadata = const {},
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id:
          json['vehicle_id'] as String? ??
          json['id'] as String? ??
          'APM-DBW-01',
      name: json['name'] as String? ?? 'VIRYA APM Skateboard #1',
      profile: json['profile'] as String? ?? 'apm_dbw',
      vin: json['vin'] as String? ?? 'VIRYA-APM-2026-X86',
      hardwarePlatform:
          json['hardware_platform'] as String? ??
          'Eclipse Leda (genericx86-64) + PEAK PCAN-USB',
      isOnline: json['is_online'] as bool? ?? true,
      supportedCapabilities:
          (json['supported_capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Vehicle.Speed',
            'Vehicle.Powertrain.TractionBattery.StateOfCharge.Current',
            'Vehicle.Chassis.SteeringWheel.Angle',
            'Vehicle.Powertrain.Transmission.CurrentGear',
            'emergency_stop',
            'apm_dbw.control',
          ],
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': id,
      'name': name,
      'profile': profile,
      'vin': vin,
      'hardware_platform': hardwarePlatform,
      'is_online': isOnline,
      'supported_capabilities': supportedCapabilities,
      'metadata': metadata,
    };
  }
}
