class Session {
  final String id;
  final String roomName;
  final String instructorId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int participantCount;
  final Map<String, dynamic>? metadata;

  Session({
    required this.id,
    required this.roomName,
    required this.instructorId,
    required this.startedAt,
    this.endedAt,
    this.participantCount = 0,
    this.metadata,
  });

  bool get isActive => endedAt == null;

  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomName': roomName,
      'instructorId': instructorId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'participantCount': participantCount,
      'metadata': metadata,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      roomName: json['roomName'] as String,
      instructorId: json['instructorId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      participantCount: json['participantCount'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Session copyWith({
    String? id,
    String? roomName,
    String? instructorId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? participantCount,
    Map<String, dynamic>? metadata,
  }) {
    return Session(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      instructorId: instructorId ?? this.instructorId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      participantCount: participantCount ?? this.participantCount,
      metadata: metadata ?? this.metadata,
    );
  }
}
