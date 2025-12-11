import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  // Login for students with name and student ID
  Future<User> loginStudent({
    required String fullName,
    required String studentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'studentId': studentId,
          'role': 'student',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User(
          id: data['userId'].toString(),
          fullName: fullName,
          studentId: studentId,
          role: UserRole.student,
          token: data['token'].toString(),
          createdAt: DateTime.now(),
        );

        await _saveUser(user);
        return user;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Login for instructors with name and instructor ID
  Future<User> loginInstructor({
    required String fullName,
    required String instructorId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'instructorId': instructorId,
          'role': 'instructor',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User(
          id: data['userId'].toString(),
          fullName: fullName,
          instructorId: instructorId,
          role: UserRole.instructor,
          token: data['token'].toString(),
          createdAt: DateTime.now(),
        );

        await _saveUser(user);
        return user;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Get LiveKit room token
  Future<Map<String, String?>> getRoomToken({
    required String userId,
    required String roomName,
    required UserRole role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.tokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'roomName': roomName,
          'role': role.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both string and map responses
        if (data is Map<String, dynamic>) {
          return {
            'token': data['token'].toString(),
            'sessionId': data['sessionId']?.toString(),
          };
        } else if (data is String) {
          return {
            'token': data,
            'sessionId': null,
          };
        } else {
          throw Exception('Unexpected token response format');
        }
      } else {
        throw Exception('Token generation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Token error: $e');
    }
  }

  // Save user to local storage
  Future<void> _saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userKey, userJson);
      if (user.token != null) {
        await prefs.setString(_tokenKey, user.token!);
      }
    } catch (e) {
      debugPrint('Error saving user: $e');
      // Clear corrupted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      rethrow;
    }
  }

  // Get current user from local storage
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson == null) return null;

      final userData = jsonDecode(userJson);
      return User.fromJson(userData);
    } catch (e) {
      debugPrint('Error loading user, clearing corrupted data: $e');
      // Clear corrupted data and return null
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      return null;
    }
  }

  // Get current token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // Clear all stored data (for troubleshooting)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('All stored data cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
}
