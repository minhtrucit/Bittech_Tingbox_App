import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/order.dart';
import '../models/config_model.dart';
import '../extension/date_time_extension.dart';

/// PrintService handles the connection to TingBox Relay Server via Socket.io.
/// It allows discovering printers on remote agents and sending print jobs.
class PrintService {
  static final PrintService _instance = PrintService._internal();
  factory PrintService() => _instance;
  PrintService._internal();

  io.Socket? _socket;

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

  String _currentServerUrl = dotenv.get('RELAY_SERVER_URL');
  String _currentAgentId = '';
  String _currentApiKey = '';
  final Map<int, DateTime> _lastPrintedOrders = {};

  /// Initialize the socket connection and load saved settings
  Future<void> init({
    String? agentId,
    String? apiKey,
    String? serverUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Ưu tiên: Tham số truyền vào > SharedPreferences > Rỗng
    final newAgentId = agentId ?? prefs.getString(_prefKeyAgentId) ?? '';
    final newApiKey = apiKey ?? '';
    final newServerUrl = serverUrl ?? _currentServerUrl;

    if (newAgentId.isEmpty || newApiKey.isEmpty) {
      _log('⚠️ [PrintService] Bỏ qua khởi tạo: Thiếu AgentID hoặc ApiKey');
      return;
    }

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

    _socket = io.io(
      _currentServerUrl,
      io.OptionBuilder()
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
    final headerBuffer = StringBuffer();
    final productsBuffer = StringBuffer();
    final footerBuffer = StringBuffer();
    //?? config?.unitName ?? 'TÊN CỬA HÀNG'
    final unitName = 'CÔNG TY TNHH CÔNG NGHỆ BITTECH';
    final address = config?.address ?? '';
    final phone = config?.phone ?? '';
    final date = order.createdAt?.toReadableDateTime() ?? '';

    // --- HEADER ---
    headerBuffer.writeln(unitName.toUpperCase());
    if (address.isNotEmpty) headerBuffer.writeln(address);
    if (phone.isNotEmpty) headerBuffer.writeln('DT: $phone');
    headerBuffer.writeln('HÓA ĐƠN BÁN HÀNG');

    // --- PRODUCTS (BODY) ---
    productsBuffer.writeln('Mã đơn: #${order.code}-${order.id}');
    productsBuffer.writeln('Ngày: $date');
    if (order.customerName.isNotEmpty) {
      productsBuffer.writeln('Khách hàng: ${order.customerName}');
    }
    productsBuffer.writeln('--------------------------------');

    for (var item in order.items) {
      final itemName = item.product?.name ?? 'Sản phẩm #${item.productId}';
      productsBuffer.writeln(itemName);
      final qtyPrice = '${item.quantity} x ${formatMoney(item.unitPrice)}';
      final total = formatMoney(item.unitPrice * item.quantity);
      final line = _justifyText(qtyPrice, total, 32);
      productsBuffer.writeln(line);
    }

    productsBuffer.writeln('--------------------------------');
    productsBuffer.writeln(
      _justifyText('Tạm tính:', formatMoney(order.subtotal ?? 0), 32),
    );
    if (order.vat > 0) {
      final vatAmount = (order.subtotal ?? 0) * order.vat / 100;
      productsBuffer.writeln(
        _justifyText(
          'VAT (${order.vat.toInt()}%):',
          formatMoney(vatAmount),
          32,
        ),
      );
    }
    if (order.discount > 0) {
      productsBuffer.writeln(
        _justifyText('Giảm giá:', formatMoney(order.discount), 32),
      );
    }
    productsBuffer.writeln(
      _justifyText('Tổng cộng:', formatMoney(order.totalAmount ?? 0), 32),
    );
    productsBuffer.writeln(
      _justifyText('Đã thanh toán:', formatMoney(order.paidAmount), 32),
    );

    final remaining = (order.totalAmount ?? 0) - order.paidAmount;
    if (remaining > 0) {
      productsBuffer.writeln(
        _justifyText('Còn lại:', formatMoney(remaining), 32),
      );
    } else if (remaining < 0) {
      productsBuffer.writeln(
        _justifyText('Tiền thừa:', formatMoney(remaining.abs()), 32),
      );
    }

    // --- FOOTER ---
    footerBuffer.writeln('\nCảm ơn quý khách!');
    footerBuffer.writeln('Hẹn gặp lại\n\n\n');

    return {
      'header': headerBuffer.toString(),
      'products': productsBuffer.toString(),
      'footer': footerBuffer.toString(),
    };
  }

  String _justifyText(String left, String right, int width) {
    final spaces = width - left.length - right.length;
    if (spaces <= 0) return '$left $right';
    return left + (' ' * spaces) + right;
  }

  String formatMoney(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Fetch receipt preview PDF from the agent via Socket.io
  Future<File> fetchReceiptPreviewPdf({
    required String targetAgentId,
    required Map<String, dynamic> receiptData,
  }) async {
    try {
      debugPrint('� [PrinterService] Target Agent ID: $targetAgentId');
      debugPrint('📄 [PrinterService] Fetching receipt preview PDF...');
      debugPrint('📤 [PrinterService] Receipt data: $receiptData');

      final completer = Completer<File>();

      if (_socket == null || !_socket!.connected) {
        throw Exception('Socket not connected to Relay Server');
      }

      final payload = {'targetAgentId': targetAgentId, 'data': receiptData};

      _socket!.emitWithAck(
        'preview-pdf-request',
        payload,
        ack: (data) async {
          if (data != null && data['success'] == true) {
            try {
              final List<int> pdfBytes;
              if (data['pdfBase64'] != null) {
                // Agent returns pdfBase64 string
                pdfBytes = base64Decode(data['pdfBase64']);
              } else if (data['pdf'] != null) {
                // Fallback for bytes/list format if ever used
                if (data['pdf'] is Uint8List) {
                  pdfBytes = data['pdf'] as Uint8List;
                } else if (data['pdf'] is List) {
                  pdfBytes = List<int>.from(data['pdf']);
                } else {
                  throw Exception('Định dạng pdf không xác định');
                }
              } else {
                throw Exception('Không tìm thấy dữ liệu PDF trong phản hồi');
              }

              final tempDir = await getTemporaryDirectory();
              final file = File(
                '${tempDir.path}/receipt_preview_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );

              await file.writeAsBytes(pdfBytes);

              debugPrint('✅ [PrinterService] PDF saved to: ${file.path}');
              completer.complete(file);
            } catch (e) {
              completer.completeError(e);
            }
          } else {
            completer.completeError(
              Exception(data?['error'] ?? 'Agent failed to generate PDF'),
            );
          }
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Yêu cầu xem trước PDF quá hạn (20s)');
        },
      );
    } catch (e) {
      debugPrint('❌ [PrinterService] Error fetching PDF: $e');
      rethrow;
    }
  }

  /// Auto-print an order based on saved settings
  Future<bool?> autoPrintOrder(Order order, ConfigModel? config) async {
    final orderId = order.id;
    if (orderId == null) return false;

    // Registry check: prevent printing the same order multiple times within 60 seconds
    final lastPrintTime = _lastPrintedOrders[orderId];
    if (lastPrintTime != null &&
        DateTime.now().difference(lastPrintTime).inSeconds < 60) {
      _log(
        '🚫 [PrintService] Auto-print ignored: Order #$orderId was already printed recently',
      );
      return null;
    }

    _lastPrintedOrders[orderId] = DateTime.now();
    _log(' [PrintService] Starting auto-print for order #${order.code}...');
    final settings = await getSavedSettings();
    final savedPrinterName = settings['printerName'];
    final savedAgentId = settings['agentId'];

    _log(
      ' [PrintService] Saved settings: { agentId: $savedAgentId, printerName: $savedPrinterName }',
    );

    // Priorities: Saved setting > Stable ID (BITTECH_USER_{id})
    final prefix = dotenv.get('AGENT_ID_PREFIX', fallback: 'BITTECH_USER_');
    final agentId =
        savedAgentId ?? (config?.id != null ? '$prefix${config!.id}' : null);

    _log(
      ' [PrintService] Final Target Agent ID: $agentId (using prefix: $prefix)',
    );

    if (agentId == null || savedPrinterName == null) {
      _log(
        '⚠️ [PrintService] Auto-print skipped: Missing critical settings. AgentId: $agentId, Printer: $savedPrinterName',
      );
      return false;
    }

    try {
      // Re-initialize if the API Key from config is different or if not connected
      bool needReconnect = false;
      if (config?.sepayApiKey != null &&
          config?.sepayApiKey != _currentApiKey) {
        _log('🔑 [PrintService] Reconnect reason: API Key changed');
        needReconnect = true;
      } else if (!isConnected.value) {
        _log(
          '🔑 [PrintService] Reconnect reason: Socket currently disconnected',
        );
        needReconnect = true;
      }

      if (needReconnect) {
        _log('🔄 [PrintService] Re-initializing connection before print...');
        await init(agentId: agentId, apiKey: config?.sepayApiKey);
      }

      _log('📝 [PrintService] Formatting order data...');
      final printData = formatOrderData(order, config);
      _log(
        '📤 [PrintService] Sending print request to printer: $savedPrinterName',
      );

      final result = await sendPrint(
        targetAgentId: agentId,
        printerName: savedPrinterName,
        printData: printData,
      );

      final isSuccess = result['success'] == true;
      if (isSuccess) {
        _log('✅ [PrintService] Auto-print successful for order #${order.code}');
      } else {
        _log(
          '❌ [PrintService] Auto-print failed for order #${order.code}. Error: ${result['error']}',
        );
      }
      return isSuccess;
    } catch (e, stack) {
      _log('🚨 [PrintService] Critical error during auto-print: $e');
      debugPrint('$stack');
      // On failure, we might want to allow a retry, so remove from registry
      _lastPrintedOrders.remove(orderId);
      return false;
    } finally {
      // Cleanup old entries (older than 1 minute) to keep the map small
      _lastPrintedOrders.removeWhere(
        (key, value) => DateTime.now().difference(value).inSeconds > 60,
      );
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
