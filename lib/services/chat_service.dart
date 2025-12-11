import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'livekit_service.dart';
import 'database_service.dart';

class ChatService extends ChangeNotifier {
  final LiveKitService _liveKitService;
  final DatabaseService _databaseService;
  final List<ChatMessage> _messages = [];
  final Set<String> _raisedHands = {};

  ChatService(this._liveKitService, this._databaseService) {
    // Don't load old messages - start fresh for each session
    // Messages will be populated as they arrive in real-time

    // Register to receive data channel messages from LiveKit
    _liveKitService.registerDataHandler(handleIncomingMessage);
    debugPrint('ChatService initialized and registered for data events');
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  int get raisedHandsCount => _raisedHands.length;
  Set<String> get raisedHands => Set.unmodifiable(_raisedHands);

  Future<void> _loadMessagesFromDatabase() async {
    try {
      final savedMessages = await _databaseService.getChatMessages(limit: 100);
      _messages.clear();
      _messages.addAll(savedMessages);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages from database: $e');
    }
  }

  // Send text message
  Future<void> sendMessage({
    required String content,
    required User currentUser,
    String? sessionId,
  }) async {
    try {
      final message = ChatMessage(
        id: const Uuid().v4(),
        senderId: currentUser.id,
        senderName: currentUser.fullName,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
        isFromInstructor: currentUser.isInstructor,
      );

      await _sendMessageViaLiveKit(message);
      await _addMessage(message, sessionId: sessionId);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Raise hand
  Future<void> raiseHand({required User currentUser, String? sessionId}) async {
    try {
      if (_raisedHands.contains(currentUser.id)) {
        return; // Hand already raised
      }

      final message = ChatMessage(
        id: const Uuid().v4(),
        senderId: currentUser.id,
        senderName: currentUser.fullName,
        content: '${currentUser.fullName} raised their hand',
        type: MessageType.handRaise,
        timestamp: DateTime.now(),
        isFromInstructor: currentUser.isInstructor,
      );

      await _sendMessageViaLiveKit(message);
      _raisedHands.add(currentUser.id);
      await _addMessage(message, sessionId: sessionId);

      // Sync hand raise to server
      if (sessionId != null) {
        Future(() async {
          try {
            await _syncHandRaiseToServer(sessionId, currentUser.id, true);
          } catch (e) {
            debugPrint('Warning: Failed to sync hand raise to server: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error raising hand: $e');
      rethrow;
    }
  }

  // Lower hand
  Future<void> lowerHand({required User currentUser, String? sessionId}) async {
    try {
      if (!_raisedHands.contains(currentUser.id)) {
        return; // Hand not raised
      }

      final message = ChatMessage(
        id: const Uuid().v4(),
        senderId: currentUser.id,
        senderName: currentUser.fullName,
        content: '${currentUser.fullName} lowered their hand',
        type: MessageType.handLower,
        timestamp: DateTime.now(),
        isFromInstructor: currentUser.isInstructor,
      );

      await _sendMessageViaLiveKit(message);
      _raisedHands.remove(currentUser.id);
      await _addMessage(message, sessionId: sessionId);

      // Sync hand lower to server
      if (sessionId != null) {
        Future(() async {
          try {
            await _syncHandRaiseToServer(sessionId, currentUser.id, false);
          } catch (e) {
            debugPrint('Warning: Failed to sync hand lower to server: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error lowering hand: $e');
      rethrow;
    }
  }

  // Send system message
  Future<void> sendSystemMessage(String content) async {
    try {
      final message = ChatMessage(
        id: const Uuid().v4(),
        senderId: 'system',
        senderName: 'System',
        content: content,
        type: MessageType.system,
        timestamp: DateTime.now(),
        isFromInstructor: false,
      );

      await _sendMessageViaLiveKit(message);
      await _addMessage(message);
    } catch (e) {
      debugPrint('Error sending system message: $e');
      rethrow;
    }
  }

  // Send message via LiveKit data channel
  Future<void> _sendMessageViaLiveKit(ChatMessage message) async {
    try {
      await _liveKitService.sendDataMessage({
        'type': 'chat',
        'message': message.toJson(),
      });
    } catch (e) {
      debugPrint('Error sending message via LiveKit: $e');
      rethrow;
    }
  }

  // Handle incoming message from LiveKit
  Future<void> handleIncomingMessage(Map<String, dynamic> data) async {
    try {
      if (data['type'] == 'chat') {
        final messageData = data['message'] as Map<String, dynamic>;
        final message = ChatMessage.fromJson(messageData);
        await _addMessage(message);

        // Update raised hands
        if (message.type == MessageType.handRaise) {
          _raisedHands.add(message.senderId);
        } else if (message.type == MessageType.handLower) {
          _raisedHands.remove(message.senderId);
        }
      }
    } catch (e) {
      debugPrint('Error handling incoming message: $e');
    }
  }

  // Add message to list and database
  Future<void> _addMessage(ChatMessage message, {String? sessionId}) async {
    _messages.add(message);
    notifyListeners();

    // Save to local database in background (non-critical)
    Future(() async {
      try {
        await _databaseService.saveChatMessage(message);
      } catch (e) {
        // Silently ignore database errors - chat works without persistence
      }
    });

    // Sync to PostgreSQL server in background (non-critical)
    if (sessionId != null) {
      Future(() async {
        try {
          await _syncMessageToServer(message, sessionId);
        } catch (e) {
          debugPrint('Warning: Failed to sync message to server: $e');
        }
      });
    }
  }

  // Sync message to PostgreSQL server
  Future<void> _syncMessageToServer(ChatMessage message, String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.tokenServerUrl}/api/chat/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': message.id,
          'sessionId': sessionId,
          'senderId': message.senderId,
          'senderName': message.senderName,
          'content': message.content,
          'messageType': message.type.name,
          'isFromInstructor': message.isFromInstructor,
          'timestamp': message.timestamp.toIso8601String(),
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server returned status ${response.statusCode}');
      }
      debugPrint('✅ Chat message synced to PostgreSQL');
    } catch (e) {
      debugPrint('Failed to sync chat message to server: $e');
      rethrow;
    }
  }

  // Sync hand raise to server
  Future<void> _syncHandRaiseToServer(String sessionId, String studentId, bool isRaising) async {
    try {
      if (isRaising) {
        final response = await http.post(
          Uri.parse('${AppConfig.tokenServerUrl}/api/hand-raises'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sessionId': sessionId,
            'studentId': studentId,
          }),
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception('Server returned status ${response.statusCode}');
        }
        debugPrint('✅ Hand raise synced to PostgreSQL');
      } else {
        final response = await http.delete(
          Uri.parse('${AppConfig.tokenServerUrl}/api/hand-raises/$sessionId/$studentId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode != 200) {
          throw Exception('Server returned status ${response.statusCode}');
        }
        debugPrint('✅ Hand lower synced to PostgreSQL');
      }
    } catch (e) {
      debugPrint('Failed to sync hand raise to server: $e');
      rethrow;
    }
  }

  // Clear all messages
  Future<void> clearMessages() async {
    _messages.clear();
    _raisedHands.clear();
    notifyListeners();
  }

  // Get message count
  int get messageCount => _messages.length;
}
