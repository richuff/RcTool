import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/is_dark_controller.dart';
import '../controller/music_controller.dart';
import '../feature/theme/type_value.dart';
import '../utils/cache_size.dart';
import '../utils/size_format.dart';
import '../widget/settings_ui.dart';

class MainSettings extends StatefulWidget {
  const MainSettings({super.key});

  @override
  State<MainSettings> createState() => _MainSettingsState();
}

class _MainSettingsState extends State<MainSettings> {
  final IsDarkController themeController =
      Get.put(IsDarkController(), permanent: true);
  final MusicController musicController =
      Get.put(MusicController(), permanent: true);

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
      title: '清除音乐缓存',
      content: '将删除已下载的音频缓存，不会删除歌曲、歌单和设置。',
      confirmText: '清除',
    );
    if (!confirmed) return;
    await DefaultCacheManager().emptyCache();
    await _readCacheSize();
    Get.snackbar('清除完成', '音乐缓存已清除', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _resetSettings() async {
    final confirmed = await _confirm(
      title: '恢复默认设置',
      content: '外观、语言和播放设置将恢复默认，歌曲与歌单不会受影响。',
      confirmText: '恢复',
    );
    if (!confirmed) return;

    await _saveBool(playKey, false);
    await musicController.updateNotificationSetting(true);
    await musicController.updateCacheSetting(true);
    await themeController.updateThemeMode(ThemeMode.light);
    await _updateLocale(const Locale('zh', 'CN'));
    await musicController.changePlayMode(PlayMode.loop);
    await musicController.changeVolume(1.0);
    musicController.cancelSleepTimer();
    if (mounted) {
      setState(() {
        autoPlay = false;
        musicNotification = true;
        cacheFirst = true;
      });
    }
    Get.snackbar('已恢复', '设置已恢复为默认值', snackPosition: SnackPosition.BOTTOM);
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
                child: const Text('取消'),
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
        title: const Text('睡眠定时'),
        children: [
          if (musicController.sleepTimerActive)
            SimpleDialogOption(
              onPressed: () => Get.back(result: 0),
              child: const Text('取消当前定时'),
            ),
          for (final item in const [15, 30, 45, 60])
            SimpleDialogOption(
              onPressed: () => Get.back(result: item),
              child: Text('$item 分钟后暂停'),
            ),
        ],
      ),
    );
    if (minutes == null) return;
    if (minutes == 0) {
      musicController.cancelSleepTimer();
      Get.snackbar('睡眠定时', '已取消定时', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    musicController.startSleepTimer(Duration(minutes: minutes));
    Get.snackbar(
      '睡眠定时',
      '$minutes 分钟后将自动暂停播放',
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
              title: '外观',
              icon: Icons.palette_outlined,
              children: [
                SettingsChoiceTile(
                  icon: Icons.brightness_auto_outlined,
                  title: '跟随系统',
                  subtitle: '根据系统外观自动切换',
                  selected: controller.themeMode == ThemeMode.system,
                  onTap: () => controller.updateThemeMode(ThemeMode.system),
                ),
                SettingsChoiceTile(
                  icon: Icons.light_mode_outlined,
                  title: '亮色模式',
                  selected: controller.themeMode == ThemeMode.light,
                  onTap: () => controller.updateThemeMode(ThemeMode.light),
                ),
                SettingsChoiceTile(
                  icon: Icons.dark_mode_outlined,
                  title: '暗色模式',
                  selected: controller.themeMode == ThemeMode.dark,
                  onTap: () => controller.updateThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          SettingsSection(
            title: '语言',
            icon: Icons.translate,
            children: [
              SettingsChoiceTile(
                icon: Icons.translate,
                title: '简体中文',
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
            title: '播放',
            icon: Icons.play_circle_outline,
            children: [
              GetBuilder<MusicController>(
                builder: (controller) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '默认播放模式',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _modeChip(controller, PlayMode.loop, '列表循环'),
                          _modeChip(controller, PlayMode.single, '单曲循环'),
                          _modeChip(controller, PlayMode.random, '随机播放'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
                  title: '睡眠定时',
                  subtitle: controller.sleepTimerActive
                      ? '剩余 ${controller.sleepRemainingLabel}，点击修改或取消'
                      : '播放指定时间后自动暂停',
                  onTap: () => _showSleepTimerDialog(),
                ),
              ),
              SettingsSwitchTile(
                icon: Icons.play_circle_outline,
                title: '自动播放',
                subtitle: '进入音乐页后自动恢复播放',
                value: autoPlay,
                onChanged: (value) {
                  setState(() => autoPlay = value);
                  _saveBool(playKey, value);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: '播放通知',
                subtitle: '切歌时显示当前播放提示',
                value: musicNotification,
                onChanged: (value) {
                  setState(() => musicNotification = value);
                  musicController.updateNotificationSetting(value);
                },
              ),
              SettingsSwitchTile(
                icon: Icons.cached,
                title: '缓存优先',
                subtitle:
                    '已缓存 ${_formatCacheSize(_cacheBytes)} · 优先使用本地缓存，关闭后直接在线播放',
                value: cacheFirst,
                onChanged: (value) {
                  setState(() => cacheFirst = value);
                  musicController.updateCacheSetting(value);
                },
              ),
            ],
          ),
          SettingsSection(
            title: '存储与重置',
            icon: Icons.storage_outlined,
            margin: EdgeInsets.zero,
            children: [
              SettingsActionTile(
                icon: Icons.cleaning_services_outlined,
                title: '清除音乐缓存',
                subtitle:
                    '当前占用 ${_formatCacheSize(_cacheBytes)}，清除不会影响歌曲和歌单',
                onTap: _clearMusicCache,
              ),
              SettingsActionTile(
                icon: Icons.restart_alt,
                title: '恢复默认设置',
                subtitle: '不会影响已保存的歌曲和歌单',
                onTap: _resetSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeChip(
    MusicController controller,
    PlayMode mode,
    String label,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = controller.playMode.value == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      selectedColor: scheme.primaryContainer,
      backgroundColor: scheme.surfaceContainerHighest.withOpacity(0.5),
      side: BorderSide(
        color: selected ? scheme.primary.withOpacity(0.5) : Colors.transparent,
      ),
      onSelected: (_) => controller.changePlayMode(mode),
    );
  }
}
