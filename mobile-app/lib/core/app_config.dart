class AppConfig {
  static const String appName = 'Madrasah ERP Lite';

  // Google Sheet used as operational data store.
  // Optional runtime override:
  // flutter run --dart-define=GOOGLE_SHEET_ID=your_sheet_id
  static const String googleSheetId = String.fromEnvironment(
    'GOOGLE_SHEET_ID',
    defaultValue: '1oDjX_FS0F0_4ZjZM0YBS-TLHFRmYwbNRCPKhcTUxr3Y',
  );

  static const bool enableDebugLogs = bool.fromEnvironment('ENABLE_DEBUG_LOGS', defaultValue: true);
}
