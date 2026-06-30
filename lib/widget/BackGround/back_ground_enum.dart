import 'package:flutter/cupertino.dart';

/// @EnumName BackGroundEnum
/// @Description 背景图枚举类
/// @Author richuff
/// @Date 2024-11-12
/// @Version 1.0
enum BackGroundEnum {
  homeBackGround(
    BoxDecoration(
      image: DecorationImage(
        opacity: 0.2,
        image: AssetImage("image/HomeBackGround.jpg"),
        fit: BoxFit.cover))),

  livetodBackGround(
    BoxDecoration(
    image: DecorationImage(
    opacity: 0.2,
    image: AssetImage("image/LivetodBackGround.jpg"),
    fit: BoxFit.cover))),

  musicBackGround(
      BoxDecoration(
      image: DecorationImage(
          opacity: 0.2,
          image: AssetImage("image/MusicBackGround.jpg"),
          fit: BoxFit.cover))),

  aboutBackGround(
      BoxDecoration(
      image: DecorationImage(
          opacity: 0.2,
          image: AssetImage("image/AboutBackGround.jpg"),
          fit: BoxFit.cover)));

  final BoxDecoration decoration;

  const BackGroundEnum(this.decoration);
}
