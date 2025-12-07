import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import '../models/participant.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class LiveKitService extends ChangeNotifier {
  Room? _room;
  LocalParticipant? _localParticipant;
  final Map<String, ParticipantData> _participants = {};
  final List<StreamSubscription> _subscriptions = [];
  bool _isConnected = false;
  String? _currentRoomName;

  Room? get room => _room;
  bool get isConnected => _isConnected;
  String? get currentRoomName => _currentRoomName;
  List<ParticipantData> get participants => _participants.values.toList();
  LocalParticipant? get localParticipant => _localParticipant;

  // Connect to LiveKit room
  Future<void> connect({
    required String url,
    required String token,
    required String roomName,
    required User currentUser,
  }) async {
    try {
      // Disconnect if already connected
      if (_isConnected) {
        await disconnect();
      }

      // Create room
      _room = Room();
      _currentRoomName = roomName;

      // Setup event listeners
      _setupRoomListeners();

      // Connect to room
      await _room!.connect(
        url,
        token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(
            name: 'microphone',
            stream: 'audio',
          ),
          defaultVideoPublishOptions: VideoPublishOptions(
            name: 'camera',
            simulcast: true,
          ),
          defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
            useiOSBroadcastExtension: false,
            params: VideoParameters(
              dimensions: VideoDimensions(1920, 1080),
              encoding: VideoEncoding(
                maxBitrate: 3000000,
                maxFramerate: 15,
              ),
            ),
          ),
        ),
      );

      _localParticipant = _room!.localParticipant;
      _isConnected = true;

      // For students: enable microphone
      if (currentUser.isStudent) {
        await enableMicrophone();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error connecting to LiveKit: $e');
      rethrow;
    }
  }

  // Setup room event listeners
  void _setupRoomListeners() {
    if (_room == null) return;

    final listener = _room!.createListener();

    listener
      ..on<RoomConnectedEvent>((event) {
        debugPrint('Connected to room');
        _isConnected = true;
        notifyListeners();
      })
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('Disconnected from room');
        _isConnected = false;
        notifyListeners();
      })
      ..on<ParticipantConnectedEvent>((event) {
        _onParticipantConnected(event.participant);
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        _onParticipantDisconnected(event.participant);
      })
      ..on<TrackPublishedEvent>((event) {
        _onTrackPublished(event.participant, event.publication);
      })
      ..on<TrackUnpublishedEvent>((event) {
        _onTrackUnpublished(event.participant, event.publication);
      })
      ..on<TrackSubscribedEvent>((event) {
        if (event.track is RemoteTrack) {
          _onTrackSubscribed(event.participant, event.track as RemoteTrack, event.publication);
        }
      })
      ..on<TrackUnsubscribedEvent>((event) {
        if (event.track is RemoteTrack) {
          _onTrackUnsubscribed(event.participant, event.track as RemoteTrack, event.publication);
        }
      })
      ..on<DataReceivedEvent>((event) {
        _onDataReceived(event.participant, event.data);
      });
  }

  void _onParticipantConnected(RemoteParticipant participant) {
    debugPrint('Participant connected: ${participant.identity}');

    // Parse participant metadata to get user info
    final metadata = participant.metadata;
    Map<String, dynamic>? userInfo;
    if (metadata != null && metadata.isNotEmpty) {
      try {
        userInfo = jsonDecode(metadata);
      } catch (e) {
        debugPrint('Error parsing participant metadata: $e');
      }
    }

    _participants[participant.sid] = ParticipantData(
      id: participant.identity,
      fullName: userInfo?['fullName'] ?? participant.name ?? 'Unknown',
      universityId: userInfo?['universityId'],
      role: UserRole.values.firstWhere(
        (r) => r.name == userInfo?['role'],
        orElse: () => UserRole.student,
      ),
      liveKitParticipant: participant,
    );

    notifyListeners();
  }

  void _onParticipantDisconnected(RemoteParticipant participant) {
    debugPrint('Participant disconnected: ${participant.identity}');
    _participants.remove(participant.sid);
    notifyListeners();
  }

  void _onTrackPublished(Participant participant, TrackPublication publication) {
    debugPrint('Track published: ${publication.name} by ${participant.identity}');
    notifyListeners();
  }

  void _onTrackUnpublished(Participant participant, TrackPublication publication) {
    debugPrint('Track unpublished: ${publication.name} by ${participant.identity}');
    notifyListeners();
  }

  void _onTrackSubscribed(
    RemoteParticipant participant,
    RemoteTrack track,
    RemoteTrackPublication publication,
  ) {
    debugPrint('Track subscribed: ${track.sid} from ${participant.identity}');

    final participantData = _participants[participant.sid];
    if (participantData == null) return;

    if (track.kind == TrackType.VIDEO && publication.source == TrackSource.screenShareVideo) {
      // Screen share track
      final screenTracks = participantData.screenTracks ?? [];
      _participants[participant.sid] = participantData.copyWith(
        isSharingScreen: true,
        screenTracks: [...screenTracks, publication as RemoteTrackPublication<RemoteVideoTrack>],
      );
    } else if (track.kind == TrackType.AUDIO) {
      // Audio track
      _participants[participant.sid] = participantData.copyWith(
        audioTrack: publication as RemoteTrackPublication<RemoteAudioTrack>,
      );
    }

    notifyListeners();
  }

  void _onTrackUnsubscribed(
    RemoteParticipant participant,
    RemoteTrack track,
    RemoteTrackPublication publication,
  ) {
    debugPrint('Track unsubscribed: ${track.sid} from ${participant.identity}');

    final participantData = _participants[participant.sid];
    if (participantData == null) return;

    if (track.kind == TrackType.VIDEO && publication.source == TrackSource.screenShareVideo) {
      final screenTracks = participantData.screenTracks ?? [];
      screenTracks.removeWhere((t) => t.sid == publication.sid);
      _participants[participant.sid] = participantData.copyWith(
        isSharingScreen: screenTracks.isNotEmpty,
        screenTracks: screenTracks,
      );
    }

    notifyListeners();
  }

  void _onDataReceived(RemoteParticipant? participant, List<int> data) {
    // Handle data channel messages (chat, hand raise, etc.)
    // This will be implemented in ChatService
    debugPrint('Data received from ${participant?.identity}');
  }

  // Enable microphone
  Future<void> enableMicrophone() async {
    try {
      await _localParticipant?.setMicrophoneEnabled(true);
      notifyListeners();
    } catch (e) {
      debugPrint('Error enabling microphone: $e');
      rethrow;
    }
  }

  // Disable microphone
  Future<void> disableMicrophone() async {
    try {
      await _localParticipant?.setMicrophoneEnabled(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Error disabling microphone: $e');
      rethrow;
    }
  }

  // Start screen sharing
  Future<void> startScreenShare() async {
    try {
      await _localParticipant?.setScreenShareEnabled(true);
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting screen share: $e');
      rethrow;
    }
  }

  // Stop screen sharing
  Future<void> stopScreenShare() async {
    try {
      await _localParticipant?.setScreenShareEnabled(false);
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping screen share: $e');
      rethrow;
    }
  }

  // Mute specific participant (instructor only)
  Future<void> muteParticipant(String participantSid) async {
    try {
      final participant = _participants[participantSid];
      if (participant?.liveKitParticipant == null) return;

      // Send mute command via data channel
      await sendDataMessage({
        'type': 'mute',
        'targetId': participant!.id,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error muting participant: $e');
      rethrow;
    }
  }

  // Mute all participants (instructor only)
  Future<void> muteAllParticipants() async {
    try {
      await sendDataMessage({
        'type': 'muteAll',
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error muting all participants: $e');
      rethrow;
    }
  }

  // Remove participant from room (instructor only)
  Future<void> removeParticipant(String participantSid) async {
    try {
      final participant = _participants[participantSid];
      if (participant == null) return;

      // Send remove command via data channel
      await sendDataMessage({
        'type': 'remove',
        'targetId': participant.id,
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error removing participant: $e');
      rethrow;
    }
  }

  // Send data message via LiveKit data channel
  Future<void> sendDataMessage(Map<String, dynamic> data) async {
    try {
      final jsonData = jsonEncode(data);
      await _localParticipant?.publishData(
        utf8.encode(jsonData),
        reliable: true,
      );
    } catch (e) {
      debugPrint('Error sending data message: $e');
      rethrow;
    }
  }

  // Disconnect from room
  Future<void> disconnect() async {
    try {
      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();

      // Disconnect room
      await _room?.disconnect();
      await _room?.dispose();

      _room = null;
      _localParticipant = null;
      _participants.clear();
      _isConnected = false;
      _currentRoomName = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
