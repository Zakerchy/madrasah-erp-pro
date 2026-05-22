class AppConfig {
  static const String appName = 'Madrasah ERP Lite';

  // Runtime-overridable API URL for CI and release builds:
  // flutter build apk --dart-define=API_BASE_URL=https://script.google.com/macros/s/DEPLOYMENT/exec
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://script.google.com/macros/s/AKfycbzdFMBIbvNlFthecYbR9XlEe7BhRaWaMuomWWPfwsiB3kG0CmjuagH3_rszNmr7WJc7/exec',
  );

  static const bool enableDebugLogs = bool.fromEnvironment('ENABLE_DEBUG_LOGS', defaultValue: true);
}
