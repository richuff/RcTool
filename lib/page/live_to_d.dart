import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rctool/widget/BackGround/back_ground_enum.dart';
import 'package:rctool/widget/app_scaffold.dart';
import 'package:rctool/widget/live2d/live2d_webview.dart';

/// @ClassName LiveTod
/// @Description Live2D 页：WebView 全屏展示模型，叠加模型信息、互动提示与重新加载入口。
/// @Author richuff
/// @Version 2.0
class LiveTod extends StatefulWidget {
  const LiveTod({super.key});

  @override
  State<LiveTod> createState() => _LiveTodState();
}

class _LiveTodState extends State<LiveTod> {
  /// 改变该值即可重建 WebView，实现「重新加载」。
  int _reloadToken = 0;
  bool _showTips = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppScaffold(
      background: BackGroundEnum.livetodBackGround,
      body: Stack(
        children: [
          Positioned.fill(
            child: Live2DWebView(
              key: ValueKey(_reloadToken),
              assetPath: 'assets/live2d/viewer/index.html',
            ),
          ),
          // 顶部渐隐，让 WebView 与应用栏自然衔接
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 56,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surface.withOpacity(0.9),
                      scheme.surface.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 模型徽标
          Positioned(
            left: 16,
            top: 14,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.86),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: scheme.outline.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.face_retouching_natural,
                        size: 14, color: scheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Haru',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 互动提示卡
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: _showTips ? Offset.zero : const Offset(0, 1.2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showTips ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !_showTips,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        decoration: BoxDecoration(
                          color: scheme.surface.withOpacity(0.78),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: scheme.outline.withOpacity(0.22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.touch_app_outlined,
                                  size: 20, color: scheme.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '互动提示',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '拖动模型身体可以切换动作，视线会跟随指针',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.4,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: '重新加载',
                              onPressed: () {
                                setState(() {
                                  _reloadToken++;
                                  _showTips = true;
                                });
                              },
                              icon: Icon(Icons.refresh_rounded,
                                  color: scheme.onSurfaceVariant),
                            ),
                            IconButton(
                              tooltip: '收起提示',
                              onPressed: () => setState(() => _showTips = false),
                              icon: Icon(Icons.close_rounded,
                                  size: 20, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 收起后的小提示按钮
          if (!_showTips)
            Positioned(
              right: 16,
              bottom: 16,
              child: Material(
                color: scheme.surface.withOpacity(0.9),
                shape: const CircleBorder(),
                elevation: 3,
                shadowColor: scheme.shadow,
                child: IconButton(
                  tooltip: '互动提示',
                  onPressed: () => setState(() => _showTips = true),
                  icon: Icon(Icons.help_outline_rounded, color: scheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
