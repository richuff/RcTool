import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static const String newMusicChannelId = 'new_music_channel';
  static const String newMusicChannelName = 'New Music Releases';
  static const String newMusicChannelDescription = 'Notifications for new music releases';

  static const String playbackControlChannelId = 'playback_control_channel';
  static const String playbackControlChannelName = 'Playback Controls';
  static const String playbackControlChannelDescription = 'Notifications for playback controls';

  static const String ticker = 'ticker';

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notificationsPlugin.initialize(initializationSettings);

    // 创建新音乐发布通知通道
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      AndroidNotificationChannel(
        newMusicChannelId,
        newMusicChannelName,
        description: newMusicChannelDescription,
        importance: Importance.high,
      ),
    );

    // 创建播放控制通知通道
    await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      AndroidNotificationChannel(
        playbackControlChannelId,
        playbackControlChannelName,
        description: playbackControlChannelDescription,
        importance: Importance.low,
      ),
    );
  }

  Future<void> showNewMusicNotification({required String title, required String body}) async {
    final AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      newMusicChannelId,
      newMusicChannelName,
      channelDescription: newMusicChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: ticker,
    );
    final DarwinNotificationDetails iosNotificationDetails =
    DarwinNotificationDetails();
    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /*Future<void> showPlaybackControlNotification({required String title, required String body}) async {
    final AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      playbackControlChannelId,
      playbackControlChannelName,
      channelDescription: playbackControlChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ticker: ticker,
      // 设置为true以使通知持续显示
      ongoing: true,
    );
    final DarwinNotificationDetails iosNotificationDetails =
    DarwinNotificationDetails();
    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    await _notificationsPlugin.show(
      1,
      title,
      body,
      platformChannelSpecifics,
    );
  }*/
}