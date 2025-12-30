class AppConfig {
  static const bool isDemoMode = false;

  static bool get isDemo {
    const demoEnv = String.fromEnvironment('DEMO_MODE', defaultValue: 'true');
    return demoEnv == 'true';
  }

  // Remote Print Configuration
  static const String relayServerUrl = 'ws://localhost:3000';
}
