import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rctool/feature/theme/type_value.dart';

class MainSettings extends StatefulWidget {
  const MainSettings({super.key});

  @override
  State<StatefulWidget> createState() => _MainSettings();
}

class _MainSettings extends State<MainSettings> {
  bool autoPlay = false;
  bool musicNotification = true;
  bool cacheFirst = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readData();
    });
  }

  Future<void> _saveData(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _readData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      autoPlay = prefs.getBool(playKey) ?? false;
      musicNotification = prefs.getBool(notificationKey) ?? true;
      cacheFirst = prefs.getBool(cacheFirstKey) ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Container(
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
                  "播放设置",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _switchTile(
                context,
                icon: Icons.play_circle_outline,
                title: "自动播放",
                subtitle: "进入音乐页后自动恢复播放",
                value: autoPlay,
                onChanged: (value) {
                  setState(() {
                    autoPlay = value;
                  });
                  _saveData(playKey, value);
                },
              ),
              _switchTile(
                context,
                icon: Icons.notifications_active_outlined,
                title: "播放通知",
                subtitle: "切歌时显示当前播放提示",
                value: musicNotification,
                onChanged: (value) {
                  setState(() {
                    musicNotification = value;
                  });
                  _saveData(notificationKey, value);
                },
              ),
              _switchTile(
                context,
                icon: Icons.cached,
                title: "缓存优先",
                subtitle: "优先使用已缓存的音乐文件",
                value: cacheFirst,
                onChanged: (value) {
                  setState(() {
                    cacheFirst = value;
                  });
                  _saveData(cacheFirstKey, value);
                },
              ),
            ],
          ),
        ),
      ],
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
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      value: value,
      activeColor: scheme.onSecondary,
      inactiveThumbColor: scheme.surface,
      inactiveTrackColor: scheme.surfaceVariant,
      activeTrackColor: scheme.secondary,
      onChanged: onChanged,
    );
  }
}
