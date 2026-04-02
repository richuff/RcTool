import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionRequest{
   static Future<void> requestNotificationPermission() async {
    // 请求通知权限
    var notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted ) {
      notificationStatus = await Permission.notification.request();
    }
    //请求蓝牙权限
    if (!kIsWeb) {
      var bluetoothStatus = await Permission.bluetoothConnect.status;
      if (!bluetoothStatus.isGranted){
        bluetoothStatus = await Permission.bluetoothConnect.request();
      }
    }
  }
}