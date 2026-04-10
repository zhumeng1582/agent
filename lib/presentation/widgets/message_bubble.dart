import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/message.dart';
import 'text_message.dart';
import 'image_message.dart';
import 'voice_message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isDarkMode;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final Function(String)? onForward;

  const MessageBubble({
    super.key,
    required this.message,
    this.isDarkMode = false,
    this.onReply,
    this.onDelete,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final isFromMe = message.isFromMe;

    return GestureDetector(
      onLongPress: () => _showMessageMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment:
              isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender name
            Text(
              isFromMe ? '我' : 'AI助手',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment:
                  isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isFromMe) ...[
                  _buildAvatar(isFromMe: false),
                  const SizedBox(width: 8),
                ],
                Column(
                  crossAxisAlignment:
                      isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (message.replyToContent != null) _buildReplyQuote(),
                    _buildMessageContent(),
                    const SizedBox(height: 4),
                    Text(
                      timeFormat.format(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isFromMe) ...[
                  const SizedBox(width: 8),
                  _buildAvatar(isFromMe: true),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyQuote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 250),
      child: Text(
        message.replyPreview,
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (message.type == MessageType.text) _buildMenuItem(
              icon: Icons.copy,
              title: '复制',
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content ?? ''));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制到剪贴板')),
                );
              },
            ),
            if (message.type == MessageType.image) _buildMenuItem(
              icon: Icons.copy,
              title: '复制图片',
              onTap: () => _copyImage(context),
            ),
            _buildMenuItem(
              icon: Icons.reply,
              title: '引用回复',
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            _buildMenuItem(
              icon: Icons.delete_outline,
              title: '删除',
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
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
  }) {
    return ListTile(
      leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.black),
      title: Text(
        title,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      onTap: onTap,
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
          const SnackBar(content: Text('图片路径已复制到剪贴板')),
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
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isFromMe}) {
    if (isFromMe) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      );
    } else {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
      );
    }
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return TextMessage(message: message, isDarkMode: isDarkMode);
      case MessageType.image:
        return ImageMessage(message: message);
      case MessageType.voice:
        return VoiceMessage(message: message, isDarkMode: isDarkMode);
    }
  }
}
