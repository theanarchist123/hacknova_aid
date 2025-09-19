import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/disaster_message.dart';

/// Database helper for storing disaster relief messages locally
class MessageDatabase {
  static Database? _database;
  static final MessageDatabase _instance = MessageDatabase._internal();
  factory MessageDatabase() => _instance;
  MessageDatabase._internal();

  /// Initialize the database connection
  Future<void> init() async {
    await database; // This will trigger initialization
  }

  /// Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'disaster_messages.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL,
        metadata TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_timestamp ON messages(timestamp DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_type ON messages(type)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_sender ON messages(sender_id)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database schema changes here
  }

  /// Insert a new message
  Future<void> insertMessage(DisasterMessage message) async {
    final db = await database;
    final data = message.toDatabase();
    data['created_at'] = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'messages',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple messages
  Future<void> insertMessages(List<DisasterMessage> messages) async {
    final db = await database;
    final batch = db.batch();

    for (final message in messages) {
      final data = message.toDatabase();
      data['created_at'] = DateTime.now().millisecondsSinceEpoch;
      batch.insert('messages', data, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get all messages ordered by timestamp
  Future<List<DisasterMessage>> getAllMessages({int? limit}) async {
    final db = await database;
    final result = await db.query(
      'messages',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return result.map((map) => DisasterMessage.fromDatabase(map)).toList();
  }

  /// Get messages by type
  Future<List<DisasterMessage>> getMessagesByType(MessageType type) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => DisasterMessage.fromDatabase(map)).toList();
  }

  /// Get messages from a specific sender
  Future<List<DisasterMessage>> getMessagesBySender(String senderId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'sender_id = ?',
      whereArgs: [senderId],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => DisasterMessage.fromDatabase(map)).toList();
  }

  /// Get emergency messages (SOS and emergency types)
  Future<List<DisasterMessage>> getEmergencyMessages() async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'type IN (?, ?)',
      whereArgs: [
        MessageType.sos.toString().split('.').last,
        MessageType.emergency.toString().split('.').last,
      ],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => DisasterMessage.fromDatabase(map)).toList();
  }

  /// Get recent messages (last 24 hours)
  Future<List<DisasterMessage>> getRecentMessages() async {
    final db = await database;
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    
    final result = await db.query(
      'messages',
      where: 'timestamp > ?',
      whereArgs: [yesterday],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => DisasterMessage.fromDatabase(map)).toList();
  }

  /// Update message status
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': status.toString().split('.').last},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Delete old messages (older than specified days)
  Future<int> deleteOldMessages(int daysOld) async {
    final db = await database;
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;

    return await db.delete(
      'messages',
      where: 'timestamp < ? AND type != ?',
      whereArgs: [
        cutoffTime,
        MessageType.sos.toString().split('.').last, // Keep SOS messages
      ],
    );
  }

  /// Get message count
  Future<int> getMessageCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM messages');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get message count by type
  Future<int> getMessageCountByType(MessageType type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE type = ?',
      [type.toString().split('.').last],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Search messages by content
  Future<List<DisasterMessage>> searchMessages(String query) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'content LIKE ? OR sender_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => DisasterMessage.fromDatabase(map)).toList();
  }

  /// Clear all messages
  Future<void> clearAllMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  /// Get database size information
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    final messageCount = await getMessageCount();
    final emergencyCount = await getMessageCountByType(MessageType.emergency);
    final sosCount = await getMessageCountByType(MessageType.sos);
    
    return {
      'totalMessages': messageCount,
      'emergencyMessages': emergencyCount,
      'sosMessages': sosCount,
      'databasePath': db.path,
    };
  }

  /// Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}