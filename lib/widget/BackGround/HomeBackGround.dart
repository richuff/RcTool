import 'package:flutter/cupertino.dart';

BoxDecoration homeBackGround() {
  return const BoxDecoration(
    image: DecorationImage(
        opacity: 0.2,
        image: AssetImage("image/HomeBackGround.jpg"),
        fit: BoxFit.cover),
  );
}