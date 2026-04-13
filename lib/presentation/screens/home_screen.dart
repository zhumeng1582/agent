import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import 'chat_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  ChatListScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
            // Bottom navigation bar - use same background as app
            Container(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 56,
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    type: BottomNavigationBarType.fixed,
                    selectedLabelStyle: const TextStyle(fontSize: 11),
                    unselectedLabelStyle: const TextStyle(fontSize: 11),
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.chat_bubble_outline),
                        activeIcon: const Icon(Icons.chat_bubble),
                        label: _t('chats', locale),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.settings_outlined),
                        activeIcon: const Icon(Icons.settings),
                        label: _t('settings', locale),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _t(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'chats': {'en': 'Chats', 'zh': '聊天', 'zh_TW': '聊天'},
      'settings': {'en': 'Set', 'zh': '设置', 'zh_TW': '設置'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }
}
