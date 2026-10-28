class ApiConstants {
  ApiConstants._();

  // Documented Central Node Endpoints
  static const String defaultLocalBaseUrl = 'http://10.1.30.193:8000';
  static const String defaultNgrokBaseUrl =
      'https://spearfish-carving-slightly.ngrok-free.dev';

  // REST Paths
  static const String pathVehicles = '/api/v1/vehicles';
  static const String pathLatestTelemetry = '/api/v1/telemetry/latest';
  static const String pathPostTelemetry = '/api/v1/telemetry';

  // WebSocket
  static const String pathWsTelemetry = '/ws/telemetry';

  // Timeouts & Polling
  static const Duration connectTimeout = Duration(seconds: 4);
  static const Duration receiveTimeout = Duration(seconds: 4);
  static const Duration pollingInterval = Duration(milliseconds: 1000);
  static const Duration staleThreshold = Duration(seconds: 5);
}
