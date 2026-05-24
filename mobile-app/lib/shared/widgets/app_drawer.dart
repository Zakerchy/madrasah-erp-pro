import 'package:flutter/material.dart';

import '../../core/app_lang.dart';
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

        final role = SessionService.role;

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
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(user?.name ?? AppLang.t('অতিথি', 'Guest'),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${AppLang.t('ভূমিকা', 'Role')}: ${user?.role ?? 'N/A'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
              item('ড্যাশবোর্ড', 'Dashboard', '/dashboard'),
              item('দান সংগ্রহ', 'Donations', '/donations'),
              if (role == 'ADMIN' || role == 'ACCOUNTANT') item('খরচ', 'Expenses', '/expenses'),
              if (role == 'ADMIN' || role == 'ACCOUNTANT') item('বেতন', 'Salary', '/salary'),
              if (role == 'ADMIN' || role == 'ACCOUNTANT') item('সুবিধাভোগী', 'Beneficiaries', '/beneficiaries'),
              if (role == 'ADMIN' || role == 'ACCOUNTANT') item('বৃত্তি', 'Scholarship', '/scholarship'),
              item('রিপোর্ট', 'Reports', '/reports'),
              if (role == 'ADMIN') item('সেটিংস', 'Settings', '/settings'),
              const Divider(),
              ListTile(
                title: Text(AppLang.t('লগআউট', 'Logout')),
                leading: const Icon(Icons.logout),
                onTap: () {
                  SessionService.clear();
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
