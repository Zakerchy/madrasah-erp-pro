class RoleDefinition {
  final String key;
  final String nameBn;
  final String nameEn;
  final String description;
  final List<String> permissions;
  final bool isBuiltin;
  final bool active;

  const RoleDefinition({
    required this.key,
    required this.nameBn,
    required this.nameEn,
    required this.description,
    required this.permissions,
    required this.isBuiltin,
    required this.active,
  });

  factory RoleDefinition.fromMap(Map<String, dynamic> map) {
    final permissions = (map['permissions'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return RoleDefinition(
      key: (map['key'] ?? '').toString().trim().toUpperCase(),
      nameBn: (map['name_bn'] ?? map['key'] ?? '').toString().trim(),
      nameEn: (map['name_en'] ?? map['key'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      permissions: permissions,
      isBuiltin: map['is_builtin'] == true,
      active: map['active'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'name_bn': nameBn,
      'name_en': nameEn,
      'description': description,
      'permissions': permissions,
      'is_builtin': isBuiltin,
      'active': active,
    };
  }
}
