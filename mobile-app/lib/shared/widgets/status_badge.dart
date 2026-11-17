import 'package:flutter/material.dart';

import '../../core/app_lang.dart';

/// Unified color-coded status pill for all ERP & Donor Portal modules.
/// Handles common backend enum values (ACTIVE, PENDING, CONFIRMED, PAID, etc.).
class StatusBadge extends StatelessWidget {
  final String status;
  final String? labelOverride;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.labelOverride,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final upper = status.trim().toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final _BadgeStyle style = _resolveStyle(upper, scheme, isDark);
    final text = labelOverride ?? _localizedLabel(upper);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style.fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: style.fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  static _BadgeStyle _resolveStyle(
      String upper, ColorScheme scheme, bool isDark) {
    switch (upper) {
      case 'ACTIVE':
      case 'APPROVED':
      case 'CONFIRMED':
      case 'PAID':
      case 'PASS':
      case 'PRESENT':
        final fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534);
        final bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
        return _BadgeStyle(fg: fg, bg: bg, border: fg.withValues(alpha: 0.35));

      case 'PENDING':
      case 'PARTIAL':
      case 'LATE':
      case 'IN_REVIEW':
        final fg = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
        final bg = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
        return _BadgeStyle(fg: fg, bg: bg, border: fg.withValues(alpha: 0.35));

      case 'REJECTED':
      case 'VOID':
      case 'BLOCKED':
      case 'UNPAID':
      case 'DUE':
      case 'FAIL':
      case 'ABSENT':
      case 'CANCELLED':
        final fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
        final bg = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
        return _BadgeStyle(fg: fg, bg: bg, border: fg.withValues(alpha: 0.35));

      default:
        return _BadgeStyle(
          fg: scheme.onSurfaceVariant,
          bg: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          border: scheme.outlineVariant,
        );
    }
  }

  static String _localizedLabel(String upper) {
    switch (upper) {
      case 'ACTIVE':
        return AppLang.t('সক্রিয়', 'Active');
      case 'APPROVED':
        return AppLang.t('অনুমোদিত', 'Approved');
      case 'CONFIRMED':
        return AppLang.t('নিশ্চিত', 'Confirmed');
      case 'PAID':
        return AppLang.t('পরিশোধিত', 'Paid');
      case 'PASS':
        return AppLang.t('সঠিক', 'Pass');
      case 'PRESENT':
        return AppLang.t('উপস্থিত', 'Present');
      case 'PENDING':
        return AppLang.t('অপেক্ষমাণ', 'Pending');
      case 'PARTIAL':
        return AppLang.t('আংশিক', 'Partial');
      case 'LATE':
        return AppLang.t('বিলম্বে', 'Late');
      case 'REJECTED':
        return AppLang.t('বাতিল', 'Rejected');
      case 'VOID':
        return AppLang.t('বাতিলকৃত', 'Void');
      case 'BLOCKED':
        return AppLang.t('ব্লকড', 'Blocked');
      case 'UNPAID':
        return AppLang.t('অপরিশোধিত', 'Unpaid');
      case 'DUE':
        return AppLang.t('বকেয়া', 'Due');
      case 'FAIL':
        return AppLang.t('ব্যর্থ', 'Fail');
      case 'ABSENT':
        return AppLang.t('অনুপস্থিত', 'Absent');
      case 'CANCELLED':
        return AppLang.t('বাতিল', 'Cancelled');
      default:
        return upper.isEmpty ? '-' : upper;
    }
  }
}

class _BadgeStyle {
  final Color fg;
  final Color bg;
  final Color border;
  const _BadgeStyle({required this.fg, required this.bg, required this.border});
}
