import 'package:flutter/material.dart';
import 'package:get/get.dart';

Text darkLightText(String text){
  return Text(
    text,
    style: TextStyle(color: Get.isDarkMode ? Colors.white : Colors.black),
  );
}