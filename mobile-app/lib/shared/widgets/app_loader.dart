import 'package:flutter/material.dart';

import '../services/org_settings_service.dart';

/// Branded full-screen/section loading spinner: the org logo centered
/// inside a spinning ring. Falls back to a plain spinner before the logo
/// URL is known or if it fails to load.
class AppLoader extends StatelessWidget {
  final double size;

  const AppLoader({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (OrgSettings.logoUrl.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.4),
          ClipOval(
            child: Image.network(
              OrgSettings.logoUrl,
              width: size * 0.62,
              height: size * 0.62,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.school, color: cs.primary, size: size * 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
