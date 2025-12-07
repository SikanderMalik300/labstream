import 'package:livekit_client/livekit_client.dart';
import 'user.dart';

enum ParticipantStatus {
  active,
  muted,
  handRaised,
  sharingScreen,
  blocked,
}

class ParticipantData {
  final String id;
  final String fullName;
  final String? universityId;
  final UserRole role;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isSharingScreen;
  final bool hasHandRaised;
  final bool isBlocked;
  final DateTime? blockedUntil;
  final RemoteParticipant? liveKitParticipant;
  final List<RemoteTrackPublication<RemoteVideoTrack>>? screenTracks;
  final RemoteTrackPublication<RemoteAudioTrack>? audioTrack;

  ParticipantData({
    required this.id,
    required this.fullName,
    this.universityId,
    required this.role,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    this.isSharingScreen = false,
    this.hasHandRaised = false,
    this.isBlocked = false,
    this.blockedUntil,
    this.liveKitParticipant,
    this.screenTracks,
    this.audioTrack,
  });

  bool get isStudent => role == UserRole.student;
  bool get isInstructor => role == UserRole.instructor;
  bool get isCurrentlyBlocked {
    if (!isBlocked) return false;
    if (blockedUntil == null) return true; // Permanent block
    return DateTime.now().isBefore(blockedUntil!);
  }

  ParticipantData copyWith({
    String? id,
    String? fullName,
    String? universityId,
    UserRole? role,
    bool? isAudioMuted,
    bool? isVideoMuted,
    bool? isSharingScreen,
    bool? hasHandRaised,
    bool? isBlocked,
    DateTime? blockedUntil,
    RemoteParticipant? liveKitParticipant,
    List<RemoteTrackPublication<RemoteVideoTrack>>? screenTracks,
    RemoteTrackPublication<RemoteAudioTrack>? audioTrack,
  }) {
    return ParticipantData(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      universityId: universityId ?? this.universityId,
      role: role ?? this.role,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
      isSharingScreen: isSharingScreen ?? this.isSharingScreen,
      hasHandRaised: hasHandRaised ?? this.hasHandRaised,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedUntil: blockedUntil ?? this.blockedUntil,
      liveKitParticipant: liveKitParticipant ?? this.liveKitParticipant,
      screenTracks: screenTracks ?? this.screenTracks,
      audioTrack: audioTrack ?? this.audioTrack,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'universityId': universityId,
      'role': role.name,
      'isAudioMuted': isAudioMuted,
      'isVideoMuted': isVideoMuted,
      'isSharingScreen': isSharingScreen,
      'hasHandRaised': hasHandRaised,
      'isBlocked': isBlocked,
      'blockedUntil': blockedUntil?.toIso8601String(),
    };
  }

  factory ParticipantData.fromJson(Map<String, dynamic> json) {
    return ParticipantData(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      universityId: json['universityId'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      isAudioMuted: json['isAudioMuted'] as bool? ?? false,
      isVideoMuted: json['isVideoMuted'] as bool? ?? false,
      isSharingScreen: json['isSharingScreen'] as bool? ?? false,
      hasHandRaised: json['hasHandRaised'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockedUntil: json['blockedUntil'] != null
          ? DateTime.parse(json['blockedUntil'] as String)
          : null,
    );
  }
}
