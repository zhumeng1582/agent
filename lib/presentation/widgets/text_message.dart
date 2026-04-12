import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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

    final displayContent = _getDisplayContent();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: MarkdownBody(
              data: displayContent,
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
          if (message.isStreaming) _buildCursor(textColor),
        ],
      ),
    );
  }

  String _getDisplayContent() {
    final content = message.content ?? '';
    if (!message.isStreaming || content.isEmpty) {
      return content;
    }
    // Show partial content while streaming for visual effect
    // This creates a typewriter-like visual without complex animation
    final length = content.length;
    final showLength = (length * 0.5).ceil().clamp(1, length);
    return content.substring(0, showLength);
  }

  Widget _buildCursor(Color color) {
    return _BlinkingCursor(color: color);
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;

  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 18,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}
