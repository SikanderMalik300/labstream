enum MessageType {
  text,
  system,
  handRaise,
  handLower;

  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.system:
        return 'System';
      case MessageType.handRaise:
        return 'Hand Raised';
      case MessageType.handLower:
        return 'Hand Lowered';
    }
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isFromInstructor;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isFromInstructor = false,
  });

  bool get isSystemMessage => type == MessageType.system;
  bool get isHandRaise => type == MessageType.handRaise;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isFromInstructor': isFromInstructor,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFromInstructor: json['isFromInstructor'] as bool? ?? false,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isFromInstructor,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isFromInstructor: isFromInstructor ?? this.isFromInstructor,
    );
  }
}
