import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

class TranslationService {
  Future<String> translate(String text, {String targetLang = 'Chinese'}) async {
    if (text.isEmpty) return '';

    try {
      final response = await ApiService.translate(text, targetLang: targetLang);
      if (response.success && response.data != null) {
        return response.data['translated_text'] as String? ?? text;
      }
      return '翻译失败: ${response.error}';
    } catch (e) {
      return '翻译失败: $e';
    }
  }
}
