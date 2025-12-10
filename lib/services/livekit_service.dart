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
  Function(Map<String, dynamic>)? _onDataCallback;
  Function(String controlType, Map<String, dynamic> data)? _onControlCallback;

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

      debugPrint('Successfully connected to LiveKit room');

      // Add local participant to the list (yourself)
      await _addLocalParticipant(currentUser);

      // Load existing remote participants already in the room
      _loadExistingParticipants();

      notifyListeners();

      // Try to enable microphone for students (non-blocking)
      if (currentUser.isStudent) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            await enableMicrophone();
          } catch (e) {
            debugPrint('Could not auto-enable microphone: $e');
            // Non-critical error - user can manually enable later
          }
        });
      }
    } catch (e) {
      debugPrint('Error connecting to LiveKit: $e');
      rethrow;
    }
  }

  // Add local participant to the participant list
  Future<void> _addLocalParticipant(User currentUser) async {
    if (_localParticipant == null) return;

    _participants[_localParticipant!.sid] = ParticipantData(
      id: currentUser.id,
      fullName: currentUser.fullName,
      studentId: currentUser.studentId,
      instructorId: currentUser.instructorId,
      role: currentUser.role,
      liveKitParticipant: _localParticipant!,
      isLocal: true,
    );

    debugPrint('Added local participant: ${currentUser.fullName}');
  }

  // Load existing participants when joining a room
  void _loadExistingParticipants() {
    if (_room == null) return;

    for (final participant in _room!.remoteParticipants.values) {
      _onParticipantConnected(participant);
    }

    debugPrint('Loaded ${_room!.remoteParticipants.length} existing participants');
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
      studentId: userInfo?['studentId'],
      instructorId: userInfo?['instructorId'],
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
    try {
      // Decode the data
      final jsonString = utf8.decode(data);
      final decodedData = jsonDecode(jsonString) as Map<String, dynamic>;

      final messageType = decodedData['type'] as String?;
      debugPrint('Data received from ${participant?.identity}: $messageType');

      // Separate control messages from chat messages
      if (messageType == 'mute' || messageType == 'muteAll' || messageType == 'remove') {
        // Control message - forward to control handler
        if (messageType != null) {
          _onControlCallback?.call(messageType, decodedData);
        }
      } else if (messageType == 'chat') {
        // Chat message - forward to chat handler
        _onDataCallback?.call(decodedData);
      }
    } catch (e) {
      debugPrint('Error handling received data: $e');
    }
  }

  // Register a callback for data channel messages
  void registerDataHandler(Function(Map<String, dynamic>) handler) {
    _onDataCallback = handler;
  }

  // Unregister data handler
  void unregisterDataHandler() {
    _onDataCallback = null;
  }

  // Register a callback for control messages (mute, remove, etc.)
  void registerControlHandler(Function(String controlType, Map<String, dynamic> data) handler) {
    _onControlCallback = handler;
  }

  // Unregister control handler
  void unregisterControlHandler() {
    _onControlCallback = null;
  }

  // Enable microphone
  Future<void> enableMicrophone() async {
    try {
      if (_localParticipant == null || _room == null) {
        throw Exception('Not connected to room');
      }

      await _localParticipant!.setMicrophoneEnabled(true);
      debugPrint('Microphone enabled successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error enabling microphone: $e');
      // Don't rethrow - this is a non-critical error
      // User can try again manually
    }
  }

  // Disable microphone
  Future<void> disableMicrophone() async {
    try {
      if (_localParticipant == null || _room == null) {
        throw Exception('Not connected to room');
      }

      await _localParticipant!.setMicrophoneEnabled(false);
      debugPrint('Microphone disabled successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error disabling microphone: $e');
      // Don't rethrow - this is a non-critical error
    }
  }

  // Start screen sharing
  Future<void> startScreenShare() async {
    try {
      if (_localParticipant == null) {
        throw Exception('Not connected to room');
      }

      // For desktop platforms, LiveKit will handle screen capture
      // Make sure the app has screen capture permissions
      await _localParticipant!.setScreenShareEnabled(
        true,
        captureScreenAudio: false, // Set to true if you want to capture system audio
      );

      debugPrint('Screen share started successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting screen share: $e');
      // Provide more user-friendly error message
      if (e.toString().contains('getDisplayMedia')) {
        throw Exception(
          'Screen sharing is not available. Please ensure the app has screen capture permissions.'
        );
      }
      rethrow;
    }
  }

  // Stop screen sharing
  Future<void> stopScreenShare() async {
    try {
      if (_localParticipant == null) {
        throw Exception('Not connected to room');
      }

      await _localParticipant!.setScreenShareEnabled(false);
      debugPrint('Screen share stopped successfully');
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
