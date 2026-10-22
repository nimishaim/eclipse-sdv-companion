import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';
import 'package:mobile/core/utils/formatters.dart';
import 'package:mobile/data/models/control_command.dart';
import 'package:mobile/data/models/ota_status.dart';
import 'package:mobile/data/models/telemetry.dart';
import 'package:mobile/data/models/vehicle.dart';
import 'package:mobile/data/services/api_service.dart';
import 'package:mobile/data/repositories/vehicle_repository.dart';
import 'package:mobile/state/vehicle_provider.dart';
import 'package:mobile/presentation/screens/dashboard/widgets/speed_gauge_widget.dart';
import 'package:mobile/presentation/screens/dashboard/widgets/telemetry_card.dart';

class TestVehicleRepository implements VehicleRepository {
  final _controller = StreamController<Telemetry>.broadcast();

  @override
  Future<List<Vehicle>> getVehicles() async {
    return const [
      Vehicle(
        id: 'APM-DBW-01',
        name: 'VIRYA APM Autonomous Skateboard',
        profile: 'apm_dbw',
        vin: 'VIRYA-APM-2026-X86',
        hardwarePlatform: 'Eclipse Leda',
      ),
    ];
  }

  @override
  Future<Telemetry?> getLatestTelemetry(String vehicleId) async {
    return Telemetry(
      vehicleId: vehicleId,
      timestamp: DateTime.now(),
      speedKmh: 42.0,
      batterySoc: 85.0,
      steeringAngle: 2.5,
      gear: 'D',
      emergencyStop: false,
    );
  }

  @override
  Stream<Telemetry> getTelemetryStream() => _controller.stream;

  @override
  Future<HealthCheckResult> testConnection() async {
    return HealthCheckResult(isHealthy: true, statusCode: 200, latencyMs: 12);
  }

  @override
  Future<ControlCommand> executeCommand(ControlCommand command) async {
    return command.copyWith(status: CommandStatus.verified);
  }

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Eclipse SDV Companion Test Suite', () {
    testWidgets('App renders main navigation and cockpit dashboard', (
      WidgetTester tester,
    ) async {
      final testRepo = TestVehicleRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [vehicleRepositoryProvider.overrideWithValue(testRepo)],
          child: const EclipseSdvCompanionApp(),
        ),
      );

      await tester.pump();

      // Verify dashboard elements are rendered
      expect(find.text('Cockpit Dashboard'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Vehicle'), findsOneWidget);
      expect(find.text('Controls'), findsOneWidget);
      expect(find.text('OTA Updates'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify speed gauge is rendered
      expect(find.byType(SpeedGaugeWidget), findsOneWidget);
      expect(find.byType(TelemetryCard), findsWidgets);

      // Clean unmount
      await tester.pumpWidget(const SizedBox.shrink());
      testRepo.dispose();
    });

    test('Telemetry model json parsing and staleness calculations', () {
      final json = {
        'vehicle_id': 'APM-DBW-01',
        'timestamp': DateTime.now().toIso8601String(),
        'speed_kmh': 45.2,
        'battery_soc': 82.0,
        'steering_angle': 12.5,
        'gear': 'D',
        'emergency_stop': false,
        'motor_temp_c': 42.0,
      };

      final telem = Telemetry.fromJson(json);
      expect(telem.vehicleId, 'APM-DBW-01');
      expect(telem.speedKmh, 45.2);
      expect(telem.batterySoc, 82.0);
      expect(telem.steeringAngle, 12.5);
      expect(telem.gear, 'D');
      expect(telem.emergencyStop, false);
      expect(telem.isStale, false);

      // Stale calculation: 10 seconds ago should be marked stale
      final staleTelem = telem.copyWith(
        timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(staleTelem.isStale, true);
    });

    test('Vehicle model parsing and capabilities', () {
      const vehicle = Vehicle(
        id: 'APM-DBW-01',
        name: 'VIRYA APM Skateboard',
        profile: 'apm_dbw',
        vin: 'VIRYA-APM-2026-X86',
        hardwarePlatform: 'Eclipse Leda',
      );

      expect(vehicle.id, 'APM-DBW-01');
      expect(vehicle.supportedCapabilities.contains('Vehicle.Speed'), true);
      expect(vehicle.supportedCapabilities.contains('apm_dbw.control'), true);
    });

    test('OTA Status initial state and dual-partition slots', () {
      final ota = OtaStatus.initial(isSimulated: true);
      expect(ota.activeSlot.contains('root_a'), true);
      expect(ota.inactiveSlot.contains('root_b'), true);
      expect(ota.stage, OtaStage.idle);
      expect(ota.hasUpdate, true);
      expect(ota.isSimulated, true);
    });

    test('ControlCommand safety attributes and status flow', () {
      final cmd = ControlCommand(
        id: 'CMD-001',
        name: 'emergency_stop_trigger',
        parameter: 'HARD_STOP',
        status: CommandStatus.pending,
        timestamp: DateTime.now(),
        requiresSafetyConfirmation: true,
      );

      expect(cmd.requiresSafetyConfirmation, true);
      expect(cmd.status, CommandStatus.pending);

      final accepted = cmd.copyWith(status: CommandStatus.accepted);
      expect(accepted.status, CommandStatus.accepted);

      final verified = accepted.copyWith(status: CommandStatus.verified);
      expect(verified.status, CommandStatus.verified);
    });

    test('Automotive Formatters precision and units', () {
      expect(Formatters.speed(45.234), '45.2');
      expect(Formatters.batterySoc(82.6), '83%');
      expect(Formatters.steeringAngle(12.54), '12.5°');
      expect(Formatters.temperature(38.0), '38.0°C');
    });
  });
}
