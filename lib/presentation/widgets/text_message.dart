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
  String _displayContent = '';
  Timer? _timer;
  int _charIndex = 0;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _initStreaming();
  }

  void _initStreaming() {
    _isStreaming = widget.message.isStreaming ?? false;
    _displayContent = widget.message.content ?? '';

    if (_isStreaming && _displayContent.isNotEmpty) {
      _startTypewriterAnimation();
    }
  }

  void _startTypewriterAnimation() {
    _charIndex = 0;
    _displayContent = '';

    // Show first character immediately
    setState(() {
      _displayContent = widget.message.content?.substring(0, 1) ?? '';
      _charIndex = 1;
    });

    // Then add remaining characters
    final remaining = (widget.message.content?.length ?? 1) - 1;
    if (remaining > 0) {
      _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        if (_charIndex >= (widget.message.content?.length ?? 0)) {
          timer.cancel();
          return;
        }

        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _charIndex++;
          _displayContent = widget.message.content?.substring(0, _charIndex) ?? '';
        });
      });
    }
  }

  @override
  void didUpdateWidget(TextMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // New streaming message
    if (widget.message.isStreaming == true &&
        oldWidget.message.content != widget.message.content) {
      _timer?.cancel();
      _initStreaming();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = ref.watch(fontSizeProvider);
    final textColor = widget.message.isFromMe
        ? Colors.white
        : (widget.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary);

    final content = _displayContent.isEmpty ? (widget.message.content ?? '') : _displayContent;
    final showCursor = (_isStreaming || widget.message.isStreaming == true) &&
        _charIndex < (widget.message.content?.length ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
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
            Container(
              width: 2,
              height: 16,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}
