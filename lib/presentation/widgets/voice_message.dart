import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/message.dart';
import '../providers/chat_provider.dart';

class VoiceMessage extends ConsumerWidget {
  final Message message;
  final bool isDarkMode;

  const VoiceMessage({
    super.key,
    required this.message,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final playingPath = ref.watch(playingPathProvider);
    final audioService = ref.read(audioServiceProvider);

    final isThisPlaying = isPlaying && playingPath == message.mediaPath;

    final textColor = message.isFromMe
        ? Colors.white
        : (isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return GestureDetector(
      onTap: () async {
        if (message.mediaPath == null) return;

        if (isThisPlaying) {
          await audioService.stopPlayback();
          ref.read(isPlayingProvider.notifier).state = false;
          ref.read(playingPathProvider.notifier).state = null;
        } else {
          await audioService.playAudio(message.mediaPath!);
          ref.read(isPlayingProvider.notifier).state = true;
          ref.read(playingPathProvider.notifier).state = message.mediaPath;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: message.isFromMe
                    ? const LinearGradient(
                        colors: [Colors.white, Colors.white],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.1),
                        ],
                      ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: message.isFromMe ? AppColors.primary : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.mic_rounded,
              color: textColor.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
