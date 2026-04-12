import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/font_size_provider.dart';
import '../../data/models/message.dart';

class TextMessage extends ConsumerStatefulWidget {
  final Message message;
  final bool isDarkMode;

  const TextMessage({
    super.key,
    required this.message,
    this.isDarkMode = false,
  });

  @override
  ConsumerState<TextMessage> createState() => _TextMessageState();
}

class _TextMessageState extends ConsumerState<TextMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _shouldAnimate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _calculateDuration(widget.message.content ?? ''),
      vsync: this,
    );

    _shouldAnimate = widget.message.isStreaming == true;
    if (_shouldAnimate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(TextMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if this is a new streaming message
    if (widget.message.content != oldWidget.message.content &&
        widget.message.isStreaming == true) {
      _shouldAnimate = true;
      _controller.duration = _calculateDuration(widget.message.content ?? '');
      _controller.forward(from: 0);
    }
  }

  Duration _calculateDuration(String text) {
    // 30ms per character, min 300ms, max 3 seconds
    final charDuration = (text.length * 30).clamp(300, 3000);
    return Duration(milliseconds: charDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final textColor = widget.message.isFromMe
        ? Colors.white
        : (widget.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary);

    final content = widget.message.content ?? '';
    final displayContent = _shouldAnimate && _controller.isAnimating
        ? _getPartialContent(content, _controller.value)
        : content;

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
                  backgroundColor: widget.message.isFromMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : (widget.isDarkMode ? Colors.grey[600] : Colors.grey[200]),
                  fontSize: 14 * fontSize.scale,
                ),
                codeblockDecoration: BoxDecoration(
                  color: widget.isDarkMode ? AppColors.surfaceDark : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (_shouldAnimate && _controller.isAnimating)
            _BlinkingCursor(color: textColor),
        ],
      ),
    );
  }

  String _getPartialContent(String fullContent, double progress) {
    if (fullContent.isEmpty) return '';
    final charCount = (fullContent.length * progress).ceil().clamp(1, fullContent.length);
    return fullContent.substring(0, charCount);
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
