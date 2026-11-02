import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant/app_info.dart';
import '../utils/device_info.dart';
import 'settings_ui.dart';

/// @ClassName DeviceInfoPanel
/// @Description 「全局设置」中的设备信息卡：机型、系统、CPU、内存、屏幕分辨率等。
///             数据来源为 Android 原生通道 + /proc 兜底，不依赖第三方插件。
/// @Author richuff
/// @Version 1.0
class DeviceInfoPanel extends StatefulWidget {
  const DeviceInfoPanel({super.key});

  @override
  State<DeviceInfoPanel> createState() => _DeviceInfoPanelState();
}

class _DeviceInfoPanelState extends State<DeviceInfoPanel> {
  late Future<DeviceInfo> _future = DeviceInfoService.load(forceRefresh: true);

  void _refresh() {
    setState(() {
      _future = DeviceInfoService.load(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<DeviceInfo>(
      future: _future,
      builder: (context, snapshot) {
        final info = snapshot.data;
        return SettingsSection(
          title: '设备信息'.tr,
          icon: Icons.phone_android_rounded,
          children: [
            if (info == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '正在读取设备信息…',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              SettingsInfoTile(
                icon: Icons.smartphone_rounded,
                label: '机型'.tr,
                value: info.deviceLabel,
              ),
              SettingsInfoTile(
                icon: Icons.android_rounded,
                label: '系统'.tr,
                value: info.systemLabel,
              ),
              SettingsInfoTile(
                icon: Icons.memory_rounded,
                label: '处理器'.tr,
                value: info.cpuLabel,
              ),
              if (info.cpuModel.isNotEmpty)
                SettingsInfoTile(
                  icon: Icons.developer_board_rounded,
                  label: '型号'.tr,
                  value: info.cpuModel,
                ),
              SettingsInfoTile(
                icon: Icons.storage_rounded,
                label: '内存'.tr,
                value: info.ramUsageLabel,
              ),
              SettingsInfoTile(
                icon: Icons.aspect_ratio_rounded,
                label: '屏幕'.tr,
                value: _screenLabel(context),
              ),
              SettingsInfoTile(
                icon: Icons.info_outline_rounded,
                label: '应用'.tr,
                value: '${AppInfo.name} ${AppInfo.version}',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('刷新', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _screenLabel(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final width = (size.width * ratio).round();
    final height = (size.height * ratio).round();
    return '$width × $height · ${ratio.toStringAsFixed(1)}x';
  }
}
