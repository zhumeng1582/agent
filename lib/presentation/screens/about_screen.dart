import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../../core/constants/auth_provider.dart';
import 'login_screen.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          _getLocalizedText('about', currentLocale),
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
            title: _getLocalizedText('appInfo', currentLocale),
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
          _buildSection(
            title: _getLocalizedText('support', currentLocale),
            isDarkMode: isDarkMode,
            children: [
              _buildInfoTile(
                title: _getLocalizedText('email', currentLocale),
                value: 'support@example.com',
                isDarkMode: isDarkMode,
              ),
              _buildInfoTile(
                title: _getLocalizedText('website', currentLocale),
                value: 'www.example.com',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
          _buildSection(
            title: _getLocalizedText('legal', currentLocale),
            isDarkMode: isDarkMode,
            children: [
              _buildNavigationTile(
                title: _getLocalizedText('privacyPolicy', currentLocale),
                isDarkMode: isDarkMode,
                onTap: () {
                  // TODO: Navigate to privacy policy
                },
              ),
              _buildNavigationTile(
                title: _getLocalizedText('termsOfService', currentLocale),
                isDarkMode: isDarkMode,
                onTap: () {
                  // TODO: Navigate to terms of service
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLogoutButton(context, ref, currentLocale, isDarkMode),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              _getLocalizedText('poweredBy', currentLocale),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, Locale currentLocale, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(_getLocalizedText('logout', currentLocale)),
              content: Text(_getLocalizedText('logoutConfirm', currentLocale)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(_getLocalizedText('cancel', currentLocale)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    _getLocalizedText('logout', currentLocale),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
        child: Text(
          _getLocalizedText('logout', currentLocale),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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

  Widget _buildNavigationTile({
    required String title,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
      onTap: onTap,
    );
  }

  String _getLocalizedText(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'about': {'en': 'About', 'zh': '关于', 'zh_TW': '關於'},
      'appInfo': {'en': 'App Info', 'zh': '应用信息', 'zh_TW': '應用資訊'},
      'version': {'en': 'Version', 'zh': '版本', 'zh_TW': '版本'},
      'developer': {'en': 'Developer', 'zh': '开发者', 'zh_TW': '開發者'},
      'support': {'en': 'Support', 'zh': '支持', 'zh_TW': '支持'},
      'email': {'en': 'Email', 'zh': '邮箱', 'zh_TW': '郵箱'},
      'website': {'en': 'Website', 'zh': '网站', 'zh_TW': '網站'},
      'legal': {'en': 'Legal', 'zh': '法律', 'zh_TW': '法律'},
      'privacyPolicy': {'en': 'Privacy Policy', 'zh': '隐私政策', 'zh_TW': '隱私政策'},
      'termsOfService': {'en': 'Terms of Service', 'zh': '服务条款', 'zh_TW': '服務條款'},
      'poweredBy': {'en': 'Powered by MiniMax-M2.7', 'zh': '由MiniMax-M2.7提供技术支持', 'zh_TW': '由MiniMax-M2.7提供技術支持'},
      'logout': {'en': 'Logout', 'zh': '退出登录', 'zh_TW': '退出登入'},
      'logoutConfirm': {'en': 'Are you sure you want to logout?', 'zh': '确定要退出登录吗？', 'zh_TW': '確定要退出登入嗎？'},
      'cancel': {'en': 'Cancel', 'zh': '取消', 'zh_TW': '取消'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }
}
