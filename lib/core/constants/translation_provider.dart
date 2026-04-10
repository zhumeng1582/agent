import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/minimax_service.dart';
import 'app_config.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

class TranslationService {
  final _service = MiniMaxService(AppConfig.minimaxApiKey);

  Future<String> translate(String text, {String targetLang = '中文'}) async {
    try {
      final prompt = 'Translate the following text to $targetLang. Only output the translation, nothing else.\n\nText: $text';
      final result = await _service.chat(prompt);
      return result.trim();
    } catch (e) {
      return 'Translation failed: $e';
    }
  }
}
