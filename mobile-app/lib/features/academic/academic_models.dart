class AcademicStudent {
  final String id;
  final String nameBn;
  final String classId;
  final String sectionId;
  final String status;

  const AcademicStudent({
    required this.id,
    required this.nameBn,
    required this.classId,
    required this.sectionId,
    required this.status,
  });

  factory AcademicStudent.fromJson(Map<String, dynamic> json) {
    return AcademicStudent(
      id: json['id']?.toString() ?? '',
      nameBn: json['name_bn']?.toString() ?? '',
      classId: json['class_id']?.toString() ?? '',
      sectionId: json['section_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class AcademicClassRoom {
  final String id;
  final String name;
  final String status;

  const AcademicClassRoom(
      {required this.id, required this.name, required this.status});

  factory AcademicClassRoom.fromJson(Map<String, dynamic> json) {
    return AcademicClassRoom(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class AcademicGuardian {
  final String id;
  final String studentId;
  final String name;
  final String phone;

  const AcademicGuardian({
    required this.id,
    required this.studentId,
    required this.name,
    required this.phone,
  });

  factory AcademicGuardian.fromJson(Map<String, dynamic> json) {
    return AcademicGuardian(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}
