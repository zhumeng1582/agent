import 'package:flutter_riverpod/flutter_riverpod.dart';

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, double>((ref) {
  return FontSizeNotifier();
});

class FontSizeNotifier extends StateNotifier<double> {
  FontSizeNotifier() : super(14.0);

  void setFontSize(double size) {
    state = size.clamp(12.0, 20.0);
  }

  void increaseFontSize() {
    state = (state + 1).clamp(12.0, 20.0);
  }

  void decreaseFontSize() {
    state = (state - 1).clamp(12.0, 20.0);
  }
}
