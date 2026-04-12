import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/font_size_provider.dart';
import '../../data/models/message.dart';
import '../../data/services/database_service.dart';

final favoriteMessagesProvider = FutureProvider<List<Message>>((ref) async {
  final maps = await DatabaseService.getFavoriteMessages();
  return maps.map((m) => Message.fromMap(m)).toList();
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final fontSize = ref.watch(fontSizeProvider);
    final favoritesAsync = ref.watch(favoriteMessagesProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          '收藏',
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无收藏',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildFavoriteItem(context, message, isDarkMode, fontSize, ref);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteItem(BuildContext context, Message message, bool isDarkMode, FontSizeState fontSize, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: message.isFromMe
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  message.isFromMe ? Icons.person : Icons.smart_toy,
                  size: 14,
                  color: message.isFromMe ? AppColors.primary : AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message.isFromMe ? '我' : 'AI助手',
                style: TextStyle(
                  fontSize: 12.0 * fontSize.scale,
                  color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await DatabaseService.updateMessageFavorite(message.id, false);
                  ref.invalidate(favoriteMessagesProvider);
                },
                child: Icon(
                  Icons.star,
                  size: 20,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MarkdownBody(
            data: message.content ?? '',
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
                fontSize: 15.0 * fontSize.scale,
                height: 1.4,
              ),
              code: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
                backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                fontSize: 14.0 * fontSize.scale,
              ),
              codeblockDecoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (message.translatedContent != null && message.translatedContent!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.surfaceDark.withValues(alpha: 0.5)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message.translatedContent!,
                style: TextStyle(
                  fontSize: 13.0 * fontSize.scale,
                  color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
