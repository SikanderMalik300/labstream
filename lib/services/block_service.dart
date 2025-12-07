import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/block.dart';
import '../config/app_config.dart';
import 'database_service.dart';

class BlockService {
  final DatabaseService _databaseService;

  BlockService(this._databaseService);

  // Block a student
  Future<Block> blockStudent({
    required String sessionId,
    required String studentId,
    required String instructorId,
    required BlockDuration duration,
    String? reason,
  }) async {
    try {
      DateTime? expiresAt;
      if (duration != BlockDuration.permanent) {
        expiresAt = DateTime.now().add(Duration(minutes: duration.inMinutes));
      }

      final block = Block(
        id: const Uuid().v4(),
        sessionId: sessionId,
        studentId: studentId,
        instructorId: instructorId,
        duration: duration,
        reason: reason,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      // Save to local database
      await _databaseService.saveBlock(block);

      // Sync to server (optional)
      try {
        await _syncToServer(block);
      } catch (e) {
        print('Warning: Failed to sync block to server: $e');
      }

      return block;
    } catch (e) {
      throw Exception('Error blocking student: $e');
    }
  }

  // Check if student is blocked
  Future<bool> isStudentBlocked(String studentId) async {
    try {
      final blocks = await _databaseService.getActiveBlocks(studentId);
      return blocks.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking block status: $e');
    }
  }

  // Get active blocks for a student
  Future<List<Block>> getActiveBlocks(String studentId) async {
    try {
      final blocks = await _databaseService.getActiveBlocks(studentId);
      return blocks.where((block) => block.isActive).toList();
    } catch (e) {
      throw Exception('Error getting active blocks: $e');
    }
  }

  // Get block details with remaining time
  Future<Map<String, dynamic>?> getBlockDetails(String studentId) async {
    try {
      final blocks = await getActiveBlocks(studentId);
      if (blocks.isEmpty) return null;

      final block = blocks.first;
      return {
        'block': block,
        'remainingTime': block.remainingTime,
        'isPermanent': block.isPermanent,
        'reason': block.reason,
      };
    } catch (e) {
      throw Exception('Error getting block details: $e');
    }
  }

  // Sync block to server
  Future<void> _syncToServer(Block block) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.blockEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(block.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch blocks from server
  Future<List<Block>> fetchBlocksFromServer(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.blockEndpoint}/$studentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Block.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch blocks from server');
      }
    } catch (e) {
      throw Exception('Error fetching blocks: $e');
    }
  }
}
