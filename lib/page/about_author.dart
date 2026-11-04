import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rctool/constant/app_info.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/slide_fade_in.dart';

/// @ClassName AboutAuthor
/// @Description 关于作者页面：渐变信息卡 + 作者自述 + 项目信息 + 仓库地址复制。
/// @Author richuff
/// @Version 2.0
class AboutAuthor extends StatelessWidget {
  const AboutAuthor({super.key});

  static const String _repoUrl = AppInfo.repoUrl;
  static const String _version = AppInfo.version;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      background: BackGroundEnum.aboutBackGround,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SlideFadeIn(
            child: _HeroCard(
              name: 'richuff',
              role: 'Flutter Developer · RcTool 作者'.tr,
              tags: const ['Flutter', 'GetX', 'Live2D', 'SQLite'],
            ),
          ),
          const SizedBox(height: 16),
          SlideFadeIn(
            delay: const Duration(milliseconds: 80),
            child: _InfoCard(
              icon: Icons.person_outline_rounded,
              title: '关于作者'.tr,
              content: '一'.tr,
            ),
          ),
          const SizedBox(height: 12),
          SlideFadeIn(
            delay: const Duration(milliseconds: 160),
            child: _InfoCard(
              icon: Icons.favorite_rounded,
              title: '作者的话'.tr,
              content: '二'.tr,
              accentColor: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          const SlideFadeIn(
            delay: Duration(milliseconds: 240),
            child: _ProjectCard(version: _version, repoUrl: _repoUrl),
          ),
          const SizedBox(height: 22),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copyright_rounded,
                    size: 13, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Made with Flutter by richuff',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 顶部渐变个人卡片
class _HeroCard extends StatelessWidget {
  final String name;
  final String role;
  final List<String> tags;

  const _HeroCard({
    required this.name,
    required this.role,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
            scheme.tertiary.withOpacity(0.22),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装饰光斑
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface.withOpacity(0.28),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface.withOpacity(0.18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 应用 Logo
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        color: scheme.surface.withOpacity(0.85),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'image/RcToolIcon.png',
                          width: 66,
                          height: 66,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 66,
                            height: 66,
                            color: scheme.primaryContainer,
                            child: Icon(Icons.music_note,
                                color: scheme.onPrimaryContainer),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: scheme.onPrimaryContainer,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  scheme.onPrimaryContainer.withOpacity(0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: scheme.surface.withOpacity(0.72),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 文字信息卡
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color? accentColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? scheme.secondary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.65,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 项目信息卡
class _ProjectCard extends StatelessWidget {
  final String version;
  final String repoUrl;

  const _ProjectCard({required this.version, required this.repoUrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.apps_rounded, size: 18, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                '项目信息'.tr,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _InfoRow(label: '版本'.tr, value: 'v$version'),
          _InfoRow(label: '技术栈'.tr, value: 'Flutter · GetX · SQLite'),
          _InfoRow(
            label: '功能'.tr,
            value: '音乐播放 · 每日推荐 · 排行榜 · Live2D'.tr,
          ),
          Divider(color: scheme.outline.withOpacity(0.16)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.link_rounded, color: scheme.secondary),
            title: Text('复制仓库地址'.tr),
            subtitle: Text(
              repoUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            trailing: Icon(Icons.copy_rounded, size: 18, color: scheme.outline),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: repoUrl));
              Get.snackbar(
                '已复制'.tr,
                repoUrl,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
