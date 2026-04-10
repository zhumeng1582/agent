import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatsProvider);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.background,
      appBar: AppBar(
        title: Text(
          _t('appTitle', locale),
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
            icon: const Icon(Icons.add),
            onPressed: () {
              _createNewChat(context, ref, locale);
            },
          ),
        ],
      ),
      body: chats.isEmpty
          ? Center(
              child: Text(
                _t('noChats', locale),
                textAlign: TextAlign.center,
                style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
              ),
            )
          : ReorderableListView.builder(
              itemCount: chats.length,
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                ref.read(chatsProvider.notifier).reorderChats(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _ChatListItem(
                  key: Key(chat.id),
                  chat: chat,
                  isDarkMode: isDarkMode,
                  locale: locale,
                );
              },
            ),
    );
  }

  void _createNewChat(BuildContext context, WidgetRef ref, Locale locale) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(chatId: tempId, chatName: _t('newChat', locale), isTempChat: true),
      ),
    );
  }

  String _t(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'appTitle': {'en': 'Multi-modal Chat', 'zh': '多模态聊天', 'zh_TW': '多模態聊天'},
      'noChats': {'en': 'No chats yet\nTap + to create a new chat', 'zh': '暂无聊天\n点击右上角 + 创建新聊天', 'zh_TW': '暫無聊天\n點擊右上角 + 創建新聊天'},
      'newChat': {'en': 'New Chat', 'zh': '新聊天', 'zh_TW': '新聊天'},
      'deleteChat': {'en': 'Delete Chat', 'zh': '删除聊天', 'zh_TW': '刪除聊天'},
      'deleteChatConfirm': {'en': 'Are you sure you want to delete this chat?', 'zh': '确定要删除这个聊天吗？', 'zh_TW': '確定要刪除這個聊天嗎？'},
      'cancel': {'en': 'Cancel', 'zh': '取消', 'zh_TW': '取消'},
      'delete': {'en': 'Delete', 'zh': '删除', 'zh_TW': '刪除'},
      'noMessages': {'en': 'No messages', 'zh': '暂无消息', 'zh_TW': '暫無訊息'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }
}

class _ChatListItem extends ConsumerWidget {
  final dynamic chat;
  final bool isDarkMode;
  final Locale locale;

  const _ChatListItem({super.key, required this.chat, required this.isDarkMode, required this.locale});

  String _t(String key) {
    final Map<String, Map<String, String>> translations = {
      'deleteChat': {'en': 'Delete Chat', 'zh': '删除聊天', 'zh_TW': '刪除聊天'},
      'deleteChatConfirm': {'en': 'Are you sure you want to delete this chat?', 'zh': '确定要删除这个聊天吗？', 'zh_TW': '確定要刪除這個聊天嗎？'},
      'cancel': {'en': 'Cancel', 'zh': '取消', 'zh_TW': '取消'},
      'delete': {'en': 'Delete', 'zh': '删除', 'zh_TW': '刪除'},
      'pin': {'en': 'Pin', 'zh': '置顶', 'zh_TW': '置頂'},
      'unpin': {'en': 'Unpin', 'zh': '取消置顶', 'zh_TW': '取消置頂'},
      'noMessages': {'en': 'No messages', 'zh': '暂无消息', 'zh_TW': '暫無訊息'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MM/dd');

    String formatTime(DateTime time) {
      final now = DateTime.now();
      if (time.year == now.year &&
          time.month == now.month &&
          time.day == now.day) {
        return timeFormat.format(time);
      }
      return dateFormat.format(time);
    }

    return Slidable(
      key: Key(chat.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (context) {
              ref.read(chatsProvider.notifier).togglePinChat(chat.id);
            },
            backgroundColor: chat.isPinned ? Colors.grey : AppColors.primary,
            foregroundColor: Colors.white,
            icon: chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: chat.isPinned ? _t('unpin') : _t('pin'),
          ),
          SlidableAction(
            onPressed: (context) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(_t('deleteChat')),
                  content: Text(_t('deleteChatConfirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(_t('cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(_t('delete')),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(chatsProvider.notifier).deleteChat(chat.id);
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: _t('delete'),
          ),
        ],
      ),
      child: Container(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          title: Row(
            children: [
              if (chat.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.push_pin,
                    size: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              Expanded(
                child: Text(
                  chat.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            chat.lastMessagePreview ?? _t('noMessages'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          trailing: Text(
            formatTime(chat.lastMessageTime),
            style: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.grey[500], fontSize: 12),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomScreen(chatId: chat.id, chatName: chat.name),
              ),
            );
          },
        ),
      ),
    );
  }
}
