class AppConfig {
  // Toggle này để bật/tắt demo mode
  // true = Demo mode (có preview, mock printer)
  // false = Production mode (in trực tiếp, máy in thật)
  static const bool isDemoMode = true;

  // Có thể dùng environment variable
  // flutter run --dart-define=DEMO_MODE=false
  static bool get isDemo {
    const demoEnv = String.fromEnvironment('DEMO_MODE', defaultValue: 'true');
    return demoEnv == 'true';
  }
}
