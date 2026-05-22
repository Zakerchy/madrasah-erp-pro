class SessionUser {
  final String id;
  final String name;
  final String role;
  final String phone;
  final String email;

  const SessionUser({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
  });

  factory SessionUser.fromMap(Map<String, dynamic> map) {
    return SessionUser(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phone': phone,
      'email': email,
    };
  }
}
