import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/font_size_provider.dart';
import '../../data/models/message.dart';

class TextMessage extends ConsumerWidget {
  final Message message;
  final bool isDarkMode;

  const TextMessage({
    super.key,
    required this.message,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: message.isFromMe
            ? AppColors.primary
            : (isDarkMode ? Colors.grey[700] : AppColors.receivedBubble),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message.content ?? '',
        style: TextStyle(
          color: message.isFromMe
              ? Colors.white
              : (isDarkMode ? Colors.white : Colors.black),
          fontSize: fontSize,
        ),
      ),
    );
  }
}
