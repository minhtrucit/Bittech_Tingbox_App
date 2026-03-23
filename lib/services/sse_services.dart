import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SseEvent {
  final String? event;
  final dynamic data;

  SseEvent({this.event, this.data});

  @override
  String toString() => 'SseEvent(event: $event, data: $data)';
}

class SSEService {
  final _eventController = StreamController<SseEvent>.broadcast();
  Stream<SseEvent> get eventStream => _eventController.stream;

  bool _isConnected = false;
  bool _isDisposed = false; // ✅ Thêm flag này
  StreamSubscription? _subscription; // ✅ Giữ reference subscription

  bool get isConnected => _isConnected;

  SSEService._();
  static final SSEService instance = SSEService._();

  Future<void> connect() async {
    if (_isConnected || _isDisposed) return; // ✅ Check disposed

    final apiKey = dotenv.get('OCR_API_KEY');
    final baseUrl = dotenv.get('OCR_API_URL');
    final url = '$baseUrl/api/events';

    debugPrint('[SSE] Connecting to $url...');

    try {
      _isConnected = true;
      _subscription = SSEClient.subscribeToSSE( // ✅ Lưu subscription
        method: SSERequestType.GET,
        url: url,
        header: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'x-api-key': apiKey,
        },
      ).listen(
        (event) {
          if (_isDisposed) return; // ✅ Guard

          if (event.id == 'heartbeat' ||
              (event.data?.contains('heartbeat') ?? false)) {
            debugPrint('[SSE] Received heartbeat 💓');
            return;
          }

          debugPrint('[SSE-RAW] Event: ${event.event}, Data: ${event.data}');

          if (event.data != null && event.data!.isNotEmpty) {
            dynamic decodedData;
            try {
              decodedData = jsonDecode(event.data!);
            } catch (_) {
              decodedData = event.data;
            }

            if (!_isDisposed) { // ✅ Guard trước khi add
              _eventController.add(SseEvent(event: event.event, data: decodedData));
            }
          }
        },
        onError: (error) {
          debugPrint('[SSE] Connection error');
          _isConnected = false;
          // ✅ Không retry nếu đã disconnect chủ động
          if (!_isDisposed) {
            debugPrint('---RETRY CONNECTION---');
            Future.delayed(const Duration(seconds: 3), () {
              if (!_isDisposed) connect();
            });
          }
        },
      );
    } catch (e) {
      debugPrint('[SSE] Failed to subscribe');
      _isConnected = false;
    }
  }

  void disconnect() {
    _isDisposed = true;        // ✅ Stop mọi retry
    _isConnected = false;
    _subscription?.cancel();   // ✅ Cancel subscription
    _subscription = null;
    SSEClient.unsubscribeFromSSE();
    debugPrint('[SSE] Disconnected');
  }

  // Gọi khi login lại để reset
  void reset() {
    _isDisposed = false; // ✅ Cho phép connect lại
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}