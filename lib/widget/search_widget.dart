import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/is_dark_controller.dart';
import 'package:rctool/controller/music_controller.dart';
import 'package:rctool/feature/theme/type_value.dart';
import 'package:rctool/iconfont/rc_icon.dart';
import 'package:rctool/utils/cache_size.dart';
import 'package:rctool/utils/size_format.dart';
import 'package:rctool/widget/device_info_panel.dart';
import 'package:rctool/widget/setting_dialog.dart';
import 'package:rctool/widget/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/design/icon_button_no_ripple.dart';

/// @ClassName SearchWidget
/// @Description 搜索 / 全局设置入口：底部面板与「完整设置」共用设置组件，样式完全对齐。
/// @Author richuff
/// @Date 2024-10-11
/// @Version 2.0
class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => _SearchWidget();
}

class _SearchWidget extends State<SearchWidget> {
  IsDarkController isDarkController = Get.put(IsDarkController());
  bool autoPlay = false;
  bool musicNotification = true;
  bool cacheFirst = true;
  int _cacheBytes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAutoPlay();
      _loadCacheSize();
    });
  }

  Future<void> _loadCacheSize() async {
    try {
      final size = await readMusicCacheSize();
      if (!mounted) return;
      setState(() => _cacheBytes = size);
    } catch (_) {
      // 读取失败时保留上一次的值
    }
  }

  Future<void> _loadAutoPlay() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      autoPlay = prefs.getBool(playKey) ?? false;
      musicNotification = prefs.getBool(notificationKey) ?? true;
      cacheFirst = prefs.getBool(cacheFirstKey) ?? true;
    });
  }

  Future<void> _updateBoolSetting(String key, bool value) async {
    if (key == notificationKey && Get.isRegistered<MusicController>()) {
      await Get.find<MusicController>().updateNotificationSetting(value);
    } else if (key == cacheFirstKey && Get.isRegistered<MusicController>()) {
      await Get.find<MusicController>().updateCacheSetting(value);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    }
    if (!mounted) return;
    setState(() {
      if (key == playKey) autoPlay = value;
      if (key == notificationKey) musicNotification = value;
      if (key == cacheFirstKey) cacheFirst = value;
    });
  }

  Future<void> _updateLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageCodeKey, locale.languageCode);
    await prefs.setString(countryCodeKey, locale.countryCode ?? "");
    Get.updateLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: IconButtonNoRipple(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          hoverColor: scheme.primaryContainer,
          focusColor: scheme.primaryContainer,
          highlightColor: scheme.secondaryContainer,
          tooltip: '全局设置'.tr,
          onPressed: () {
            _loadAutoPlay();
            _loadCacheSize();
            Get.bottomSheet(
              StatefulBuilder(
                builder: (sheetContext, setSheetState) {
                  final sheetScheme = Theme.of(sheetContext).colorScheme;
                  return Container(
                    height: height > 560 ? 640 : height * 0.9,
                    decoration: BoxDecoration(
                      color: sheetScheme.surface,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        // 顶部拖拽条
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: sheetScheme.outline.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            children: [
                              SettingsHeader(
                                icon: Icons.tune,
                                title: "全局设置".tr,
                                subtitle: '快捷调整外观与播放'.tr,
                                onClose: () => Get.back(),
                              ),
                              const SizedBox(height: 14),
                              const DeviceInfoPanel(),
                              const SizedBox(height: 12),
                              Obx(
                                () => SettingsSection(
                                  title: '主题'.tr,
                                  icon: Icons.palette_outlined,
                                  children: [
                                    SettingsChoiceTile(
                                      icon: Icons.brightness_auto_outlined,
                                      title: "跟随系统",
                                      selected: isDarkController.themeMode ==
                                          ThemeMode.system,
                                      onTap: () {
                                        isDarkController
                                            .updateThemeMode(ThemeMode.system);
                                        setSheetState(() {});
                                      },
                                    ),
                                    SettingsChoiceTile(
                                      icon: Icons.sunny,
                                      title: "亮色",
                                      selected: isDarkController.themeMode ==
                                          ThemeMode.light,
                                      onTap: () {
                                        isDarkController
                                            .updateThemeMode(ThemeMode.light);
                                        setSheetState(() {});
                                      },
                                    ),
                                    SettingsChoiceTile(
                                      icon: Icons.nightlight,
                                      title: "暗色",
                                      selected: isDarkController.themeMode ==
                                          ThemeMode.dark,
                                      onTap: () {
                                        isDarkController
                                            .updateThemeMode(ThemeMode.dark);
                                        setSheetState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SettingsSection(
                                title: '语言'.tr,
                                icon: Icons.translate,
                                children: [
                                  SettingsChoiceTile(
                                    icon: RcIcon.chinese,
                                    title: "简体中文",
                                    selected:
                                        Get.locale?.languageCode == "zh",
                                    onTap: () {
                                      _updateLocale(
                                          const Locale("zh", "CN"));
                                      setSheetState(() {});
                                    },
                                  ),
                                  SettingsChoiceTile(
                                    icon: RcIcon.english,
                                    title: "English",
                                    selected:
                                        Get.locale?.languageCode == "en",
                                    onTap: () {
                                      _updateLocale(
                                          const Locale("en", "US"));
                                      setSheetState(() {});
                                    },
                                  ),
                                  SettingsChoiceTile(
                                    icon: RcIcon.japanese,
                                    title: "日本語",
                                    selected:
                                        Get.locale?.languageCode == "ja",
                                    onTap: () {
                                      _updateLocale(
                                          const Locale("ja", "JP"));
                                      setSheetState(() {});
                                    },
                                  ),
                                ],
                              ),
                              SettingsSection(
                                title: '播放设置'.tr,
                                icon: Icons.play_circle_outline,
                                children: [
                                  SettingsSwitchTile(
                                    icon: Icons.play_circle_outline,
                                    title: "自动播放".tr,
                                    subtitle: "进入音乐页后自动恢复播放".tr,
                                    value: autoPlay,
                                    onChanged: (value) async {
                                      await _updateBoolSetting(
                                          playKey, value);
                                      setSheetState(() {});
                                    },
                                  ),
                                  SettingsSwitchTile(
                                    icon: Icons.notifications_active_outlined,
                                    title: "播放通知".tr,
                                    subtitle: "切歌时显示当前播放提示",
                                    value: musicNotification,
                                    onChanged: (value) async {
                                      await _updateBoolSetting(
                                          notificationKey, value);
                                      setSheetState(() {});
                                    },
                                  ),
                                  SettingsSwitchTile(
                                    icon: Icons.cached,
                                    title: "缓存优先".tr,
                                    subtitle:
                                        "已缓存 ${formatBytes(_cacheBytes)} · 优先使用本地缓存",
                                    value: cacheFirst,
                                    onChanged: (value) async {
                                      await _updateBoolSetting(
                                          cacheFirstKey, value);
                                      setSheetState(() {});
                                    },
                                  ),
                                ],
                              ),
                              SettingsSection(
                                title: '更多'.tr,
                                icon: Icons.settings_outlined,
                                margin: EdgeInsets.zero,
                                children: [
                                  SettingsActionTile(
                                    icon: Icons.settings,
                                    title: "完整设置",
                                    subtitle: "播放模式、音量、睡眠定时与缓存管理",
                                    onTap: () {
                                      Get.back();
                                      showDialog(
                                        context: context,
                                        builder: (_) => const SettingDialog(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            );
          },
          icon: const Icon(Icons.widgets)),
    );
  }
}
