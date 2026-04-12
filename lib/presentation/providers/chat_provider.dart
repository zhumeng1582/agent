import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/usage_provider.dart';
import '../../core/constants/app_config.dart';
import '../../data/models/chat.dart';
import '../../data/models/message.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/image_service.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/minimax_service.dart';

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

final aiServiceProvider = Provider<AIService>((ref) {
  return MiniMaxService(AppConfig.minimaxApiKey);
});

final minimaxServiceProvider = Provider<MiniMaxService>((ref) {
  return MiniMaxService(AppConfig.minimaxApiKey);
});

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

class MessagesNotifier extends StateNotifier<List<Message>> {
  final Ref _ref;
  final String _chatId;
  final _uuid = const Uuid();

  MessagesNotifier(this._ref, this._chatId) : super([]) {
    _loadMessages();
  }

  MessageRepository get _repository => _ref.read(messageRepositoryProvider);
  AIService get _aiService => _ref.read(aiServiceProvider);

  Future<void> _loadMessages() async {
    final messages = await _repository.getMessages(_chatId);
    state = messages;
  }

  Future<void> updateMessage(Message updatedMessage) async {
    await _repository.saveMessage(updatedMessage);
    state = state.map((m) => m.id == updatedMessage.id ? updatedMessage : m).toList();
  }

  Future<void> sendTextMessage(String content, {String? replyToId, String? replyToContent}) async {
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
      // Use first 20 chars as title, or request AI summarization
      String title = content;
      if (content.length > 20) {
        title = '${content.substring(0, 20)}...';
      }

      // Try AI summarization but don't block on it
      _aiService.summarizeForTitle(content).then((aiTitle) {
        if (aiTitle != '新聊天' && aiTitle.isNotEmpty) {
          title = aiTitle;
        }
        _ref.read(chatsProvider.notifier).updateChatName(_chatId, title);
      }).catchError((e) {
        // Use simple title on error
        _ref.read(chatsProvider.notifier).updateChatName(_chatId, title);
      });
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
        _addAIReply(message);
      }
    } else {
      _addLimitExceededMessage();
    }
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
      final imagePath = await _aiService.generateImage(originalMessage.content ?? '');

      if (imagePath.isNotEmpty) {
        final reply = Message(
          id: _uuid.v4(),
          chatId: _chatId,
          type: MessageType.image,
          mediaPath: imagePath,
          timestamp: DateTime.now(),
          isFromMe: false,
        );

        await _repository.saveMessage(reply);
        state = [...state, reply];
        _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, '[图片]');
      } else {
        final errorReply = Message(
          id: _uuid.v4(),
          chatId: _chatId,
          type: MessageType.text,
          content: '图片生成失败，请稍后重试',
          timestamp: DateTime.now(),
          isFromMe: false,
        );
        await _repository.saveMessage(errorReply);
        state = [...state, errorReply];
      }
    } catch (e) {
      final errorReply = Message(
        id: _uuid.v4(),
        chatId: _chatId,
        type: MessageType.text,
        content: '图片生成失败: $e',
        timestamp: DateTime.now(),
        isFromMe: false,
      );
      await _repository.saveMessage(errorReply);
      state = [...state, errorReply];
    } finally {
      _ref.read(loadingChatIdsProvider.notifier).state = _ref.read(loadingChatIdsProvider).where((id) => id != _chatId).toSet();
    }
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

    // Create a placeholder message first
    final placeholderMessage = Message(
      id: _uuid.v4(),
      chatId: _chatId,
      type: MessageType.text,
      content: '正在生成视频，请稍候...',
      timestamp: DateTime.now(),
      isFromMe: false,
    );
    await _repository.saveMessage(placeholderMessage);
    state = [...state, placeholderMessage];

    try {
      final minimaxService = _aiService as MiniMaxService;
      final taskId = await minimaxService.createVideoTask(
        originalMessage.content ?? '',
        duration: 6,
        resolution: '768P',
      );

      // Poll for video completion
      String? videoUrl;
      String? fileId;
      while (videoUrl == null || videoUrl.isEmpty) {
        await Future.delayed(const Duration(seconds: 5));
        final result = await minimaxService.queryVideoTaskStatus(taskId);
        final status = result['status'] as String;
        final videoUrlFromResult = result['video_url'] as String?;
        final fileIdFromResult = result['file_id'] as String?;
        debugPrint('Video task status: $status, video_url: $videoUrlFromResult, file_id: $fileIdFromResult');

        if (status == 'Success') {
          // Try video_url first, otherwise use file_id to get download URL
          videoUrl = videoUrlFromResult;
          if (videoUrl == null || videoUrl.isEmpty) {
            fileId = fileIdFromResult;
            if (fileId != null && fileId.isNotEmpty) {
              debugPrint('Getting download URL from file_id: $fileId');
              videoUrl = await minimaxService.getVideoDownloadUrl(fileId);
              debugPrint('Download URL from file_id: $videoUrl');
            }
          }
          if (videoUrl != null && videoUrl.isNotEmpty) {
            break;
          }
        } else if (status == 'Fail') {
          throw Exception(result['error'] ?? '视频生成失败');
        }
      }

      debugPrint('Final video URL: $videoUrl');
      if (videoUrl != null && videoUrl.isNotEmpty) {
        // Replace placeholder with video message (store URL directly)
        final videoMessage = Message(
          id: _uuid.v4(),
          chatId: _chatId,
          type: MessageType.video,
          mediaPath: videoUrl,
          timestamp: DateTime.now(),
          isFromMe: false,
        );

        // Remove placeholder
        await _repository.deleteMessage(placeholderMessage.id);
        state = state.where((m) => m.id != placeholderMessage.id).toList();

        // Add video message
        await _repository.saveMessage(videoMessage);
        state = [...state, videoMessage];
        _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, '[视频]');
      } else {
        // No URL obtained
        final errorMessage = Message(
          id: _uuid.v4(),
          chatId: _chatId,
          type: MessageType.text,
          content: '视频生成失败: 无法获取视频链接',
          timestamp: DateTime.now(),
          isFromMe: false,
        );

        await _repository.deleteMessage(placeholderMessage.id);
        state = state.where((m) => m.id != placeholderMessage.id).toList();

        await _repository.saveMessage(errorMessage);
        state = [...state, errorMessage];
      }
    } catch (e) {
      debugPrint('Video generation error: $e');
      // Replace placeholder with error message
      final errorMessage = Message(
        id: _uuid.v4(),
        chatId: _chatId,
        type: MessageType.text,
        content: '视频生成失败: $e',
        timestamp: DateTime.now(),
        isFromMe: false,
      );

      await _repository.deleteMessage(placeholderMessage.id);
      state = state.where((m) => m.id != placeholderMessage.id).toList();

      await _repository.saveMessage(errorMessage);
      state = [...state, errorMessage];
    } finally {
      _ref.read(loadingChatIdsProvider.notifier).state = _ref.read(loadingChatIdsProvider).where((id) => id != _chatId).toSet();
    }
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
      // Try AI summarization but don't block on it
      _aiService.summarizeImageForTitle(imagePath).then((title) {
        if (title != '图片' && title.isNotEmpty) {
          _ref.read(chatsProvider.notifier).updateChatName(_chatId, title);
        } else {
          _ref.read(chatsProvider.notifier).updateChatName(_chatId, '图片');
        }
      }).catchError((e) {
        // Use simple title on error
        _ref.read(chatsProvider.notifier).updateChatName(_chatId, '图片');
      });
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

    try {
      String replyContent;

      // Build conversation history from current state (messages)
      final messages = <Map<String, String>>[];

      // Add previous messages as history (up to last 20 to avoid token limits)
      final historyMessages = state.reversed.take(20);
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
      replyContent = await _aiService.chat(messages);

      // Estimate tokens from response length (rough approximation: 1 token ≈ 2 chars)
      final estimatedTokens = (replyContent.length / 2).ceil();
      _ref.read(usageProvider.notifier).addTokens(estimatedTokens);

      final reply = Message(
        id: _uuid.v4(),
        chatId: _chatId,
        type: MessageType.text,
        content: replyContent,
        timestamp: DateTime.now(),
        isFromMe: false,
        isStreaming: true,
      );

      await _repository.saveMessage(reply);
      state = [...state, reply];
      _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, replyContent);

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
        chatId: _chatId,
        type: MessageType.text,
        content: 'AI回复失败: $e',
        timestamp: DateTime.now(),
        isFromMe: false,
      );
      await _repository.saveMessage(errorReply);
      state = [...state, errorReply];
    } finally {
      _ref.read(loadingChatIdsProvider.notifier).state = _ref.read(loadingChatIdsProvider).where((id) => id != _chatId).toSet();
    }
  }

  Future<void> _addAIImageReply(Message originalMessage) async {
    _ref.read(loadingChatIdsProvider.notifier).state = {..._ref.read(loadingChatIdsProvider), _chatId};

    try {
      final replyContent = await _aiService.chatImage(
        '请描述这张图片',
        originalMessage.mediaPath ?? '',
      );

      final reply = Message(
        id: _uuid.v4(),
        chatId: _chatId,
        type: MessageType.text,
        content: replyContent,
        timestamp: DateTime.now(),
        isFromMe: false,
      );

      await _repository.saveMessage(reply);
      state = [...state, reply];
      _ref.read(chatsProvider.notifier).updateChatPreview(_chatId, replyContent);
    } catch (e) {
      final errorReply = Message(
        id: _uuid.v4(),
        chatId: _chatId,
        type: MessageType.text,
        content: 'AI图片识别失败: $e',
        timestamp: DateTime.now(),
        isFromMe: false,
      );
      await _repository.saveMessage(errorReply);
      state = [...state, errorReply];
    } finally {
      _ref.read(loadingChatIdsProvider.notifier).state = _ref.read(loadingChatIdsProvider).where((id) => id != _chatId).toSet();
    }
  }

  Future<void> deleteMessage(String id) async {
    await _repository.deleteMessage(id);
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
