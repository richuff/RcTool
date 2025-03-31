import 'package:flutter/cupertino.dart';

BoxDecoration livetodBackGround() {
  return const BoxDecoration(
    image: DecorationImage(
        opacity: 0.2,
        image: AssetImage("image/LivetodBackGround.jpg"),
        fit: BoxFit.cover),
  );
}