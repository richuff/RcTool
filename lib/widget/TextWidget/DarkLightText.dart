import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

Text darkLightText(String text){
  return Text(
    text,
    style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
  );
}