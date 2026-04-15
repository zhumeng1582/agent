import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static Database? _database;
  static String? _currentUserId;

  static void setCurrentUser(String? userId) {
    _currentUserId = userId;
    debugPrint('[DatabaseService] Current user set to: $userId');
  }

  static String? get currentUserId => _currentUserId;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_app.db');

    return await openDatabase(
      path,
      version: 6,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN isFavorite INTEGER DEFAULT 0');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN translatedContent TEXT');
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN reasoning TEXT');
          } catch (_) {}
        }
        if (oldVersion < 6) {
          try {
            await db.execute('ALTER TABLE chats ADD COLUMN userId TEXT');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN userId TEXT');
          } catch (_) {}
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chats(
            id TEXT PRIMARY KEY,
            userId TEXT,
            name TEXT NOT NULL,
            lastMessageTime INTEGER,
            lastMessagePreview TEXT,
            unreadCount INTEGER DEFAULT 0,
            isPinned INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            userId TEXT,
            chatId TEXT NOT NULL,
            type INTEGER NOT NULL,
            content TEXT,
            mediaPath TEXT,
            timestamp INTEGER NOT NULL,
            isFromMe INTEGER NOT NULL,
            replyToId TEXT,
            replyToContent TEXT,
            isFavorite INTEGER DEFAULT 0,
            translatedContent TEXT,
            reasoning TEXT
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_messages_chatId ON messages(chatId)
        ''');

        await db.execute('''
          CREATE INDEX idx_chats_userId ON chats(userId)
        ''');

        await db.execute('''
          CREATE INDEX idx_messages_userId ON messages(userId)
        ''');
      },
    );
  }

  static Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Chat operations
  static Future<void> insertChat(Map<String, dynamic> chat) async {
    final db = await database;
    if (_currentUserId != null) {
      chat['userId'] = _currentUserId;
    }
    await db.insert('chats', chat, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getChats() async {
    final db = await database;
    if (_currentUserId == null) return [];
    return await db.query(
      'chats',
      where: 'userId = ?',
      whereArgs: [_currentUserId],
      orderBy: 'isPinned DESC, lastMessageTime DESC',
    );
  }

  static Future<void> updateChat(Map<String, dynamic> chat) async {
    final db = await database;
    await db.update('chats', chat, where: 'id = ? AND userId = ?', whereArgs: [chat['id'], _currentUserId]);
  }

  static Future<void> deleteChat(String id) async {
    final db = await database;
    await db.delete('chats', where: 'id = ? AND userId = ?', whereArgs: [id, _currentUserId]);
    await db.delete('messages', where: 'chatId = ? AND userId = ?', whereArgs: [id, _currentUserId]);
  }

  // Message operations
  static Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    if (_currentUserId != null) {
      message['userId'] = _currentUserId;
    }
    await db.insert('messages', message, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'chatId = ? AND userId = ?',
      whereArgs: [chatId, _currentUserId],
      orderBy: 'timestamp ASC',
    );
  }

  static Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ? AND userId = ?', whereArgs: [id, _currentUserId]);
  }

  static Future<void> deleteAllMessages() async {
    final db = await database;
    if (_currentUserId == null) return;
    await db.delete('messages', where: 'userId = ?', whereArgs: [_currentUserId]);
  }

  /// 将临时对话的消息迁移到新创建的服务器对话
  static Future<void> migrateMessagesChatId(String oldChatId, String newChatId) async {
    final db = await database;
    if (_currentUserId == null) return;
    await db.update(
      'messages',
      {'chatId': newChatId},
      where: 'chatId = ? AND userId = ?',
      whereArgs: [oldChatId, _currentUserId],
    );
  }

  static Future<List<Map<String, dynamic>>> getFavoriteMessages() async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'isFavorite = ? AND userId = ?',
      whereArgs: [1, _currentUserId],
      orderBy: 'timestamp DESC',
    );
  }

  static Future<void> updateMessageFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'messages',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, _currentUserId],
    );
  }

  static Future<void> updateMessageTranslation(String id, String translatedContent) async {
    final db = await database;
    await db.update(
      'messages',
      {'translatedContent': translatedContent},
      where: 'id = ? AND userId = ?',
      whereArgs: [id, _currentUserId],
    );
  }

  static Future<void> clearAllDataForCurrentUser() async {
    final db = await database;
    if (_currentUserId == null) return;
    await db.delete('messages', where: 'userId = ?', whereArgs: [_currentUserId]);
    await db.delete('chats', where: 'userId = ?', whereArgs: [_currentUserId]);
  }
}
