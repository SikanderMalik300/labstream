enum UserRole {
  student,
  instructor;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.instructor:
        return 'Instructor';
    }
  }
}

class User {
  final String id;
  final String fullName;
  final String? studentId; // Only for students
  final String? instructorId; // Only for instructors
  final UserRole role;
  final String? token; // JWT token
  final DateTime? createdAt;

  User({
    required this.id,
    required this.fullName,
    this.studentId,
    this.instructorId,
    required this.role,
    this.token,
    this.createdAt,
  });

  bool get isStudent => role == UserRole.student;
  bool get isInstructor => role == UserRole.instructor;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'studentId': studentId,
      'instructorId': instructorId,
      'role': role.name,
      'token': token,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      studentId: json['studentId'] as String?,
      instructorId: json['instructorId'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      token: json['token'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  User copyWith({
    String? id,
    String? fullName,
    String? studentId,
    String? instructorId,
    UserRole? role,
    String? token,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      studentId: studentId ?? this.studentId,
      instructorId: instructorId ?? this.instructorId,
      role: role ?? this.role,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
