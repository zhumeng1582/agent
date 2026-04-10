import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final avatarProvider = StateNotifierProvider<AvatarNotifier, AvatarState>((ref) {
  return AvatarNotifier();
});

class AvatarState {
  final String? customAvatarPath;
  final int selectedDefaultIndex;

  AvatarState({this.customAvatarPath, this.selectedDefaultIndex = 0});

  String? get avatarPath => customAvatarPath;
}

class AvatarNotifier extends StateNotifier<AvatarState> {
  AvatarNotifier() : super(AvatarState()) {
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('custom_avatar_path');
    final defaultIndex = prefs.getInt('default_avatar_index') ?? 0;
    state = AvatarState(customAvatarPath: customPath, selectedDefaultIndex: defaultIndex);
  }

  Future<void> setCustomAvatar(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_avatar_path', path);
    state = AvatarState(customAvatarPath: path, selectedDefaultIndex: -1);
  }

  Future<void> setDefaultAvatar(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_avatar_index', index);
    await prefs.remove('custom_avatar_path');
    state = AvatarState(customAvatarPath: null, selectedDefaultIndex: index);
  }

  Future<void> clearCustomAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_avatar_path');
    state = AvatarState(customAvatarPath: null, selectedDefaultIndex: state.selectedDefaultIndex);
  }
}

// Default avatars list
class DefaultAvatars {
  static const List<Color> colors = [
    Color(0xFF6750A4),
    Color(0xFF625B71),
    Color(0xFF7D5260),
    Color(0xFF0061A4),
    Color(0xFF006E1C),
    Color(0xFFB42B51),
    Color(0xFF984061),
    Color(0xFF7E5700),
    Color(0xFF3D3D3D),
    Color(0xFF4B4B4B),
    Color(0xFF00629C),
    Color(0xFF007449),
    Color(0xFFBE3A34),
    Color(0xFF8B3D67),
    Color(0xFF5C5C5C),
    Color(0xFF3C3C3C),
    Color(0xFF004B80),
    Color(0xFF005D38),
    Color(0xFFA50034),
    Color(0xFF7D0058),
  ];

  static const List<IconData> icons = [
    Icons.person,
    Icons.face,
    Icons.sentiment_satisfied,
    Icons.mood,
    Icons.emoji_emotions,
    Icons.face_2,
    Icons.face_3,
    Icons.face_4,
    Icons.face_5,
    Icons.face_6,
    Icons.sports_esports,
    Icons.sports_soccer,
    Icons.pets,
    Icons.cruelty_free,
    Icons.smart_toy,
    Icons.psychology,
    Icons.lightbulb,
    Icons.star,
    Icons.favorite,
    Icons.rocket_launch,
  ];

  static Widget buildAvatar(int index, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors[index % colors.length],
        shape: BoxShape.circle,
      ),
      child: Icon(
        icons[index % icons.length],
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
