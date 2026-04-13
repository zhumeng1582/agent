import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/sync_queue_service.dart';

class MessageRepository {
  final SyncQueueService _syncQueue = SyncQueueService();

  // 增量同步：只拉取自 lastSyncTime 以来新消息
  Future<List<Message>> getMessages(String chatId, {DateTime? since}) async {
    if (ApiService.isAuthenticated) {
      try {
        final response = await ApiService.getMessages(chatId);
        if (response.success && response.data != null) {
          final List<dynamic> data = response.data['data'] ?? response.data;
          final serverMessages = data.map((map) => Message.fromServerMap(map)).toList();

          if (since == null) {
            // 全量同步：清空并重建
            await _syncAllMessages(chatId, serverMessages);
            return serverMessages;
          } else {
            // 增量同步：合并
            return await _mergeMessages(chatId, serverMessages, since);
          }
        }
      } catch (e) {
        debugPrint('Failed to fetch messages from server: $e');
      }
    }

    // 离线或失败：读本地
    final maps = await DatabaseService.getMessages(chatId);
    final localMessages = maps.map((map) => Message.fromMap(map)).toList();

    if (since != null) {
      return localMessages.where((m) => m.timestamp.isAfter(since)).toList();
    }

    return localMessages;
  }

  Future<void> _syncAllMessages(String chatId, List<Message> serverMessages) async {
    // 清空该会话的本地消息
    final db = await DatabaseService.database;
    await db.delete('messages', where: 'chatId = ?', whereArgs: [chatId]);

    // 写入服务端消息
    for (final message in serverMessages) {
      await DatabaseService.insertMessage(message.toMap());
    }
  }

  Future<List<Message>> _mergeMessages(
    String chatId,
    List<Message> serverMessages,
    DateTime since,
  ) async {
    final localMaps = await DatabaseService.getMessages(chatId);
    final localMessages = localMaps.map((map) => Message.fromMap(map)).toList();

    // 以服务端为准进行合并
    final mergedMap = <String, Message>{};

    // 加入服务端消息
    for (final msg in serverMessages) {
      mergedMap[msg.id] = msg;
    }

    // 合并本地消息
    for (final msg in localMessages) {
      if (msg.timestamp.isAfter(since)) {
        if (!mergedMap.containsKey(msg.id)) {
          // 本地独有的消息（可能是离线时发送的）
          mergedMap[msg.id] = msg;
        }
      }
    }

    // 更新本地数据库
    for (final msg in mergedMap.values) {
      await DatabaseService.insertMessage(msg.toMap());
    }

    return mergedMap.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<Message> saveMessage(Message message) async {
    // 立即写入本地
    await DatabaseService.insertMessage(message.toMap());

    // 尝试同步到服务端
    if (ApiService.isAuthenticated) {
      try {
        final response = await ApiService.sendMessage(
          message.chatId,
          message.toServerMap(),
        );
        if (response.success && response.data != null) {
          // 服务端返回的消息可能包含更多信息（如服务器生成的 ID）
          final serverMessage = Message.fromServerMap(response.data);
          if (serverMessage.id != message.id) {
            // 服务端分配了新 ID，更新本地
            await DatabaseService.deleteMessage(message.id);
            await DatabaseService.insertMessage(serverMessage.toMap());
            return serverMessage;
          }
        }
      } catch (e) {
        debugPrint('Failed to sync message: $e');
        // 加入同步队列
        await _syncQueue.addOperation(SyncOperation(
          id: 'msg_create_${message.id}',
          type: SyncOperationType.create,
          entity: 'message',
          entityId: message.id,
          conversationId: message.chatId,
          data: message.toServerMap(),
          createdAt: DateTime.now(),
        ));
      }
    } else {
      // 未登录，加入同步队列
      await _syncQueue.addOperation(SyncOperation(
        id: 'msg_create_${message.id}',
        type: SyncOperationType.create,
        entity: 'message',
        entityId: message.id,
        conversationId: message.chatId,
        data: message.toServerMap(),
        createdAt: DateTime.now(),
      ));
    }

    return message;
  }

  Future<void> deleteMessage(String id) async {
    await DatabaseService.deleteMessage(id);

    // 查找对应的 conversationId（如果需要同步）
    // 注意：本地删除时我们需要记录 conversationId 以便后续同步
    // 这需要在调用前确保 conversationId 可用
  }

  Future<void> syncDeleteToServer(String conversationId, String messageId) async {
    // 先删除本地
    await DatabaseService.deleteMessage(messageId);

    if (ApiService.isAuthenticated) {
      try {
        final response = await ApiService.deleteMessage(conversationId, messageId);
        if (!response.success) {
          // 加入同步队列
          await _syncQueue.addOperation(SyncOperation(
            id: 'msg_delete_$messageId',
            type: SyncOperationType.delete,
            entity: 'message',
            entityId: messageId,
            conversationId: conversationId,
            createdAt: DateTime.now(),
          ));
        }
      } catch (e) {
        // 加入同步队列
        await _syncQueue.addOperation(SyncOperation(
          id: 'msg_delete_$messageId',
          type: SyncOperationType.delete,
          entity: 'message',
          entityId: messageId,
          conversationId: conversationId,
          createdAt: DateTime.now(),
        ));
      }
    } else {
      await _syncQueue.addOperation(SyncOperation(
        id: 'msg_delete_$messageId',
        type: SyncOperationType.delete,
        entity: 'message',
        entityId: messageId,
        conversationId: conversationId,
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<void> clearAllMessages() async {
    await DatabaseService.deleteAllMessages();
  }

  Future<List<Message>> getFavoriteMessages() async {
    final maps = await DatabaseService.getFavoriteMessages();
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  Future<void> updateMessageFavorite(String id, bool isFavorite) async {
    await DatabaseService.updateMessageFavorite(id, isFavorite);
  }
}
