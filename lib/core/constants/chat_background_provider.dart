import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final chatBackgroundProvider = StateNotifierProvider<ChatBackgroundNotifier, ChatBackgroundState>((ref) {
  return ChatBackgroundNotifier();
});

class ChatBackgroundState {
  final int selectedIndex;
  final Color customColor;

  ChatBackgroundState({this.selectedIndex = 0, Color? customColor})
      : customColor = customColor ?? Colors.white;

  ChatBackgroundState copyWith({int? selectedIndex, Color? customColor}) {
    return ChatBackgroundState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      customColor: customColor ?? this.customColor,
    );
  }
}

class ChatBackgroundNotifier extends StateNotifier<ChatBackgroundState> {
  ChatBackgroundNotifier() : super(ChatBackgroundState()) {
    _load();
  }

  static const List<Color> presetColors = [
    Colors.white,
    Color(0xFFF5F5DC), // Beige
    Color(0xFFE8F4FD), // Light blue
    Color(0xFFF0FFF0), // Honeydew
    Color(0xFFFFF0F5), // Lavender blush
    Color(0xFFF5F5F5), // Smoke
    Color(0xFFE6E6FA), // Lavender
    Color(0xFFFFFACD), // Lemon chiffon
    Color(0xFFE0FFFF), // Light cyan
    Color(0xFFFFE4E1), // Misty rose
  ];

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('chat_bg_index') ?? 0;
    final colorValue = prefs.getInt('chat_bg_color');
    state = ChatBackgroundState(
      selectedIndex: index,
      customColor: colorValue != null ? Color(colorValue) : null,
    );
  }

  Future<void> setBackground(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chat_bg_index', index);
    state = state.copyWith(selectedIndex: index, customColor: presetColors[index]);
  }

  Future<void> setCustomColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chat_bg_color', color.value);
    state = state.copyWith(customColor: color);
  }
}
