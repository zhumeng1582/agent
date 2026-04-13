import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../providers/chat_provider.dart';

class ChatSettingsScreen extends ConsumerWidget {
  final String chatId;
  final String currentTitle;
  final Function(String) onTitleChanged;
  final VoidCallback onDeleted;

  const ChatSettingsScreen({
    super.key,
    required this.chatId,
    required this.currentTitle,
    required this.onTitleChanged,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final locale = ref.watch(localeProvider);
    // Use currentTitle passed from parent instead of looking up from provider
    // This avoids issues when chat is deleted while settings screen is open
    final liveTitle = currentTitle;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          _t('chatSettings', locale),
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: _t('chatTitle', locale),
            isDarkMode: isDarkMode,
            children: [
              _buildTitleTile(context, ref, locale, isDarkMode, liveTitle),
            ],
          ),
          _buildSection(
            title: _t('dangerZone', locale),
            isDarkMode: isDarkMode,
            children: [
              _buildDeleteConversationTile(context, locale, isDarkMode, ref),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDarkMode,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        Container(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTitleTile(BuildContext context, WidgetRef ref, Locale locale, bool isDarkMode, String liveTitle) {
    return ListTile(
      leading: Icon(Icons.edit, color: AppColors.primary),
      title: Text(
        _t('chatTitle', locale),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Text(
        liveTitle,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      onTap: () => _showTitleDialog(context, ref, locale, liveTitle),
    );
  }

  void _showTitleDialog(BuildContext context, WidgetRef ref, Locale locale, String liveTitle) {
    final controller = TextEditingController(text: liveTitle);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('editTitle', locale)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _t('titleHint', locale),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_t('cancel', locale)),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                onTitleChanged(newTitle);
                ref.read(chatsProvider.notifier).updateChatName(chatId, newTitle);
              }
              Navigator.pop(dialogContext);
            },
            child: Text(_t('confirm', locale)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteConversationTile(BuildContext context, Locale locale, bool isDarkMode, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.delete_outline, color: Colors.red),
      title: Text(
        _t('deleteConversation', locale),
        style: const TextStyle(color: Colors.red),
      ),
      onTap: () => _showDeleteConversationDialog(context, locale, isDarkMode, ref),
    );
  }

  void _showDeleteConversationDialog(BuildContext context, Locale locale, bool isDarkMode, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _t('deleteConversation', locale),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          _t('deleteConversationConfirm', locale),
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_t('cancel', locale)),
          ),
          TextButton(
            onPressed: () async {
              // Delete first before closing screens
              await ref.read(chatsProvider.notifier).deleteChat(chatId);
              if (!context.mounted) return;
              Navigator.pop(dialogContext); // close dialog
              Navigator.pop(context); // close settings screen
              onDeleted();
            },
            child: Text(_t('confirm', locale), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _t(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'chatSettings': {'en': 'Chat Settings', 'zh': '聊天设置', 'zh_TW': '聊天設置'},
      'chatTitle': {'en': 'Chat Title', 'zh': '聊天标题', 'zh_TW': '聊天標題'},
      'editTitle': {'en': 'Edit Title', 'zh': '修改标题', 'zh_TW': '修改標題'},
      'titleHint': {'en': 'Enter chat title', 'zh': '输入聊天标题', 'zh_TW': '輸入聊天標題'},
      'dangerZone': {'en': 'Danger Zone', 'zh': '危险操作', 'zh_TW': '危險操作'},
      'deleteConversation': {'en': 'Delete Conversation', 'zh': '删除会话', 'zh_TW': '刪除會話'},
      'deleteConversationConfirm': {'en': 'Are you sure you want to delete this conversation? This cannot be undone.', 'zh': '确定要删除此会话吗？此操作无法撤销。', 'zh_TW': '確定要刪除此會話嗎？此操作無法撤銷。'},
      'cancel': {'en': 'Cancel', 'zh': '取消', 'zh_TW': '取消'},
      'confirm': {'en': 'Confirm', 'zh': '确定', 'zh_TW': '確定'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }
}
