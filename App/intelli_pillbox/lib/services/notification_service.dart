import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

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
      final androidImplementation =
          _notificationsPlugin
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
      final androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (androidImplementation != null) {
        await _createNotificationChannels(androidImplementation);
      }
    }
    _isInitialized = true;
  }

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
