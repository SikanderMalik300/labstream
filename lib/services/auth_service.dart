import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';

  // Login for students with name and university ID
  Future<User> loginStudent({
    required String fullName,
    required String universityId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'universityId': universityId,
          'role': 'student',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User(
          id: data['userId'].toString(),
          fullName: fullName,
          universityId: universityId,
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

  // Login for instructors
  Future<User> loginInstructor({required String fullName}) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'role': 'instructor',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User(
          id: data['userId'].toString(),
          fullName: fullName,
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
  Future<String> getRoomToken({
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
          return data['token'].toString();
        } else if (data is String) {
          return data;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    if (user.token != null) {
      await prefs.setString(_tokenKey, user.token!);
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
}
