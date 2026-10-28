import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../data/services/api_service.dart';

class AppSettingsState {
  final String baseUrl;
  final bool isDemoMode;
  final HealthCheckResult? lastPing;
  final bool isPinging;

  const AppSettingsState({
    required this.baseUrl,
    required this.isDemoMode,
    this.lastPing,
    this.isPinging = false,
  });

  AppSettingsState copyWith({
    String? baseUrl,
    bool? isDemoMode,
    HealthCheckResult? lastPing,
    bool? isPinging,
  }) {
    return AppSettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      lastPing: lastPing ?? this.lastPing,
      isPinging: isPinging ?? this.isPinging,
    );
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    return const AppSettingsState(
      baseUrl: ApiConstants.defaultLocalBaseUrl,
      isDemoMode: false,
    );
  }

  void setBaseUrl(String newUrl) {
    state = state.copyWith(baseUrl: newUrl);
    ref.read(apiServiceProvider).updateBaseUrl(newUrl);
  }

  void setDemoMode(bool isDemo) {
    state = state.copyWith(isDemoMode: isDemo);
  }

  Future<void> pingBackend() async {
    state = state.copyWith(isPinging: true);
    final api = ref.read(apiServiceProvider);
    api.updateBaseUrl(state.baseUrl);
    final result = await api.ping();
    state = state.copyWith(isPinging: false, lastPing: result);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(
      AppSettingsNotifier.new,
    );
