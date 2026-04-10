import '../models/chat.dart';
import '../models/message.dart';
import '../services/database_service.dart';

class ChatRepository {
  Future<List<Chat>> getAllChats() async {
    final maps = await DatabaseService.getChats();
    return maps.map((map) => Chat.fromMap(map)).toList();
  }

  Future<void> saveChat(Chat chat) async {
    await DatabaseService.insertChat(chat.toMap());
  }

  Future<void> deleteChat(String id) async {
    await DatabaseService.deleteChat(id);
  }

  Future<Chat?> getOrCreateDefaultChat() async {
    final chats = await getAllChats();
    if (chats.isEmpty) {
      final chat = Chat(
        id: 'default',
        name: '聊天',
        lastMessageTime: DateTime.now(),
      );
      await saveChat(chat);
      return chat;
    }
    return chats.first;
  }
}

class MessageRepository {
  Future<List<Message>> getMessages(String chatId) async {
    final maps = await DatabaseService.getMessages(chatId);
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  Future<void> saveMessage(Message message) async {
    await DatabaseService.insertMessage(message.toMap());
  }

  Future<void> deleteMessage(String id) async {
    await DatabaseService.deleteMessage(id);
  }

  Future<void> clearAllMessages() async {
    await DatabaseService.deleteAllMessages();
  }
}
