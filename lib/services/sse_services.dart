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
  bool get isConnected => _isConnected;

  SSEService._();

  static final SSEService instance = SSEService._();

  Future<void> connect() async {
    if (_isConnected) return;

    final apiKey = dotenv.get('OCR_API_KEY');

    final baseUrl = dotenv.get('OCR_API_URL');
    final url = '$baseUrl/api/events';

    debugPrint('[SSE] Connecting to $url using flutter_client_sse...');

    try {
      _isConnected = true;
      SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: url,
        header: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'x-api-key': apiKey,
        },
      ).listen(
        (event) {
          if (event.id == 'heartbeat' ||
              (event.data?.contains('heartbeat') ?? false)) {
            debugPrint('[SSE] Received heartbeat 💓');
            return;
          }

          // Hiển thị toàn bộ dữ liệu trả về (không bị cắt bớt)
          debugPrint('[SSE-RAW] Event: ${event.event}, Data: ${event.data}');

          if (event.data != null && event.data!.isNotEmpty) {
            dynamic decodedData;
            try {
              decodedData = jsonDecode(event.data!);
            } catch (_) {
              decodedData = event.data;
            }

            final sseEvent = SseEvent(event: event.event, data: decodedData);

            debugPrint('[SSE] Dispatching Event: ${event.event ?? "message"}');
            _eventController.add(sseEvent);
          }
        },
        onError: (error) {
          debugPrint('[SSE] Connection error');
          _isConnected = false;
        },
      );
    } catch (e) {
      debugPrint('[SSE] Failed to subscribe');
      _isConnected = false;
    }
  }

  void disconnect() {
    SSEClient.unsubscribeFromSSE();
    _isConnected = false;
    debugPrint('[SSE] Disconnected');
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
