import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rctool/controller/is_dark_controller.dart';
import 'package:rctool/feature/Theme/type_value.dart';
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
    });
  }

  Future<void> _updateAutoPlay(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(playKey, value);
    setState(() {
      autoPlay = value;
    });
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
              Container(
                decoration: BoxDecoration(
                    color: scheme.surface,
                    image: const DecorationImage(
                        opacity: 0.16,
                        image: AssetImage("image/BottomBackGround.jpg"),
                        fit: BoxFit.cover)),
                height: height > 520 ? 520 : height * 0.82,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          "全局设置",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _quickButton(
                          context,
                          icon: Icons.home,
                          label: "主页".tr,
                          onTap: () {
                            Get.back();
                            Get.toNamed(RoutePath.HOME);
                          },
                        ),
                        _quickButton(
                          context,
                          icon: Icons.music_note,
                          label: "听音乐".tr,
                          onTap: () {
                            Get.back();
                            Get.toNamed(RoutePath.MUSIC);
                          },
                        ),
                        _quickButton(
                          context,
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
                      context,
                      title: "主题",
                      children: [
                        _choiceTile(
                          context,
                          icon: Icons.sunny,
                          title: "亮色",
                          selected: !isDarkController.isDark.value,
                          onTap: () {
                            isDarkController.updateIsDark(false);
                            setState(() {});
                          },
                        ),
                        _choiceTile(
                          context,
                          icon: Icons.nightlight,
                          title: "暗色",
                          selected: isDarkController.isDark.value,
                          onTap: () {
                            isDarkController.updateIsDark(true);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _settingCard(
                      context,
                      title: "语言",
                      children: [
                        _choiceTile(
                          context,
                          icon: RcIcon.chinese,
                          title: "简体中文",
                          selected: Get.locale?.languageCode == "zh",
                          onTap: () => Get.updateLocale(
                            const Locale("zh", "CN"),
                          ),
                        ),
                        _choiceTile(
                          context,
                          icon: RcIcon.english,
                          title: "English",
                          selected: Get.locale?.languageCode == "en",
                          onTap: () => Get.updateLocale(
                            const Locale("en", "US"),
                          ),
                        ),
                        _choiceTile(
                          context,
                          icon: RcIcon.japanese,
                          title: "日本語",
                          selected: Get.locale?.languageCode == "ja",
                          onTap: () => Get.updateLocale(
                            const Locale("ja", "JP"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _settingCard(
                      context,
                      title: "播放",
                      children: [
                        SwitchListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          secondary: Icon(
                            Icons.play_circle_outline,
                            color: scheme.secondary,
                          ),
                          title: darkLightText("自动播放"),
                          value: autoPlay,
                          activeColor: scheme.onSecondary,
                          activeTrackColor: scheme.secondary,
                          onChanged: _updateAutoPlay,
                        ),
                      ],
                    ),
                  ],
                ),
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
}
