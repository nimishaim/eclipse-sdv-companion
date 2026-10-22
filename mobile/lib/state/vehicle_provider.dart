import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/vehicle.dart';
import '../data/repositories/vehicle_repository.dart';
import '../data/services/websocket_service.dart';
import '../data/services/mock_data_service.dart';
import 'app_settings_provider.dart';

final mockDataServiceProvider = Provider<MockDataService>((ref) {
  final service = MockDataService();
  ref.onDispose(() => service.dispose());
  return service;
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final apiService = ref.watch(apiServiceProvider);
  final wsService = ref.watch(webSocketServiceProvider);
  final mockService = ref.watch(mockDataServiceProvider);

  if (settings.isDemoMode) {
    return MockVehicleRepository(mockService);
  } else {
    wsService.connect(settings.baseUrl);
    return LiveVehicleRepository(apiService: apiService, wsService: wsService);
  }
});

final vehiclesFutureProvider = FutureProvider<List<Vehicle>>((ref) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  return await repo.getVehicles();
});

class SelectedVehicleIdNotifier extends Notifier<String> {
  @override
  String build() => 'APM-DBW-01';

  void select(String id) => state = id;
}

final selectedVehicleIdProvider =
    NotifierProvider<SelectedVehicleIdNotifier, String>(
      SelectedVehicleIdNotifier.new,
    );

final selectedVehicleProvider = Provider<Vehicle?>((ref) {
  final vehiclesAsync = ref.watch(vehiclesFutureProvider);
  final selectedId = ref.watch(selectedVehicleIdProvider);

  return vehiclesAsync.maybeWhen(
    data: (vehicles) {
      return vehicles.firstWhere(
        (v) => v.id == selectedId,
        orElse: () => vehicles.isNotEmpty
            ? vehicles.first
            : const Vehicle(
                id: 'APM-DBW-01',
                name: 'VIRYA APM Autonomous Skateboard',
                profile: 'apm_dbw',
                vin: 'VIRYA-APM-2026-X86',
                hardwarePlatform: 'Eclipse Leda',
              ),
      );
    },
    orElse: () => const Vehicle(
      id: 'APM-DBW-01',
      name: 'VIRYA APM Autonomous Skateboard',
      profile: 'apm_dbw',
      vin: 'VIRYA-APM-2026-X86',
      hardwarePlatform: 'Eclipse Leda',
    ),
  );
});
