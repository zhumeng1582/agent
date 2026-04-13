import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/services/api_service.dart';

final ttsProvider = StateNotifierProvider<TTSNotifier, TTSState>((ref) {
  return TTSNotifier();
});

class TTSState {
  final bool isPlaying;
  final String? playingMessageId;
  final String? error;

  TTSState({this.isPlaying = false, this.playingMessageId, this.error});

  TTSState copyWith({bool? isPlaying, String? playingMessageId, String? error}) {
    return TTSState(
      isPlaying: isPlaying ?? this.isPlaying,
      playingMessageId: playingMessageId,
      error: error,
    );
  }
}

class TTSNotifier extends StateNotifier<TTSState> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  TTSNotifier() : super(TTSState()) {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        state = TTSState();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<String> speak(String messageId, String text) async {
    if (state.isPlaying) {
      await stop();
    }

    state = TTSState(isPlaying: true, playingMessageId: messageId);

    try {
      final response = await ApiService.textToSpeech(text);
      if (!response.success) {
        state = TTSState(error: response.error ?? '语音合成失败');
        return response.error ?? '语音合成失败';
      }

      final bytes = response.data?['bytes'];
      if (bytes == null || bytes is! List<int>) {
        state = TTSState(error: '语音数据无效');
        return '语音数据无效';
      }

      // Save to temp file and play
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/tts_$messageId.mp3';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      debugPrint('TTS file saved: $filePath, size: ${bytes.length}');

      await _audioPlayer.play(DeviceFileSource(filePath));
      return '播放中';
    } catch (e) {
      debugPrint('TTS播放异常: $e');
      state = TTSState(error: '播放失败: $e');
      return '播放失败: $e';
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    state = TTSState();
  }
}
