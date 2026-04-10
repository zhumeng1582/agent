import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/services/minimax_service.dart';
import 'app_config.dart';

List<int> _hexDecode(String hexString) {
  final result = <int>[];
  for (int i = 0; i < hexString.length; i += 2) {
    result.add(int.parse(hexString.substring(i, i + 2), radix: 16));
  }
  return result;
}

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
      final service = MiniMaxService(AppConfig.minimaxApiKey);
      final base64Audio = await service.textToSpeech(text);

      debugPrint('TTS returned: "$base64Audio"');

      if (base64Audio.isEmpty) {
        state = TTSState(error: '语音合成失败');
        return '语音合成失败';
      }

      debugPrint('TTS audio length: ${base64Audio.length}');

      // Decode hex and save to temp file
      final tempDir = await getTemporaryDirectory();
      final audioBytes = _hexDecode(base64Audio);
      final filePath = '${tempDir.path}/tts_$messageId.mp3';
      final file = File(filePath);
      await file.writeAsBytes(audioBytes);
      debugPrint('TTS file saved: $filePath, size: ${audioBytes.length}');
      // Print first few bytes to help debug format
      debugPrint('First bytes: ${audioBytes.take(16).map((b) => b.toRadixString(16)).join(' ')}');
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
