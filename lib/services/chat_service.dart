import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
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
      await _addMessage(message);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Raise hand
  Future<void> raiseHand({required User currentUser}) async {
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
      await _addMessage(message);
    } catch (e) {
      debugPrint('Error raising hand: $e');
      rethrow;
    }
  }

  // Lower hand
  Future<void> lowerHand({required User currentUser}) async {
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
      await _addMessage(message);
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
  Future<void> _addMessage(ChatMessage message) async {
    _messages.add(message);
    notifyListeners();

    try {
      await _databaseService.saveChatMessage(message);
    } catch (e) {
      debugPrint('Error saving message to database: $e');
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
