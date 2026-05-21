import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/beneficiaries/beneficiaries_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/donations/donation_screen.dart';
import '../features/expenses/expense_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/salary/salary_screen.dart';
import '../features/scholarship/scholarship_screen.dart';
import '../features/settings/settings_screen.dart';
import 'theme.dart';

class MadrasahErpLiteApp extends StatelessWidget {
  const MadrasahErpLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Madrasah ERP Lite',
      theme: buildTheme(),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/donations': (_) => const DonationScreen(),
        '/expenses': (_) => const ExpenseScreen(),
        '/salary': (_) => const SalaryScreen(),
        '/beneficiaries': (_) => const BeneficiariesScreen(),
        '/scholarship': (_) => const ScholarshipScreen(),
        '/reports': (_) => const ReportsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
