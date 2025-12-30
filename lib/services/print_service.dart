import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/order.dart';
import '../models/config_model.dart';
import '../extension/date_time_extension.dart';

/// PrintService handles the connection to TingBox Relay Server via Socket.io.
/// It allows discovering printers on remote agents and sending print jobs.
class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  IO.Socket? _socket;

  // Reactive connection status
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  // Custom Logger
  void _log(String message) {
    final now = DateTime.now();
    final time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    debugPrint('[$time] $message');
  }

  // Configuration Constants
  static const String _prefKeyAgentId = 'remote_print_agent_id';
  static const String _prefKeyPrinterName = 'remote_print_printer_name';

  String _currentServerUrl = 'ws://192.168.200.241:3000';
  String _currentAgentId = 'USER_01'; // Default Agent ID
  String _currentApiKey = 'TINGBOX_KEY_2024'; // Default API Key

  /// Initialize the socket connection and load saved settings
  Future<void> init({
    String? agentId,
    String? apiKey,
    String? serverUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final newAgentId = agentId ?? prefs.getString(_prefKeyAgentId) ?? 'USER_01';
    final newApiKey = apiKey ?? 'TINGBOX_KEY_2024';
    final newServerUrl = serverUrl ?? _currentServerUrl;

    // Improved skipping logic: Only skip if parameters match AND we are already CONNECTED
    if (_socket != null &&
        _currentAgentId == newAgentId &&
        _currentApiKey == newApiKey &&
        _currentServerUrl == newServerUrl &&
        _socket!.connected) {
      _log(
        'ℹ️ [PrintService] Already connected with same credentials. Skipping init.',
      );
      return;
    }

    _currentAgentId = newAgentId;
    _currentApiKey = newApiKey;
    _currentServerUrl = newServerUrl;

    if (_socket != null) {
      _log('🔄 [PrintService] Re-initializing socket...');
      _socket!.disconnect();
      _socket!.dispose();
    }

    _log('🚀 [PrintService] Connecting to Relay Server: $_currentServerUrl');
    _log(
      '📄 [PrintService] Credentials: { x-agent-id: $_currentAgentId, x-api-key: $_currentApiKey }',
    );

    _socket = IO.io(
      _currentServerUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({
            'agentId': _currentAgentId,
            'apiKey': _currentApiKey,
          }) // BACK: Query is more stable for initial handshake
          .setExtraHeaders({
            'x-agent-id': _currentAgentId,
            'x-api-key': _currentApiKey,
          })
          .setReconnectionAttempts(99) // Try reconnecting almost indefinitely
          .setReconnectionDelay(5000) // Wait 5 seconds between attempts
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _log('🟢 [PrintService] Connected to Relay Server');
      isConnected.value = true;
    });

    _socket!.onDisconnect((reason) {
      _log('🔴 [PrintService] Disconnected: $reason');
      isConnected.value = false;
      if (reason == 'io server disconnect') {
        _log(
          '🚨 [PrintService] Connection was explicitly closed by server. Checking credentials...',
        );
        // In case of explicit server kick, try to reconnect manually after a delay
        Future.delayed(const Duration(seconds: 2), () => _socket?.connect());
      }
    });

    _socket!.onConnectError((data) {
      _log('🟠 [PrintService] Connection Error: $data');
      isConnected.value = false;
    });

    _socket!.onReconnect((_) {
      _log('♻️ [PrintService] Reconnected successfully');
      isConnected.value = true;
    });

    _socket!.onReconnectAttempt((count) {
      _log('🔄 [PrintService] Reconnect attempt #$count');
    });

    _socket!.onReconnectError((data) {
      _log('⚠️ [PrintService] Reconnection Error: $data');
    });

    _socket!.onError((data) {
      _log('🔴 [PrintService] Socket Error: $data');
    });
  }

  /// Save printer selection for auto-print
  Future<void> savePrinterSettings(String agentId, String printerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyAgentId, agentId);
    await prefs.setString(_prefKeyPrinterName, printerName);
    _currentAgentId = agentId;
  }

  /// Get saved settings
  Future<Map<String, String?>> getSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'agentId': prefs.getString(_prefKeyAgentId),
      'printerName': prefs.getString(_prefKeyPrinterName),
    };
  }

  /// Format Order to Print Data
  Map<String, String> formatOrderData(Order order, ConfigModel? config) {
    final businessName = config?.unitName ?? 'Cửa hàng TingBox';
    final phone = config?.phone ?? '';
    final address = config?.address ?? '';

    // Simple text format for thermal printers
    return {
      'type': 'RECEIPT',
      'title': 'HÓA ĐƠN THANH TOÁN',
      'header': '$businessName\nSĐT: $phone\nĐC: $address',
      'orderCode': order.code ?? order.id.toString(),
      'date': DateTime.now().toIso8601String().toReadableDateTime(),
      'items': jsonEncode(
        order.items.map((item) {
          return {
            'name': item.product?.name ?? 'Sản phẩm',
            'qty': item.quantity,
            'price': item.unitPrice,
            'total': item.quantity * item.unitPrice,
          };
        }).toList(),
      ),
      'total': order.totalAmount?.toString() ?? '0',
      'footer': 'Cảm ơn quý khách!\nHẹn gặp lại!',
    };
  }

  /// Auto-print an order based on saved settings
  Future<bool> autoPrintOrder(Order order, ConfigModel? config) async {
    final settings = await getSavedSettings();
    final printerName = settings['printerName'];

    // Priorities: Saved setting > Stable ID (BITTECH_USER_{id})
    final agentId =
        settings['agentId'] ??
        (config?.id != null ? 'BITTECH_USER_${config!.id}' : null);

    if (agentId == null || printerName == null) {
      _log('⚠️ [PrintService] Auto-print skipped: No agent or printer saved');
      return false;
    }

    try {
      // Re-initialize if the API Key from config is different or if not connected
      if (config?.sepayApiKey != null &&
          config?.sepayApiKey != _currentApiKey) {
        _log('🔑 [PrintService] Key changed, re-initializing...');
        await init(agentId: agentId, apiKey: config?.sepayApiKey);
      } else if (!isConnected.value) {
        await init(agentId: agentId, apiKey: config?.sepayApiKey);
      }

      final printData = formatOrderData(order, config);
      final result = await sendPrint(
        targetAgentId: agentId,
        printerName: printerName,
        printData: printData,
      );
      return result['success'] == true;
    } catch (e) {
      _log('🚨 [PrintService] Auto-print failed: $e');
      return false;
    }
  }

  /// Get list of printers from a target Agent ID
  Future<List<String>> getPrinters(String targetAgentId) {
    _log('🔍 [PrintService] Requesting printers from agent: $targetAgentId');
    final completer = Completer<List<String>>();
    if (_socket == null || !_socket!.connected) {
      _log('❌ [PrintService] getPrinters failed: Socket not connected');
      return Future.error('Not connected to Relay Server');
    }

    _log(
      '📤 [PrintService] >> EMIT: get-printers-request | Payload: {targetAgentId: $targetAgentId}',
    );
    _socket!.emitWithAck(
      'get-printers-request',
      {'targetAgentId': targetAgentId},
      ack: (data) {
        _log(
          '📥 [PrintService] << ACK: get-printers-request | Data: ${jsonEncode(data)}',
        );
        if (data != null && data['success'] == true) {
          final List<dynamic> printersList = data['printers'] ?? [];
          _log(
            '✅ [PrintService] Success: Found ${printersList.length} printers',
          );
          completer.complete(printersList.map((e) => e.toString()).toList());
        } else {
          final error = data?['error'] ?? 'Agent did not respond or failed';
          _log('⚠️ [PrintService] Agent Error: $error');
          completer.completeError(error);
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _log('⏳ [PrintService] Timeout: get-printers-request after 20s');
        throw TimeoutException('Agent $targetAgentId did not respond in time');
      },
    );
  }

  /// Send a print job
  Future<Map<String, dynamic>> sendPrint({
    required String targetAgentId,
    required String printerName,
    required Map<String, String> printData,
  }) {
    _log('🖨️ [PrintService] Preparing print job...');
    final completer = Completer<Map<String, dynamic>>();

    if (_socket == null || !_socket!.connected) {
      _log('❌ [PrintService] sendPrint failed: Socket not connected');
      return Future.error('Not connected to Relay Server');
    }

    final payload = {
      'targetAgentId': targetAgentId,
      'printData': {...printData, 'printerName': printerName},
    };

    _log(
      '📤 [PrintService] >> EMIT: send-print-request | Target: $targetAgentId',
    );
    _socket!.emitWithAck(
      'send-print-request',
      payload,
      ack: (data) {
        _log(
          '📥 [PrintService] << ACK: send-print-request | Data: ${jsonEncode(data)}',
        );
        if (data != null) {
          completer.complete(Map<String, dynamic>.from(data));
        } else {
          _log('⚠️ [PrintService] Receive null ACK for send-print-request');
          completer.complete({'success': false, 'error': 'No response'});
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _log('⏳ [PrintService] Timeout: send-print-request after 15s');
        return {'success': false, 'error': 'Print request timed out'};
      },
    );
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
  }
}
