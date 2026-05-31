import 'package:flutter_test/flutter_test.dart';
import 'package:madrasah_erp_lite/shared/models/notification_settings.dart';

void main() {
  test('defaults keep in-app enabled and email toggles off', () {
    final s = NotificationSettings.defaults();
    expect(s.inAppEnabled, isTrue);
    expect(s.emailApproval, isFalse);
    expect(s.emailFailedSync, isFalse);
    expect(s.emailDailySummary, isFalse);
    expect(s.emailDueReminder, isFalse);
    expect(s.emailSecurityAlert, isFalse);
  });

  test('fromApi parses bool-like strings with fallback', () {
    final s = NotificationSettings.fromApi({
      'in_app_enabled': 'TRUE',
      'email_approval': 'TRUE',
      'email_failed_sync': 'false',
      'email_daily_summary': '1',
      'email_due_reminder': '0',
      'email_security_alert': '',
      'updated_at': '2026-05-31T10:00:00Z',
    });

    expect(s.inAppEnabled, isTrue);
    expect(s.emailApproval, isTrue);
    expect(s.emailFailedSync, isFalse);
    expect(s.emailDailySummary, isTrue);
    expect(s.emailDueReminder, isFalse);
    expect(s.emailSecurityAlert, isFalse);
    expect(s.updatedAt, '2026-05-31T10:00:00Z');
  });
}
