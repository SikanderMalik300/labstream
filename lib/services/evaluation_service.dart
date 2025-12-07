import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/evaluation.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'database_service.dart';

class EvaluationService {
  final DatabaseService _databaseService;

  EvaluationService(this._databaseService);

  // Create or update evaluation
  Future<Evaluation> saveEvaluation({
    required String sessionId,
    required String studentId,
    required String instructorId,
    required double score,
    String? notes,
  }) async {
    try {
      // Validate score
      if (score < AppConfig.minScore || score > AppConfig.maxScore) {
        throw Exception('Score must be between ${AppConfig.minScore} and ${AppConfig.maxScore}');
      }

      // Check if evaluation already exists
      final existing = await _databaseService.getEvaluation(studentId, sessionId);

      final evaluation = Evaluation(
        id: existing?.id ?? const Uuid().v4(),
        sessionId: sessionId,
        studentId: studentId,
        instructorId: instructorId,
        score: score,
        notes: notes,
        createdAt: existing?.createdAt ?? DateTime.now(),
        updatedAt: existing != null ? DateTime.now() : null,
      );

      // Save to local database
      await _databaseService.saveEvaluation(evaluation);

      // Sync to server (optional)
      try {
        await _syncToServer(evaluation);
      } catch (e) {
        // Continue even if server sync fails
        print('Warning: Failed to sync evaluation to server: $e');
      }

      return evaluation;
    } catch (e) {
      throw Exception('Error saving evaluation: $e');
    }
  }

  // Get evaluation for a student in a session
  Future<Evaluation?> getEvaluation({
    required String studentId,
    required String sessionId,
  }) async {
    try {
      return await _databaseService.getEvaluation(studentId, sessionId);
    } catch (e) {
      throw Exception('Error getting evaluation: $e');
    }
  }

  // Get all evaluations for a student
  Future<List<Evaluation>> getStudentEvaluations(String studentId) async {
    try {
      return await _databaseService.getStudentEvaluations(studentId);
    } catch (e) {
      throw Exception('Error getting student evaluations: $e');
    }
  }

  // Sync evaluation to server
  Future<void> _syncToServer(Evaluation evaluation) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.evaluationEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(evaluation.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch evaluations from server
  Future<List<Evaluation>> fetchEvaluationsFromServer(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.evaluationEndpoint}/$studentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Evaluation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch evaluations from server');
      }
    } catch (e) {
      throw Exception('Error fetching evaluations: $e');
    }
  }
}
