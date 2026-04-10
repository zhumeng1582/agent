import 'package:flutter_riverpod/flutter_riverpod.dart';

final translationLoadingProvider = StateNotifierProvider<TranslationLoadingNotifier, Set<String>>((ref) {
  return TranslationLoadingNotifier();
});

class TranslationLoadingNotifier extends StateNotifier<Set<String>> {
  TranslationLoadingNotifier() : super({});

  void setLoading(String messageId, bool loading) {
    if (loading) {
      state = {...state, messageId};
    } else {
      state = state.where((id) => id != messageId).toSet();
    }
  }

  bool isLoading(String messageId) => state.contains(messageId);
}
