import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/message.dart';

class ImageMessage extends StatelessWidget {
  final Message message;

  const ImageMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.mediaPath == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(message.mediaPath!),
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50),
          );
        },
      ),
    );
  }
}
