import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ting_box/config/app_config.dart';

class PrinterDiscoveryService {
  static final PrinterDiscoveryService _instance =
      PrinterDiscoveryService._internal();
  factory PrinterDiscoveryService() => _instance;
  PrinterDiscoveryService._internal();

  static const String _printerUrlKey = 'discovered_printer_url';
  static const int _discoveryPort = 5050;
  static const Duration _timeout = Duration(milliseconds: 300);
  static const int _concurrentScans = 20;

  final Dio _dio = Dio(
    BaseOptions(connectTimeout: _timeout, receiveTimeout: _timeout),
  );

  final StreamController<bool> _discoveryStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get discoveryStatusStream => _discoveryStatusController.stream;

  final StreamController<String> _discoveryResultController =
      StreamController<String>.broadcast();
  Stream<String> get discoveryResultStream => _discoveryResultController.stream;

  String? _discoveredUrl;
  bool _isScanning = false;
  Timer? _retryTimer;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _discoveredUrl = prefs.getString(_printerUrlKey);

    if (_discoveredUrl != null) {
      debugPrint('💾 [Discovery] Loaded saved URL: $_discoveredUrl');
      AppConfig.updatePrinterUrl(_discoveredUrl!);
    }

    // Listen for network changes
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty &&
          results.any((r) => r == ConnectivityResult.wifi)) {
        debugPrint('📡 WiFi connectivity detected, starting discovery...');
        discover();
      }
    });

    // Initial validation of saved URL (Low cost, only 1 request)
    if (_discoveredUrl != null) {
      _validatePrinterUrl(_discoveredUrl!);
    }
  }

  Future<String?> get printerUrl async {
    if (_discoveredUrl == null) {
      await discover();
    }
    return _discoveredUrl;
  }

  Future<void> discover() async {
    if (_isScanning) return;
    _isScanning = true;
    _discoveryStatusController.add(true);

    try {
      final info = NetworkInfo();
      final String? ip = await info.getWifiIP();

      if (ip == null) {
        debugPrint('❌ [Discovery] No WiFi IP found. Clearing printer URL...');
        _discoveredUrl = null;
        AppConfig.updatePrinterUrl(null);
        return;
      }

      final String subnet = ip.substring(0, ip.lastIndexOf('.'));

      // Check if we are on a different subnet than the saved one
      if (_discoveredUrl != null && !_discoveredUrl!.contains(subnet)) {
        debugPrint(
          '🌐 [Discovery] Subnet changed! Invaliding old printer URL.',
        );
        _discoveredUrl = null;
        // Don't update AppConfig yet, let it stay until we find a new one or fail
      }

      debugPrint('🔍 [Discovery] Scanning subnet: $subnet.0/24');

      final List<String> ips = List.generate(254, (i) => '$subnet.${i + 1}');
      String? foundUrl;

      for (var i = 0; i < ips.length; i += _concurrentScans) {
        final chunk = ips.skip(i).take(_concurrentScans);
        final results = await Future.wait(chunk.map((ip) => _checkIp(ip)));
        foundUrl = results.firstWhere((url) => url != null, orElse: () => null);
        if (foundUrl != null) break;
      }

      if (foundUrl != null) {
        await _savePrinterUrl(foundUrl);
        debugPrint('✅ [Discovery] Printer found at: $foundUrl');
        _stopRetryTimer(); // Stop retrying once found
      } else {
        debugPrint('⚠️ [Discovery] No Print Agent found in this subnet');
        // If we were scanning because of a network change and found nothing,
        // we should clear the old cached URL so it falls back to default.
        if (_discoveredUrl == null) {
          AppConfig.updatePrinterUrl(null);
          _startRetryTimer(); // Start/Keep retrying if still nothing
        }
      }
    } catch (e) {
      debugPrint('❌ [Discovery] error: $e');
      _startRetryTimer(); // Start retrying on error
    } finally {
      _isScanning = false;
      _discoveryStatusController.add(false);
    }
  }

  Future<String?> _checkIp(String ip) async {
    final url = 'http://$ip:$_discoveryPort/ping';
    try {
      final response = await _dio.get(url);
      if (response.data != null && response.data['service'] == 'PRINT_AGENT') {
        return 'http://$ip:$_discoveryPort';
      } else {
        debugPrint(
          '❓ Found something at $ip but not Print Agent: ${response.data}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          // Silent timeout is expected for most IPs
        } else {
          debugPrint('🚫 Error at $ip: ${e.message}');
        }
      }
    }
    return null;
  }

  Future<void> _savePrinterUrl(String url) async {
    _discoveredUrl = url;
    AppConfig.updatePrinterUrl(url); // Notify AppConfig
    _discoveryResultController.add(url); // Notify UI listeners
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerUrlKey, url);
  }

  Future<void> _validatePrinterUrl(String url) async {
    try {
      final response = await _dio.get('$url/ping');
      if (response.data != null && response.data['service'] == 'PRINT_AGENT') {
        debugPrint('✅ Saved printer URL is valid: $url');
        AppConfig.updatePrinterUrl(url);
      } else {
        debugPrint('⚠️ Saved printer URL is invalid, re-scanning...');
        _discoveredUrl = null;
        discover();
      }
    } catch (_) {
      debugPrint('❌ Saved printer URL unreachable, re-scanning...');
      _discoveredUrl = null;
      discover();
    }
  }

  /// Force re-discovery if a print request fails
  void handlePrintFailure() {
    debugPrint('🚨 Print failure detected, re-running discovery...');
    _discoveredUrl = null;
    AppConfig.updatePrinterUrl(null);
    discover();
  }

  void _startRetryTimer() {
    if (_retryTimer != null && _retryTimer!.isActive) return;
    debugPrint('⏲️ [Discovery] Starting background retry timer (30s)...');
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_discoveredUrl == null && !_isScanning) {
        debugPrint('🔄 [Discovery] Periodic background scan starting...');
        discover();
      } else if (_discoveredUrl != null) {
        _stopRetryTimer();
      }
    });
  }

  void _stopRetryTimer() {
    if (_retryTimer != null) {
      debugPrint('🛑 [Discovery] Stopping background retry timer.');
      _retryTimer!.cancel();
      _retryTimer = null;
    }
  }
}
