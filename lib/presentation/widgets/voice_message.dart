import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/message.dart';
import '../../data/services/speech_service.dart';
import '../providers/chat_provider.dart';

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

class VoiceMessage extends ConsumerStatefulWidget {
  final Message message;
  final bool isDarkMode;

  const VoiceMessage({
    super.key,
    required this.message,
    this.isDarkMode = false,
  });

  @override
  ConsumerState<VoiceMessage> createState() => _VoiceMessageState();
}

class _VoiceMessageState extends ConsumerState<VoiceMessage> {
  bool _isTranscribing = false;
  String? _transcription;
  bool _showTranscription = false;

  Future<void> _transcribe() async {
    if (widget.message.mediaPath == null) return;

    setState(() {
      _isTranscribing = true;
    });

    try {
      final speechService = ref.read(speechServiceProvider);
      final result = await speechService.listenAndTranscribe();
      setState(() {
        _transcription = result;
        _showTranscription = true;
        _isTranscribing = false;
      });
    } catch (e) {
      setState(() {
        _isTranscribing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('语音识别失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(isPlayingProvider);
    final playingPath = ref.watch(playingPathProvider);
    final audioService = ref.read(audioServiceProvider);

    final isThisPlaying = isPlaying && playingPath == widget.message.mediaPath;

    final bubbleColor = widget.message.isFromMe
        ? AppColors.primary
        : (widget.isDarkMode ? Colors.grey[700] : AppColors.receivedBubble);
    final textColor = widget.message.isFromMe ? Colors.white : (widget.isDarkMode ? Colors.white : Colors.black);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: _transcribe,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(widget.message.isFromMe ? 20 : 4),
                bottomRight: Radius.circular(widget.message.isFromMe ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isTranscribing)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () async {
                      if (widget.message.mediaPath == null) return;

                      if (isThisPlaying) {
                        await audioService.stopPlayback();
                        ref.read(isPlayingProvider.notifier).state = false;
                        ref.read(playingPathProvider.notifier).state = null;
                      } else {
                        await audioService.playAudio(widget.message.mediaPath!);
                        ref.read(isPlayingProvider.notifier).state = true;
                        ref.read(playingPathProvider.notifier).state = widget.message.mediaPath;
                      }
                    },
                    child: Icon(
                      isThisPlaying ? Icons.pause : Icons.play_arrow,
                      color: textColor,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.mic,
                  color: textColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_showTranscription && _transcription != null)
          Container(
            margin: const EdgeInsets.only(top: 4, left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.grey[700]!.withValues(alpha: 0.5) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.text_fields,
                  size: 14,
                  color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _transcription!,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
