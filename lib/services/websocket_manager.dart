import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// WebSocket Manager chuyên xử lý Socket.IO
class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();

  factory WebSocketManager() => _instance;

  WebSocketManager._internal();

  IO.Socket? _socket;
  bool _manuallyDisconnected = false;

  // Reconnect config
  final int maxRetry = 10;
  int _retryCount = 0;

  // Heartbeat variables
  Timer? _pingTimer;
  Duration pingInterval = const Duration(seconds: 25);

  bool get isConnected => _socket?.connected ?? false;

  /// Connect to Socket.IO server
  void connect(String baseUrl) {
    if (isConnected || _socket != null) return;

    print("SocketIO: Connecting to $baseUrl");

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
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
      print("SocketIO: connected");
      _retryCount = 0;

      // Bật heartbeat
      _startHeartbeat();
    });

    _socket!.onDisconnect((_) {
      print("SocketIO: disconnected");

      _stopHeartbeat();

      if (!_manuallyDisconnected) {
        _retryReconnect();
      }
    });

    _socket!.onError((err) {
      print("SocketIO: Error $err");

      _stopHeartbeat();

      _retryReconnect();
    });

    _socket!.onReconnectAttempt((_) {
      print("SocketIO: trying reconnect...");
    });
  }

  /// Emit event
  void emit(String event, dynamic data) {
    if (isConnected) {
      _socket?.emit(event, data);
    } else {
      print("SocketIO: emit fail, socket not connected");
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
      print("SocketIO: Max retry reached");
      return;
    }

    final delay = Duration(seconds: 2 * _retryCount + 1);
    print("SocketIO: retrying in ${delay.inSeconds}s (retry $_retryCount)");

    Future.delayed(delay, () {
      if (!_manuallyDisconnected) {
        _retryCount++;
        _socket?.connect();
      }
    });
  }

  /// Heartbeat ping/pong
  void _startHeartbeat() {
    print("SocketIO: Heartbeat started");

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (isConnected) {
        print("SocketIO: ping");
        _socket?.emit("ping", {"ts": DateTime.now().millisecondsSinceEpoch});
      }
    });
  }

  void _stopHeartbeat() {
    print("SocketIO: Heartbeat stopped");
    _pingTimer?.cancel();
  }

  /// Manual disconnect
  void disconnect() {
    print("SocketIO: manual disconnect");

    _manuallyDisconnected = true;
    _stopHeartbeat();
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
  }
}
