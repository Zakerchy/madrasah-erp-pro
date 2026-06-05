import 'package:flutter/material.dart';

import '../constants/app_permissions.dart';
import '../constants/app_routes.dart';
import '../services/access_control_service.dart';
import '../services/session_service.dart';

class GuardedRoute extends StatefulWidget {
  final Widget child;
  final String routeName;
  final String? permission;

  const GuardedRoute({
    super.key,
    required this.child,
    required this.routeName,
    this.permission,
  });

  @override
  State<GuardedRoute> createState() => _GuardedRouteState();
}

class _GuardedRouteState extends State<GuardedRoute> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.routeName == AppRoutes.login) return;
      if (!SessionService.isLoggedIn) {
        await AccessControlService.showLoginRequiredDialog(
          context,
          routeName: widget.routeName,
        );
        return;
      }
      final permission = widget.permission;
      if (permission == null || SessionService.can(permission)) return;
      await AccessControlService.showRouteDeniedDialog(
        context,
        permission: permission,
        routeName: widget.routeName,
      );
      if (!mounted) return;
      final fallback = SessionService.can(AppPermissions.dashboardView)
          ? AppRoutes.dashboard
          : AppRoutes.login;
      Navigator.pushNamedAndRemoveUntil(context, fallback, (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.routeName == AppRoutes.login) return widget.child;
    if (!SessionService.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final permission = widget.permission;
    if (permission != null && !SessionService.can(permission)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}
