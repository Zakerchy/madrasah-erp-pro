class AppConfig {
  static const String appName = 'মাদ্রাসা ERP';

  // Google Apps Script Web App URL (deploy once, paste here)
  // flutter run --dart-define=APPS_SCRIPT_URL=https://script.google.com/macros/s/YOUR_ID/exec
  static const String appsScriptUrl = String.fromEnvironment(
    'APPS_SCRIPT_URL',
    defaultValue: 'https://script.google.com/macros/s/AKfycbwPLACEHOLDER/exec',
  );

  // Bootstrap admin email (first login when users sheet is empty)
  static const String bootstrapAdminEmail = String.fromEnvironment(
    'BOOTSTRAP_ADMIN_EMAIL',
    defaultValue: 'zakerchy@gmail.com',
  );

  static const bool enableDebugLogs = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGS',
    defaultValue: true,
  );
}
