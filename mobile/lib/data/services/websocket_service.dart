import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_constants.dart';
import '../models/telemetry.dart';

enum WsConnectionStatus { disconnected, connecting, connected, error }

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _telemetryController = StreamController<Telemetry>.broadcast();
  final _statusController = StreamController<WsConnectionStatus>.broadcast();

  WsConnectionStatus _status = WsConnectionStatus.disconnected;
  String? _currentBaseUrl;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  Stream<Telemetry> get telemetryStream => _telemetryController.stream;
  Stream<WsConnectionStatus> get statusStream => _statusController.stream;
  WsConnectionStatus get status => _status;

  void _setStatus(WsConnectionStatus status) {
    _status = status;
    if (!_isDisposed) {
      _statusController.add(status);
    }
  }

  Uri _buildWsUri(String httpUrl) {
    final uri = Uri.parse(httpUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    return Uri(
      scheme: wsScheme,
      host: uri.host,
      port: port,
      path: ApiConstants.pathWsTelemetry,
    );
  }

  Future<void> connect(String httpBaseUrl) async {
    _currentBaseUrl = httpBaseUrl;
    _reconnectTimer?.cancel();

    if (_status == WsConnectionStatus.connected) {
      await disconnect();
    }

    _setStatus(WsConnectionStatus.connecting);

    try {
      final wsUri = _buildWsUri(httpBaseUrl);
      _channel = WebSocketChannel.connect(wsUri);
      await _channel!.ready;

      _setStatus(WsConnectionStatus.connected);

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final dynamic decoded = jsonDecode(data.toString());
            if (decoded is Map<String, dynamic>) {
              final telemetry = Telemetry.fromJson(decoded, isSimulated: false);
              _telemetryController.add(telemetry);
            }
          } catch (_) {
            // Ignore corrupted frame
          }
        },
        onError: (err) {
          _setStatus(WsConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          _setStatus(WsConnectionStatus.disconnected);
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _setStatus(WsConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      if (_currentBaseUrl != null && _status != WsConnectionStatus.connected) {
        connect(_currentBaseUrl!);
      }
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setStatus(WsConnectionStatus.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    disconnect();
    _telemetryController.close();
    _statusController.close();
  }
}
