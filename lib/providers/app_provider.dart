import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/participant.dart';
import '../models/evaluation.dart';
import '../models/block.dart';
import '../services/auth_service.dart';
import '../services/livekit_service.dart';
import '../services/chat_service.dart';
import '../services/evaluation_service.dart';
import '../services/block_service.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService;
  final LiveKitService _liveKitService;
  final DatabaseService _databaseService;
  late final ChatService _chatService;
  late final EvaluationService _evaluationService;
  late final BlockService _blockService;

  User? _currentUser;
  String? _currentSessionId;
  bool _isLoading = false;
  String? _error;

  AppProvider()
      : _authService = AuthService(),
        _liveKitService = LiveKitService(),
        _databaseService = DatabaseService() {
    _chatService = ChatService(_liveKitService, _databaseService);
    _evaluationService = EvaluationService(_databaseService);
    _blockService = BlockService(_databaseService);
    _initialize();
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSessionId => _currentSessionId;
  LiveKitService get liveKitService => _liveKitService;
  ChatService get chatService => _chatService;
  EvaluationService get evaluationService => _evaluationService;
  BlockService get blockService => _blockService;
  bool get isInstructor => _currentUser?.isInstructor ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  Future<void> _initialize() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }
  }

  // Login as student
  Future<void> loginStudent({
    required String fullName,
    required String universityId,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      _currentUser = await _authService.loginStudent(
        fullName: fullName,
        universityId: universityId,
      );

      notifyListeners();
    } catch (e) {
      _setError('Login failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Login as instructor
  Future<void> loginInstructor({required String fullName}) async {
    try {
      _setLoading(true);
      _setError(null);

      _currentUser = await _authService.loginInstructor(fullName: fullName);

      notifyListeners();
    } catch (e) {
      _setError('Login failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Join room
  Future<void> joinRoom({
    required String roomName,
    required String liveKitUrl,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('User not logged in');
      }

      _setLoading(true);
      _setError(null);

      // Get room token from token server
      final token = await _authService.getRoomToken(
        userId: _currentUser!.id,
        roomName: roomName,
        role: _currentUser!.role,
      );

      // Connect to LiveKit room
      await _liveKitService.connect(
        url: liveKitUrl,
        token: token,
        roomName: roomName,
        currentUser: _currentUser!,
      );

      _currentSessionId = roomName;
      notifyListeners();
    } catch (e) {
      _setError('Failed to join room: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Leave room
  Future<void> leaveRoom() async {
    try {
      await _liveKitService.disconnect();
      await _chatService.clearMessages();
      _currentSessionId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error leaving room: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await leaveRoom();
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }

  // Mute/unmute microphone
  Future<void> toggleMicrophone() async {
    try {
      final localParticipant = _liveKitService.localParticipant;
      if (localParticipant == null) return;

      final isMuted = localParticipant.isMicrophoneEnabled();
      if (isMuted) {
        await _liveKitService.disableMicrophone();
      } else {
        await _liveKitService.enableMicrophone();
      }
    } catch (e) {
      _setError('Failed to toggle microphone: $e');
    }
  }

  // Start/stop screen share
  Future<void> toggleScreenShare() async {
    try {
      final localParticipant = _liveKitService.localParticipant;
      if (localParticipant == null) return;

      final isSharing = localParticipant.isScreenShareEnabled();
      if (isSharing) {
        await _liveKitService.stopScreenShare();
      } else {
        await _liveKitService.startScreenShare();
      }
    } catch (e) {
      _setError('Failed to toggle screen share: $e');
    }
  }

  // Send chat message
  Future<void> sendChatMessage(String message) async {
    try {
      if (_currentUser == null) return;
      await _chatService.sendMessage(
        content: message,
        currentUser: _currentUser!,
      );
    } catch (e) {
      _setError('Failed to send message: $e');
    }
  }

  // Raise hand
  Future<void> raiseHand() async {
    try {
      if (_currentUser == null) return;
      await _chatService.raiseHand(currentUser: _currentUser!);
    } catch (e) {
      _setError('Failed to raise hand: $e');
    }
  }

  // Lower hand
  Future<void> lowerHand() async {
    try {
      if (_currentUser == null) return;
      await _chatService.lowerHand(currentUser: _currentUser!);
    } catch (e) {
      _setError('Failed to lower hand: $e');
    }
  }

  // Mute participant (instructor only)
  Future<void> muteParticipant(String participantSid) async {
    try {
      if (!isInstructor) return;
      await _liveKitService.muteParticipant(participantSid);
    } catch (e) {
      _setError('Failed to mute participant: $e');
    }
  }

  // Mute all participants (instructor only)
  Future<void> muteAllParticipants() async {
    try {
      if (!isInstructor) return;
      await _liveKitService.muteAllParticipants();
    } catch (e) {
      _setError('Failed to mute all: $e');
    }
  }

  // Remove participant (instructor only)
  Future<void> removeParticipant(String participantSid) async {
    try {
      if (!isInstructor) return;
      await _liveKitService.removeParticipant(participantSid);
    } catch (e) {
      _setError('Failed to remove participant: $e');
    }
  }

  // Block participant (instructor only)
  Future<void> blockParticipant({
    required String studentId,
    required String participantSid,
    required BlockDuration duration,
    String? reason,
  }) async {
    try {
      if (!isInstructor || _currentSessionId == null) return;

      await _blockService.blockStudent(
        sessionId: _currentSessionId!,
        studentId: studentId,
        instructorId: _currentUser!.id,
        duration: duration,
        reason: reason,
      );

      await removeParticipant(participantSid);
    } catch (e) {
      _setError('Failed to block participant: $e');
    }
  }

  // Save evaluation (instructor only)
  Future<void> saveEvaluation({
    required String studentId,
    required double score,
    String? notes,
  }) async {
    try {
      if (!isInstructor || _currentSessionId == null) return;

      await _evaluationService.saveEvaluation(
        sessionId: _currentSessionId!,
        studentId: studentId,
        instructorId: _currentUser!.id,
        score: score,
        notes: notes,
      );
    } catch (e) {
      _setError('Failed to save evaluation: $e');
    }
  }

  // Get student evaluations
  Future<List<Evaluation>> getStudentEvaluations() async {
    try {
      if (_currentUser == null) return [];
      return await _evaluationService.getStudentEvaluations(_currentUser!.id);
    } catch (e) {
      _setError('Failed to get evaluations: $e');
      return [];
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _liveKitService.dispose();
    super.dispose();
  }
}
