import 'dart:async';

import '../models/vehicle.dart';
import '../models/telemetry.dart';
import '../models/control_command.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/mock_data_service.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getVehicles();
  Future<Telemetry?> getLatestTelemetry(String vehicleId);
  Stream<Telemetry> getTelemetryStream();
  Future<HealthCheckResult> testConnection();
  Future<ControlCommand> executeCommand(ControlCommand command);
  void dispose();
}

class LiveVehicleRepository implements VehicleRepository {
  final ApiService apiService;
  final WebSocketService wsService;

  LiveVehicleRepository({required this.apiService, required this.wsService});

  @override
  Future<List<Vehicle>> getVehicles() async {
    return await apiService.getVehicles();
  }

  @override
  Future<Telemetry?> getLatestTelemetry(String vehicleId) async {
    return await apiService.getLatestTelemetry(vehicleId: vehicleId);
  }

  @override
  Stream<Telemetry> getTelemetryStream() {
    return wsService.telemetryStream;
  }

  @override
  Future<HealthCheckResult> testConnection() async {
    return await apiService.ping();
  }

  @override
  Future<ControlCommand> executeCommand(ControlCommand command) async {
    return command.copyWith(
      status: CommandStatus.failed,
      statusMessage: 'Command blocked: Central node has not exposed a verified CAN write RPC endpoint. Direct actuation disabled for safety.',
      isSimulated: false,
    );
  }

  @override
  void dispose() {
    wsService.dispose();
  }
}

class MockVehicleRepository implements VehicleRepository {
  final MockDataService _mockDataService;

  MockVehicleRepository(this._mockDataService) {
    _mockDataService.startSimulation();
  }

  @override
  Future<List<Vehicle>> getVehicles() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockDataService.mockVehicles;
  }

  @override
  Future<Telemetry?> getLatestTelemetry(String vehicleId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockDataService.currentTelemetry;
  }

  @override
  Stream<Telemetry> getTelemetryStream() {
    return _mockDataService.telemetryStream;
  }

  @override
  Future<HealthCheckResult> testConnection() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return HealthCheckResult(isHealthy: true, statusCode: 200, latencyMs: 14);
  }

  @override
  Future<ControlCommand> executeCommand(ControlCommand command) async {
    if (command.name == 'set_gear') {
      _mockDataService.setGear(command.parameter);
    } else if (command.name == 'emergency_stop_trigger') {
      _mockDataService.triggerEmergencyStop();
    } else if (command.name == 'emergency_stop_release') {
      _mockDataService.releaseEmergencyStop();
    } else if (command.name == 'switch_vehicle_profile') {
      _mockDataService.setVehicleProfile(command.parameter);
    }

    return command.copyWith(
      status: CommandStatus.verified,
      statusMessage:
          'Simulated command executed locally on virtual skateboard model.',
      isSimulated: true,
    );
  }

  @override
  void dispose() {
    _mockDataService.dispose();
  }
}
