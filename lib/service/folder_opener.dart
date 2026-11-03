import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// @ClassName FolderOpener
/// @Description 用系统方式打开一个本地目录：Android 通过 MethodChannel 发
///              ACTION_VIEW + resource/folder 的 Chooser Intent，由用户挑选
///              一个文件管理器打开；桌面端直接调起资源管理器。
///              没有应用能处理时退回复制路径，不至于让用户无路可走。
/// @Author richuff
/// @Version 1.1
class FolderOpener {
  FolderOpener._();

  static const MethodChannel _channel = MethodChannel('rctool/folder');

  static Future<void> open(String path) async {
    final target = path.trim();
    if (target.isEmpty) return;

    if (Platform.isAndroid) {
      try {
        final launched = await _channel.invokeMethod<bool>('openFolder', {
          'path': target,
        });
        if (launched == true) return;
      } catch (_) {
        // 通道未实现 / 没有处理方，继续走兜底
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
