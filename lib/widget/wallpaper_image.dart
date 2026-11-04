import 'package:flutter/material.dart';

import 'BackGround/back_ground_enum.dart';

/// @ClassName WallpaperImage
/// @Description 页面背景图：自定义图片优先、内置图兜底，并且按「实际显示尺寸」
///              解码——手机相机原图动辄 4000×3000，全尺寸解码一张就要 40MB+，
///              几张壁纸叠加在页面栈里就足以让系统直接杀掉进程（表现为闪退）。
///              解码失败时静默回退内置图，不再出现空白或报错红屏。
/// @Author richuff
/// @Version 1.0
class WallpaperImage extends StatelessWidget {
  final BackGroundEnum slot;
  final BoxFit fit;

  /// 内置图偏淡，避免抢内容；自定义图沿用同一透明度
  final double opacity;

  /// 解码宽度的上下限（设备像素）
  final int minDecodeWidth;
  final int maxDecodeWidth;

  const WallpaperImage({
    super.key,
    required this.slot,
    this.fit = BoxFit.cover,
    this.opacity = 1,
    this.minDecodeWidth = 320,
    this.maxDecodeWidth = 2048,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
        final target =
            (logicalWidth * dpr).round().clamp(minDecodeWidth, maxDecodeWidth);

        final provider = slot.imageProvider;
        final fallback = Image.asset(
          slot.assetPath,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
        );

        return Opacity(
          opacity: opacity,
          child: SizedBox.expand(
            child: Image(
              image: ResizeImage(provider, width: target),
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => fallback,
            ),
          ),
        );
      },
    );
  }
}
