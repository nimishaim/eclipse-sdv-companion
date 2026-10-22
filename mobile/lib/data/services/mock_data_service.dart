import 'dart:async';
import 'dart:math';

import '../models/telemetry.dart';
import '../models/vehicle.dart';

class MockDataService {
  Timer? _timer;
  final _telemetryController = StreamController<Telemetry>.broadcast();

  // Internal vehicle simulation state
  double _speed = 36.4;
  double _targetSpeed = 42.0;
  double _batterySoc = 83.5;
  double _steeringAngle = 4.2;
  String _gear = 'D';
  bool _emergencyStop = false;
  double _motorTemp = 41.5;
  double _batteryTemp = 34.8;
  String _activeProfile = 'apm_dbw';
  double _stepCounter = 0;

  final Random _random = Random();

  Stream<Telemetry> get telemetryStream => _telemetryController.stream;

  Telemetry get currentTelemetry => Telemetry(
    vehicleId: 'APM-DBW-01',
    timestamp: DateTime.now(),
    speedKmh: _speed,
    batterySoc: _batterySoc,
    steeringAngle: _steeringAngle,
    gear: _gear,
    emergencyStop: _emergencyStop,
    motorTempC: _motorTemp,
    batteryTempC: _batteryTemp,
    isSimulated: true,
    activeProfile: _activeProfile,
  );

  List<Vehicle> get mockVehicles => const [
    Vehicle(
      id: 'APM-DBW-01',
      name: 'VIRYA APM Autonomous Skateboard',
      profile: 'apm_dbw',
      vin: 'VIRYA-APM-2026-X86',
      hardwarePlatform: 'Eclipse Leda (genericx86-64) + PEAK PCAN-USB',
      isOnline: true,
      supportedCapabilities: [
        'Vehicle.Speed',
        'Vehicle.Powertrain.TractionBattery.StateOfCharge.Current',
        'Vehicle.Chassis.SteeringWheel.Angle',
        'Vehicle.Powertrain.Transmission.CurrentGear',
        'emergency_stop',
        'apm_dbw.control',
      ],
      metadata: {
        'ecu_kernel': 'Linux 6.1-genericx86-64 (systemd-boot)',
        'kuksa_broker': 'v0.4.1 (gRPC :55555)',
        'feeder_can': 'dbc2val (PCAN can0 @ 500kbps)',
        'container_runtime': 'Eclipse Kanto (kanto-cm)',
        'jetson_node': '10.1.30.193:8000',
      },
    ),
    Vehicle(
      id: 'MODEL3-VIRTUAL-02',
      name: 'Tesla Model 3 (Virtual Fallback)',
      profile: 'model3',
      vin: 'TESLA-M3-VSS-SIM',
      hardwarePlatform: 'vCAN Fallback Interface (can0)',
      isOnline: false,
      supportedCapabilities: [
        'Vehicle.Speed',
        'Vehicle.Powertrain.TractionBattery.StateOfCharge.Current',
        'Vehicle.Chassis.SteeringWheel.Angle',
        'model3.dbc',
      ],
      metadata: {
        'ecu_kernel': 'vCAN Fallback (sdv-vcan-fallback.service)',
        'kuksa_broker': 'v0.4.1 (gRPC :55555)',
      },
    ),
  ];

  void startSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      _tick();
    });
  }

  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    _stepCounter += 0.1;

    if (_emergencyStop) {
      _speed = max(0.0, _speed - 8.0);
      _gear = 'P';
      _steeringAngle = 0.0;
    } else {
      // Smooth dynamic speed adjustments simulating autonomous course navigation
      if ((_speed - _targetSpeed).abs() < 1.0) {
        // Pick new realistic autonomous cruise target between 20 and 52 km/h
        _targetSpeed = 22.0 + _random.nextDouble() * 30.0;
      }

      if (_speed < _targetSpeed) {
        _speed = min(_targetSpeed, _speed + 0.8 + _random.nextDouble() * 0.4);
      } else {
        _speed = max(_targetSpeed, _speed - 0.7 - _random.nextDouble() * 0.3);
      }

      // Smooth steering angle variation (sinusoidal + noise)
      _steeringAngle =
          sin(_stepCounter) * 14.0 + (_random.nextDouble() - 0.5) * 3.0;

      // Realistic slow battery drain (0.01% every few ticks)
      _batterySoc = max(5.0, _batterySoc - 0.008);

      // Temperature fluctuation based on speed & motor power
      final targetMotorTemp = 36.0 + (_speed / 50.0) * 12.0;
      _motorTemp +=
          (targetMotorTemp - _motorTemp) * 0.05 +
          (_random.nextDouble() - 0.5) * 0.1;
      _batteryTemp += (_random.nextDouble() - 0.49) * 0.05;
    }

    _telemetryController.add(currentTelemetry);
  }

  // Simulated control actions
  void setGear(String gear) {
    if (_emergencyStop && gear != 'P') return;
    _gear = gear;
    if (gear == 'P' || gear == 'N') {
      _targetSpeed = 0.0;
    } else if (gear == 'R') {
      _targetSpeed = 8.0;
    } else {
      _targetSpeed = 38.0;
    }
  }

  void triggerEmergencyStop() {
    _emergencyStop = true;
    _gear = 'P';
    _targetSpeed = 0.0;
  }

  void releaseEmergencyStop() {
    _emergencyStop = false;
    _gear = 'P';
  }

  void setVehicleProfile(String profile) {
    _activeProfile = profile;
  }

  void dispose() {
    stopSimulation();
    _telemetryController.close();
  }
}
