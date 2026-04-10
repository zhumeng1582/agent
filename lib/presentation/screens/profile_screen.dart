import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../../core/constants/avatar_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider);
    final avatarState = ref.watch(avatarProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.background,
      appBar: AppBar(
        title: Text(
          _t('profile', locale),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Current avatar display
            _buildCurrentAvatar(context, ref, avatarState, isDarkMode),
            const SizedBox(height: 32),

            // Default avatars section
            _buildSectionTitle(_t('defaultAvatars', locale), isDarkMode),
            const SizedBox(height: 12),
            _buildDefaultAvatarsGrid(context, ref, avatarState, isDarkMode),

            const SizedBox(height: 32),

            // Custom avatar section
            _buildSectionTitle(_t('customAvatar', locale), isDarkMode),
            const SizedBox(height: 12),
            _buildCustomAvatarOption(context, ref, isDarkMode, locale),

            if (avatarState.customAvatarPath != null) ...[
              const SizedBox(height: 12),
              _buildClearCustomAvatar(context, ref, isDarkMode, locale),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAvatar(BuildContext context, WidgetRef ref, AvatarState avatarState, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildAvatarWidget(avatarState, 100),
        ),
        const SizedBox(height: 16),
        Text(
          _t('tapToChange', ref.watch(localeProvider)),
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarWidget(AvatarState avatarState, double size) {
    if (avatarState.customAvatarPath != null) {
      return ClipOval(
        child: Image.file(
          File(avatarState.customAvatarPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return DefaultAvatars.buildAvatar(avatarState.selectedDefaultIndex, size: size);
          },
        ),
      );
    }
    return DefaultAvatars.buildAvatar(avatarState.selectedDefaultIndex, size: size);
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildDefaultAvatarsGrid(BuildContext context, WidgetRef ref, AvatarState avatarState, bool isDarkMode) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: DefaultAvatars.colors.length,
      itemBuilder: (context, index) {
        final isSelected = avatarState.selectedDefaultIndex == index && avatarState.customAvatarPath == null;
        return GestureDetector(
          onTap: () {
            ref.read(avatarProvider.notifier).setDefaultAvatar(index);
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: DefaultAvatars.buildAvatar(index),
          ),
        );
      },
    );
  }

  Widget _buildCustomAvatarOption(BuildContext context, WidgetRef ref, bool isDarkMode, Locale locale) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.photo_library_rounded,
          color: AppColors.primary,
        ),
        title: Text(
          _t('chooseFromGallery', locale),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: () async {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            ref.read(avatarProvider.notifier).setCustomAvatar(image.path);
          }
        },
      ),
    );
  }

  Widget _buildClearCustomAvatar(BuildContext context, WidgetRef ref, bool isDarkMode, Locale locale) {
    return TextButton.icon(
      onPressed: () {
        ref.read(avatarProvider.notifier).clearCustomAvatar();
      },
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      label: Text(
        _t('removeCustomAvatar', locale),
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  String _t(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'profile': {'en': 'Profile', 'zh': '个人资料', 'zh_TW': '個人資料'},
      'defaultAvatars': {'en': 'Default Avatars', 'zh': '默认头像', 'zh_TW': '默認頭像'},
      'customAvatar': {'en': 'Custom Avatar', 'zh': '自定义头像', 'zh_TW': '自定義頭像'},
      'chooseFromGallery': {'en': 'Choose from Gallery', 'zh': '从相册选择', 'zh_TW': '從相冊選擇'},
      'tapToChange': {'en': 'Tap to change avatar', 'zh': '点击更换头像', 'zh_TW': '點擊更換頭像'},
      'removeCustomAvatar': {'en': 'Remove Custom Avatar', 'zh': '移除自定义头像', 'zh_TW': '移除自定義頭像'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }
}
