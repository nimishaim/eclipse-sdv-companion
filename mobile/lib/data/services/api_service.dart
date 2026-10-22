import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/vehicle.dart';
import '../models/telemetry.dart';

class HealthCheckResult {
  final bool isHealthy;
  final int statusCode;
  final int latencyMs;
  final String? errorMessage;

  HealthCheckResult({
    required this.isHealthy,
    required this.statusCode,
    required this.latencyMs,
    this.errorMessage,
  });
}

class ApiService {
  final Dio _dio;
  String _baseUrl;

  ApiService({String? baseUrl})
    : _baseUrl = baseUrl ?? ApiConstants.defaultLocalBaseUrl,
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? ApiConstants.defaultLocalBaseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {'Accept': 'application/json'},
        ),
      );

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  /// Pings backend to measure connectivity and latency
  Future<HealthCheckResult> ping() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get(
        ApiConstants.pathVehicles,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      stopwatch.stop();
      return HealthCheckResult(
        isHealthy: response.statusCode == 200,
        statusCode: response.statusCode ?? 200,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      return HealthCheckResult(
        isHealthy: false,
        statusCode: e.response?.statusCode ?? 0,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.message ?? e.type.name,
      );
    } catch (e) {
      stopwatch.stop();
      return HealthCheckResult(
        isHealthy: false,
        statusCode: 0,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
      );
    }
  }

  /// GET /api/v1/vehicles
  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _dio.get(ApiConstants.pathVehicles);
      final data = response.data;

      if (data is List) {
        return data
            .map(
              (item) =>
                  Vehicle.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } else if (data is Map) {
        // Multi-vehicle dictionary or {vehicles: [...]}
        if (data.containsKey('vehicles') && data['vehicles'] is List) {
          return (data['vehicles'] as List)
              .map(
                (item) =>
                    Vehicle.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
        } else {
          // Keys might be vehicle IDs
          final list = <Vehicle>[];
          data.forEach((k, v) {
            if (v is Map) {
              list.add(Vehicle.fromJson(Map<String, dynamic>.from(v)));
            } else {
              list.add(
                Vehicle(
                  id: k.toString(),
                  name: 'VIRYA $k',
                  profile: 'apm_dbw',
                  vin: 'VIRYA-$k',
                  hardwarePlatform: 'Eclipse Leda',
                ),
              );
            }
          });
          return list;
        }
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to fetch vehicles from $_baseUrl: ${e.message}');
    }
  }

  /// GET /api/v1/telemetry/latest
  Future<Telemetry?> getLatestTelemetry({String? vehicleId}) async {
    try {
      final queryParams = vehicleId != null ? {'vehicle_id': vehicleId} : null;
      final response = await _dio.get(
        ApiConstants.pathLatestTelemetry,
        queryParameters: queryParams,
      );
      final data = response.data;

      if (data == null) return null;

      if (data is Map) {
        // If data is keyed by vehicleId
        if (vehicleId != null && data.containsKey(vehicleId)) {
          return Telemetry.fromJson(
            Map<String, dynamic>.from(data[vehicleId] as Map),
            isSimulated: false,
          );
        }
        // Direct telemetry object
        if (data.containsKey('speed_kmh') || data.containsKey('vehicle_id')) {
          return Telemetry.fromJson(
            Map<String, dynamic>.from(data),
            isSimulated: false,
          );
        }
        // Pick first value if map of vehicles
        if (data.isNotEmpty && data.values.first is Map) {
          return Telemetry.fromJson(
            Map<String, dynamic>.from(data.values.first as Map),
            isSimulated: false,
          );
        }
      }
      return null;
    } on DioException catch (e) {
      throw Exception('Failed to fetch telemetry: ${e.message}');
    }
  }

  /// POST /api/v1/telemetry (documented ingestion API)
  Future<bool> postTelemetry(Telemetry telemetry) async {
    try {
      final response = await _dio.post(
        ApiConstants.pathPostTelemetry,
        data: telemetry.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
