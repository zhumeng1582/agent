import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

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
      version: 4,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN isFavorite INTEGER DEFAULT 0');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE messages ADD COLUMN translatedContent TEXT');
          } catch (_) {}
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chats(
            id TEXT PRIMARY KEY,
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
            chatId TEXT NOT NULL,
            type INTEGER NOT NULL,
            content TEXT,
            mediaPath TEXT,
            timestamp INTEGER NOT NULL,
            isFromMe INTEGER NOT NULL,
            replyToId TEXT,
            replyToContent TEXT,
            isFavorite INTEGER DEFAULT 0,
            translatedContent TEXT
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_messages_chatId ON messages(chatId)
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
    await db.insert('chats', chat, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getChats() async {
    final db = await database;
    return await db.query('chats', orderBy: 'isPinned DESC, lastMessageTime DESC');
  }

  static Future<void> updateChat(Map<String, dynamic> chat) async {
    final db = await database;
    await db.update('chats', chat, where: 'id = ?', whereArgs: [chat['id']]);
  }

  static Future<void> deleteChat(String id) async {
    final db = await database;
    await db.delete('chats', where: 'id = ?', whereArgs: [id]);
    await db.delete('messages', where: 'chatId = ?', whereArgs: [id]);
  }

  // Message operations
  static Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert('messages', message, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
  }

  static Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAllMessages() async {
    final db = await database;
    await db.delete('messages');
  }

  static Future<List<Map<String, dynamic>>> getFavoriteMessages() async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
  }

  static Future<void> updateMessageFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'messages',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateMessageTranslation(String id, String translatedContent) async {
    final db = await database;
    await db.update(
      'messages',
      {'translatedContent': translatedContent},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
