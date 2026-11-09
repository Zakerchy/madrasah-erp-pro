import 'package:flutter/material.dart';

import 'org_logo.dart';

/// Branded full-screen/section loading spinner: the org logo centered
/// inside a spinning ring.
class AppLoader extends StatelessWidget {
  final double size;

  const AppLoader({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 2.4),
          ClipOval(child: OrgLogo(size: size * 0.62)),
        ],
      ),
    );
  }
}
