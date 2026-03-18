import 'package:permission_handler/permission_handler.dart';

class PermissionRequest{
   static Future<void> requestNotificationPermission() async {
    // 请求通知权限
    var notificationStatus = await Permission.notification.status;
    //请求蓝牙权限
    var bluetoothStatus = await Permission.bluetoothConnect.status;

    if (!notificationStatus.isGranted && !bluetoothStatus.isGranted) {
      notificationStatus = await Permission.notification.request();
      bluetoothStatus = await Permission.bluetoothConnect.request();
    }
  }
}