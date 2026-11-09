import 'package:flutter/material.dart';

import '../services/org_settings_service.dart';

/// The single place every screen gets the organization's logo from.
///
/// Always shows the real, bundled official logo (`assets/images/org_logo.png`)
/// as the default — never a generic icon — so the brand is correct even
/// before `OrgSettings` has loaded, or if the network image is briefly
/// unavailable. If an admin later changes the logo in Settings, the live
/// `OrgSettings.logoUrl` (once loaded) is shown on top of that default.
class OrgLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const OrgLogo({super.key, required this.size, this.fit = BoxFit.cover});

  static const String assetPath = 'assets/images/org_logo.png';

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(assetPath, width: size, height: size, fit: fit);
    if (OrgSettings.logoUrl.isEmpty) return fallback;
    return Image.network(
      OrgSettings.logoUrl,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
    );
  }
}
