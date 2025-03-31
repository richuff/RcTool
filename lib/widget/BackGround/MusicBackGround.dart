import 'package:flutter/cupertino.dart';

BoxDecoration musicBackGround() {
  return const BoxDecoration(
    image: DecorationImage(
        opacity: 0.2,
        image: AssetImage("image/MusicBackGround.jpg"),
        fit: BoxFit.cover),
  );
}