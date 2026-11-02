import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/wallpaper_controller.dart';

/// @EnumName BackGroundEnum
/// @Description 页面背景槽位。图片本身不再写死：
///              优先用用户放在 `<外部目录>/wallpaper/<slot>.<ext>` 的图，
///              没有时才回退到随包内置的默认图（见 [assetPath]）。
/// @Author richuff
/// @Date 2024-11-12
/// @Version 2.0
enum BackGroundEnum {
  homeBackGround('home', 'image/HomeBackGround.jpg', '首页'),
  livetodBackGround('live2d', 'image/LivetodBackGround.jpg', 'Live2D'),
  musicBackGround('music', 'image/MusicBackGround.jpg', '音乐'),
  aboutBackGround('about', 'image/AboutBackGround.jpg', '关于');

  /// 外部目录中的文件名（不含扩展名），也支持放一张 `default` 统一生效
  final String slot;

  /// 内置兜底图，用户没有替换时使用
  final String assetPath;

  /// 设置页展示用的名字
  final String label;

  const BackGroundEnum(this.slot, this.assetPath, this.label);

  /// 背景图不透明度：内置图偏淡，自定义图同样压淡避免抢内容
  double get opacity => 0.2;

  /// 当前应使用的图片：自定义文件优先，其次内置资源
  ImageProvider get imageProvider {
    final controller = Get.isRegistered<WallpaperController>()
        ? Get.find<WallpaperController>()
        : null;
    return controller?.customImage(slot) ?? AssetImage(assetPath);
  }

  /// 是否正在使用用户自己的壁纸
  bool get isCustom {
    final controller = Get.isRegistered<WallpaperController>()
        ? Get.find<WallpaperController>()
        : null;
    return controller?.hasCustom(slot) ?? false;
  }

  BoxDecoration get decoration => BoxDecoration(
        image: DecorationImage(
          opacity: opacity,
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      );
}
