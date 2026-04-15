import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/usage_provider.dart';
import '../../data/models/chat.dart';
import '../../data/models/message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/database_service.dart';
import '../../data/services/image_service.dart';
import '../../data/services/api_service.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

// AI 服务现在完全通过后端 API 调用，不再在客户端存储 Key

// Chat list provider
final chatsProvider = StateNotifierProvider<ChatsNotifier, List<Chat>>((ref) {
  return ChatsNotifier(ref);
});

class ChatsNotifier extends StateNotifier<List<Chat>> {
  final Ref _ref;
  final _uuid = const Uuid();

  ChatsNotifier(this._ref) : super([]) {
    _loadChats();
  }

  ChatRepository get _repository => _ref.read(chatRepositoryProvider);

  Future<void> _loadChats() async {
    final chats = await _repository.getAllChats();
    if (chats.isEmpty) {
      final defaultChat = Chat(
        id: _uuid.v4(),
        name: '新聊天',
        lastMessageTime: DateTime.now(),
      );
      await _repository.saveChat(defaultChat);
      state = [defaultChat];
    } else {
      state = chats;
    }
  }

  Future<Chat> createChat() async {
    final chat = Chat(
      id: _uuid.v4(),
      name: '新聊天',
      lastMessageTime: DateTime.now(),
    );
    await _repository.saveChat(chat);
    state = [chat, ...state];
    return chat;
  }

  Future<Chat> createChatForTemp(String tempId) async {
    // Check if chat already exists
    if (state.any((c) => c.id == tempId)) {
      return state.firstWhere((c) => c.id == tempId);
    }
    final chat = Chat(
      id: tempId,
      name: '新聊天',
      lastMessageTime: DateTime.now(),
    );
    await _repository.saveChat(chat);
    state = [chat, ...state];
    return chat;
  }

  Future<void> updateChatPreview(String chatId, String preview) async {
    final chat = state.firstWhere((c) => c.id == chatId);
    final updated = chat.copyWith(
      lastMessagePreview: preview,
      lastMessageTime: DateTime.now(),
    );
    await _repository.saveChat(updated);
    state = state.map((c) => c.id == chatId ? updated : c).toList();
  }

  Future<void> updateChatName(String chatId, String name) async {
    final chat = state.firstWhere((c) => c.id == chatId);
    final updated = chat.copyWith(name: name);
    await _repository.saveChat(updated);
    state = state.map((c) => c.id == chatId ? updated : c).toList();
  }

  Future<void> deleteChat(String chatId) async {
    await _repository.deleteChat(chatId);
    state = state.where((c) => c.id != chatId).toList();
  }

  /// 将临时对话的本地 ID 更新为服务端返回的真实 ID，同时迁移消息
  Future<void> updateChatId(String oldId, String newId) async {
    final chatIndex = state.indexWhere((c) => c.id == oldId);
    if (chatIndex == -1) return;

    final oldChat = state[chatIndex];
    final updatedChat = oldChat.copyWith(id: newId);

    // 迁移消息到新的 chatId
    await DatabaseService.migrateMessagesChatId(oldId, newId);

    // 从本地数据库删除旧的聊天记录，插入新的
    await _repository.deleteChat(oldId);
    await _repository.saveChat(updatedChat);

    // 更新状态
    state = [
      updatedChat,
      ...state.where((c) => c.id != oldId),
    ];
  }

  Future<void> togglePinChat(String chatId) async {
    final chat = state.firstWhere((c) => c.id == chatId);
    final updated = chat.copyWith(isPinned: !chat.isPinned);
    await _repository.saveChat(updated);
    state = state.map((c) => c.id == chatId ? updated : c).toList();
    // Re-sort to put pinned chats at top
    state = [
      ...state.where((c) => c.isPinned),
      ...state.where((c) => !c.isPinned),
    ];
  }

  Future<void> reorderChats(int oldIndex, int newIndex) async {
    final List<Chat> chats = List.from(state);
    final chat = chats.removeAt(oldIndex);
    chats.insert(newIndex, chat);
    state = chats;

    // Persist the new order
    for (int i = 0; i < chats.length; i++) {
      final updated = chats[i].copyWith(lastMessageTime: chats[i].lastMessageTime);
      await _repository.saveChat(updated);
    }
  }
}

// Messages provider for a specific chat
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, List<Message>, String>(
  (ref, chatId) => MessagesNotifier(ref, chatId),
);

// 正在等待AI回复的会话ID集合，可以同时多个会话在loading
final loadingChatIdsProvider = StateProvider<Set<String>>((ref) => {});

// 建议追问话题Provider
final suggestedTopicsProvider = StateProvider.family<List<String>, String>((ref, chatId) => []);

class MessagesNotifier extends StateNotifier<List<Message>> {
  final Ref _ref;
  final String _chatId;
  final _uuid = const Uuid();
  bool _isLoading = false;
  bool _isInitialized = false;
  Completer<void>? _loadCompleter;

  MessagesNotifier(this._ref, this._chatId) : super([]) {
    _loadMessages();
  }

  MessageRepository get _repository => _ref.read(messageRepositoryProvider);

  Future<void> _loadMessages() async {
    if (_isLoading) return;
    _isLoading = true;
    _loadCompleter = Completer<void>();
    final messages = await _repository.getMessages(_chatId);
    state = messages;
    _isInitialized = true;
    _isLoading = false;
    _loadCompleter?.complete();
    _loadCompleter = null;
  }

  Future<void> ensureInitialized() async {
    // If already initialized, done
    if (_isInitialized) return;
    // If currently loading, wait for it to complete
    if (_isLoading && _loadCompleter != null) {
      await _loadCompleter!.future;
      if (_isInitialized) return;
    }
    // Otherwise do a fresh load
    await _loadMessages();
  }

  Future<void> updateMessage(Message updatedMessage) async {
    await _repository.saveMessage(updatedMessage);
    state = state.map((m) => m.id == updatedMessage.id ? updatedMessage : m).toList();
  }

  Future<void> addAIMessage(String content) async {
    final message = Message(
      id: _uuid.v4(),
      chatId: _chatId,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
      isFromMe: false,
    );
    await _repository.saveMessage(message);
    state = [...state, message];
  }

  Future<void> sendTextMessage(String content, {String? replyToId, String? replyToContent}) async {
    // Ensure messages are loaded before processing
    await ensureInitialized();

    // Clear previous suggestions when user sends a new message
    _ref.read(suggestedTopicsProvider(_chatId).notifier).state = [];

    // Check if this is the first user message
    final isFirstMessage = state.where((m) => m.isFromMe).isEmpty;

    final message = Message(
      id: _uuid.v4(),
      chatId: _chatId,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
      isFromMe: true,
      replyToId: replyToId,
      replyToContent: replyToContent,
    );
    await _repository.saveMessage(message);
    state = [...state, message];

    // Update chat title if this is the first user message
    if (isFirstMessage) {
      // Use first 20 chars as title
      String title = content;
      if (content.length > 20) {
        title = '${content.substring(0, 20)}...';
      }
      _ref.read(chatsProvider.notifier).updateChatName(_chatId, title);
    }
    _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, content);

    // Check usage limit before AI reply
    final canUse = await _ref.read(usageProvider.notifier).tryUse();
    if (canUse) {
      // Check if user wants to generate a video
      if (_isVideoGenerationRequest(content)) {
        _addAIGeneratedVideoReply(message);
      } else if (_isImageGenerationRequest(content)) {
        _addAIGeneratedImageReply(message);
      } else {
        await _addAIReply(message);
      }
    } else {
      _addLimitExceededMessage();
    }

    // Ask AI for follow-up suggestions - AI decides if needed
    _generateFollowUpSuggestions(content);
  }

  Future<void> _generateFollowUpSuggestions(String latestMessage) async {
    // 追问建议功能已禁用，所有 AI 请求必须通过后端 API
    // 如果需要此功能，请在后端添加相应端点
  }

  bool _isImageGenerationRequest(String content) {
    final keywords = [
      // Chinese
      '生成图片', '给我一张', '画一个', '画一张', '生成一张', '创建图片', '生成一幅', '画一幅', '生成图', '给我图',
      // English
      'generate an image', 'generate a picture', 'create an image', 'create a picture',
      'draw a picture', 'give me a picture', 'give me an image', 'can you draw',
      'make an image', 'make a picture',
    ];
    final lower = content.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }

  Future<void> _addAIGeneratedImageReply(Message originalMessage) async {
    _ref.read(loadingChatIdsProvider.notifier).state = {..._ref.read(loadingChatIdsProvider), _chatId};

    try {
      final response = await ApiService.generateImage(originalMessage.content ?? '');
      if (response.success && response.data != null) {
        final imageUrl = response.data['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final reply = Message(
            id: _uuid.v4(),
            chatId: _chatId,
            type: MessageType.image,
            mediaPath: imageUrl,
            timestamp: DateTime.now(),
            isFromMe: false,
          );
          await _repository.saveMessage(reply);
          state = [...state, reply];
          _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, '[图片]');
        } else {
          _addErrorReply('图片生成失败');
        }
      } else {
        _addErrorReply(response.error ?? '图片生成失败');
      }
    } catch (e) {
      _addErrorReply('图片生成失败: $e');
    } finally {
      _ref.read(loadingChatIdsProvider.notifier).state = _ref.read(loadingChatIdsProvider).where((id) => id != _chatId).toSet();
    }
  }

  void _addErrorReply(String content) {
    final errorReply = Message(
      id: _uuid.v4(),
      chatId: _chatId,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
      isFromMe: false,
    );
    _repository.saveMessage(errorReply);
    state = [...state, errorReply];
  }

  bool _isVideoGenerationRequest(String content) {
    final keywords = [
      // Chinese
      '生成视频', '生成一段视频', '做个视频', '制作视频', '创建视频', '给我一个视频', '生成短视频',
      // English
      'generate a video', 'generate video', 'create a video', 'make a video', 'give me a video',
    ];
    final lower = content.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }

  Future<void> _addAIGeneratedVideoReply(Message originalMessage) async {
    _ref.read(loadingChatIdsProvider.notifier).state = {..._ref.read(loadingChatIdsProvider), _chatId};

    // 视频生成功能需要后端支持，暂时提示用户
    final errorReply = Message(
      id: _uuid.v4(),
      chatId: _chatId,
      type: MessageType.text,
      content: '视频生成功能即将上线，请登录后使用',
      timestamp: DateTime.now(),
      isFromMe: false,
    );
    await _repository.saveMessage(errorReply);
    state = [...state, errorReply];
    _ref.read(loadingChatIdsProvider.notifier).state = _ref.read(loadingChatIdsProvider).where((id) => id != _chatId).toSet();
  }

  Future<void> sendImageMessage(String imagePath, {String? replyToId, String? replyToContent}) async {
    // Check if this is the first user message
    final isFirstMessage = state.where((m) => m.isFromMe).isEmpty;

    final message = Message(
      id: _uuid.v4(),
      chatId: _chatId,
      type: MessageType.image,
      mediaPath: imagePath,
      timestamp: DateTime.now(),
      isFromMe: true,
      replyToId: replyToId,
      replyToContent: replyToContent,
    );
    await _repository.saveMessage(message);
    state = [...state, message];

    // Update chat title if this is the first user message
    if (isFirstMessage) {
      _ref.read(chatsProvider.notifier).updateChatName(_chatId, '图片');
    }
    _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, '[图片]');

    // Check usage limit before AI reply
    final canUse = await _ref.read(usageProvider.notifier).tryUse();
    if (canUse) {
      _addAIImageReply(message);
    } else {
      _addLimitExceededMessage();
    }
  }

  Future<void> sendVoiceMessage(String audioPath, {String? replyToId, String? replyToContent}) async {
    // Check if this is the first user message
    final isFirstMessage = state.where((m) => m.isFromMe).isEmpty;

    final message = Message(
      id: _uuid.v4(),
      chatId: _chatId,
      type: MessageType.voice,
      mediaPath: audioPath,
      timestamp: DateTime.now(),
      isFromMe: true,
      replyToId: replyToId,
      replyToContent: replyToContent,
    );
    await _repository.saveMessage(message);
    state = [...state, message];

    // Update chat title to "[语音]" if this is the first user message
    if (isFirstMessage) {
      _ref.read(chatsProvider.notifier).updateChatName(_chatId, '[语音]');
    }
    _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, '[语音]');

    // Check usage limit before AI reply
    final canUse = await _ref.read(usageProvider.notifier).tryUse();
    if (canUse) {
      _addAIReply(message);
    } else {
      _addLimitExceededMessage();
    }
  }

  void _addLimitExceededMessage() {
    _ref.read(loadingChatIdsProvider.notifier).state = _ref.read(loadingChatIdsProvider).where((id) => id != _chatId).toSet();
    final limitMessage = Message(
      id: _uuid.v4(),
      chatId: _chatId,
      type: MessageType.text,
      content: '今日免费次数已用完（100次/天），请明天再来或升级会员。',
      timestamp: DateTime.now(),
      isFromMe: false,
    );
    _repository.saveMessage(limitMessage);
    state = [...state, limitMessage];
    _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, '今日免费次数已用完');
  }

  Future<void> _addAIReply(Message originalMessage) async {
    _ref.read(loadingChatIdsProvider.notifier).state = {..._ref.read(loadingChatIdsProvider), _chatId};

    await ensureInitialized();

    // 检查是否是临时对话（本地创建的，服务端还没有）
    bool isTempChat = _chatId.startsWith('temp_');
    // 追踪最终使用的 chatId（可能在创建对话后更新为服务端 ID）
    String effectiveChatId = _chatId;

    // 如果是临时对话，先在服务端创建对话，避免 404
    if (isTempChat) {
      debugPrint('[_addAIReply] Temp chat $_chatId, creating on server first');
      try {
        final createResult = await ApiService.createConversation(title: '新聊天');
        if (createResult.success && createResult.data != null) {
          final serverChatId = createResult.data['id'] as String?;
          if (serverChatId != null) {
            await _ref.read(chatsProvider.notifier).updateChatId(_chatId, serverChatId);
            effectiveChatId = serverChatId;
            debugPrint('[_addAIReply] Created conversation $serverChatId, migrating messages');
          }
        }
      } catch (e) {
        debugPrint('[_addAIReply] Failed to create temp chat on server: $e');
        // 继续尝试发送，服务端可能会自动创建
      }
    }

    try {
      // Build conversation history from current state (messages)
      final messages = <Map<String, String>>[];

      // Add previous messages as history (up to last 20 to avoid token limits)
      // Exclude originalMessage since it will be added separately as the current message
      final historyMessages = state.reversed.take(20).where((m) => m.id != originalMessage.id);
      for (final msg in historyMessages) {
        if (msg.type == MessageType.text && msg.content != null) {
          messages.add({
            'role': msg.isFromMe ? 'user' : 'assistant',
            'content': msg.content!,
          });
        }
      }

      // Add current message
      String userContent;
      switch (originalMessage.type) {
        case MessageType.text:
          userContent = originalMessage.content ?? '';
          break;
        case MessageType.voice:
          userContent = originalMessage.content ?? '语音消息';
          break;
        case MessageType.image:
          userContent = '用户发送了一张图片';
          break;
        case MessageType.video:
          userContent = '用户发送了一个视频';
          break;
      }

      // Include reply context if this is a reply
      if (originalMessage.replyToContent != null && originalMessage.replyToContent!.isNotEmpty) {
        userContent = '用户在回复中引用了"${originalMessage.replyToContent}"，并说：\n\n$userContent';
      }

      messages.add({
        'role': 'user',
        'content': userContent,
      });

      // Add reply chain context if the replied message was itself a reply
      if (originalMessage.replyToId != null) {
        // Find the message being replied to and check if it was also a reply
        final repliedMessage = state.firstWhere(
          (m) => m.id == originalMessage.replyToId,
          orElse: () => originalMessage,
        );
        if (repliedMessage.replyToContent != null && repliedMessage.replyToContent!.isNotEmpty) {
          // Modify the last message to include the reply chain
          messages[messages.length - 1] = {
            'role': 'user',
            'content': '用户回复的是AI助手之前的消息"${repliedMessage.replyToContent}"，该消息的内容是"${repliedMessage.content}"。\n\n用户的回复：$userContent',
          };
        }
      }

      String replyContent;
      String? reasoning;

      // 所有 AI 请求都通过后端 API
      final response = await ApiService.chatInConversation(effectiveChatId, {
        'messages': messages,
      });

      if (response.success && response.data != null) {
        replyContent = response.data['content'] ?? '';
        reasoning = response.data['reasoning'];
      } else if (response.statusCode == 404) {
        // 对话在服务端不存在，删除本地对话并提示用户
        await ChatRepository().deleteChat(effectiveChatId);
        replyContent = '该对话已在其他设备删除，已为您返回聊天列表';
        reasoning = null;
      } else {
        replyContent = 'AI 服务暂时不可用，请检查网络或登录状态';
        reasoning = null;
      }

      // Estimate tokens from response length (rough approximation: 1 token ≈ 2 chars)
      final estimatedTokens = (replyContent.length / 2).ceil();
      _ref.read(usageProvider.notifier).addTokens(estimatedTokens);

      final reply = Message(
        id: _uuid.v4(),
        chatId: effectiveChatId,
        type: MessageType.text,
        content: replyContent,
        timestamp: DateTime.now(),
        isFromMe: false,
        isStreaming: true,
        reasoning: reasoning,
      );

      await _repository.saveMessage(reply);
      state = [...state, reply];
      _ref.read(chatsProvider.notifier).updateChatPreview(effectiveChatId, replyContent);

      // Mark streaming as complete after animation finishes (30ms per char + 500ms buffer)
      final animationDuration = Duration(milliseconds: replyContent.length * 30 + 500);
      Future.delayed(animationDuration, () {
        final completedReply = reply.copyWith(isStreaming: false);
        _repository.saveMessage(completedReply);
        updateMessage(completedReply);
      });
    } catch (e) {
      final errorReply = Message(
        id: _uuid.v4(),
        chatId: effectiveChatId,
        type: MessageType.text,
        content: 'AI回复失败: $e',
        timestamp: DateTime.now(),
        isFromMe: false,
      );
      await _repository.saveMessage(errorReply);
      state = [...state, errorReply];
    } finally {
      // 从 loading 状态移除（使用原始 _chatId，因为 loading 状态是用它添加的）
      _ref.read(loadingChatIdsProvider.notifier).state = _ref.read(loadingChatIdsProvider).where((id) => id != _chatId).toSet();
      // Note: Don't reset consecutive count here - it should only reset when user acts on suggestions
    }
  }

  Future<void> _addAIImageReply(Message originalMessage) async {
    _ref.read(loadingChatIdsProvider.notifier).state = {..._ref.read(loadingChatIdsProvider), _chatId};

    try {
      // mediaPath could be a local file path or URL
      final imagePath = originalMessage.mediaPath ?? '';
      if (imagePath.isEmpty) {
        _addErrorReply('无法识别图片：路径为空');
        return;
      }

      final response = await ApiService.describeImage(imagePath);
      if (response.success && response.data != null) {
        final description = response.data['description'] as String? ?? '图片描述不可用';
        final reply = Message(
          id: _uuid.v4(),
          chatId: _chatId,
          type: MessageType.text,
          content: description,
          timestamp: DateTime.now(),
          isFromMe: false,
        );
        await _repository.saveMessage(reply);
        state = [...state, reply];
        _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, description);
      } else {
        _addErrorReply(response.error ?? '图片识别失败');
      }
    } catch (e) {
      _addErrorReply('图片识别失败: $e');
    } finally {
      _ref.read(loadingChatIdsProvider.notifier).state = _ref.read(loadingChatIdsProvider).where((id) => id != _chatId).toSet();
    }
  }

  Future<void> deleteMessage(String id) async {
    // 同步删除到服务端（会加入队列等待网络恢复）
    await _repository.syncDeleteToServer(_chatId, id);
    state = state.where((m) => m.id != id).toList();
  }

  Future<void> clearAll() async {
    await _repository.clearAllMessages();
    state = [];
  }
}

final isRecordingProvider = StateProvider<bool>((ref) => false);
final recordingPathProvider = StateProvider<String?>((ref) => null);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final playingPathProvider = StateProvider<String?>((ref) => null);
