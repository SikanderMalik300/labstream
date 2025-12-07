import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/evaluation.dart';
import '../models/block.dart';
import '../models/chat_message.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'labstream.db';
  static const int _dbVersion = 1;

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize FFI for desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocDir.path, _dbName);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Evaluations table
    await db.execute('''
      CREATE TABLE evaluations (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        instructor_id TEXT NOT NULL,
        score REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Blocks table
    await db.execute('''
      CREATE TABLE blocks (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        instructor_id TEXT NOT NULL,
        duration TEXT NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL,
        expires_at TEXT
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_from_instructor INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        room_name TEXT NOT NULL,
        instructor_id TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        participant_count INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_evaluations_student ON evaluations(student_id)');
    await db.execute('CREATE INDEX idx_evaluations_session ON evaluations(session_id)');
    await db.execute('CREATE INDEX idx_blocks_student ON blocks(student_id)');
    await db.execute('CREATE INDEX idx_blocks_expires ON blocks(expires_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // Evaluation operations
  Future<void> saveEvaluation(Evaluation evaluation) async {
    final db = await database;
    await db.insert(
      'evaluations',
      {
        'id': evaluation.id,
        'session_id': evaluation.sessionId,
        'student_id': evaluation.studentId,
        'instructor_id': evaluation.instructorId,
        'score': evaluation.score,
        'notes': evaluation.notes,
        'created_at': evaluation.createdAt.toIso8601String(),
        'updated_at': evaluation.updatedAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Evaluation?> getEvaluation(String studentId, String sessionId) async {
    final db = await database;
    final results = await db.query(
      'evaluations',
      where: 'student_id = ? AND session_id = ?',
      whereArgs: [studentId, sessionId],
    );

    if (results.isEmpty) return null;

    final data = results.first;
    return Evaluation(
      id: data['id'] as String,
      sessionId: data['session_id'] as String,
      studentId: data['student_id'] as String,
      instructorId: data['instructor_id'] as String,
      score: data['score'] as double,
      notes: data['notes'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
    );
  }

  Future<List<Evaluation>> getStudentEvaluations(String studentId) async {
    final db = await database;
    final results = await db.query(
      'evaluations',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );

    return results.map((data) {
      return Evaluation(
        id: data['id'] as String,
        sessionId: data['session_id'] as String,
        studentId: data['student_id'] as String,
        instructorId: data['instructor_id'] as String,
        score: data['score'] as double,
        notes: data['notes'] as String?,
        createdAt: DateTime.parse(data['created_at'] as String),
        updatedAt: data['updated_at'] != null
            ? DateTime.parse(data['updated_at'] as String)
            : null,
      );
    }).toList();
  }

  // Block operations
  Future<void> saveBlock(Block block) async {
    final db = await database;
    await db.insert(
      'blocks',
      {
        'id': block.id,
        'session_id': block.sessionId,
        'student_id': block.studentId,
        'instructor_id': block.instructorId,
        'duration': block.duration.name,
        'reason': block.reason,
        'created_at': block.createdAt.toIso8601String(),
        'expires_at': block.expiresAt?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Block>> getActiveBlocks(String studentId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final results = await db.query(
      'blocks',
      where: 'student_id = ? AND (expires_at IS NULL OR expires_at > ?)',
      whereArgs: [studentId, now],
    );

    return results.map((data) {
      return Block(
        id: data['id'] as String,
        sessionId: data['session_id'] as String,
        studentId: data['student_id'] as String,
        instructorId: data['instructor_id'] as String,
        duration: BlockDuration.values.firstWhere(
          (e) => e.name == data['duration'],
        ),
        reason: data['reason'] as String?,
        createdAt: DateTime.parse(data['created_at'] as String),
        expiresAt: data['expires_at'] != null
            ? DateTime.parse(data['expires_at'] as String)
            : null,
      );
    }).toList();
  }

  // Chat message operations
  Future<void> saveChatMessage(ChatMessage message) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      {
        'id': message.id,
        'sender_id': message.senderId,
        'sender_name': message.senderName,
        'content': message.content,
        'type': message.type.name,
        'timestamp': message.timestamp.toIso8601String(),
        'is_from_instructor': message.isFromInstructor ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getChatMessages({int limit = 100}) async {
    final db = await database;
    final results = await db.query(
      'chat_messages',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return results.reversed.map((data) {
      return ChatMessage(
        id: data['id'] as String,
        senderId: data['sender_id'] as String,
        senderName: data['sender_name'] as String,
        content: data['content'] as String,
        type: MessageType.values.firstWhere(
          (e) => e.name == data['type'],
        ),
        timestamp: DateTime.parse(data['timestamp'] as String),
        isFromInstructor: (data['is_from_instructor'] as int) == 1,
      );
    }).toList();
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('evaluations');
    await db.delete('blocks');
    await db.delete('chat_messages');
    await db.delete('sessions');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
