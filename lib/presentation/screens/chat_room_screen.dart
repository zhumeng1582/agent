import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../../core/constants/translation_provider.dart';
import '../../core/constants/translation_state_provider.dart';
import '../../core/constants/font_size_provider.dart';
import '../../data/models/message.dart';
import '../../data/services/database_service.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';
import 'chat_settings_screen.dart';
import 'favorites_screen.dart';
import 'search_screen.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final bool isTempChat;
  final String? highlightMessageId;
  final String? initialMessage;  // For follow-up feature
  final bool initialMessageFromAI;  // If true, it's an AI message (no AI response needed)

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isTempChat = false,
    this.highlightMessageId,
    this.initialMessage,
    this.initialMessageFromAI = false,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _scrollController = ScrollController();
  bool _userHasScrolledUp = false;
  late String _chatTitle;
  bool _initialized = false;
  late String _actualChatId;
  Message? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _actualChatId = widget.chatId;
    _chatTitle = widget.chatName;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.highlightMessageId != null) {
        _scrollToMessage(widget.highlightMessageId!);
      } else {
        _scrollToBottom(animated: false);
      }
      _initialized = true;
      // Auto-send initial message for follow-up feature
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        if (widget.initialMessageFromAI) {
          _addInitialAIMessage(widget.initialMessage!);
        } else {
          _sendInitialUserMessage(widget.initialMessage!);
        }
      }
    });
  }

  Future<void> _sendInitialUserMessage(String content) async {
    // Create the chat first if it's a temp chat
    if (widget.isTempChat) {
      await ref.read(chatsProvider.notifier).createChatForTemp(widget.chatId);
    }
    // Send the message as user message and request AI response
    await ref.read(messagesProvider(_actualChatId).notifier).sendTextMessage(content);
  }

  Future<void> _addInitialAIMessage(String content) async {
    // Create the chat first if it's a temp chat
    if (widget.isTempChat) {
      await ref.read(chatsProvider.notifier).createChatForTemp(widget.chatId);
    }
    // Add the message as AI message directly (no AI response needed)
    await ref.read(messagesProvider(_actualChatId).notifier).addAIMessage(content);
    // Request AI to generate title for the conversation
    _generateChatTitle(content);
  }

  Future<void> _generateChatTitle(String content) async {
    // Use AI to generate a title based on the message content
    final aiService = ref.read(aiServiceProvider);
    final title = await aiService.summarizeForTitle(content);
    if (title.isNotEmpty && title != '新聊天') {
      await ref.read(chatsProvider.notifier).updateChatName(_actualChatId, title);
      setState(() {
        _chatTitle = title;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const threshold = 50.0;

    if (maxScroll - currentScroll <= threshold) {
      if (_userHasScrolledUp) {
        setState(() => _userHasScrolledUp = false);
      }
    } else {
      _userHasScrolledUp = true;
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(maxScroll);
      }
    }
  }

  void _scrollToMessage(String messageId) {
    final messages = ref.read(messagesProvider(_actualChatId));
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1 && _scrollController.hasClients) {
      // Estimate item height (message bubble + padding + timestamp)
      const itemHeight = 120.0;
      final targetOffset = index * itemHeight;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxScroll);
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _setReplyTo(Message message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  Future<void> _toggleFavorite(Message message) async {
    final newFavorite = !message.isFavorite;
    await DatabaseService.updateMessageFavorite(message.id, newFavorite);
    // Update the message in state directly without full refresh
    final updatedMessage = message.copyWith(isFavorite: newFavorite);
    ref.read(messagesProvider(_actualChatId).notifier).updateMessage(updatedMessage);
    // Invalidate favorites list so it refreshes
    ref.invalidate(favoriteMessagesProvider);
  }

  Future<void> _translateMessage(Message message) async {
    if (message.translatedContent != null && message.translatedContent!.isNotEmpty) {
      // Already translated, just show it
      return;
    }
    if (message.content == null || message.content!.isEmpty) {
      return;
    }

    // Set loading state
    final loadingNotifier = ref.read(translationLoadingProvider.notifier);
    loadingNotifier.setLoading(message.id, true);

    try {
      final translationService = ref.read(translationServiceProvider);
      final translated = await translationService.translate(message.content!);
      await DatabaseService.updateMessageTranslation(message.id, translated);
      // Update the message in state directly without full refresh
      final updatedMessage = message.copyWith(translatedContent: translated);
      ref.read(messagesProvider(_actualChatId).notifier).updateMessage(updatedMessage);
    } finally {
      loadingNotifier.setLoading(message.id, false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  void _createFollowUpChat(BuildContext context, Message message) {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatId: tempId,
          chatName: '创建新对话',
          isTempChat: true,
          initialMessage: message.content ?? '',
          initialMessageFromAI: !message.isFromMe,
        ),
      ),
    );
  }

  String _t(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'aiThinking': {'en': 'AI is thinking...', 'zh': 'AI思考中...', 'zh_TW': 'AI思考中...'},
      'clearChat': {'en': 'Clear Chat', 'zh': '清空聊天', 'zh_TW': '清空聊天'},
      'clearChatConfirm': {'en': 'Are you sure you want to clear all messages?', 'zh': '确定要清空所有消息吗？', 'zh_TW': '確定要清空所有訊息嗎？'},
      'cancel': {'en': 'Cancel', 'zh': '取消', 'zh_TW': '取消'},
      'confirm': {'en': 'Confirm', 'zh': '确定', 'zh_TW': '確定'},
      'startChatting': {'en': 'Start chatting\nSend text, image or voice messages', 'zh': '开始聊天吧\n发送文本、图片或语音消息', 'zh_TW': '開始聊天吧\n發送文本、圖片或語音訊息'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }

  Widget _buildLoadingIndicator(bool isDarkMode, Locale locale) {
    final loadingChatIds = ref.watch(loadingChatIdsProvider);
    final isLoading = loadingChatIds.contains(_actualChatId);
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _TypingIndicator(isDarkMode: isDarkMode),
          const SizedBox(width: 12),
          Text(
            _t('aiThinking', locale),
            style: TextStyle(
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBanner() {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final fontSize = ref.watch(fontSizeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(color: isDarkMode ? AppColors.inputBorderDark : AppColors.inputBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '引用回复',
                  style: TextStyle(
                    fontSize: 12.0 * fontSize.scale,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToMessage?.replyPreview ?? '',
                  style: TextStyle(
                    fontSize: 13.0 * fontSize.scale,
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(_actualChatId));
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

    ref.listen(messagesProvider(_actualChatId), (previous, next) {
      if (previous != null && next.length > previous.length) {
        // New message added - scroll to bottom
        if (_initialized) {
          _scrollToBottom();
        }
      } else if (previous != null && next.length == previous.length) {
        // Message updated (e.g., streaming completed) - check if should scroll
        if (_initialized && !_userHasScrolledUp) {
          final hasStreaming = next.any((m) => m.isStreaming == true);
          if (hasStreaming) {
            _scrollToBottom();
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          _chatTitle,
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(chatId: _actualChatId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatSettingsScreen(
                    chatId: _actualChatId,
                    currentTitle: _chatTitle,
                    onTitleChanged: (newTitle) {
                      setState(() {
                        _chatTitle = newTitle;
                      });
                    },
                    onClearChat: () async {
                      await ref.read(messagesProvider(_actualChatId).notifier).clearAll();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2),
                                  AppColors.primary.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _t('startChatting', locale),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final showDate = index == 0 ||
                            !_isSameDay(messages[index - 1].timestamp, message.timestamp);

                        return MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isDarkMode: isDarkMode,
                          showDate: showDate,
                          onReply: () => _setReplyTo(message),
                          onDelete: () => ref.read(messagesProvider(_actualChatId).notifier).deleteMessage(message.id),
                          onFavorite: () => _toggleFavorite(message),
                          onTranslate: () => _translateMessage(message),
                          onFollowUp: (msg) => _createFollowUpChat(context, msg),
                        );
                      },
                    ),
            ),
            if (_replyToMessage != null) _buildReplyBanner(),
            _buildLoadingIndicator(isDarkMode, locale),
            InputBar(
              chatId: _actualChatId,
              isTempChat: widget.isTempChat,
              locale: locale,
              replyToMessage: _replyToMessage,
              onCancelReply: _cancelReply,
              onFirstMessageSent: () {
                if (widget.isTempChat) {
                  ref.read(chatsProvider.notifier).createChatForTemp(widget.chatId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final bool isDarkMode;

  const _TypingIndicator({required this.isDarkMode});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: SizedBox(
        width: 36,
        height: 20,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final value = ((_controller.value - delay) % 1.0);
                final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.3, 1.0);
                final scale = (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.5, 1.0);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: opacity),
                          AppColors.primaryLight.withValues(alpha: opacity),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
