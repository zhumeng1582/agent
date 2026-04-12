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

class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final bool isDarkMode;
  final bool showDate;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final VoidCallback? onTranslate;
  final Function(Message)? onFollowUp;

  const MessageBubble({
    super.key,
    required this.message,
    this.isDarkMode = false,
    this.showDate = false,
    this.onReply,
    this.onDelete,
    this.onFavorite,
    this.onTranslate,
    this.onFollowUp,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isMenuVisible = false;
  bool _isSelectionMode = false;
  String? _selectedText;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isMenuVisible = false;
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedText = null;
    });
  }

  void _copySelectedText() {
    if (_selectedText != null && _selectedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _selectedText!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已复制到剪贴板'),
          backgroundColor: widget.isDarkMode ? Colors.grey[700] : Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    _exitSelectionMode();
  }

  void _showFloatingMenu(BuildContext context) {
    if (_isMenuVisible) {
      _removeOverlay();
      return;
    }

    _removeOverlay();

    // Calculate if message is in lower half of screen
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    bool showMenuAbove = true;
    if (renderBox != null) {
      final messagePosition = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;
      // If message is in lower 40% of screen, show menu above
      showMenuAbove = messagePosition.dy > screenHeight * 0.4;
    }

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => _FloatingMessageMenu(
        message: widget.message,
        isDarkMode: widget.isDarkMode,
        layerLink: _layerLink,
        showMenuAbove: showMenuAbove,
        onDismiss: _removeOverlay,
        onReply: () {
          _removeOverlay();
          widget.onReply?.call();
        },
        onCopy: () {
          Clipboard.setData(ClipboardData(text: widget.message.content ?? ''));
          _removeOverlay();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('已复制到剪贴板'),
              backgroundColor: widget.isDarkMode ? Colors.grey[700] : Colors.grey[800],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
        onFavorite: () {
          _removeOverlay();
          widget.onFavorite?.call();
        },
        onTranslate: () {
          _removeOverlay();
          widget.onTranslate?.call();
        },
        onDelete: () {
          _removeOverlay();
          _confirmDelete(context);
        },
        onFollowUp: () {
          _removeOverlay();
          widget.onFollowUp?.call(widget.message);
        },
        onSelectText: () {
          _removeOverlay();
          setState(() {
            _isSelectionMode = true;
          });
        },
      ),
    );

    _isMenuVisible = true;
    overlay.insert(_overlayEntry!);
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
              widget.onDelete?.call();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final isFromMe = widget.message.isFromMe;
    final fontSize = ref.watch(fontSizeProvider);

    return Column(
      children: [
        // Date separator
        if (widget.showDate)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? AppColors.surfaceDark.withValues(alpha: 0.8)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(widget.message.timestamp),
              style: TextStyle(
                fontSize: 12.0 * fontSize.scale,
                color: widget.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Message bubble
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onLongPress: () => _showFloatingMenu(context),
            onSecondaryTap: () => _showFloatingMenu(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              width: double.infinity,
              child: Column(
                crossAxisAlignment:
                    isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Reply quote
                  if (widget.message.replyToContent != null) _buildReplyQuote(fontSize),
                  // Message content with bubble
                  _buildBubble(context, isFromMe),
                  const SizedBox(height: 4),
                  // Timestamp, status, TTS button and favorite
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeFormat.format(widget.message.timestamp),
                        style: TextStyle(
                          fontSize: 11.0 * fontSize.scale,
                          color: widget.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
                      if (!isFromMe && widget.message.type == MessageType.text) ...[
                        const SizedBox(width: 8),
                        _buildTTSButton(context, ref),
                      ],
                      if (widget.message.isFavorite) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onFavorite,
                          child: const Icon(
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
                  // Selection mode floating toolbar
                  if (_isSelectionMode && _selectedText != null && _selectedText!.isNotEmpty)
                    _buildSelectionToolbar(fontSize),
                  // Exit selection mode hint
                  if (_isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: _exitSelectionMode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode
                                ? AppColors.surfaceDark.withValues(alpha: 0.9)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '点击任意处退出选取',
                            style: TextStyle(
                              fontSize: 12 * fontSize.scale,
                              color: widget.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionToolbar(FontSizeState fontSize) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '已选择 ${_selectedText!.length} 字符',
            style: TextStyle(
              fontSize: 13 * fontSize.scale,
              color: widget.isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _copySelectedText,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '复制',
                style: TextStyle(
                  fontSize: 13 * fontSize.scale,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isFromMe) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      decoration: BoxDecoration(
        gradient: isFromMe
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isFromMe ? null : (widget.isDarkMode ? AppColors.receivedBubbleDark : AppColors.receivedBubble),
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
    final isLoading = ref.watch(translationLoadingProvider).contains(widget.message.id);
    final fontSize = ref.watch(fontSizeProvider);

    if (isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isDarkMode
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
                color: widget.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.message.translatedContent != null && widget.message.translatedContent!.isNotEmpty) {
      return GestureDetector(
        onLongPress: () {
          widget.onTranslate?.call();
        },
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? AppColors.surfaceDark.withValues(alpha: 0.6)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.message.translatedContent!,
            style: TextStyle(
              fontSize: 13.0 * fontSize.scale,
              color: widget.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
        color: widget.isDarkMode
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
        widget.message.replyPreview,
        style: TextStyle(
          fontSize: 13.0 * fontSize.scale,
          color: widget.isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTTSButton(BuildContext context, WidgetRef ref) {
    final ttsState = ref.watch(ttsProvider);
    final isPlaying = ttsState.isPlaying && ttsState.playingMessageId == widget.message.id;
    final hasError = ttsState.error != null && ttsState.playingMessageId == widget.message.id;

    return GestureDetector(
      onTap: () async {
        if (isPlaying) {
          ref.read(ttsProvider.notifier).stop();
        } else {
          final result = await ref.read(ttsProvider.notifier).speak(widget.message.id, widget.message.content ?? '');
          if (result != '播放中' && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result),
                duration: const Duration(seconds: 2),
                backgroundColor: widget.isDarkMode ? Colors.grey[700] : Colors.grey[800],
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
                : (widget.isDarkMode ? Colors.grey[500] : Colors.grey[400])),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return TextMessage(
          message: widget.message,
          isDarkMode: widget.isDarkMode,
          selectionEnabled: _isSelectionMode,
          onSelectionChanged: (text) {
            setState(() {
              _selectedText = text;
            });
          },
        );
      case MessageType.image:
        return ImageMessage(message: widget.message);
      case MessageType.voice:
        return VoiceMessage(message: widget.message, isDarkMode: widget.isDarkMode);
      case MessageType.video:
        return VideoMessage(message: widget.message);
    }
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
}

class _FloatingMessageMenu extends StatelessWidget {
  final Message message;
  final bool isDarkMode;
  final LayerLink layerLink;
  final bool showMenuAbove;
  final VoidCallback onDismiss;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;
  final VoidCallback onTranslate;
  final VoidCallback onDelete;
  final VoidCallback onFollowUp;
  final VoidCallback onSelectText;

  const _FloatingMessageMenu({
    required this.message,
    required this.isDarkMode,
    required this.layerLink,
    required this.showMenuAbove,
    required this.onDismiss,
    required this.onReply,
    required this.onCopy,
    required this.onFavorite,
    required this.onTranslate,
    required this.onDelete,
    required this.onFollowUp,
    required this.onSelectText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            onSecondaryTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu
        Positioned(
          width: 200,
          child: CompositedTransformFollower(
            link: layerLink,
            targetAnchor: showMenuAbove ? Alignment.bottomRight : Alignment.topRight,
            followerAnchor: showMenuAbove ? Alignment.topRight : Alignment.bottomRight,
            offset: showMenuAbove ? const Offset(0, -8) : const Offset(0, 8),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: isDarkMode ? AppColors.surfaceDark : Colors.white,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.type == MessageType.text) ...[
                      _buildMenuItem(
                        icon: Icons.text_fields,
                        title: '选取文字',
                        onTap: onSelectText,
                      ),
                      _buildMenuItem(
                        icon: Icons.copy_rounded,
                        title: '复制',
                        onTap: onCopy,
                      ),
                    ],
                    if (message.type == MessageType.image)
                      _buildMenuItem(
                        icon: Icons.copy_rounded,
                        title: '复制图片',
                        onTap: onCopy,
                      ),
                    _buildMenuItem(
                      icon: Icons.reply_rounded,
                      title: '引用回复',
                      onTap: onReply,
                    ),
                    if (message.type == MessageType.text)
                      _buildMenuItem(
                        icon: Icons.add_circle_outline,
                        title: '创建新对话',
                        onTap: onFollowUp,
                      ),
                    _buildMenuItem(
                      icon: message.isFavorite ? Icons.star : Icons.star_border,
                      title: message.isFavorite ? '取消收藏' : '收藏',
                      onTap: onFavorite,
                    ),
                    if (message.type == MessageType.text)
                      _buildMenuItem(
                        icon: Icons.translate,
                        title: '翻译',
                        onTap: onTranslate,
                      ),
                    _buildMenuItem(
                      icon: Icons.delete_outline_rounded,
                      title: '删除',
                      onTap: onDelete,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? Colors.red
                  : (isDarkMode ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isDestructive
                    ? Colors.red
                    : (isDarkMode ? Colors.white : AppColors.textPrimary),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
