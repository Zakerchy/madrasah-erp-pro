import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
import '../constants/app_permissions.dart';
import '../constants/app_routes.dart';
import '../services/role_service.dart';
import '../services/session_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLang.isEnglish,
      builder: (context, isEn, _) {
        Widget item(String bn, String en, String route) {
          return ListTile(
            title: Text(AppLang.t(bn, en)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, route);
            },
          );
        }

        return Drawer(
          child: ListView(
            children: [
              ValueListenableBuilder(
                valueListenable: SessionService.currentUser,
                builder: (_, user, __) {
                  return DrawerHeader(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          AppLang.t('মাদ্রাসা ERP', 'Madrasah ERP'),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(user?.name ?? AppLang.t('অতিথি', 'Guest'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${AppLang.t('ভূমিকা', 'Role')}: ${user == null ? 'N/A' : RoleService.roleName(user.role, isEnglish: isEn)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (SessionService.can(AppPermissions.dashboardView))
                item('ড্যাশবোর্ড', 'Dashboard', AppRoutes.dashboard),
              if (SessionService.can(AppPermissions.academicFoundationView))
                item('শিক্ষার্থী ও একাডেমিক', 'Students & Academic',
                    AppRoutes.academic),
              if (SessionService.can(AppPermissions.academicCoreView))
                item('হাজিরা ও ফলাফল', 'Attendance & Results',
                    AppRoutes.academicCore),
              if (SessionService.can(AppPermissions.donationsView))
                item('দান সংগ্রহ', 'Donations', AppRoutes.donations),
              if (SessionService.can(AppPermissions.feesView))
                item('ফি ও বকেয়া', 'Fees & Dues', AppRoutes.fees),
              if (SessionService.can(AppPermissions.financeView))
                item('ফাইন্যান্স কন্ট্রোল', 'Finance Control',
                    AppRoutes.financeControl),
              if (SessionService.can(AppPermissions.communicationView))
                item('নোটিশ ও ডকুমেন্ট', 'Notices & Documents',
                    AppRoutes.communication),
              if (SessionService.can(AppPermissions.expensesView))
                item('খরচ', 'Expenses', AppRoutes.expenses),
              if (SessionService.can(AppPermissions.salaryView))
                item('বেতন', 'Salary', AppRoutes.salary),
              if (SessionService.can(AppPermissions.beneficiariesView))
                item('সুবিধাভোগী', 'Beneficiaries', AppRoutes.beneficiaries),
              if (SessionService.can(AppPermissions.scholarshipView))
                item('বৃত্তি', 'Scholarship', AppRoutes.scholarship),
              if (SessionService.can(AppPermissions.reportsView))
                item('রিপোর্ট', 'Reports', AppRoutes.reports),
              if (SessionService.can(AppPermissions.settingsView))
                item('সেটিংস', 'Settings', AppRoutes.settings),
              const Divider(),
              ListTile(
                title: Text(AppLang.t('লগআউট', 'Logout')),
                leading: const Icon(Icons.logout),
                onTap: () {
                  SessionService.clear();
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.login, (route) => false);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
