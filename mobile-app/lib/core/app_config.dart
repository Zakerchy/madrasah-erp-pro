class AppConfig {
  static const String appName = 'মাদ্রাসা ERP';
  // Project default Apps Script endpoint (keeps local/dev zero-friction).
  static const String _projectDefaultAppsScriptUrl =
      'https://script.google.com/macros/s/AKfycbzbgTChISsQWhEU_EG06UYO3kTGhH-NsEiSdd0v-PEftI3882X7sUDRWCL96224-Bui/exec';

  // Preferred key:
  // flutter run --dart-define=APPS_SCRIPT_URL=https://script.google.com/macros/s/YOUR_ID/exec
  static const String _appsScriptUrlPrimary = String.fromEnvironment(
    'APPS_SCRIPT_URL',
    defaultValue: '',
  );

  // Backward-compatibility for older docs/workflows.
  static const String _appsScriptUrlLegacy = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Optional: provide deployment id and URL will be auto-generated.
  static const String _appsScriptDeploymentId = String.fromEnvironment(
    'APPS_SCRIPT_DEPLOYMENT_ID',
    defaultValue: '',
  );

  static const String appsScriptUrl = _appsScriptUrlPrimary != ''
      ? _appsScriptUrlPrimary
      : (_appsScriptUrlLegacy != ''
          ? _appsScriptUrlLegacy
          : (_appsScriptDeploymentId != ''
              ? 'https://script.google.com/macros/s/$_appsScriptDeploymentId/exec'
              : _projectDefaultAppsScriptUrl));

  static const bool hasConfiguredAppsScriptUrl = _appsScriptUrlPrimary != '' ||
      _appsScriptUrlLegacy != '' ||
      _appsScriptDeploymentId != '';

  static final bool isUsingPlaceholderUrl =
      appsScriptUrl.contains('PLACEHOLDER');

  static const String appsScriptConfigSource = _appsScriptUrlPrimary != ''
      ? 'APPS_SCRIPT_URL'
      : (_appsScriptUrlLegacy != ''
          ? 'API_BASE_URL'
          : (_appsScriptDeploymentId != ''
              ? 'APPS_SCRIPT_DEPLOYMENT_ID'
              : 'PROJECT_DEFAULT'));

  // Bootstrap admin email (first login when users sheet is empty)
  static const String bootstrapAdminEmail = String.fromEnvironment(
    'BOOTSTRAP_ADMIN_EMAIL',
    defaultValue: 'zakerchy@gmail.com',
  );

  static const bool enableDebugLogs = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGS',
    defaultValue: true,
  );

  static const String apkDownloadUrl = String.fromEnvironment(
    'APK_DOWNLOAD_URL',
    defaultValue:
        'https://github.com/Zakerchy/madrasah-erp-pro/releases/download/latest-apk/app-debug.apk',
  );
}
