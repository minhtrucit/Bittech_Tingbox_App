import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/extension/date_time_extension.dart';
import '../config/app_config.dart';
import '../models/mock_bluetooth_device.dart';
import '../models/order.dart';
import 'package:path_provider/path_provider.dart';
import '../models/config_model.dart';
import 'printer_discovery_service.dart';

class PrinterService {
  static const String _printerAddressKey = 'saved_printer_address';
  static const String _printerNameKey = 'saved_printer_name';

  MockBluetoothDevice? _connectedDevice;
  final Dio _dio = Dio();

  // ==================== PUBLIC METHODS ====================

  /// Quét thiết bị Bluetooth
  Future<List<MockBluetoothDevice>> scanDevices() async {
    if (AppConfig.isDemoMode) {
      return _mockScanDevices();
    } else {
      return _scanDevices();
    }
  }

  /// Kết nối máy in
  Future<bool> connectPrinter(String address, String name) async {
    if (AppConfig.isDemoMode) {
      return _mockConnect(address, name);
    } else {
      return _connect(address, name);
    }
  }

  /// Kiểm tra đã kết nối chưa
  Future<bool> isConnected() async {
    if (AppConfig.isDemoMode) {
      return _connectedDevice?.isConnected ?? false;
    } else {
      return true; // Với Agent luôn coi là true
    }
  }

  /// In hóa đơn
  Future<bool> printReceipt(Order order, {ConfigModel? config}) async {
    if (AppConfig.isDemoMode) {
      return _mockPrint(order, config);
    } else {
      return _print(order, config);
    }
  }

  /// Kiểm tra máy in có khả dụng không (với WMIC status check)
  Future<Map<String, dynamic>?> checkPrinterAvailability() async {
    try {
      debugPrint(
        '🚀 [PrinterService] Target URL: ${AppConfig.printerAgentUrl}',
      );
      debugPrint('🔍 [PrinterService] Checking printer availability...');

      final response = await _dio.get(
        '${AppConfig.printerAgentUrl}/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final printerData = data['printer'];

        debugPrint('✅ [PrinterService] Printer status: $printerData');

        return {
          // Kiểm tra máy in ONLINE (không chỉ installed)
          'available': (printerData['online'] ?? 0) > 0,
          'defaultPrinter': printerData['default'] ?? 'N/A',
          'defaultStatus': printerData['defaultStatus'] ?? 'Unknown',
          'defaultIsOnline': printerData['defaultIsOnline'] ?? false,
          'configuredPrinter': printerData['configured'] ?? '',
          'totalPrinters': printerData['total'] ?? 0,
          'onlinePrinters': printerData['online'] ?? 0,
          'offlinePrinters': printerData['offline'] ?? 0,
          'status': data['status'],
        };
      }

      return null;
    } catch (e) {
      debugPrint('❌ [PrinterService] Error checking printer: $e');
      return null;
    }
  }

  /// Lấy danh sách tất cả máy in
  Future<List<Map<String, dynamic>>> getPrintersList() async {
    try {
      debugPrint(
        '🚀 [PrinterService] Target URL: ${AppConfig.printerAgentUrl}',
      );
      debugPrint('🔍 [PrinterService] Fetching printers list...');

      final response = await _dio
          .get(
            '${AppConfig.printerAgentUrl}/printers',
            options: Options(
              receiveTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 5),
            ),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200 && response.data is List) {
        final printers =
            (response.data as List)
                .map((p) => p as Map<String, dynamic>)
                .toList();

        debugPrint('✅ [PrinterService] Found ${printers.length} printer(s)');
        return printers;
      }

      return [];
    } catch (e) {
      debugPrint('❌ [PrinterService] Error fetching printers: $e');
      return [];
    }
  }

  /// Lưu máy in đã chọn
  Future<void> savePrinter(String address, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerAddressKey, address);
    await prefs.setString(_printerNameKey, name);
  }

  /// Lấy máy in đã lưu
  Future<Map<String, String>?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_printerAddressKey);
    final name = prefs.getString(_printerNameKey);

    if (address != null && name != null) {
      return {'address': address, 'name': name};
    }
    return null;
  }

  /// Xóa máy in đã lưu
  Future<void> clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_printerAddressKey);
    await prefs.remove(_printerNameKey);
    _connectedDevice = null;
  }

  // ==================== MOCK METHODS (DEMO MODE) ====================

  Future<List<MockBluetoothDevice>> _mockScanDevices() async {
    debugPrint('🔍 [MOCK] Scanning for Bluetooth devices...');
    await Future.delayed(Duration(seconds: 1));

    return [
      MockBluetoothDevice(
        name: 'Demo Printer 58mm',
        address: 'DEMO:00:11:22:33:44',
      ),
      MockBluetoothDevice(
        name: 'Demo Printer 80mm',
        address: 'DEMO:AA:BB:CC:DD:EE',
      ),
      MockBluetoothDevice(
        name: 'Sunmi V2 Pro (Demo)',
        address: 'DEMO:FF:EE:DD:CC:BB',
      ),
    ];
  }

  Future<bool> _mockConnect(String address, String name) async {
    debugPrint('🔌 [MOCK] Connecting to printer: $name ($address)');
    await Future.delayed(Duration(milliseconds: 800));

    _connectedDevice = MockBluetoothDevice(
      name: name,
      address: address,
      isConnected: true,
    );

    // Lưu vào SharedPreferences
    await savePrinter(address, name);

    debugPrint('✅ [MOCK] Connected successfully');
    return true;
  }

  Future<bool> _mockPrint(Order order, ConfigModel? config) async {
    debugPrint('📄 [MOCK] Printing receipt for Order #${order.id}');
    debugPrint('   Customer: ${order.customerName}');
    debugPrint('   Total: ${order.totalAmount}');
    debugPrint('   Items: ${order.items.length}');

    await Future.delayed(Duration(seconds: 2)); // Giả lập thời gian in

    debugPrint('✅ [MOCK] Print completed successfully');
    return true;
  }

  // ==================== REAL METHODS (PRODUCTION MODE) ====================

  Future<List<MockBluetoothDevice>> _scanDevices() async {
    return [];
  }

  Future<bool> _connect(String address, String name) async {
    return true;
  }

  Future<File> fetchReceiptPreviewPdf(Map<String, dynamic> receiptData) async {
    try {
      debugPrint(
        '🚀 [PrinterService] Target URL: ${AppConfig.printerAgentUrl}',
      );
      debugPrint('📄 [PrinterService] Fetching receipt preview PDF...');
      debugPrint('📤 [PrinterService] Receipt data: $receiptData');

      final response = await _dio
          .post(
            '${AppConfig.printerAgentUrl}/preview-pdf',
            data: receiptData,
            options: Options(
              responseType: ResponseType.bytes,
              headers: {'Content-Type': 'application/json'},
            ),
          )
          .timeout(Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Không thể tạo preview PDF: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/receipt_preview_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      await file.writeAsBytes(response.data as List<int>);

      debugPrint('✅ [PrinterService] PDF saved to: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ [PrinterService] Error fetching PDF: $e');
      rethrow;
    }
  }

  Future<bool> _print(Order order, ConfigModel? config) async {
    debugPrint('🚀 [PrinterService] Target URL: ${AppConfig.printerAgentUrl}');
    debugPrint(
      '📄 [REAL] Printing to Node.js Print Agent via Structured API...',
    );
    try {
      final receiptData = _formatReceiptData(order, config);

      debugPrint('Receipt data: $receiptData');
      final response = await _dio
          .post('${AppConfig.printerAgentUrl}/print', data: receiptData)
          .timeout(Duration(seconds: 30));

      debugPrint('Print response: ${response.data}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('✅ [REAL] Print request sent successfully');
        return true;
      } else {
        debugPrint('❌ [REAL] Print request failed: ${response.data}');
        PrinterDiscoveryService().handlePrintFailure();
        return false;
      }
    } catch (e) {
      debugPrint('❌ [REAL] Error calling Print Agent API: $e');
      PrinterDiscoveryService().handlePrintFailure();
      return false;
    }
  }

  Map<String, String> _formatReceiptData(Order order, ConfigModel? config) {
    final headerBuffer = StringBuffer();
    final productsBuffer = StringBuffer();
    final footerBuffer = StringBuffer();

    final unitName = config?.unitName ?? 'TÊN CỬA HÀNG';
    final address = config?.address ?? '';
    final phone = config?.phone ?? '';
    final date = order.createdAt?.toReadableDateTime() ?? '';

    // --- HEADER: Thông tin cửa hàng + Tên hóa đơn ---
    headerBuffer.writeln(unitName.toUpperCase());
    if (address.isNotEmpty) headerBuffer.writeln(address);
    if (phone.isNotEmpty) headerBuffer.writeln('DT: $phone');
    headerBuffer.writeln('Hóa đơn bán hàng');

    // --- PRODUCTS (BODY): Thông tin đơn hàng + Danh sách sản phẩm + Tổng tiền ---
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
    productsBuffer.writeln('================================');
    productsBuffer.writeln(
      _justifyText('Tổng cộng:', formatMoney(order.totalAmount ?? 0), 32),
    );
    productsBuffer.writeln('--------------------------------');
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

    // --- FOOTER: Cảm ơn + Chào tạm biệt ---
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
}
