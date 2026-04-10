import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _isListening = false;
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  Future<String> listenAndTranscribe() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      throw Exception('Speech recognition not available');
    }

    _isListening = true;
    String result = '';

    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult speechResult) {
          result = speechResult.recognizedWords;
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'zh_CN',
      );

      // Wait for listening to complete
      while (_isListening && _speechToText.isListening) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      // Ignore
    }

    return result;
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  bool get isListening => _speechToText.isListening;

  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }
}
