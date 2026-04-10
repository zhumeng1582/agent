import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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

final isLoadingProvider = StateProvider<bool>((ref) => false);

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

    _addAIReply(message);
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

    _addAIImageReply(message);
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

    _addAIReply(message);
  }

  Future<void> _addAIReply(Message originalMessage) async {
    _ref.read(isLoadingProvider.notifier).state = true;

    try {
      String replyContent;
      switch (originalMessage.type) {
        case MessageType.text:
          replyContent = await _aiService.chat(originalMessage.content ?? '');
          break;
        case MessageType.voice:
          replyContent = await _aiService.chatVoice(
            originalMessage.content ?? '语音消息',
            originalMessage.mediaPath ?? '',
          );
          break;
        case MessageType.image:
          replyContent = '收到图片';
          break;
      }

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
        content: 'AI回复失败: $e',
        timestamp: DateTime.now(),
        isFromMe: false,
      );
      await _repository.saveMessage(errorReply);
      state = [...state, errorReply];
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _addAIImageReply(Message originalMessage) async {
    _ref.read(isLoadingProvider.notifier).state = true;

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
      _ref.read(isLoadingProvider.notifier).state = false;
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
