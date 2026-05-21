import 'package:flutter/material.dart';

import '../services/session_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(String label, String route) {
      return ListTile(
        title: Text(label),
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
                    const Text('Madrasah ERP Lite', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(user?.name ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Role: ${user?.role ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
          item('Dashboard', '/dashboard'),
          item('Donations', '/donations'),
          if (role == 'ADMIN' || role == 'ACCOUNTANT') item('Expenses', '/expenses'),
          if (role == 'ADMIN' || role == 'ACCOUNTANT') item('Salary', '/salary'),
          if (role == 'ADMIN' || role == 'ACCOUNTANT') item('Beneficiaries', '/beneficiaries'),
          if (role == 'ADMIN' || role == 'ACCOUNTANT') item('Scholarship', '/scholarship'),
          item('Reports', '/reports'),
          if (role == 'ADMIN') item('Settings', '/settings'),
          const Divider(),
          ListTile(
            title: const Text('Logout'),
            onTap: () {
              SessionService.clear();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          )
        ],
      ),
    );
  }
}
