enum BlockDuration {
  minutes10,
  minutes30,
  permanent;

  int get inMinutes {
    switch (this) {
      case BlockDuration.minutes10:
        return 10;
      case BlockDuration.minutes30:
        return 30;
      case BlockDuration.permanent:
        return -1;
    }
  }

  String get displayName {
    switch (this) {
      case BlockDuration.minutes10:
        return '10 Minutes';
      case BlockDuration.minutes30:
        return '30 Minutes';
      case BlockDuration.permanent:
        return 'Permanent';
    }
  }
}

class Block {
  final String id;
  final String sessionId;
  final String studentId;
  final String instructorId;
  final BlockDuration duration;
  final String? reason;
  final DateTime createdAt;
  final DateTime? expiresAt;

  Block({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.instructorId,
    required this.duration,
    this.reason,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isPermanent => duration == BlockDuration.permanent;

  bool get isActive {
    if (isPermanent) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!);
  }

  Duration? get remainingTime {
    if (isPermanent || expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return null;
    return expiresAt!.difference(now);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'instructorId': instructorId,
      'duration': duration.name,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      studentId: json['studentId'] as String,
      instructorId: json['instructorId'] as String,
      duration: BlockDuration.values.firstWhere(
        (e) => e.name == json['duration'],
        orElse: () => BlockDuration.minutes10,
      ),
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Block copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    String? instructorId,
    BlockDuration? duration,
    String? reason,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Block(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      instructorId: instructorId ?? this.instructorId,
      duration: duration ?? this.duration,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
