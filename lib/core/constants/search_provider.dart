import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _load();
  }

  static const int maxHistory = 10;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('search_history') ?? [];
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    final trimmed = query.trim();
    final newState = [trimmed, ...state.where((e) => e != trimmed)];
    if (newState.length > maxHistory) {
      state = newState.sublist(0, maxHistory);
    } else {
      state = newState;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', state);
  }

  Future<void> removeSearch(String query) async {
    state = state.where((e) => e != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', state);
  }

  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }
}
