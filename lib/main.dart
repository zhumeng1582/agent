import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/constants/app_config.dart';
import 'data/services/sync_queue_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service with backend URL (async)
  await AppConfig.initializeApiService();

  // Initialize sync queue service
  await SyncQueueService().init();

  // 初始设置导航栏颜色（浅色模式）
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFFF2F2F7),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
