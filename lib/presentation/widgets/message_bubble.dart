import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/tts_provider.dart';
import '../../core/constants/translation_state_provider.dart';
import '../../core/constants/font_size_provider.dart';
import '../../data/models/message.dart';
import 'text_message.dart';
import 'image_message.dart';
import 'voice_message.dart';
import 'video_message.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isDarkMode;
  final bool showDate;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final VoidCallback? onTranslate;

  const MessageBubble({
    super.key,
    required this.message,
    this.isDarkMode = false,
    this.showDate = false,
    this.onReply,
    this.onDelete,
    this.onFavorite,
    this.onTranslate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('HH:mm');
    final isFromMe = message.isFromMe;
    final fontSize = ref.watch(fontSizeProvider);

    return Column(
      children: [
        // Date separator
        if (showDate)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.surfaceDark.withValues(alpha: 0.8)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(message.timestamp),
              style: TextStyle(
                fontSize: 12.0 * fontSize.scale,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Message bubble
        GestureDetector(
          onLongPress: () => _showMessageMenu(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment:
                  isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment:
                        isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Reply quote
                      if (message.replyToContent != null) _buildReplyQuote(fontSize),
                      // Message content with bubble
                      _buildBubble(context, isFromMe),
                      const SizedBox(height: 4),
                      // Timestamp, status, TTS button and favorite
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeFormat.format(message.timestamp),
                            style: TextStyle(
                              fontSize: 11.0 * fontSize.scale,
                              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          if (isFromMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: AppColors.primary.withValues(alpha: 0.7),
                            ),
                          ],
                          if (!isFromMe && message.type == MessageType.text) ...[
                            const SizedBox(width: 8),
                            _buildTTSButton(context, ref),
                          ],
                          if (message.isFavorite) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onFavorite,
                              child: Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Translation display
                      _buildTranslationDisplay(ref),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(BuildContext context, bool isFromMe) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      decoration: BoxDecoration(
        gradient: isFromMe
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isFromMe ? null : (isDarkMode ? AppColors.receivedBubbleDark : AppColors.receivedBubble),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isFromMe ? 18 : 4),
          bottomRight: Radius.circular(isFromMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: (isFromMe ? AppColors.primary : Colors.black).withValues(alpha: isFromMe ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildMessageContent(),
    );
  }

  Widget _buildTranslationDisplay(WidgetRef ref) {
    final isLoading = ref.watch(translationLoadingProvider).contains(message.id);
    final fontSize = ref.watch(fontSizeProvider);

    if (isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppColors.surfaceDark.withValues(alpha: 0.6)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '翻译中...',
              style: TextStyle(
                fontSize: 12.0 * fontSize.scale,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (message.translatedContent != null && message.translatedContent!.isNotEmpty) {
      return GestureDetector(
        onLongPress: () {
          onTranslate?.call();
        },
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.surfaceDark.withValues(alpha: 0.6)
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
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildReplyQuote(FontSizeState fontSize) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.surfaceDark.withValues(alpha: 0.5)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 280),
      child: Text(
        message.replyPreview,
        style: TextStyle(
          fontSize: 13.0 * fontSize.scale,
          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (message.type == MessageType.text)
              _buildMenuItem(
                icon: Icons.copy_rounded,
                title: '复制',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content ?? ''));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('已复制到剪贴板'),
                      backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[800],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
              ),
            if (message.type == MessageType.image)
              _buildMenuItem(
                icon: Icons.copy_rounded,
                title: '复制图片',
                onTap: () => _copyImage(context),
              ),
            _buildMenuItem(
              icon: Icons.reply_rounded,
              title: '引用回复',
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            _buildMenuItem(
              icon: message.isFavorite ? Icons.star : Icons.star_border,
              title: message.isFavorite ? '取消收藏' : '收藏',
              onTap: () {
                Navigator.pop(context);
                onFavorite?.call();
              },
            ),
            if (message.type == MessageType.text)
              _buildMenuItem(
                icon: Icons.translate,
                title: '翻译',
                onTap: () {
                  Navigator.pop(context);
                  onTranslate?.call();
                },
              ),
            _buildMenuItem(
              icon: Icons.delete_outline_rounded,
              title: '删除',
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
              isDestructive: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red
            : (isDarkMode ? Colors.white : Colors.black),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? Colors.red
              : (isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Future<void> _copyImage(BuildContext context) async {
    if (message.mediaPath == null) return;

    try {
      final file = File(message.mediaPath!);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片文件不存在')),
          );
        }
        return;
      }

      await Clipboard.setData(ClipboardData(text: message.mediaPath!));

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('图片路径已复制到剪贴板'),
            backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[800],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('复制失败: $e')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除这条消息吗？'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '今天';
    } else if (messageDate == yesterday) {
      return '昨天';
    } else {
      return DateFormat('MM月dd日').format(date);
    }
  }

  Widget _buildTTSButton(BuildContext context, WidgetRef ref) {
    final ttsState = ref.watch(ttsProvider);
    final isPlaying = ttsState.isPlaying && ttsState.playingMessageId == message.id;
    final hasError = ttsState.error != null && ttsState.playingMessageId == message.id;

    return GestureDetector(
      onTap: () async {
        if (isPlaying) {
          ref.read(ttsProvider.notifier).stop();
        } else {
          final result = await ref.read(ttsProvider.notifier).speak(message.id, message.content ?? '');
          if (result != '播放中' && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result),
                duration: const Duration(seconds: 2),
                backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[800],
              ),
            );
          }
        }
      },
      child: Icon(
        isPlaying ? Icons.stop_circle : (hasError ? Icons.error_outline : Icons.volume_up),
        size: 16,
        color: isPlaying
            ? AppColors.primary
            : (hasError
                ? Colors.red
                : (isDarkMode ? Colors.grey[500] : Colors.grey[400])),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return TextMessage(message: message, isDarkMode: isDarkMode);
      case MessageType.image:
        return ImageMessage(message: message);
      case MessageType.voice:
        return VoiceMessage(message: message, isDarkMode: isDarkMode);
      case MessageType.video:
        return VideoMessage(message: message);
    }
  }
}
