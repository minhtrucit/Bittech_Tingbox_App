import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/mock_bluetooth_device.dart';
import '../models/order.dart';
import '../models/config_model.dart';

class PrinterService {
  static const String _printerAddressKey = 'saved_printer_address';
  static const String _printerNameKey = 'saved_printer_name';

  MockBluetoothDevice? _connectedDevice;

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
      return _isConnected();
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
    debugPrint('🔍 [REAL] Scanning for real Bluetooth devices...');
    try {
      return [];
    } catch (e) {
      debugPrint('❌ Error scanning devices: $e');
      return [];
    }
  }

  Future<bool> _connect(String address, String name) async {
    debugPrint('🔌 [REAL] Connecting to real printer: $name ($address)');
    try {
      
      return false;
    } catch (e) {
      debugPrint('❌ Error connecting to printer: $e');
      return false;
    }
  }

  Future<bool> _isConnected() async {
    try {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _print(Order order, ConfigModel? config) async {
    debugPrint('📄 [REAL] Printing to real printer...');
    return false;
      
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
