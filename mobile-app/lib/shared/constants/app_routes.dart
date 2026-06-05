import 'app_permissions.dart';

class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const academic = '/academic';
  static const academicCore = '/academic-core';
  static const donations = '/donations';
  static const expenses = '/expenses';
  static const fees = '/fees';
  static const financeControl = '/finance-control';
  static const communication = '/communication';
  static const salary = '/salary';
  static const beneficiaries = '/beneficiaries';
  static const scholarship = '/scholarship';
  static const reports = '/reports';
  static const settings = '/settings';

  static const requiredPermissions = <String, String>{
    dashboard: AppPermissions.dashboardView,
    academic: AppPermissions.academicFoundationView,
    academicCore: AppPermissions.academicCoreView,
    donations: AppPermissions.donationsView,
    expenses: AppPermissions.expensesView,
    fees: AppPermissions.feesView,
    financeControl: AppPermissions.financeView,
    communication: AppPermissions.communicationView,
    salary: AppPermissions.salaryView,
    beneficiaries: AppPermissions.beneficiariesView,
    scholarship: AppPermissions.scholarshipView,
    reports: AppPermissions.reportsView,
    settings: AppPermissions.settingsView,
  };
}
