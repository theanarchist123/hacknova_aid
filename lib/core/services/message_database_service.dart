import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/bluetooth_mesh_service.dart';

/// Database service for storing Bluetooth messages locally
class MessageDatabaseService {
  static final MessageDatabaseService _instance = MessageDatabaseService._internal();
  factory MessageDatabaseService() => _instance;
  MessageDatabaseService._internal();

  Database? _database;
  static const String _databaseName = 'bluetooth_messages.db';
  static const int _databaseVersion = 1;

  // Table and column names
  static const String _messagesTable = 'messages';
  static const String _columnId = 'id';
  static const String _columnSenderId = 'sender_id';
  static const String _columnSenderName = 'sender_name';
  static const String _columnContent = 'content';
  static const String _columnTimestamp = 'timestamp';
  static const String _columnStatus = 'status';
  static const String _columnHopCount = 'hop_count';
  static const String _columnRoutedThrough = 'routed_through';
  static const String _columnCreatedAt = 'created_at';

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_messagesTable (
        $_columnId TEXT PRIMARY KEY,
        $_columnSenderId TEXT NOT NULL,
        $_columnSenderName TEXT NOT NULL,
        $_columnContent TEXT NOT NULL,
        $_columnTimestamp TEXT NOT NULL,
        $_columnStatus INTEGER NOT NULL,
        $_columnHopCount INTEGER DEFAULT 0,
        $_columnRoutedThrough TEXT DEFAULT '',
        $_columnCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_messages_timestamp ON $_messagesTable($_columnTimestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_sender ON $_messagesTable($_columnSenderId)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_status ON $_messagesTable($_columnStatus)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema changes
    if (oldVersion < 2) {
      // Example: Add new columns for future versions
      // await db.execute('ALTER TABLE $_messagesTable ADD COLUMN new_column TEXT');
    }
  }

  /// Insert a new message
  Future<void> insertMessage(BluetoothMessage message) async {
    final db = await database;
    
    await db.insert(
      _messagesTable,
      {
        _columnId: message.id,
        _columnSenderId: message.senderId,
        _columnSenderName: message.senderName,
        _columnContent: message.content,
        _columnTimestamp: message.timestamp.toIso8601String(),
        _columnStatus: message.status.index,
        _columnHopCount: message.hopCount,
        _columnRoutedThrough: message.routedThrough.join(','),
        _columnCreatedAt: DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update message status
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final db = await database;
    
    await db.update(
      _messagesTable,
      {_columnStatus: status.index},
      where: '$_columnId = ?',
      whereArgs: [messageId],
    );
  }

  /// Get all messages ordered by timestamp
  Future<List<BluetoothMessage>> getAllMessages() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      orderBy: '$_columnTimestamp ASC',
    );

    return maps.map(_mapToBluetoothMessage).toList();
  }

  /// Get messages by sender
  Future<List<BluetoothMessage>> getMessagesBySender(String senderId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: '$_columnSenderId = ?',
      whereArgs: [senderId],
      orderBy: '$_columnTimestamp ASC',
    );

    return maps.map(_mapToBluetoothMessage).toList();
  }

  /// Get messages by status
  Future<List<BluetoothMessage>> getMessagesByStatus(MessageStatus status) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: '$_columnStatus = ?',
      whereArgs: [status.index],
      orderBy: '$_columnTimestamp ASC',
    );

    return maps.map(_mapToBluetoothMessage).toList();
  }

  /// Get recent messages (last 24 hours)
  Future<List<BluetoothMessage>> getRecentMessages() async {
    final db = await database;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: '$_columnTimestamp > ?',
      whereArgs: [yesterday.toIso8601String()],
      orderBy: '$_columnTimestamp ASC',
    );

    return maps.map(_mapToBluetoothMessage).toList();
  }

  /// Search messages by content
  Future<List<BluetoothMessage>> searchMessages(String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: '$_columnContent LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: '$_columnTimestamp DESC',
    );

    return maps.map(_mapToBluetoothMessage).toList();
  }

  /// Get message count
  Future<int> getMessageCount() async {
    final db = await database;
    
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_messagesTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get message count by status
  Future<int> getMessageCountByStatus(MessageStatus status) async {
    final db = await database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $_messagesTable WHERE $_columnStatus = ?',
      [status.index],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete message by ID
  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    
    await db.delete(
      _messagesTable,
      where: '$_columnId = ?',
      whereArgs: [messageId],
    );
  }

  /// Delete messages older than specified days
  Future<void> deleteOldMessages(int days) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    await db.delete(
      _messagesTable,
      where: '$_columnTimestamp < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  /// Clear all messages
  Future<void> clearAllMessages() async {
    final db = await database;
    await db.delete(_messagesTable);
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    final totalMessages = await getMessageCount();
    final sentMessages = await getMessageCountByStatus(MessageStatus.sent);
    final pendingMessages = await getMessageCountByStatus(MessageStatus.pending);
    final failedMessages = await getMessageCountByStatus(MessageStatus.failed);
    
    // Get unique senders count
    final uniqueSendersResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT $_columnSenderId) FROM $_messagesTable'
    );
    final uniqueSenders = Sqflite.firstIntValue(uniqueSendersResult) ?? 0;
    
    // Get oldest and newest message timestamps
    final oldestResult = await db.rawQuery(
      'SELECT MIN($_columnTimestamp) FROM $_messagesTable'
    );
    final newestResult = await db.rawQuery(
      'SELECT MAX($_columnTimestamp) FROM $_messagesTable'
    );
    
    return {
      'totalMessages': totalMessages,
      'sentMessages': sentMessages,
      'pendingMessages': pendingMessages,
      'failedMessages': failedMessages,
      'uniqueSenders': uniqueSenders,
      'oldestMessage': oldestResult.first.values.first,
      'newestMessage': newestResult.first.values.first,
    };
  }

  /// Convert database map to BluetoothMessage
  BluetoothMessage _mapToBluetoothMessage(Map<String, dynamic> map) {
    return BluetoothMessage(
      id: map[_columnId],
      senderId: map[_columnSenderId],
      senderName: map[_columnSenderName],
      content: map[_columnContent],
      timestamp: DateTime.parse(map[_columnTimestamp]),
      status: MessageStatus.values[map[_columnStatus]],
      hopCount: map[_columnHopCount] ?? 0,
      routedThrough: (map[_columnRoutedThrough] as String?)
          ?.split(',')
          .where((id) => id.isNotEmpty)
          .toSet() ?? {},
    );
  }

  /// Backup messages to a JSON string
  Future<String> exportMessages() async {
    final messages = await getAllMessages();
    final List<Map<String, dynamic>> jsonData = messages.map((msg) => msg.toJson()).toList();
    
    return jsonEncode(jsonData);
  }

  /// Import messages from JSON string
  Future<void> importMessages(String jsonData) async {
    try {
      final List<dynamic> jsonList = List<dynamic>.from(jsonDecode(jsonData));
      
      for (final json in jsonList) {
        final message = BluetoothMessage.fromJson(json);
        await insertMessage(message);
      }
    } catch (e) {
      throw Exception('Failed to import messages: $e');
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}