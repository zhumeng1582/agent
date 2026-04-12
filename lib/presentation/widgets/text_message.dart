import 'dart:async';
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

class _TextMessageState extends ConsumerState<TextMessage> {
  String _displayText = '';
  Timer? _timer;
  int _charIndex = 0;
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _initAnimation();
  }

  void _initAnimation() {
    final content = widget.message.content ?? '';
    final isStreaming = widget.message.isStreaming ?? false;

    if (isStreaming && content.isNotEmpty) {
      _displayText = content.substring(0, 1);
      _charIndex = 1;

      if (content.length > 1) {
        _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
          if (!_mounted) {
            timer.cancel();
            return;
          }
          if (_charIndex >= content.length) {
            timer.cancel();
            setState(() {});
            return;
          }

          setState(() {
            _charIndex++;
            _displayText = content.substring(0, _charIndex);
          });
        });
      }
    } else {
      _displayText = content;
    }
  }

  @override
  void didUpdateWidget(TextMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // New streaming message - restart animation
    if (widget.message.isStreaming == true &&
        oldWidget.message.content != widget.message.content) {
      _timer?.cancel();
      _initAnimation();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final textColor = widget.message.isFromMe
        ? Colors.white
        : (widget.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary);

    final content = widget.message.content ?? '';
    final isStreaming = widget.message.isStreaming ?? false;
    final displayContent = isStreaming ? _displayText : content;
    final showCursor = isStreaming && _charIndex < content.length;

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
          if (showCursor)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Container(
                width: 2,
                height: 16,
                decoration: BoxDecoration(
                  color: textColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
