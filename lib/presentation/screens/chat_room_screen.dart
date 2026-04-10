import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../../data/models/message.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/input_bar.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final bool isTempChat;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isTempChat = false,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _scrollController = ScrollController();
  bool _userHasScrolledUp = false;
  bool _initialized = false;
  late String _actualChatId;
  Message? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _actualChatId = widget.chatId;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
      _initialized = true;
    });
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

  void _ensureChatCreated() {
    if (widget.isTempChat) {
      final chats = ref.read(chatsProvider);
      if (chats.isEmpty || chats.any((c) => c.id == widget.chatId)) {
        ref.read(chatsProvider.notifier).createChatForTemp(widget.chatId);
      }
    }
  }

  void _setReplyTo(Message message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
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
    final isLoading = ref.watch(isLoadingProvider);
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
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBanner() {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        border: Border(
          top: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
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
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToMessage?.replyPreview ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
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
        if (_initialized) {
          _scrollToBottom();
        }
      }
    });

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.chatName,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[850] : AppColors.surface,
        elevation: 1,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    _t('clearChat', locale),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  content: Text(
                    _t('clearChatConfirm', locale),
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(_t('cancel', locale)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(_t('confirm', locale)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(messagesProvider(_actualChatId).notifier).clearAll();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      _t('startChatting', locale),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(
                        message: messages[index],
                        isDarkMode: isDarkMode,
                        onReply: () => _setReplyTo(messages[index]),
                        onDelete: () => ref.read(messagesProvider(_actualChatId).notifier).deleteMessage(messages[index].id),
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
    return SizedBox(
      width: 40,
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
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? Colors.white.withValues(alpha: opacity)
                        : AppColors.primary.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
