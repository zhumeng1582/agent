import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../../core/constants/font_size_provider.dart';
import '../../core/constants/usage_provider.dart';
import 'avatar_edit_screen.dart';
import 'favorites_screen.dart';

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
            title: _getLocalizedText('account', currentLocale),
            isDarkMode: isDarkMode,
            children: [
              _buildAvatarEditTile(context, ref, currentLocale, isDarkMode),
              _buildFavoritesTile(context, currentLocale, isDarkMode),
            ],
          ),
          _buildSection(
            title: _getLocalizedText('usage', currentLocale),
            isDarkMode: isDarkMode,
            children: [
              _buildUsageTile(usage, isDarkMode, currentLocale),
              _buildTokenTile(usage, isDarkMode, currentLocale),
            ],
          ),
          _buildSection(
            title: _getLocalizedText('appearance', currentLocale),
            isDarkMode: isDarkMode,
            children: [
              _buildThemeModeTile(context, ref, currentLocale, isDarkMode),
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

  Widget _buildTokenTile(UsageState usage, bool isDarkMode, Locale locale) {
    final tokens = usage.tokensUsedToday;

    return ListTile(
      title: Text(
        _getLocalizedText('tokenUsage', locale),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Text(
        _formatTokens(tokens),
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  String _formatTokens(int tokens) {
    if (tokens < 1000) {
      return '$tokens';
    } else if (tokens < 1000000) {
      return '${(tokens / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(tokens / 1000000).toStringAsFixed(1)}M';
    }
  }

  Widget _buildAvatarEditTile(BuildContext context, WidgetRef ref, Locale currentLocale, bool isDarkMode) {
    return ListTile(
      leading: Icon(
        Icons.face,
        color: AppColors.primary,
      ),
      title: Text(
        _getLocalizedText('editAvatar', currentLocale),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AvatarEditScreen()),
        );
      },
    );
  }

  Widget _buildFavoritesTile(BuildContext context, Locale currentLocale, bool isDarkMode) {
    return ListTile(
      leading: Icon(
        Icons.star,
        color: AppColors.primary,
      ),
      title: Text(
        _getLocalizedText('favorites', currentLocale),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FavoritesScreen()),
        );
      },
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

  Widget _buildThemeModeTile(BuildContext context, WidgetRef ref, Locale currentLocale, bool isDarkMode) {
    final themeMode = ref.watch(themeProvider);
    String themeText;
    IconData themeIcon;
    switch (themeMode) {
      case ThemeMode.light:
        themeText = _getLocalizedText('lightMode', currentLocale);
        themeIcon = Icons.light_mode;
        break;
      case ThemeMode.dark:
        themeText = _getLocalizedText('darkMode', currentLocale);
        themeIcon = Icons.dark_mode;
        break;
      case ThemeMode.system:
        themeText = _getLocalizedText('systemMode', currentLocale);
        themeIcon = Icons.brightness_auto;
        break;
    }

    return ListTile(
      leading: Icon(themeIcon, color: AppColors.primary),
      title: Text(
        _getLocalizedText('theme', currentLocale),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            themeText,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ],
      ),
      onTap: () {
        _showThemeSelector(context, ref, currentLocale, isDarkMode);
      },
    );
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref, Locale currentLocale, bool isDarkMode) {
    final currentMode = ref.read(themeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getLocalizedText('selectTheme', currentLocale),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              context,
              ref,
              ThemeMode.system,
              Icons.brightness_auto,
              _getLocalizedText('systemMode', currentLocale),
              currentMode == ThemeMode.system,
              isDarkMode,
            ),
            _buildThemeOption(
              context,
              ref,
              ThemeMode.light,
              Icons.light_mode,
              _getLocalizedText('lightMode', currentLocale),
              currentMode == ThemeMode.light,
              isDarkMode,
            ),
            _buildThemeOption(
              context,
              ref,
              ThemeMode.dark,
              Icons.dark_mode,
              _getLocalizedText('darkMode', currentLocale),
              currentMode == ThemeMode.dark,
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeMode mode,
    IconData icon,
    String title,
    bool isSelected,
    bool isDarkMode,
  ) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : (isDarkMode ? Colors.grey[400] : Colors.grey[600])),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
        Navigator.pop(context);
      },
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

  Widget _buildFontSizeTile(BuildContext context, WidgetRef ref, FontSizeState fontSizeState, bool isDarkMode, Locale locale) {
    String sizeLabel;
    switch (fontSizeState.option) {
      case FontSizeOption.small:
        sizeLabel = '小';
        break;
      case FontSizeOption.medium:
        sizeLabel = '中';
        break;
      case FontSizeOption.large:
        sizeLabel = '大';
        break;
    }

    return ListTile(
      title: Text(
        _getLocalizedText('fontSize', locale),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sizeLabel,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ],
      ),
      onTap: () {
        _showFontSizeSelector(context, ref, fontSizeState, isDarkMode, locale);
      },
    );
  }

  void _showFontSizeSelector(BuildContext context, WidgetRef ref, FontSizeState currentState, bool isDarkMode, Locale locale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getLocalizedText('selectFontSize', locale),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildFontSizeOption(
              context,
              ref,
              FontSizeOption.small,
              '小',
              '${_getLocalizedText('smallDesc', locale)} (0.8x)',
              currentState.option == FontSizeOption.small,
              isDarkMode,
            ),
            _buildFontSizeOption(
              context,
              ref,
              FontSizeOption.medium,
              '中',
              '${_getLocalizedText('mediumDesc', locale)} (1.0x)',
              currentState.option == FontSizeOption.medium,
              isDarkMode,
            ),
            _buildFontSizeOption(
              context,
              ref,
              FontSizeOption.large,
              '大',
              '${_getLocalizedText('largeDesc', locale)} (1.2x)',
              currentState.option == FontSizeOption.large,
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(
    BuildContext context,
    WidgetRef ref,
    FontSizeOption option,
    String title,
    String subtitle,
    bool isSelected,
    bool isDarkMode,
  ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        ref.read(fontSizeProvider.notifier).setFontSize(option);
        Navigator.pop(context);
      },
    );
  }

  String _getLocalizedText(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'settings': {'en': 'Settings', 'zh': '设置', 'zh_TW': '設定'},
      'account': {'en': 'Account', 'zh': '账号', 'zh_TW': '帳號'},
      'editAvatar': {'en': 'Edit Avatar', 'zh': '修改头像', 'zh_TW': '修改頭像'},
      'favorites': {'en': 'Favorites', 'zh': '收藏', 'zh_TW': '收藏'},
      'appearance': {'en': 'Appearance', 'zh': '外观', 'zh_TW': '外觀'},
      'darkMode': {'en': 'Dark Mode', 'zh': '深色模式', 'zh_TW': '深色模式'},
      'darkModeSubtitle': {'en': 'Enable dark theme', 'zh': '开启后应用将使用深色主题', 'zh_TW': '開啟後應用將使用深色主題'},
      'theme': {'en': 'Theme', 'zh': '主题', 'zh_TW': '主題'},
      'lightMode': {'en': 'Light', 'zh': '浅色', 'zh_TW': '淺色'},
      'darkMode': {'en': 'Dark', 'zh': '深色', 'zh_TW': '深色'},
      'systemMode': {'en': 'System', 'zh': '跟随系统', 'zh_TW': '跟隨系統'},
      'selectTheme': {'en': 'Select Theme', 'zh': '选择主题', 'zh_TW': '選擇主題'},
      'about': {'en': 'About', 'zh': '关于', 'zh_TW': '關於'},
      'version': {'en': 'Version', 'zh': '版本', 'zh_TW': '版本'},
      'developer': {'en': 'Developer', 'zh': '开发者', 'zh_TW': '開發者'},
      'language': {'en': 'Language', 'zh': '语言', 'zh_TW': '語言'},
      'selectLanguage': {'en': 'Select Language', 'zh': '选择语言', 'zh_TW': '選擇語言'},
      'fontSize': {'en': 'Font Size', 'zh': '字体大小', 'zh_TW': '字體大小'},
      'selectFontSize': {'en': 'Select Font Size', 'zh': '选择字体大小', 'zh_TW': '選擇字體大小'},
      'smallDesc': {'en': 'Small', 'zh': '小', 'zh_TW': '小'},
      'mediumDesc': {'en': 'Medium', 'zh': '中', 'zh_TW': '中'},
      'largeDesc': {'en': 'Large', 'zh': '大', 'zh_TW': '大'},
      'usage': {'en': 'Usage', 'zh': '使用情况', 'zh_TW': '使用情況'},
      'dailyUsage': {'en': 'Daily AI Chats', 'zh': '今日AI对话', 'zh_TW': '今日AI對話'},
      'remaining': {'en': 'remaining', 'zh': '次可用', 'zh_TW': '次可用'},
      'limitReached': {'en': 'Limit', 'zh': '已用完', 'zh_TW': '已用完'},
      'tokenUsage': {'en': 'Token Usage', 'zh': 'Token消耗', 'zh_TW': 'Token消耗'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }
}
