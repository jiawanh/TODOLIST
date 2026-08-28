// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化国际化时间格式
  await initializeDateFormatting('zh_CN', null);

  // 初始化时区
  tz.initializeTimeZones();

  // 桌面端窗口配置
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(960, 680),
      minimumSize: Size(640, 480),
      center: true,
      title: '任务清单',
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // 初始化系统托盘
    final trayService = TrayService();
  await trayService.initialize();
  }

  // 初始化通知服务
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: TodoApp(),
    ),
  );
}
