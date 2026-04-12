import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/font_size_provider.dart';
import '../../data/models/message.dart';

class TextMessage extends ConsumerWidget {
  final Message message;
  final bool isDarkMode;

  const TextMessage({
    super.key,
    required this.message,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final textColor = message.isFromMe
        ? Colors.white
        : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary);

    final content = message.content ?? '';
    final isStreaming = message.isStreaming ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isStreaming
          ? _buildTypewriterText(content, textColor, fontSize.scale)
          : _buildStaticText(content, textColor, fontSize.scale),
    );
  }

  Widget _buildTypewriterText(String content, Color textColor, double fontScale) {
    return AnimatedTextKit(
      animatedTexts: [
        TypewriterAnimatedText(
          content,
          textStyle: TextStyle(
            color: textColor,
            fontSize: 16 * fontScale,
            height: 1.4,
          ),
          speed: const Duration(milliseconds: 30),
        ),
      ],
      isRepeatingAnimation: false,
    );
  }

  Widget _buildStaticText(String content, Color textColor, double fontScale) {
    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: textColor,
          fontSize: 16 * fontScale,
          height: 1.4,
        ),
        code: TextStyle(
          color: textColor,
          backgroundColor: message.isFromMe
              ? Colors.white.withValues(alpha: 0.2)
              : (isDarkMode ? Colors.grey[600] : Colors.grey[200]),
          fontSize: 14 * fontScale,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
