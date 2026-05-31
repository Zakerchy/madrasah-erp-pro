class NotificationSettings {
  final bool inAppEnabled;
  final bool emailApproval;
  final bool emailFailedSync;
  final bool emailDailySummary;
  final bool emailDueReminder;
  final bool emailSecurityAlert;
  final String updatedAt;

  const NotificationSettings({
    required this.inAppEnabled,
    required this.emailApproval,
    required this.emailFailedSync,
    required this.emailDailySummary,
    required this.emailDueReminder,
    required this.emailSecurityAlert,
    required this.updatedAt,
  });

  factory NotificationSettings.defaults() {
    return const NotificationSettings(
      inAppEnabled: true,
      emailApproval: false,
      emailFailedSync: false,
      emailDailySummary: false,
      emailDueReminder: false,
      emailSecurityAlert: false,
      updatedAt: '',
    );
  }

  factory NotificationSettings.fromApi(Map<String, dynamic> map) {
    bool toBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      final raw = (value ?? '').toString().trim().toUpperCase();
      if (raw.isEmpty) return fallback;
      return raw == 'TRUE' || raw == '1' || raw == 'YES' || raw == 'ON';
    }

    return NotificationSettings(
      inAppEnabled: toBool(map['in_app_enabled'], true),
      emailApproval: toBool(map['email_approval'], false),
      emailFailedSync: toBool(map['email_failed_sync'], false),
      emailDailySummary: toBool(map['email_daily_summary'], false),
      emailDueReminder: toBool(map['email_due_reminder'], false),
      emailSecurityAlert: toBool(map['email_security_alert'], false),
      updatedAt: (map['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'email_approval': emailApproval,
      'email_failed_sync': emailFailedSync,
      'email_daily_summary': emailDailySummary,
      'email_due_reminder': emailDueReminder,
      'email_security_alert': emailSecurityAlert,
    };
  }

  NotificationSettings copyWith({
    bool? inAppEnabled,
    bool? emailApproval,
    bool? emailFailedSync,
    bool? emailDailySummary,
    bool? emailDueReminder,
    bool? emailSecurityAlert,
    String? updatedAt,
  }) {
    return NotificationSettings(
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      emailApproval: emailApproval ?? this.emailApproval,
      emailFailedSync: emailFailedSync ?? this.emailFailedSync,
      emailDailySummary: emailDailySummary ?? this.emailDailySummary,
      emailDueReminder: emailDueReminder ?? this.emailDueReminder,
      emailSecurityAlert: emailSecurityAlert ?? this.emailSecurityAlert,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
