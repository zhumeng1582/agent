import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../../core/constants/font_size_provider.dart';
import '../../core/constants/usage_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final currentLocale = ref.watch(localeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final usage = ref.watch(usageProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.background,
      appBar: AppBar(
        title: Text(
          _getLocalizedText('settings', currentLocale),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[850] : AppColors.surface,
        elevation: 1,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: _getLocalizedText('usage', currentLocale),
            isDarkMode: isDarkMode,
            children: [
              _buildUsageTile(usage, isDarkMode, currentLocale),
            ],
          ),
          _buildSection(
            title: _getLocalizedText('appearance', currentLocale),
            isDarkMode: isDarkMode,
            children: [
              _buildSwitchTile(
                title: _getLocalizedText('darkMode', currentLocale),
                subtitle: _getLocalizedText('darkModeSubtitle', currentLocale),
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
                isDarkMode: isDarkMode,
              ),
              _buildLanguageTile(context, ref, currentLocale, isDarkMode),
              _buildFontSizeTile(context, ref, fontSize, isDarkMode, currentLocale),
            ],
          ),
          _buildSection(
            title: _getLocalizedText('about', currentLocale),
            isDarkMode: isDarkMode,
            children: [
              _buildInfoTile(
                title: _getLocalizedText('version', currentLocale),
                value: '1.0.0',
                isDarkMode: isDarkMode,
              ),
              _buildInfoTile(
                title: _getLocalizedText('developer', currentLocale),
                value: 'Claude Code',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTile(UsageState usage, bool isDarkMode, Locale locale) {
    final remaining = usage.remaining;
    final isLimited = usage.isLimited;

    return ListTile(
      title: Text(
        _getLocalizedText('dailyUsage', locale),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        '${remaining}/100 ${_getLocalizedText('remaining', locale)}',
        style: TextStyle(
          color: isLimited
              ? Colors.red
              : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
      trailing: isLimited
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getLocalizedText('limitReached', locale),
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            )
          : null,
    );
  }

  Widget _buildLanguageTile(BuildContext context, WidgetRef ref, Locale currentLocale, bool isDarkMode) {
    return ListTile(
      title: Text(
        _getLocalizedText('language', currentLocale),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        _getLanguageName(currentLocale),
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
      onTap: () => _showLanguageDialog(context, ref, currentLocale),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, Locale currentLocale) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_getLocalizedText('selectLanguage', currentLocale)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, ref, const Locale('zh'), '简体中文', currentLocale),
              _buildLanguageOption(context, ref, const Locale('zh', 'TW'), '繁體中文', currentLocale),
              _buildLanguageOption(context, ref, const Locale('en'), 'English', currentLocale),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, WidgetRef ref, Locale locale, String name, Locale currentLocale) {
    final isSelected = currentLocale.languageCode == locale.languageCode &&
        (currentLocale.countryCode == locale.countryCode || (currentLocale.countryCode == null && locale.countryCode == null));

    return ListTile(
      title: Text(name),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.pop(context);
      },
    );
  }

  String _getLanguageName(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
      return '繁體中文';
    } else if (locale.languageCode == 'zh') {
      return '简体中文';
    } else {
      return 'English';
    }
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildFontSizeTile(BuildContext context, WidgetRef ref, double fontSize, bool isDarkMode, Locale locale) {
    return ListTile(
      title: Text(
        _getLocalizedText('fontSize', locale),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        '${fontSize.toInt()}',
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: fontSize > 12 ? () => ref.read(fontSizeProvider.notifier).decreaseFontSize() : null,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: fontSize < 20 ? () => ref.read(fontSizeProvider.notifier).increaseFontSize() : null,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ],
      ),
    );
  }

  String _getLocalizedText(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'settings': {'en': 'Settings', 'zh': '设置', 'zh_TW': '設定'},
      'appearance': {'en': 'Appearance', 'zh': '外观', 'zh_TW': '外觀'},
      'darkMode': {'en': 'Dark Mode', 'zh': '深色模式', 'zh_TW': '深色模式'},
      'darkModeSubtitle': {'en': 'Enable dark theme', 'zh': '开启后应用将使用深色主题', 'zh_TW': '開啟後應用將使用深色主題'},
      'about': {'en': 'About', 'zh': '关于', 'zh_TW': '關於'},
      'version': {'en': 'Version', 'zh': '版本', 'zh_TW': '版本'},
      'developer': {'en': 'Developer', 'zh': '开发者', 'zh_TW': '開發者'},
      'language': {'en': 'Language', 'zh': '语言', 'zh_TW': '語言'},
      'selectLanguage': {'en': 'Select Language', 'zh': '选择语言', 'zh_TW': '選擇語言'},
      'fontSize': {'en': 'Font Size', 'zh': '字体大小', 'zh_TW': '字體大小'},
      'usage': {'en': 'Usage', 'zh': '使用情况', 'zh_TW': '使用情況'},
      'dailyUsage': {'en': 'Daily AI Chats', 'zh': '今日AI对话', 'zh_TW': '今日AI對話'},
      'remaining': {'en': 'remaining', 'zh': '次可用', 'zh_TW': '次可用'},
      'limitReached': {'en': 'Limit', 'zh': '已用完', 'zh_TW': '已用完'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }
}
