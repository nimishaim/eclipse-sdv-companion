import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/telemetry.dart';
import 'app_settings_provider.dart';
import 'vehicle_provider.dart';

enum TelemetryConnectionStatus {
  liveConnected,
  simulatedActive,
  stale,
  disconnected,
  error,
}

class TelemetryState {
  final Telemetry telemetry;
  final List<double> speedHistory;
  final TelemetryConnectionStatus status;
  final DateTime lastReceived;
  final String? errorMessage;

  const TelemetryState({
    required this.telemetry,
    required this.speedHistory,
    required this.status,
    required this.lastReceived,
    this.errorMessage,
  });

  bool get isStale =>
      status == TelemetryConnectionStatus.stale ||
      DateTime.now().difference(lastReceived).inSeconds > 5;

  TelemetryState copyWith({
    Telemetry? telemetry,
    List<double>? speedHistory,
    TelemetryConnectionStatus? status,
    DateTime? lastReceived,
    String? errorMessage,
  }) {
    return TelemetryState(
      telemetry: telemetry ?? this.telemetry,
      speedHistory: speedHistory ?? this.speedHistory,
      status: status ?? this.status,
      lastReceived: lastReceived ?? this.lastReceived,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TelemetryNotifier extends Notifier<TelemetryState> {
  StreamSubscription<Telemetry>? _subscription;
  Timer? _staleChecker;
  Timer? _livePollingTimer;

  @override
  TelemetryState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _staleChecker?.cancel();
      _livePollingTimer?.cancel();
    });

    _startStaleChecker();
    _listenToRepository();

    ref.listen(vehicleRepositoryProvider, (_, _) {
      _listenToRepository();
    });

    return TelemetryState(
      telemetry: Telemetry(
        vehicleId: 'APM-DBW-01',
        timestamp: DateTime.now(),
        speedKmh: 0.0,
        batterySoc: 85.0,
        steeringAngle: 0.0,
        gear: 'P',
        emergencyStop: false,
        isSimulated: true,
      ),
      speedHistory: const [0, 5, 12, 20, 28, 35, 41, 38, 42],
      status: TelemetryConnectionStatus.simulatedActive,
      lastReceived: DateTime.now(),
    );
  }

  void refreshListener() {
    _listenToRepository();
  }

  void _listenToRepository() {
    _subscription?.cancel();
    _livePollingTimer?.cancel();

    final repo = ref.read(vehicleRepositoryProvider);
    final isDemo = ref.read(appSettingsProvider).isDemoMode;

    if (isDemo) {
      _subscription = repo.getTelemetryStream().listen(
        (data) => _onDataReceived(data, isSimulated: true),
        onError: (e) => _onError(e.toString()),
      );
    } else {
      _subscription = repo.getTelemetryStream().listen(
        (data) => _onDataReceived(data, isSimulated: false),
        onError: (e) => _onError(e.toString()),
      );

      _livePollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        try {
          final selectedId = ref.read(selectedVehicleIdProvider);
          final telemetry = await repo.getLatestTelemetry(selectedId);
          if (telemetry != null) {
            _onDataReceived(telemetry, isSimulated: false);
          }
        } catch (e) {
          if (DateTime.now().difference(state.lastReceived).inSeconds > 5) {
            state = state.copyWith(
              status: TelemetryConnectionStatus.disconnected,
              errorMessage: 'Backend unreachable ($e)',
            );
          }
        }
      });
    }
  }

  void _onDataReceived(Telemetry data, {required bool isSimulated}) {
    final updatedHistory = List<double>.from(state.speedHistory);
    if (updatedHistory.length >= 25) {
      updatedHistory.removeAt(0);
    }
    updatedHistory.add(data.speedKmh);

    state = state.copyWith(
      telemetry: data,
      speedHistory: updatedHistory,
      status: isSimulated
          ? TelemetryConnectionStatus.simulatedActive
          : TelemetryConnectionStatus.liveConnected,
      lastReceived: DateTime.now(),
      errorMessage: null,
    );
  }

  void _onError(String error) {
    state = state.copyWith(
      status: TelemetryConnectionStatus.error,
      errorMessage: error,
    );
  }

  void _startStaleChecker() {
    _staleChecker?.cancel();
    _staleChecker = Timer.periodic(const Duration(seconds: 2), (_) {
      if (state.status == TelemetryConnectionStatus.liveConnected) {
        if (DateTime.now().difference(state.lastReceived).inSeconds > 5) {
          state = state.copyWith(status: TelemetryConnectionStatus.stale);
        }
      }
    });
  }
}

final telemetryProvider = NotifierProvider<TelemetryNotifier, TelemetryState>(
  TelemetryNotifier.new,
);
