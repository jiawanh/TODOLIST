// lib/services/tray_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../core/constants.dart';

class TrayService with TrayListener {
  Future<void> initialize() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

    trayManager.addListener(this);
    await trayManager.setIcon(_getIconPath());
    await trayManager.setToolTip('任务清单');

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: '显示主界面',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: '退出',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  String _getIconPath() {
    if (Platform.isWindows) {
      final exePath = Platform.resolvedExecutable;
      final exeDir = (exePath.contains('\\') 
          ? exePath.substring(0, exePath.lastIndexOf('\\'))
          : exePath);
      return '$exeDir\\data\\flutter_assets\\assets\\app_icon.ico';
    } else if (Platform.isMacOS) {
      return 'AppIcon';
    }
    return ''; // Linux icon path if needed
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
      exit(0);
    }
  }

  void dispose() {
    trayManager.removeListener(this);
  }
}
