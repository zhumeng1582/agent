import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int dailyLimit = 100;

final usageProvider = StateNotifierProvider<UsageNotifier, UsageState>((ref) {
  return UsageNotifier();
});

class UsageState {
  final int usedToday;
  final String lastUsedDate;

  UsageState({required this.usedToday, required this.lastUsedDate});

  int get remaining => dailyLimit - usedToday;
  bool get isLimited => remaining <= 0;
}

class UsageNotifier extends StateNotifier<UsageState> {
  UsageNotifier() : super(UsageState(usedToday: 0, lastUsedDate: '')) {
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final lastDate = prefs.getString('last_used_date') ?? '';
    final used = prefs.getInt('used_today') ?? 0;

    if (lastDate != today) {
      // New day, reset count
      await prefs.setString('last_used_date', today);
      await prefs.setInt('used_today', 0);
      state = UsageState(usedToday: 0, lastUsedDate: today);
    } else {
      state = UsageState(usedToday: used, lastUsedDate: today);
    }
  }

  Future<bool> tryUse() async {
    await _loadUsage();

    if (state.isLimited) {
      return false;
    }

    final today = _getTodayString();
    final newUsed = state.usedToday + 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_used_date', today);
    await prefs.setInt('used_today', newUsed);

    state = UsageState(usedToday: newUsed, lastUsedDate: today);
    return true;
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    await prefs.setString('last_used_date', today);
    await prefs.setInt('used_today', 0);
    state = UsageState(usedToday: 0, lastUsedDate: today);
  }
}
