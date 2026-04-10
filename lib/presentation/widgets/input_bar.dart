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
  bool _isRecording = false;

  @override
  void dispose() {
    _textController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording) _buildRecordingIndicator(isDarkMode),
            Row(
              children: [
                _buildMediaButton(icon: Icons.image, onTap: _pickImage, isDarkMode: isDarkMode),
                _buildMediaButton(icon: Icons.camera_alt, onTap: _takePhoto, isDarkMode: isDarkMode),
                Expanded(child: _buildTextField(isDarkMode)),
                const SizedBox(width: 8),
                _isRecording ? _buildRecordingControls(isDarkMode) : _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          const SizedBox(width: 8),
          Text(
            _t('recording'),
            style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({required IconData icon, required VoidCallback onTap, required bool isDarkMode}) {
    return IconButton(
      icon: Icon(icon, color: AppColors.primary),
      onPressed: onTap,
    );
  }

  Widget _buildTextField(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _textController,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: _t('typeMessage'),
          hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _sendText(),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.mic, color: Colors.white),
        onPressed: _startRecording,
      ),
    );
  }

  Widget _buildRecordingControls(bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _cancelRecording,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _stopRecording,
          ),
        ),
      ],
    );
  }
}
