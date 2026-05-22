class AppConfig {
  static const String appName = 'Madrasah ERP Lite';

  // Google Sheet used as operational data store.
  // Optional runtime override:
  // flutter run --dart-define=GOOGLE_SHEET_ID=your_sheet_id
  static const String googleSheetId = String.fromEnvironment(
    'GOOGLE_SHEET_ID',
    defaultValue: '1oDjX_FS0F0_4ZjZM0YBS-TLHFRmYwbNRCPKhcTUxr3Y',
  );

  // First-login bootstrap admin (only used when users_roles has no data row).
  // Optional override:
  // flutter run --dart-define=BOOTSTRAP_ADMIN_EMAIL=you@gmail.com
  static const String bootstrapAdminEmail = String.fromEnvironment(
    'BOOTSTRAP_ADMIN_EMAIL',
    defaultValue: 'zakerchy@gmail.com',
  );
  static const String bootstrapAdminName = String.fromEnvironment(
    'BOOTSTRAP_ADMIN_NAME',
    defaultValue: 'Admin',
  );

  static const bool enableDebugLogs = bool.fromEnvironment('ENABLE_DEBUG_LOGS', defaultValue: true);
}
