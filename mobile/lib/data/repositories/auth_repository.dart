class DemoOperator {
  final String id;
  final String name;
  final String role;
  final String email;
  final String accessLevel;
  final DateTime? authenticatedAt;

  const DemoOperator({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.accessLevel,
    this.authenticatedAt,
  });
}

class AuthRepository {
  DemoOperator? _currentOperator;

  DemoOperator? get currentOperator => _currentOperator;
  bool get isAuthenticated => _currentOperator != null;

  static const List<DemoOperator> availableDemoRoles = [
    DemoOperator(
      id: 'OP-001',
      name: 'Alex Vance',
      role: 'Autonomous Fleet Safety Engineer',
      email: 'alex.vance@eclipse-sdv.demo',
      accessLevel: 'L3_CAN_DIAGNOSTICS',
    ),
    DemoOperator(
      id: 'OP-002',
      name: 'Sarah Connor',
      role: 'APM Skateboard Integration Lead',
      email: 'sarah.c@eclipse-sdv.demo',
      accessLevel: 'L2_VEHICLE_CONTROLS',
    ),
    DemoOperator(
      id: 'OP-003',
      name: 'David Lightman',
      role: 'Field Telemetry & OTA Auditor',
      email: 'david.l@eclipse-sdv.demo',
      accessLevel: 'L1_OBSERVER_OTA',
    ),
  ];

  Future<DemoOperator> loginDemo(DemoOperator roleTemplate) async {
    await Future.delayed(const Duration(milliseconds: 350));
    _currentOperator = DemoOperator(
      id: roleTemplate.id,
      name: roleTemplate.name,
      role: roleTemplate.role,
      email: roleTemplate.email,
      accessLevel: roleTemplate.accessLevel,
      authenticatedAt: DateTime.now(),
    );
    return _currentOperator!;
  }

  Future<void> logout() async {
    _currentOperator = null;
  }
}
