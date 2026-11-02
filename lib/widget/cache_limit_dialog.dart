import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/offline_controller.dart';

/// 选择音乐缓存上限。返回 true 表示已修改。
Future<bool?> showCacheLimitDialog(
  BuildContext context,
  OfflineController offline,
) async {
  const mb = 1024 * 1024;
  final scheme = Theme.of(context).colorScheme;
  final options = <int, String>{
    0: '不限'.tr,
    200 * mb: '200 MB',
    500 * mb: '500 MB',
    1024 * mb: '1 GB',
    2048 * mb: '2 GB',
  };

  final picked = await Get.dialog<int>(
    SimpleDialog(
      title: Text('音乐缓存上限'.tr),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
          child: Text(
            '超出上限时会自动清理最早下载的歌曲'.tr,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        for (final item in options.entries)
          SimpleDialogOption(
            onPressed: () => Get.back(result: item.key),
            child: Row(
              children: [
                Text(item.value),
                const Spacer(),
                if (offline.limitBytes.value == item.key)
                  Icon(Icons.check_rounded, size: 18, color: scheme.primary),
              ],
            ),
          ),
      ],
    ),
  );
  if (picked == null) return false;
  await offline.setLimit(picked);
  return true;
}
