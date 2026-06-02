import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/academic/academic_foundation_screen.dart';
import '../features/academic/academic_core_screen.dart';
import '../features/beneficiaries/beneficiaries_screen.dart';
import '../features/communication/communication_documents_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/donations/donation_screen.dart';
import '../features/expenses/expense_screen.dart';
import '../features/fees/fee_dues_screen.dart';
import '../features/finance_control/finance_control_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/salary/salary_screen.dart';
import '../features/scholarship/scholarship_screen.dart';
import '../features/settings/settings_screen.dart';
import 'app_lang.dart';
import 'theme.dart';

class MadrasahErpLiteApp extends StatefulWidget {
  const MadrasahErpLiteApp({super.key});

  @override
  State<MadrasahErpLiteApp> createState() => _MadrasahErpLiteAppState();
}

class _MadrasahErpLiteAppState extends State<MadrasahErpLiteApp> {
  @override
  void initState() {
    super.initState();
    AppLang.isEnglish.addListener(_onLangChange);
  }

  @override
  void dispose() {
    AppLang.isEnglish.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppLang.t('মাদ্রাসা ERP Lite', 'Madrasah ERP Lite'),
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/academic': (_) => const AcademicFoundationScreen(),
        '/academic-core': (_) => const AcademicCoreScreen(),
        '/donations': (_) => const DonationScreen(),
        '/expenses': (_) => const ExpenseScreen(),
        '/fees': (_) => const FeeDuesScreen(),
        '/finance-control': (_) => const FinanceControlScreen(),
        '/communication': (_) => const CommunicationDocumentsScreen(),
        '/salary': (_) => const SalaryScreen(),
        '/beneficiaries': (_) => const BeneficiariesScreen(),
        '/scholarship': (_) => const ScholarshipScreen(),
        '/reports': (_) => const ReportsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
