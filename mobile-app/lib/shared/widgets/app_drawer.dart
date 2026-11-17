import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../../core/theme.dart';
import '../constants/app_permissions.dart';
import '../constants/app_routes.dart';
import '../services/org_settings_service.dart';
import '../services/role_service.dart';
import '../services/session_service.dart';
import 'org_logo.dart';

class _NavItem {
  final String bn;
  final String en;
  final String route;
  final IconData icon;
  final String permission;

  const _NavItem({
    required this.bn,
    required this.en,
    required this.route,
    required this.icon,
    required this.permission,
  });
}

const _navSections = <({String bn, String en, List<_NavItem> items})>[
  (
    bn: 'প্রধান',
    en: 'Overview',
    items: [
      _NavItem(
        bn: 'ড্যাশবোর্ড',
        en: 'Dashboard',
        route: AppRoutes.dashboard,
        icon: Icons.dashboard_outlined,
        permission: AppPermissions.dashboardView,
      ),
      _NavItem(
        bn: 'রিপোর্ট',
        en: 'Reports',
        route: AppRoutes.reports,
        icon: Icons.assessment_outlined,
        permission: AppPermissions.reportsView,
      ),
    ],
  ),
  (
    bn: 'একাডেমিক ও শিক্ষার্থী',
    en: 'Academic & Students',
    items: [
      _NavItem(
        bn: 'শিক্ষার্থী ও একাডেমিক',
        en: 'Students & Academic',
        route: AppRoutes.academic,
        icon: Icons.school_outlined,
        permission: AppPermissions.academicFoundationView,
      ),
      _NavItem(
        bn: 'হাজিরা ও ফলাফল',
        en: 'Attendance & Results',
        route: AppRoutes.academicCore,
        icon: Icons.fact_check_outlined,
        permission: AppPermissions.academicCoreView,
      ),
      _NavItem(
        bn: 'ফি ও বকেয়া',
        en: 'Fees & Dues',
        route: AppRoutes.fees,
        icon: Icons.receipt_long_outlined,
        permission: AppPermissions.feesView,
      ),
    ],
  ),
  (
    bn: 'অর্থ ও কল্যাণ',
    en: 'Finance & Welfare',
    items: [
      _NavItem(
        bn: 'দান সংগ্রহ',
        en: 'Donations',
        route: AppRoutes.donations,
        icon: Icons.volunteer_activism_outlined,
        permission: AppPermissions.donationsView,
      ),
      _NavItem(
        bn: 'খরচ',
        en: 'Expenses',
        route: AppRoutes.expenses,
        icon: Icons.payments_outlined,
        permission: AppPermissions.expensesView,
      ),
      _NavItem(
        bn: 'ফাইন্যান্স কন্ট্রোল',
        en: 'Finance Control',
        route: AppRoutes.financeControl,
        icon: Icons.account_balance_outlined,
        permission: AppPermissions.financeView,
      ),
      _NavItem(
        bn: 'বেতন',
        en: 'Salary',
        route: AppRoutes.salary,
        icon: Icons.badge_outlined,
        permission: AppPermissions.salaryView,
      ),
      _NavItem(
        bn: 'সুবিধাভোগী',
        en: 'Beneficiaries',
        route: AppRoutes.beneficiaries,
        icon: Icons.groups_outlined,
        permission: AppPermissions.beneficiariesView,
      ),
      _NavItem(
        bn: 'বৃত্তি',
        en: 'Scholarship',
        route: AppRoutes.scholarship,
        icon: Icons.workspace_premium_outlined,
        permission: AppPermissions.scholarshipView,
      ),
    ],
  ),
  (
    bn: 'যোগাযোগ ও সিস্টেম',
    en: 'System & Comms',
    items: [
      _NavItem(
        bn: 'নোটিশ ও ডকুমেন্ট',
        en: 'Notices & Documents',
        route: AppRoutes.communication,
        icon: Icons.campaign_outlined,
        permission: AppPermissions.communicationView,
      ),
      _NavItem(
        bn: 'সেটিংস',
        en: 'Settings',
        route: AppRoutes.settings,
        icon: Icons.settings_outlined,
        permission: AppPermissions.settingsView,
      ),
    ],
  ),
];

/// Shared navigation menu used by both mobile [AppDrawer] and desktop sidebar.
class AppNavContent extends StatelessWidget {
  final bool isDrawer;

  const AppNavContent({super.key, this.isDrawer = true});

  @override
  Widget build(BuildContext context) {
    final activeRoute = ModalRoute.of(context)?.settings.name ?? '';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) {
        return Column(
          children: [
            _buildHeader(context, scheme, isEn),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  for (final section in _navSections) ...[
                    Builder(
                      builder: (context) {
                        final visible = section.items
                            .where((i) => SessionService.can(i.permission))
                            .toList();
                        if (visible.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                              child: Text(
                                AppLang.t(section.bn, section.en).toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            for (final item in visible)
                              _buildNavTile(
                                context,
                                item,
                                isActive: activeRoute == item.route,
                                scheme: scheme,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(Icons.logout, color: scheme.error),
                title: Text(
                  AppLang.t('লগআউট', 'Logout'),
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  SessionService.clear();
                  if (isDrawer) Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, ColorScheme scheme, bool isEnglish) {
    final orgTitle = AppLang.t(
      OrgSettings.nameBn.trim().isNotEmpty
          ? OrgSettings.nameBn.trim()
          : 'মাদ্রাসা ERP',
      OrgSettings.nameEn.trim().isNotEmpty
          ? OrgSettings.nameEn.trim()
          : 'Madrasah ERP',
    );

    return ValueListenableBuilder(
      valueListenable: SessionService.currentUser,
      builder: (_, user, __) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              16, isDrawer ? 42 : 20, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppBrand.greenDark, scheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: AppBrand.gold.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppBrand.gold, width: 1.5),
                      color: Colors.white,
                    ),
                    child: const ClipOval(child: OrgLogo(size: 38)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      orgTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                user?.name ?? AppLang.t('অতিথি', 'Guest'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppBrand.gold.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: AppBrand.gold.withValues(alpha: 0.6)),
                ),
                child: Text(
                  user == null
                      ? 'N/A'
                      : RoleService.roleName(user.role, isEnglish: isEnglish),
                  style: const TextStyle(
                    color: AppBrand.goldLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavTile(
    BuildContext context,
    _NavItem item, {
    required bool isActive,
    required ColorScheme scheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        selected: isActive,
        selectedTileColor: scheme.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isActive
              ? BorderSide(color: AppBrand.gold.withValues(alpha: 0.55))
              : BorderSide.none,
        ),
        leading: Icon(
          item.icon,
          size: 20,
          color: isActive ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: Text(
          AppLang.t(item.bn, item.en),
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? scheme.primary : scheme.onSurface,
          ),
        ),
        onTap: () {
          if (isDrawer) Navigator.pop(context);
          if (!isActive) {
            Navigator.pushReplacementNamed(context, item.route);
          }
        },
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(
      child: AppNavContent(isDrawer: true),
    );
  }
}
