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
  final bool selectionEnabled;
  final Function(String)? onSelectionChanged;

  const TextMessage({
    super.key,
    required this.message,
    this.isDarkMode = false,
    this.selectionEnabled = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final textColor = message.isFromMe
        ? Colors.white
        : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary);

    final content = message.content ?? '';
    final isStreaming = message.isStreaming ?? false;
    final reasoning = message.reasoning;

    if (isStreaming) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  content,
                  textStyle: TextStyle(
                    color: textColor,
                    fontSize: 16 * fontSize.scale,
                    height: 1.4,
                  ),
                  speed: const Duration(milliseconds: 30),
                  cursor: '|',  // Vertical bar cursor
                ),
              ],
              isRepeatingAnimation: false,
            ),
          ),
          if (reasoning != null && reasoning.isNotEmpty)
            _buildReasoningWidget(reasoning, fontSize, isDarkMode),
        ],
      );
    }

    // When selection is enabled, show SelectableText instead of Markdown
    if (selectionEnabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SelectableText(
              content,
              style: TextStyle(
                color: textColor,
                fontSize: 16 * fontSize.scale,
                height: 1.4,
              ),
              onSelectionChanged: (selection, cause) {
                if (selection.baseOffset != selection.extentOffset) {
                  final selectedText = content.substring(
                    selection.baseOffset.clamp(0, content.length),
                    selection.extentOffset.clamp(0, content.length),
                  );
                  onSelectionChanged?.call(selectedText);
                }
              },
            ),
          ),
          if (reasoning != null && reasoning.isNotEmpty)
            _buildReasoningWidget(reasoning, fontSize, isDarkMode),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: textColor,
                fontSize: 16 * fontSize.scale,
                height: 1.4,
              ),
              code: TextStyle(
                color: textColor,
                backgroundColor: message.isFromMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDarkMode ? Colors.grey[600] : Colors.grey[200]),
                fontSize: 14 * fontSize.scale,
              ),
              codeblockDecoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (reasoning != null && reasoning.isNotEmpty)
          _buildReasoningWidget(reasoning, fontSize, isDarkMode),
      ],
    );
  }

  Widget _buildReasoningWidget(String reasoning, FontSizeState fontSize, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[800]?.withValues(alpha: 0.5)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'AI思考过程',
              style: TextStyle(
                fontSize: 12 * fontSize.scale,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Text(
            reasoning,
            style: TextStyle(
              fontSize: 11 * fontSize.scale,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
