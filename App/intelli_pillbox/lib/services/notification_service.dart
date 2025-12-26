import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // FlutterLocalNotificationsPlugin 實例，用於管理通知
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // 標記通知服務是否已初始化
  static bool _isInitialized = false;

  // 初始化通知服務
  // 設定 Android 和 iOS 的初始化設定，並請求權限
  static Future<void> initialize({bool requestPermissions = true}) async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid && requestPermissions) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
        await _createNotificationChannels(androidImplementation);
      }
    } else if (Platform.isAndroid && !requestPermissions) {
      // 即使不請求權限，也要建立頻道，否則無法發送通知
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        await _createNotificationChannels(androidImplementation);
      }
    }
    _isInitialized = true;
  }

  // 建立通知頻道
  // 建立給藥提醒和取藥確認的通知頻道
  static Future<void> _createNotificationChannels(
    AndroidFlutterLocalNotificationsPlugin androidImplementation,
  ) async {
    const AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
          'pill_reminder_channel',
          '給藥提醒',
          description: '提醒使用者按時服藥',
          importance: Importance.max,
          playSound: true,
        );
    await androidImplementation.createNotificationChannel(reminderChannel);

    const AndroidNotificationChannel takenChannel = AndroidNotificationChannel(
      'pill_taken_channel',
      '取藥確認',
      description: '確認使用者已取藥',
      importance: Importance.defaultImportance,
      playSound: true,
    );
    await androidImplementation.createNotificationChannel(takenChannel);
  }

  // 顯示通知
  // 發送一個本地通知
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'pill_reminder_channel',
    String channelName = '給藥提醒',
    String? channelDescription,
    Importance importance = Importance.max,
    Priority priority = Priority.high,
    StyleInformation? styleInformation,
  }) async {
    // Ensure initialized (especially for background isolate)
    if (!_isInitialized) {
      await initialize(requestPermissions: false);
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: importance,
          priority: priority,
          showWhen: true,
          styleInformation: styleInformation ?? BigTextStyleInformation(body),
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }
}
