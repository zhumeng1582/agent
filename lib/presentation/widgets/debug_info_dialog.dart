import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugInfoDialog extends StatelessWidget {
  const DebugInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final physicalSize = MediaQuery.of(context).size;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return AlertDialog(
      title: const Text('调试信息'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('屏幕物理尺寸', '${physicalSize.width.toStringAsFixed(1)} x ${physicalSize.height.toStringAsFixed(1)}'),
            _buildInfoRow('设备像素比', devicePixelRatio.toStringAsFixed(2)),
            _buildInfoRow('状态栏高度', '${padding.top.toStringAsFixed(1)} px'),
            _buildInfoRow('导航栏高度', '${padding.bottom.toStringAsFixed(1)} px'),
            _buildInfoRow('左边安全区', '${padding.left.toStringAsFixed(1)} px'),
            _buildInfoRow('右边安全区', '${padding.right.toStringAsFixed(1)} px'),
            _buildInfoRow('键盘高度', '${viewInsets.bottom.toStringAsFixed(1)} px'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(
              text: _buildDebugText(padding, viewInsets, physicalSize, devicePixelRatio),
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已复制到剪贴板')),
            );
          },
          child: const Text('复制'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  String _buildDebugText(padding, viewInsets, physicalSize, devicePixelRatio) {
    return '''屏幕物理尺寸: ${physicalSize.width.toStringAsFixed(1)} x ${physicalSize.height.toStringAsFixed(1)}
设备像素比: ${devicePixelRatio.toStringAsFixed(2)}
状态栏高度: ${padding.top.toStringAsFixed(1)} px
导航栏高度: ${padding.bottom.toStringAsFixed(1)} px
左边安全区: ${padding.left.toStringAsFixed(1)} px
右边安全区: ${padding.right.toStringAsFixed(1)} px
键盘高度: ${viewInsets.bottom.toStringAsFixed(1)} px''';
  }
}

void showDebugInfoDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const DebugInfoDialog(),
  );
}
