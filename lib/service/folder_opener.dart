import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// @ClassName FolderOpener
/// @Description 用系统方式打开一个本地目录：Android 弹出应用选择器
///              （让用户挑一个文件管理器打开该路径），桌面端直接调起资源管理器。
///              没有应用能处理时退回复制路径，不至于让用户无路可走。
/// @Author richuff
/// @Version 1.0
class FolderOpener {
  FolderOpener._();

  static Future<void> open(String path) async {
    final target = path.trim();
    if (target.isEmpty) return;

    if (Platform.isAndroid) {
      // VIEW + resource/folder 是文件管理器通吃的打开目录方式；
      // 有多个处理方时系统会自动弹出「选择应用」。
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'file://$target',
        type: 'resource/folder',
        flags: const <int>[Flag.FLAG_GRANT_READ_URI_PERMISSION],
      );
      try {
        if (await intent.canResolveActivity() == true) {
          await intent.launch();
          return;
        }
      } catch (_) {
        // 继续走兜底
      }
      await _fallback(target);
      return;
    }

    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [target]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [target]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [target]);
      }
    } catch (_) {
      await _fallback(target);
    }
  }

  /// 兜底：复制路径并提示，用户仍可用文件管理器手动进入
  static Future<void> _fallback(String path) async {
    await Clipboard.setData(ClipboardData(text: path));
    Get.snackbar(
      '没有找到能打开文件夹的应用'.tr,
      '路径已复制，可用文件管理器手动进入'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
