import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';

class WebSocketService {
  final String url;
  WebSocketChannel? _channel;
  StreamController<dynamic> _controller = StreamController.broadcast();

  Stream<dynamic> get stream => _controller.stream;

  WebSocketService({required this.url});

  void connect() {
    debugPrint("🌐 Connecting WS: ${Uri.parse(url)}");

    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel!.stream.listen(
          (event) {
        debugPrint("📩 WS Event: $event");
        _controller.add(event);
      },
      onError: (error) {
        debugPrint("❌ WS Error: $error");
        _reconnect();
      },
      onDone: () {
        debugPrint("🔌 WS Closed");
        _reconnect();
      },
    );
  }

  void send(dynamic data) {
    _channel?.sink.add(data);
  }

  void _reconnect() {
    debugPrint("♻️ Reconnecting in 5s...");
    Future.delayed(const Duration(seconds: 5), () {
      connect();
    });
  }

  void dispose() {
    _channel?.sink.close(status.normalClosure);
    _controller.close();
  }
}
