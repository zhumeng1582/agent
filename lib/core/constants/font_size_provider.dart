import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeOption { small, medium, large }

class FontSizeState {
  final FontSizeOption option;
  final double scale;

  FontSizeState({required this.option, required this.scale});

  String get label {
    switch (option) {
      case FontSizeOption.small:
        return '小';
      case FontSizeOption.medium:
        return '中';
      case FontSizeOption.large:
        return '大';
    }
  }

  static FontSizeState fromString(String value) {
    switch (value) {
      case 'small':
        return FontSizeState(option: FontSizeOption.small, scale: 0.8);
      case 'large':
        return FontSizeState(option: FontSizeOption.large, scale: 1.2);
      default:
        return FontSizeState(option: FontSizeOption.medium, scale: 1.0);
    }
  }
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, FontSizeState>((ref) {
  return FontSizeNotifier();
});

class FontSizeNotifier extends StateNotifier<FontSizeState> {
  FontSizeNotifier() : super(FontSizeState(option: FontSizeOption.medium, scale: 1.0)) {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('font_size') ?? 'medium';
    state = FontSizeState.fromString(value);
  }

  Future<void> setFontSize(FontSizeOption option) async {
    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (option) {
      case FontSizeOption.small:
        value = 'small';
        break;
      case FontSizeOption.large:
        value = 'large';
        break;
      case FontSizeOption.medium:
        value = 'medium';
        break;
    }
    await prefs.setString('font_size', value);
    state = FontSizeState.fromString(value);
  }
}
