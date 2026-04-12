import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/utils/permission_utils.dart';
import '../../data/models/message.dart';
import '../providers/chat_provider.dart';

class InputBar extends ConsumerStatefulWidget {
  final String chatId;
  final bool isTempChat;
  final Locale locale;
  final VoidCallback? onFirstMessageSent;
  final Message? replyToMessage;
  final VoidCallback? onCancelReply;

  const InputBar({
    super.key,
    required this.chatId,
    this.isTempChat = false,
    required this.locale,
    this.onFirstMessageSent,
    this.replyToMessage,
    this.onCancelReply,
  });

  @override
  ConsumerState<InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<InputBar> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isRecording = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _t(String key) {
    final Map<String, Map<String, String>> translations = {
      'photoLibraryPermission': {'en': 'Photo library permission required', 'zh': '需要相册权限来选择图片', 'zh_TW': '需要相簿權限來選擇圖片'},
      'macOSNoCamera': {'en': 'Camera not supported on macOS', 'zh': 'macOS 暂不支持拍照', 'zh_TW': 'macOS 暫不支援拍照'},
      'cameraPermission': {'en': 'Camera permission required', 'zh': '需要相机权限来拍照', 'zh_TW': '需要相機權限來拍照'},
      'macOSNoVoice': {'en': 'Voice recording not supported on macOS', 'zh': 'macOS 暂不支持语音录制', 'zh_TW': 'macOS 暫不支援語音錄製'},
      'microphonePermission': {'en': 'Microphone permission required', 'zh': '需要麦克风权限来录制语音', 'zh_TW': '需要麥克風權限來錄製語音'},
      'recording': {'en': 'Recording...', 'zh': '正在录音...', 'zh_TW': '正在錄音...'},
      'typeMessage': {'en': 'Type a message...', 'zh': '输入消息...', 'zh_TW': '輸入消息...'},
      'holdToTalk': {'en': 'Hold to talk', 'zh': '按住说话', 'zh_TW': '按住說話'},
      'slideToCancel': {'en': 'Slide to cancel', 'zh': '滑动取消', 'zh_TW': '滑動取消'},
    };

    final localeKey = widget.locale.countryCode != null ? '${widget.locale.languageCode}_${widget.locale.countryCode}' : widget.locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }

  void _ensureChatCreated() {
    if (widget.isTempChat && widget.onFirstMessageSent != null) {
      widget.onFirstMessageSent!();
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _ensureChatCreated();

    final replyToId = widget.replyToMessage?.id;
    final replyToContent = widget.replyToMessage?.content;

    _textController.clear();
    _focusNode.unfocus();
    widget.onCancelReply?.call();
    await ref.read(messagesProvider(widget.chatId).notifier).sendTextMessage(
      text,
      replyToId: replyToId,
      replyToContent: replyToContent,
    );
  }

  Future<void> _pickImage() async {
    final hasPermission = await PermissionUtils.requestPhotoLibrary();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('photoLibraryPermission'))),
        );
      }
      return;
    }

    _ensureChatCreated();

    final imageService = ref.read(imageServiceProvider);
    final imagePath = await imageService.pickFromGallery();
    if (imagePath != null) {
      final replyToId = widget.replyToMessage?.id;
      final replyToContent = widget.replyToMessage?.content;
      widget.onCancelReply?.call();
      await ref.read(messagesProvider(widget.chatId).notifier).sendImageMessage(
        imagePath,
        replyToId: replyToId,
        replyToContent: replyToContent,
      );
    }
  }

  Future<void> _takePhoto() async {
    if (Platform.isMacOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('macOSNoCamera'))),
      );
      return;
    }

    final hasPermission = await PermissionUtils.requestCamera();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('cameraPermission'))),
        );
      }
      return;
    }

    _ensureChatCreated();

    final imageService = ref.read(imageServiceProvider);
    final imagePath = await imageService.pickFromCamera();
    if (imagePath != null) {
      final replyToId = widget.replyToMessage?.id;
      final replyToContent = widget.replyToMessage?.content;
      widget.onCancelReply?.call();
      await ref.read(messagesProvider(widget.chatId).notifier).sendImageMessage(
        imagePath,
        replyToId: replyToId,
        replyToContent: replyToContent,
      );
    }
  }

  Future<void> _startRecording() async {
    if (Platform.isMacOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('macOSNoVoice'))),
      );
      return;
    }

    final hasPermission = await PermissionUtils.requestMicrophone();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('microphonePermission'))),
        );
      }
      return;
    }

    final audioService = ref.read(audioServiceProvider);
    final path = await audioService.startRecording();
    if (path != null) {
      setState(() => _isRecording = true);
      ref.read(isRecordingProvider.notifier).state = true;
      ref.read(recordingPathProvider.notifier).state = path;
    }
  }

  Future<void> _stopRecording() async {
    final audioService = ref.read(audioServiceProvider);
    final path = await audioService.stopRecording();
    setState(() => _isRecording = false);
    ref.read(isRecordingProvider.notifier).state = false;
    ref.read(recordingPathProvider.notifier).state = null;

    if (path != null) {
      _ensureChatCreated();
      final replyToId = widget.replyToMessage?.id;
      final replyToContent = widget.replyToMessage?.content;
      widget.onCancelReply?.call();
      await ref.read(messagesProvider(widget.chatId).notifier).sendVoiceMessage(
        path,
        replyToId: replyToId,
        replyToContent: replyToContent,
      );
    }
  }

  Future<void> _cancelRecording() async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.cancelRecording();
    setState(() => _isRecording = false);
    ref.read(isRecordingProvider.notifier).state = false;
    ref.read(recordingPathProvider.notifier).state = null;
  }

  void _showMoreOptions() {
    final themeMode = ref.read(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton(
                  icon: Icons.photo_library_rounded,
                  label: '相册',
                  color: AppColors.primary,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _buildOptionButton(
                  icon: Icons.camera_alt_rounded,
                  label: '拍照',
                  color: AppColors.secondary,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.inputBackgroundDark : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _t('cancel'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording) _buildRecordingIndicator(isDarkMode),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // More options button (+)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.inputBackgroundDark
                      : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.add_rounded,
                    color: isDarkMode ? Colors.white : AppColors.textSecondary,
                    size: 24,
                  ),
                  onPressed: _showMoreOptions,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 8),
              // Text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.inputBackgroundDark
                        : AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode
                          ? AppColors.inputBorderDark
                          : AppColors.inputBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : AppColors.textPrimary,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: _t('typeMessage'),
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[500] : AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendText(),
                          maxLines: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send or Mic button
              _hasText
                  ? _buildSendButton()
                  : _buildMicButton(isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        onPressed: _sendText,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMicButton(bool isDarkMode) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.inputBackgroundDark : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          Icons.mic_rounded,
          color: AppColors.primary,
          size: 22,
        ),
        onPressed: _startRecording,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildRecordingIndicator(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _t('recording'),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _t('slideToCancel'),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
