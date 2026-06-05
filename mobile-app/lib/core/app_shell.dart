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
import '../shared/constants/app_routes.dart';
import '../shared/widgets/guarded_route.dart';

class MadrasahErpProApp extends StatefulWidget {
  const MadrasahErpProApp({super.key});

  @override
  State<MadrasahErpProApp> createState() => _MadrasahErpProAppState();
}

class _MadrasahErpProAppState extends State<MadrasahErpProApp> {
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
      title: AppLang.t('মাদ্রাসা ERP Pro', 'Madrasah ERP Pro'),
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) {
        final name = settings.name ?? AppRoutes.login;
        final routes = <String, Widget>{
          AppRoutes.login: const LoginScreen(),
          AppRoutes.dashboard: const DashboardScreen(),
          AppRoutes.academic: const AcademicFoundationScreen(),
          AppRoutes.academicCore: const AcademicCoreScreen(),
          AppRoutes.donations: const DonationScreen(),
          AppRoutes.expenses: const ExpenseScreen(),
          AppRoutes.fees: const FeeDuesScreen(),
          AppRoutes.financeControl: const FinanceControlScreen(),
          AppRoutes.communication: const CommunicationDocumentsScreen(),
          AppRoutes.salary: const SalaryScreen(),
          AppRoutes.beneficiaries: const BeneficiariesScreen(),
          AppRoutes.scholarship: const ScholarshipScreen(),
          AppRoutes.reports: const ReportsScreen(),
          AppRoutes.settings: const SettingsScreen(),
        };
        final child = routes[name] ?? const LoginScreen();
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => GuardedRoute(
            routeName: name,
            permission: AppRoutes.requiredPermissions[name],
            child: child,
          ),
        );
      },
    );
  }
}
