import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class IsDarkController extends GetxController{
  var isDark = false.obs;

  updateIsDark(bool value){
    isDark.value = value;
    update();
  }
}