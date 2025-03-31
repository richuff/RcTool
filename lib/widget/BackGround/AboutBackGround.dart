import 'package:flutter/cupertino.dart';

BoxDecoration aboutBackGround() {
  return const BoxDecoration(
    image: DecorationImage(
        opacity: 0.2,
        image: AssetImage("image/AboutBackGround.jpg"),
        fit: BoxFit.cover),
  );
}