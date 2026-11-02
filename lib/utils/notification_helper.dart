import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationHelper {
  static const String newMusicChannelId = 'new_music_channel';
  static const String newMusicChannelName = 'New Music Releases';
  static const String newMusicChannelDescription =
      'Notifications for new music releases';

  static const String playbackControlChannelId = 'playback_control_channel';
  static const String playbackControlChannelName = 'Playback Controls';
  static const String playbackControlChannelDescription =
      'Notifications for playback controls';

  static const String ticker = 'ticker';

  /// 常驻播放通知的 id（与「新歌提示」的 0 区分开）
  static const int playbackNotificationId = 1;

  /// 通知按钮动作 id
  static const String actionPrevious = 'rctool.prev';
  static const String actionToggle = 'rctool.toggle';
  static const String actionNext = 'rctool.next';

  /// 点击通知按钮的回调，由 MusicController 注入
  void Function(String actionId)? onAction;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    // 通知按钮（上一首 / 暂停 / 下一首）在应用进程存活时回调到 Dart 侧
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final actionId = response.actionId;
        if (actionId == null || actionId.isEmpty) return;
        onAction?.call(actionId);
      },
    );

    // 创建新音乐发布通知通道
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            newMusicChannelId,
            newMusicChannelName,
            description: newMusicChannelDescription,
            importance: Importance.high,
          ),
        );

    // 创建播放控制通知通道
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            playbackControlChannelId,
            playbackControlChannelName,
            description: playbackControlChannelDescription,
            importance: Importance.low,
          ),
        );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// 常驻播放控制通知：三个动作按钮 + 点击回到 App
  ///
  /// 说明：项目没有接入 audio_service 前台服务，通知按钮依赖应用进程存活
  /// （后台/息屏时仍然有效），进程被杀后系统只会保留通知本身。
  Future<void> showPlaybackNotification({
    required String title,
    required String body,
    required bool isPlaying,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      playbackControlChannelId,
      playbackControlChannelName,
      channelDescription: playbackControlChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      playSound: false,
      category: AndroidNotificationCategory.transport,
      actions: [
        AndroidNotificationAction(
          actionPrevious,
          '上一首'.tr,
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          actionToggle,
          isPlaying ? '暂停'.tr : '播放'.tr,
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          actionNext,
          '下一首'.tr,
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
    );
    await _notificationsPlugin.show(
      playbackNotificationId,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  Future<void> cancelPlaybackNotification() async {
    await _notificationsPlugin.cancel(playbackNotificationId);
  }

  Future<void> showNewMusicNotification(
      {required String title, required String body}) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      newMusicChannelId,
      newMusicChannelName,
      channelDescription: newMusicChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: ticker,
    );
    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
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
