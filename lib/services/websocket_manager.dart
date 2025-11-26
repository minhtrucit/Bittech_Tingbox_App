import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// WebSocket Manager chuyên xử lý Socket.io
class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();

  factory WebSocketManager() => _instance;

  WebSocketManager._internal();

  io.Socket? _socket;
  bool _manuallyDisconnected = false;

  // Reconnect config
  final int maxRetry = 10;
  int _retryCount = 0;

  // Heartbeat variables
  Timer? _pingTimer;
  Duration pingInterval = const Duration(seconds: 25);

  bool get isConnected => _socket?.connected ?? false;

  /// Connect to Socket.io server
  void connect(String baseUrl) {
    if (isConnected || _socket != null) return;

    debugPrint("Socketio: Connecting to $baseUrl");

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // bắt buộc
          .setPath('/socket.io') // backend đang dùng đường dẫn này
          .disableAutoConnect() // tự quản lý connect
          .enableForceNew()
          .build(),
    );

    _attachListeners();
    _socket!.connect();
  }

  /// Attach all socket listeners
  void _attachListeners() {
    _socket!.onConnect((_) {
      debugPrint("Socketio: connected");
      _retryCount = 0;

      // Bật heartbeat
      _startHeartbeat();
    });

    _socket!.onDisconnect((_) {
      debugPrint("Socketio: disconnected");

      _stopHeartbeat();

      if (!_manuallyDisconnected) {
        _retryReconnect();
      }
    });

    _socket!.onError((err) {
      debugPrint("Socketio: Error $err");

      _stopHeartbeat();

      _retryReconnect();
    });

    _socket!.onReconnectAttempt((_) {
      debugPrint("Socketio: trying reconnect...");
    });
  }

  /// Emit event
  void emit(String event, dynamic data) {
    if (isConnected) {
      _socket?.emit(event, data);
    } else {
      debugPrint("Socketio: emit fail, socket not connected");
    }
  }

  /// Listen for event
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Remove listener
  void off(String event) {
    _socket?.off(event);
  }

  /// Retry reconnect with backoff
  void _retryReconnect() {
    if (_retryCount >= maxRetry) {
      debugPrint("Socketio: Max retry reached");
      return;
    }

    final delay = Duration(seconds: 2 * _retryCount + 1);
    debugPrint("Socketio: retrying in ${delay.inSeconds}s (retry $_retryCount)");

    Future.delayed(delay, () {
      if (!_manuallyDisconnected) {
        _retryCount++;
        _socket?.connect();
      }
    });
  }

  /// Heartbeat ping/pong
  void _startHeartbeat() {
    debugPrint("Socketio: Heartbeat started");

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (isConnected) {
        debugPrint("Socketio: ping");
        _socket?.emit("ping", {"ts": DateTime.now().millisecondsSinceEpoch});
      }
    });
  }

  void _stopHeartbeat() {
    debugPrint("Socketio: Heartbeat stopped");
    _pingTimer?.cancel();
  }

  /// Manual disconnect
  void disconnect() {
    debugPrint("Socketio: manual disconnect");

    _manuallyDisconnected = true;
    _stopHeartbeat();
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
  }
}
