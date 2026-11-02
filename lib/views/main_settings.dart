import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/is_dark_controller.dart';
import '../controller/music_controller.dart';
import '../controller/offline_controller.dart';
import '../feature/theme/type_value.dart';
import '../routers/route_path.dart';
import '../utils/cache_size.dart';
import '../utils/size_format.dart';
import '../widget/cache_limit_dialog.dart';
import '../widget/settings_ui.dart';

class MainSettings extends StatefulWidget {
  const MainSettings({super.key});

  @override
  State<MainSettings> createState() => _MainSettingsState();
}

class _MainSettingsState extends State<MainSettings> {
  final IsDarkController themeController = Get.find<IsDarkController>();
  final MusicController musicController = Get.find<MusicController>();

  bool autoPlay = false;
  bool musicNotification = true;
  bool cacheFirst = true;
  Locale appLocale = const Locale('zh', 'CN');

  /// 音乐缓存占用（字节），由 flutter_cache_manager 统计
  int _cacheBytes = 0;

  @override
  void initState() {
    super.initState();
    _readData();
    _readCacheSize();
  }

  Future<void> _readCacheSize() async {
    try {
      final size = await readMusicCacheSize();
      if (!mounted) return;
      setState(() => _cacheBytes = size);
    } catch (_) {
      // 读取失败时保持上一次的值，不打断设置页
    }
  }

  String _formatCacheSize(int bytes) => formatBytes(bytes);

  Future<void> _readData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      autoPlay = prefs.getBool(playKey) ?? false;
      musicNotification = prefs.getBool(notificationKey) ?? true;
      cacheFirst = prefs.getBool(cacheFirstKey) ?? true;
      appLocale = Locale(
        prefs.getString(languageCodeKey) ?? 'zh',
        prefs.getString(countryCodeKey) ?? 'CN',
      );
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _updateLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageCodeKey, locale.languageCode);
    await prefs.setString(countryCodeKey, locale.countryCode ?? '');
    await Get.updateLocale(locale);
    if (mounted) setState(() => appLocale = locale);
  }

  Future<void> _clearMusicCache() async {
    final confirmed = await _confirm(
      title: '清除音乐缓存'.tr,
      content: '将删除已下载的音频缓存，不会删除歌曲、歌单和设置。'.tr,
      confirmText: '清除'.tr,
    );
    if (!confirmed) return;
    // 走 OfflineController 清空，顺带把「已缓存」角标一起刷新掉
    await Get.find<OfflineController>().clearAll();
    await _readCacheSize();
    Get.snackbar('清除完成'.tr, '音乐缓存已清除'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _resetSettings() async {
    final confirmed = await _confirm(
      title: '恢复默认设置'.tr,
      content: '外观、语言和播放设置将恢复默认，歌曲与歌单不会受影响。'.tr,
      confirmText: '恢复'.tr,
    );
    if (!confirmed) return;

    await _saveBool(playKey, false);
    await musicController.updateNotificationSetting(true);
    await musicController.updateCacheSetting(true);
    await themeController.updateThemeMode(ThemeMode.light);
    await _updateLocale(const Locale('zh', 'CN'));
    await musicController.changeVolume(1.0);
    musicController.cancelSleepTimer();
    if (mounted) {
      setState(() {
        autoPlay = false;
        musicNotification = true;
        cacheFirst = true;
      });
    }
    Get.snackbar('已恢复'.tr, '设置已恢复为默认值'.tr,
        snackPosition: SnackPosition.BOTTOM);
  }

  Future<bool> _confirm({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('取消'.tr),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showSleepTimerDialog() async {
    final minutes = await Get.dialog<int>(
      SimpleDialog(
        title: Text('睡眠定时'.tr),
        children: [
          if (musicController.sleepTimerActive)
            SimpleDialogOption(
              onPressed: () => Get.back(result: 0),
              child: Text('取消当前定时'.tr),
            ),
          for (final item in const [15, 30, 45, 60])
            SimpleDialogOption(
              onPressed: () => Get.back(result: item),
              child: Text('@minutes 分钟后暂停'.trParams({'minutes': '$item'})),
            ),
        ],
      ),
    );
    if (minutes == null) return;
    if (minutes == 0) {
      musicController.cancelSleepTimer();
      Get.snackbar('睡眠定时'.tr, '已取消定时'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    musicController.startSleepTimer(Duration(minutes: minutes));
    Get.snackbar(
      '睡眠定时'.tr,
      '@minutes 分钟后将自动暂停播放'.trParams({'minutes': '$minutes'}),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
        children: [
          GetBuilder<IsDarkController>(
            builder: (controller) => SettingsSection(
              title: '外观'.tr,
              icon: Icons.palette_outlined,
              children: [
                SettingsChoiceTile(
                  icon: Icons.brightness_auto_outlined,
                  title: '跟随系统'.tr,
                  subtitle: '根据系统外观自动切换'.tr,
                  selected: controller.themeMode == ThemeMode.system,
                  onTap: () => controller.updateThemeMode(ThemeMode.system),
                ),
                SettingsChoiceTile(
                  icon: Icons.light_mode_outlined,
                  title: '亮色模式'.tr,
                  selected: controller.themeMode == ThemeMode.light,
                  onTap: () => controller.updateThemeMode(ThemeMode.light),
                ),
                SettingsChoiceTile(
                  icon: Icons.dark_mode_outlined,
                  title: '暗色模式'.tr,
                  selected: controller.themeMode == ThemeMode.dark,
                  onTap: () => controller.updateThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          SettingsSection(
            title: '语言'.tr,
            icon: Icons.translate,
            children: [
              SettingsChoiceTile(
                icon: Icons.translate,
                title: '简体中文'.tr,
                selected: appLocale.languageCode == 'zh',
                onTap: () => _updateLocale(const Locale('zh', 'CN')),
              ),
              SettingsChoiceTile(
                icon: Icons.language,
                title: 'English',
                selected: appLocale.languageCode == 'en',
                onTap: () => _updateLocale(const Locale('en', 'US')),
              ),
              SettingsChoiceTile(
                icon: Icons.language,
                title: '日本語',
                selected: appLocale.languageCode == 'ja',
                onTap: () => _updateLocale(const Locale('ja', 'JP')),
              ),
            ],
          ),
          SettingsSection(
            title: '播放设置'.tr,
            icon: Icons.play_circle_outline,
            children: [
              GetBuilder<MusicController>(
                builder: (controller) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volume_up_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      Expanded(
                        child: Slider(
                          value: controller.volume.value,
                          divisions: 20,
                          label: '${(controller.volume.value * 100).round()}%',
                          onChanged: controller.changeVolume,
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${(controller.volume.value * 100).round()}%',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GetBuilder<MusicController>(
                builder: (controller) => SettingsActionTile(
                  icon: Icons.bedtime_outlined,
                  title: '睡眠定时'.tr,
                  subtitle: controller.sleepTimerActive
                      ? '剩余 @time，点击修改或取消'.trParams(
                          {'time': controller.sleepRemainingLabel})
                      : '播放指定时间后自动暂停'.tr,
                  onTap: () => _showSleepTimerDialog(),
                ),
              ),
              SettingsSwitchTile(
                icon: Icons.play_circle_outline,
                title: '自动播放'.tr,
                subtitle: '进入音乐页后自动恢复播放'.tr,
                value: autoPlay,
                onChanged: (value) {
                  setState(() => autoPlay = value);
                  _saveBool(playKey, value);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: '播放通知'.tr,
                subtitle: '切歌时显示当前播放提示'.tr,
                value: musicNotification,
                onChanged: (value) {
                  setState(() => musicNotification = value);
                  musicController.updateNotificationSetting(value);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.cached,
                title: '缓存优先'.tr,
                subtitle: '已缓存 @size · 优先使用本地缓存，关闭后直接在线播放'
                    .trParams({'size': _formatCacheSize(_cacheBytes)}),
                value: cacheFirst,
                onChanged: (value) {
                  setState(() => cacheFirst = value);
                  musicController.updateCacheSetting(value);
                },
              ),
            ],
          ),
          SettingsSection(
            title: '存储与重置'.tr,
            icon: Icons.storage_outlined,
            margin: EdgeInsets.zero,
            children: [
              GetBuilder<OfflineController>(
                builder: (offline) => SettingsActionTile(
                  icon: Icons.offline_pin_outlined,
                  title: '离线管理'.tr,
                  subtitle: '已缓存 @count 首 · 音频占用 @size'.trParams({
                    'count': '${offline.cachedUrls.length}',
                    'size': formatBytes(offline.totalBytes.value),
                  }),
                  onTap: () async {
                    await Get.toNamed(RoutePath.OFFLINE);
                    await _readCacheSize();
                  },
                ),
              ),
              GetBuilder<OfflineController>(
                builder: (offline) => SettingsActionTile(
                  icon: Icons.sd_storage_outlined,
                  title: '音乐缓存上限'.tr,
                  subtitle: offline.hasLimit
                      ? '上限 @limit，超出后自动清理最早下载的歌曲'
                          .trParams({'limit': offline.limitLabel})
                      : '不限'.tr,
                  onTap: () => showCacheLimitDialog(context, offline),
                ),
              ),
              SettingsActionTile(
                icon: Icons.cleaning_services_outlined,
                title: '清除音乐缓存'.tr,
                subtitle: '当前占用 @size，清除不会影响歌曲和歌单'
                    .trParams({'size': _formatCacheSize(_cacheBytes)}),
                onTap: _clearMusicCache,
              ),
              SettingsActionTile(
                icon: Icons.restart_alt,
                title: '恢复默认设置'.tr,
                subtitle: '不会影响已保存的歌曲和歌单'.tr,
                onTap: _resetSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
