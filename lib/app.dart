import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/theme_provider.dart';
import 'core/constants/locale_provider.dart';
import 'core/constants/font_size_provider.dart';
import 'presentation/screens/splash_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  String _getLocalizedTitle(Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'appTitle': {'en': 'Multi-modal Chat', 'zh': '多模态聊天', 'zh_TW': '多模態聊天'},
    };
    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations['appTitle']?[localeKey] ?? translations['appTitle']?['zh'] ?? '多模态聊天';
  }

  ThemeData _buildTheme(Brightness brightness, double scale) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      ),
      useMaterial3: true,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16 * scale),
        bodyMedium: TextStyle(fontSize: 14 * scale),
        bodySmall: TextStyle(fontSize: 12 * scale),
        titleLarge: TextStyle(fontSize: 22 * scale),
        titleMedium: TextStyle(fontSize: 16 * scale),
        titleSmall: TextStyle(fontSize: 14 * scale),
        labelLarge: TextStyle(fontSize: 14 * scale),
        labelMedium: TextStyle(fontSize: 12 * scale),
        labelSmall: TextStyle(fontSize: 11 * scale),
      ),
    );
    if (brightness == Brightness.light) {
      return base.copyWith(scaffoldBackgroundColor: AppColors.background);
    } else {
      return base.copyWith(scaffoldBackgroundColor: Colors.grey[900]);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final fontSizeState = ref.watch(fontSizeProvider);
    final scale = fontSizeState.scale;

    return MaterialApp(
      title: _getLocalizedTitle(locale),
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light, scale),
      darkTheme: _buildTheme(Brightness.dark, scale),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
        Locale('zh', 'TW'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
