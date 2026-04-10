import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final nicknameProvider = StateNotifierProvider<NicknameNotifier, String>((ref) {
  return NicknameNotifier();
});

class NicknameNotifier extends StateNotifier<String> {
  NicknameNotifier() : super('用户') {
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('user_nickname') ?? '用户';
  }

  Future<void> setNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nickname', nickname);
    state = nickname;
  }
}
