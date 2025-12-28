import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool isDemoMode = false;

  /// Default fallback URL
  static const String defaultPrinterUrl = 'http://localhost:5050';

  /// Synchronous access to the last discovered URL.
  /// ⚠️ IMPORTANT: Call PrinterDiscoveryService().init() on app start.
  static String get printerAgentUrl {
    // We return the discovered URL if available, otherwise fallback.
    // This allows existing sync code to work.
    return _currentPrinterUrl ?? defaultPrinterUrl;
  }

  static String? _currentPrinterUrl;

  /// Update the current printer URL (called by discovery service)
  static void updatePrinterUrl(String url) {
    debugPrint('🔄 [AppConfig] Updating printerAgentUrl to: $url');
    _currentPrinterUrl = url;
  }

  static bool get isDemo {
    const demoEnv = String.fromEnvironment('DEMO_MODE', defaultValue: 'true');
    return demoEnv == 'true';
  }
}
