import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../views/main_settings.dart';
import 'settings_ui.dart';

/// @ClassName SettingDialog
/// @Description 完整设置窗口：与「全局设置」快捷面板共用同一套设置组件，
///             头部、分组卡片与选项行样式完全对齐。
/// @Author richuff
/// @Version 2.0
class SettingDialog extends StatelessWidget {
  const SettingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = (screenHeight - 48).clamp(360.0, 720.0).toDouble();

    return Dialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 460,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            children: [
              SettingsHeader(
                icon: Icons.settings_outlined,
                title: '设置'.tr,
                subtitle: '外观、播放与存储偏好'.tr,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 6),
              Divider(
                height: 1,
                color: scheme.outline.withOpacity(0.16),
              ),
              const MainSettings(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '设置仅保存在本机'.tr,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
