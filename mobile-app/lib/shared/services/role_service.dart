import 'package:flutter/foundation.dart';

import '../constants/app_permissions.dart';
import '../models/role_definition.dart';
import 'local_store_service.dart';

class RoleService {
  static final ValueNotifier<List<RoleDefinition>> definitions =
      ValueNotifier<List<RoleDefinition>>(_defaultDefinitions);

  static Future<void> bootstrap() async {
    await LocalStoreService.init();
    final cached = LocalStoreService.readRoleDefinitions();
    if (cached.isNotEmpty) {
      definitions.value = cached;
    }
  }

  static Future<void> storeDefinitions(List<RoleDefinition> defs) async {
    final sanitized = _sanitize(defs);
    definitions.value = sanitized;
    await LocalStoreService.saveRoleDefinitions(sanitized);
  }

  static RoleDefinition? definitionFor(String roleKey) {
    final key = roleKey.trim().toUpperCase();
    for (final def in definitions.value) {
      if (def.key == key) return def;
    }
    for (final def in _defaultDefinitions) {
      if (def.key == key) return def;
    }
    return null;
  }

  static List<RoleDefinition> activeDefinitions() {
    return definitions.value.where((def) => def.active).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  static List<String> permissionsForRole(String roleKey) {
    final def = definitionFor(roleKey);
    if (def == null) {
      return definitionFor('VIEWER')?.permissions ?? const [];
    }
    return def.permissions;
  }

  static bool hasPermission(
    String permission, {
    String? role,
    List<String>? permissions,
  }) {
    final source = permissions ?? permissionsForRole(role ?? '');
    return source.contains(permission);
  }

  static String roleName(String roleKey, {required bool isEnglish}) {
    final def = definitionFor(roleKey);
    if (def == null) return roleKey;
    return isEnglish ? def.nameEn : def.nameBn;
  }

  static String permissionLabel(String permission, {required bool isEnglish}) {
    final labels = _permissionLabels[permission];
    if (labels == null) return permission;
    return isEnglish ? labels.$2 : labels.$1;
  }

  static List<RoleDefinition> _sanitize(List<RoleDefinition> defs) {
    final byKey = <String, RoleDefinition>{};
    for (final def in [..._defaultDefinitions, ...defs]) {
      byKey[def.key] = RoleDefinition(
        key: def.key,
        nameBn: def.nameBn,
        nameEn: def.nameEn,
        description: def.description,
        permissions: def.permissions
            .toSet()
            .where((permission) => AppPermissions.all.contains(permission))
            .toList()
          ..sort(),
        isBuiltin: def.isBuiltin,
        active: def.active,
      );
    }
    final out = byKey.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return out;
  }

  static const Map<String, (String, String)> _permissionLabels = {
    AppPermissions.dashboardView: ('ড্যাশবোর্ড দেখা', 'View dashboard'),
    AppPermissions.donationsView: ('দান দেখা', 'View donations'),
    AppPermissions.donationsWrite: ('দান এন্ট্রি', 'Create donations'),
    AppPermissions.transactionsManage: ('লেনদেন ম্যানেজ', 'Manage transactions'),
    AppPermissions.expensesView: ('খরচ দেখা', 'View expenses'),
    AppPermissions.expensesWrite: ('খরচ লেখা', 'Create expenses'),
    AppPermissions.beneficiariesView: ('সুবিধাভোগী দেখা', 'View beneficiaries'),
    AppPermissions.beneficiariesWrite: ('সুবিধাভোগী লেখা', 'Manage beneficiaries'),
    AppPermissions.salaryView: ('বেতন দেখা', 'View salary'),
    AppPermissions.salaryWrite: ('বেতন লেখা', 'Manage salary'),
    AppPermissions.scholarshipView: ('বৃত্তি দেখা', 'View scholarship'),
    AppPermissions.scholarshipWrite: ('বৃত্তি লেখা', 'Manage scholarship'),
    AppPermissions.academicFoundationView: ('একাডেমিক বেস দেখা', 'View academic base'),
    AppPermissions.academicFoundationWrite: ('একাডেমিক বেস লেখা', 'Manage academic base'),
    AppPermissions.academicCoreView: ('হাজিরা/ফল দেখা', 'View attendance/results'),
    AppPermissions.academicCoreWrite: ('পরীক্ষা/নম্বর লেখা', 'Manage exam and marks'),
    AppPermissions.academicAttendanceWrite: ('হাজিরা লেখা', 'Record attendance'),
    AppPermissions.feesView: ('ফি দেখা', 'View fees'),
    AppPermissions.feesWrite: ('ফি লেখা', 'Manage fees'),
    AppPermissions.financeView: ('ফাইন্যান্স দেখা', 'View finance control'),
    AppPermissions.financeWrite: ('বাজেট লেখা', 'Manage budgets'),
    AppPermissions.financeApprovalRulesManage:
        ('অ্যাপ্রুভাল রুল', 'Manage approval rules'),
    AppPermissions.financeApprovalRequestsCreate:
        ('অ্যাপ্রুভাল অনুরোধ', 'Create approval requests'),
    AppPermissions.financeApprovalRequestsDecide:
        ('অ্যাপ্রুভাল সিদ্ধান্ত', 'Decide approval requests'),
    AppPermissions.communicationView: ('নোটিশ/ডকুমেন্ট দেখা', 'View notices/documents'),
    AppPermissions.communicationWrite: ('নোটিশ/ডকুমেন্ট লেখা', 'Publish notices/documents'),
    AppPermissions.reportsView: ('রিপোর্ট দেখা', 'View reports'),
    AppPermissions.settingsView: ('সেটিংস দেখা', 'View settings'),
    AppPermissions.usersManage: ('ব্যবহারকারী ম্যানেজ', 'Manage users'),
    AppPermissions.rolesView: ('রোল দেখা', 'View roles'),
    AppPermissions.rolesManage: ('রোল তৈরি/এডিট', 'Manage roles'),
    AppPermissions.notificationsView: ('নোটিফিকেশন দেখা', 'View notifications'),
    AppPermissions.notificationsManage: ('নোটিফিকেশন সেটিংস', 'Manage notifications'),
    AppPermissions.appUiManage: ('অ্যাপ UI সেটিংস', 'Manage app UI settings'),
    AppPermissions.auditView: ('অডিট লগ দেখা', 'View audit logs'),
  };

  static final List<RoleDefinition> _defaultDefinitions = [
    RoleDefinition(
      key: 'ADMIN',
      nameBn: 'অ্যাডমিন',
      nameEn: 'Admin',
      description: 'Full platform access',
      permissions: List<String>.from(AppPermissions.all),
      isBuiltin: true,
      active: true,
    ),
    const RoleDefinition(
      key: 'ACCOUNTANT',
      nameBn: 'অ্যাকাউন্ট্যান্ট',
      nameEn: 'Accountant',
      description: 'Operations, finance and reports',
      permissions: [
        AppPermissions.dashboardView,
        AppPermissions.donationsView,
        AppPermissions.donationsWrite,
        AppPermissions.transactionsManage,
        AppPermissions.expensesView,
        AppPermissions.expensesWrite,
        AppPermissions.beneficiariesView,
        AppPermissions.beneficiariesWrite,
        AppPermissions.salaryView,
        AppPermissions.salaryWrite,
        AppPermissions.scholarshipView,
        AppPermissions.scholarshipWrite,
        AppPermissions.academicFoundationView,
        AppPermissions.academicFoundationWrite,
        AppPermissions.academicCoreView,
        AppPermissions.academicCoreWrite,
        AppPermissions.academicAttendanceWrite,
        AppPermissions.feesView,
        AppPermissions.feesWrite,
        AppPermissions.financeView,
        AppPermissions.financeWrite,
        AppPermissions.financeApprovalRequestsCreate,
        AppPermissions.communicationView,
        AppPermissions.communicationWrite,
        AppPermissions.reportsView,
        AppPermissions.rolesView,
        AppPermissions.notificationsView,
        AppPermissions.auditView,
      ],
      isBuiltin: true,
      active: true,
    ),
    const RoleDefinition(
      key: 'FIELD_USER',
      nameBn: 'ফিল্ড ইউজার',
      nameEn: 'Field User',
      description: 'Field collection and attendance tasks',
      permissions: [
        AppPermissions.dashboardView,
        AppPermissions.donationsView,
        AppPermissions.donationsWrite,
        AppPermissions.academicFoundationView,
        AppPermissions.academicCoreView,
        AppPermissions.academicAttendanceWrite,
        AppPermissions.communicationView,
        AppPermissions.reportsView,
        AppPermissions.rolesView,
        AppPermissions.notificationsView,
        AppPermissions.financeApprovalRequestsCreate,
      ],
      isBuiltin: true,
      active: true,
    ),
    const RoleDefinition(
      key: 'VIEWER',
      nameBn: 'ভিউয়ার',
      nameEn: 'Viewer',
      description: 'Read-only dashboard, academic and reports access',
      permissions: [
        AppPermissions.dashboardView,
        AppPermissions.donationsView,
        AppPermissions.academicFoundationView,
        AppPermissions.academicCoreView,
        AppPermissions.communicationView,
        AppPermissions.reportsView,
        AppPermissions.rolesView,
        AppPermissions.notificationsView,
      ],
      isBuiltin: true,
      active: true,
    ),
  ];
}
