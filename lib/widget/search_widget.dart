import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/is_dark_controller.dart';
import 'package:rctool/feature/theme/type_value.dart';
import 'package:rctool/iconfont/rc_icon.dart';
import 'package:rctool/routers/route_path.dart';
import 'package:rctool/widget/setting_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/design/icon_button_no_ripple.dart';
import 'TextWidget/dark_light_text.dart';



/// @ClassName SearchWidget
/// @Description 搜索组件
/// @Author richuff
/// @Date 2024-10-11
/// @Version 1.0
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAutoPlay();
    });
  }

  Future<void> _loadAutoPlay() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      autoPlay = prefs.getBool(playKey) ?? false;
      musicNotification = prefs.getBool(notificationKey) ?? true;
      cacheFirst = prefs.getBool(cacheFirstKey) ?? true;
    });
  }

  Future<void> _updateBoolSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
      padding: const EdgeInsets.only(right: 15),
      child: IconButtonNoRipple(
          hoverColor: scheme.primaryContainer,
          focusColor: scheme.primaryContainer,
          highlightColor: scheme.secondaryContainer,
          onPressed: () {
            Get.bottomSheet(
              StatefulBuilder(
                builder: (sheetContext, setSheetState) {
                  final sheetScheme = Theme.of(sheetContext).colorScheme;
                  return Container(
                    decoration: BoxDecoration(
                        color: sheetScheme.surface,
                        image: const DecorationImage(
                            opacity: 0.16,
                            image: AssetImage("image/BottomBackGround.jpg"),
                            fit: BoxFit.cover)),
                    height: height > 560 ? 560 : height * 0.86,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tune, color: sheetScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              "全局设置",
                              style:
                                  Theme.of(sheetContext).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _quickButton(
                              sheetContext,
                              icon: Icons.home,
                              label: "主页".tr,
                              onTap: () {
                                Get.back();
                                Get.toNamed(RoutePath.HOME);
                              },
                            ),
                            _quickButton(
                              sheetContext,
                              icon: Icons.music_note,
                              label: "听音乐".tr,
                              onTap: () {
                                Get.back();
                                Get.toNamed(RoutePath.MUSIC);
                              },
                            ),
                            _quickButton(
                              sheetContext,
                              icon: Icons.settings,
                              label: "完整设置",
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
                        const SizedBox(height: 14),
                        _settingCard(
                          sheetContext,
                          title: "主题",
                          children: [
                            Obx(
                              () => _choiceTile(
                                sheetContext,
                                icon: Icons.sunny,
                                title: "亮色",
                                selected: !isDarkController.isDark.value,
                                onTap: () {
                                  isDarkController.updateIsDark(false);
                                  setSheetState(() {});
                                },
                              ),
                            ),
                            Obx(
                              () => _choiceTile(
                                sheetContext,
                                icon: Icons.nightlight,
                                title: "暗色",
                                selected: isDarkController.isDark.value,
                                onTap: () {
                                  isDarkController.updateIsDark(true);
                                  setSheetState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _settingCard(
                          sheetContext,
                          title: "语言",
                          children: [
                            _choiceTile(
                              sheetContext,
                              icon: RcIcon.chinese,
                              title: "简体中文",
                              selected: Get.locale?.languageCode == "zh",
                              onTap: () {
                                _updateLocale(const Locale("zh", "CN"));
                                setSheetState(() {});
                              },
                            ),
                            _choiceTile(
                              sheetContext,
                              icon: RcIcon.english,
                              title: "English",
                              selected: Get.locale?.languageCode == "en",
                              onTap: () {
                                _updateLocale(const Locale("en", "US"));
                                setSheetState(() {});
                              },
                            ),
                            _choiceTile(
                              sheetContext,
                              icon: RcIcon.japanese,
                              title: "日本語",
                              selected: Get.locale?.languageCode == "ja",
                              onTap: () {
                                _updateLocale(const Locale("ja", "JP"));
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _settingCard(
                          sheetContext,
                          title: "播放",
                          children: [
                            _switchTile(
                              sheetContext,
                              icon: Icons.play_circle_outline,
                              title: "自动播放",
                              subtitle: "进入音乐页后自动恢复播放",
                              value: autoPlay,
                              onChanged: (value) async {
                                await _updateBoolSetting(playKey, value);
                                setSheetState(() {});
                              },
                            ),
                            _switchTile(
                              sheetContext,
                              icon: Icons.notifications_active_outlined,
                              title: "播放通知",
                              subtitle: "切歌时显示当前播放提示",
                              value: musicNotification,
                              onChanged: (value) async {
                                await _updateBoolSetting(
                                    notificationKey, value);
                                setSheetState(() {});
                              },
                            ),
                            _switchTile(
                              sheetContext,
                              icon: Icons.cached,
                              title: "缓存优先",
                              subtitle: "优先使用已缓存的音乐文件",
                              value: cacheFirst,
                              onChanged: (value) async {
                                await _updateBoolSetting(cacheFirstKey, value);
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              isScrollControlled: true,
            );
          },
          icon: const Icon(Icons.widgets)),
    );
  }

  Widget _quickButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
      ),
    );
  }

  Widget _settingCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _choiceTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: selected ? scheme.primary : null),
      title: darkLightText(title),
      trailing: selected
          ? Icon(Icons.check_circle, color: scheme.primary)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }

  Widget _switchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      secondary: Icon(icon, color: value ? scheme.secondary : null),
      title: darkLightText(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      value: value,
      activeColor: scheme.onSecondary,
      activeTrackColor: scheme.secondary,
      onChanged: onChanged,
    );
  }
}
