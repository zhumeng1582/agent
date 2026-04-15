import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/sync_queue_service.dart';

class ChatRepository {
  final SyncQueueService _syncQueue = SyncQueueService();

  // 增量同步：从服务端拉取自 lastSyncTime 以来更新的会话
  Future<List<Chat>> getAllChats({DateTime? since}) async {
    if (ApiService.isAuthenticated) {
      try {
        // 使用 since 参数进行增量同步
        final response = await ApiService.getConversations();
        if (response.success && response.data != null) {
          final List<dynamic> data;
          if (response.data is Map && response.data['data'] != null) {
            data = response.data['data'] as List<dynamic>;
          } else if (response.data is List) {
            data = response.data as List<dynamic>;
          } else {
            data = [];
          }
          final serverChats = data.map((map) => Chat.fromServerMap(map as Map<String, dynamic>)).toList();

          if (since == null) {
            // 全量同步：更新本地数据库
            await _syncAllChats(serverChats);
            return serverChats;
          } else {
            // 增量同步：合并服务端数据
            return await _mergeChats(serverChats, since);
          }
        }
      } catch (e) {
        debugPrint('Failed to fetch chats from server: $e');
      }
    }

    // 离线或请求失败：读取本地缓存
    final maps = await DatabaseService.getChats();
    final localChats = maps.map((map) => Chat.fromMap(map)).toList();

    // 如果有增量同步的 since 参数，过滤本地数据
    if (since != null) {
      return localChats.where((c) => c.lastMessageTime.isAfter(since)).toList();
    }

    return localChats;
  }

  Future<void> _syncAllChats(List<Chat> serverChats) async {
    // 清空并重建本地聊天列表
    final db = await DatabaseService.database;
    await db.delete('chats');

    for (final chat in serverChats) {
      await DatabaseService.insertChat(chat.toMap());
    }

    await _syncQueue.saveLastSyncTime(DateTime.now());
  }

  Future<List<Chat>> _mergeChats(List<Chat> serverChats, DateTime since) async {
    final localMaps = await DatabaseService.getChats();
    final localChats = localMaps.map((map) => Chat.fromMap(map)).toList();

    // 以服务端时间为准进行合并
    // 服务端有更新就用服务端的，本地有但服务端没有的保留（可能是本地刚创建的）
    final mergedMap = <String, Chat>{};

    // 先加入服务端数据
    for (final chat in serverChats) {
      mergedMap[chat.id] = chat;
    }

    // 再合并本地数据（保留本地独有的，服务端已更新的以服务端为准）
    for (final chat in localChats) {
      if (chat.lastMessageTime.isAfter(since)) {
        // 本地有增量更新，检查是否与服务端冲突
        final serverChat = mergedMap[chat.id];
        if (serverChat != null) {
          // 以服务端时间为准（因为服务端是权威数据）
          if (chat.lastMessageTime.isAfter(serverChat.lastMessageTime)) {
            // 本地比服务端新，这种情况应该很少见，可以考虑保留本地或以服务端为准
            // 这里选择以服务端为准
            debugPrint('Chat ${chat.id} has newer local time, using server time',);
          }
        } else {
          // 本地有但服务端没有（可能是离线时创建的），加入队列等待同步
          mergedMap[chat.id] = chat;
        }
      }
    }

    // 更新本地数据库
    for (final chat in mergedMap.values) {
      await DatabaseService.insertChat(chat.toMap());
    }

    return mergedMap.values.toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.lastMessageTime.compareTo(a.lastMessageTime);
      });
  }

  Future<Chat> createChat({String title = '新聊天'}) async {
    final chat = Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: title,
      lastMessageTime: DateTime.now(),
    );

    // 立即写入本地
    await DatabaseService.insertChat(chat.toMap());

    // 尝试同步到服务端
    if (ApiService.isAuthenticated) {
      try {
        final response = await ApiService.createConversation(title: title);
        if (response.success && response.data != null) {
          final serverChat = Chat.fromServerMap(response.data);
          // 更新本地 ID 为服务端 ID（如果是新创建的会话）
          if (chat.id != serverChat.id) {
            await DatabaseService.deleteChat(chat.id);
            await DatabaseService.insertChat(serverChat.toMap());
            return serverChat;
          }
        }
      } catch (e) {
        // 离线创建，加入同步队列
        await _syncQueue.addOperation(SyncOperation(
          id: 'chat_create_${chat.id}',
          type: SyncOperationType.create,
          entity: 'chat',
          entityId: chat.id,
          data: {'title': title},
          createdAt: DateTime.now(),
        ));
      }
    } else {
      // 未登录，加入同步队列
      await _syncQueue.addOperation(SyncOperation(
        id: 'chat_create_${chat.id}',
        type: SyncOperationType.create,
        entity: 'chat',
        entityId: chat.id,
        data: {'title': title},
        createdAt: DateTime.now(),
      ));
    }

    return chat;
  }

  Future<void> saveChat(Chat chat) async {
    await DatabaseService.insertChat(chat.toMap());

    if (ApiService.isAuthenticated) {
      // 尝试直接同步
      final response = await ApiService.updateConversation(
        chat.id,
        title: chat.name,
        isPinned: chat.isPinned,
      );
      if (!response.success) {
        // 加入同步队列
        await _syncQueue.addOperation(SyncOperation(
          id: 'chat_update_${chat.id}_${DateTime.now().millisecondsSinceEpoch}',
          type: SyncOperationType.update,
          entity: 'chat',
          entityId: chat.id,
          data: {'title': chat.name, 'isPinned': chat.isPinned},
          createdAt: DateTime.now(),
        ));
      }
    } else {
      await _syncQueue.addOperation(SyncOperation(
        id: 'chat_update_${chat.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: SyncOperationType.update,
        entity: 'chat',
        entityId: chat.id,
        data: {'title': chat.name, 'isPinned': chat.isPinned},
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<void> deleteChat(String id) async {
    await DatabaseService.deleteChat(id);

    if (ApiService.isAuthenticated) {
      // 尝试直接删除
      final response = await ApiService.deleteConversation(id);
      if (!response.success) {
        // 加入同步队列
        await _syncQueue.addOperation(SyncOperation(
          id: 'chat_delete_$id',
          type: SyncOperationType.delete,
          entity: 'chat',
          entityId: id,
          createdAt: DateTime.now(),
        ));
      }
    } else {
      await _syncQueue.addOperation(SyncOperation(
        id: 'chat_delete_$id',
        type: SyncOperationType.delete,
        entity: 'chat',
        entityId: id,
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<Chat?> getOrCreateDefaultChat() async {
    final chats = await getAllChats();
    if (chats.isEmpty) {
      return createChat(title: '聊天');
    }
    return chats.first;
  }
}
