import 'package:get/get.dart';

class IsDarkController extends GetxController{
  var isDark = false.obs;

  updateIsDark(bool value){
    isDark.value = value;
    update();
  }
}