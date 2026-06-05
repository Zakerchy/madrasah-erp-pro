import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../constants/app_routes.dart';
import 'api_service.dart';
import 'session_service.dart';

class AccessControlService {
  static void showDeniedSnack(
    BuildContext context, {
    required String permission,
    String? routeName,
  }) {
    unawaited(logDenied(
      type: 'ACTION_DENIED',
      permission: permission,
      routeName: routeName,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLang.t(
            'আপনার এই কাজের অনুমতি নেই',
            'You do not have permission for this action',
          ),
        ),
      ),
    );
  }

  static Future<void> showRouteDeniedDialog(
    BuildContext context, {
    required String permission,
    required String routeName,
  }) async {
    await logDenied(
      type: 'ROUTE_DENIED',
      permission: permission,
      routeName: routeName,
    );
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLang.t('অ্যাক্সেস সীমাবদ্ধ', 'Access Restricted')),
          content: Text(
            AppLang.t(
              'এই পাতায় প্রবেশের অনুমতি আপনার বর্তমান রোলে নেই।',
              'Your current role cannot access this page.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLang.t('ঠিক আছে', 'OK')),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showLoginRequiredDialog(
    BuildContext context, {
    required String routeName,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLang.t('লগইন প্রয়োজন', 'Login Required')),
          content: Text(
            AppLang.t(
              'এই পাতায় যেতে আগে লগইন করতে হবে।',
              'Please log in first to open this page.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLang.t('লগইন', 'Login')),
            ),
          ],
        );
      },
    );
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  static Future<void> logDenied({
    required String type,
    required String permission,
    String? routeName,
  }) async {
    if (!SessionService.isLoggedIn) return;
    try {
      await ApiService().post(
        'logClientGuard',
        {
          'user_role': SessionService.role,
          'user_id': SessionService.userId,
          'payload': {
            'type': type,
            'permission': permission,
            'route_name': routeName ?? '',
          },
        },
        allowQueue: false,
      );
    } catch (_) {
      // Guard logs should never block the UI.
    }
  }
}
