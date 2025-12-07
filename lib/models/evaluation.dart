class Evaluation {
  final String id;
  final String sessionId;
  final String studentId;
  final String instructorId;
  final double score; // 0-10
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Evaluation({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.instructorId,
    required this.score,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasPassed => score >= 5.0;

  String get grade {
    if (score >= 9.0) return 'A';
    if (score >= 8.0) return 'B';
    if (score >= 7.0) return 'C';
    if (score >= 6.0) return 'D';
    if (score >= 5.0) return 'E';
    return 'F';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'instructorId': instructorId,
      'score': score,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      studentId: json['studentId'] as String,
      instructorId: json['instructorId'] as String,
      score: (json['score'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Evaluation copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    String? instructorId,
    double? score,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Evaluation(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      instructorId: instructorId ?? this.instructorId,
      score: score ?? this.score,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
