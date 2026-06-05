class SessionUser {
  final String id;
  final String name;
  final String role;
  final String phone;
  final String email;
  final String approvalStatus;
  final List<String> permissions;

  const SessionUser({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    required this.approvalStatus,
    required this.permissions,
  });

  factory SessionUser.fromMap(Map<String, dynamic> map) {
    return SessionUser(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      approvalStatus: (map['approval_status'] ?? 'APPROVED').toString(),
      permissions: (map['permissions'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phone': phone,
      'email': email,
      'approval_status': approvalStatus,
      'permissions': permissions,
    };
  }
}
