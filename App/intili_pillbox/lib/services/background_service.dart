import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/app_models.dart';
import '../utils/format_utils.dart';
import 'notification_service.dart';

import 'package:uuid/uuid.dart';

// 產生穩定的 ID
int _generateStableId(String id) {
  var hash = 0;
  for (var i = 0; i < id.length; i++) {
    hash = 31 * hash + id.codeUnitAt(i);
    hash &= 0x7FFFFFFF;
  }
  return hash;
}

// AlarmManager 回調函數
@pragma('vm:entry-point')
void alarmCallback(int alarmId) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 確保 NotificationService 在背景執行緒中初始化 (不請求權限)
    await NotificationService.initialize(requestPermissions: false);
    await _handleDispenseTask(alarmId);
  } catch (e) {
    debugPrint('❌ 鬧鐘執行失敗: $e');
  }
}

// 處理給藥任務
Future<void> _handleDispenseTask(int alarmId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // Ensure we have the latest data
  final String? alarmsJson = prefs.getString('alarms');
  final String? membersJson = prefs.getString('members');
  final String? logsJson = prefs.getString('logs');

  if (alarmsJson == null) return;

  final List<dynamic> decoded = jsonDecode(alarmsJson);
  List<AlarmCardModel> alarms =
      decoded.map((item) => AlarmCardModel.fromJson(item)).toList();

  final index = alarms.indexWhere((a) => _generateStableId(a.id) == alarmId);

  if (index != -1) {
    final alarm = alarms[index];

    String memberName = '使用者';
    if (membersJson != null) {
      final List<dynamic> members = jsonDecode(membersJson);
      final member = members.firstWhere(
        (m) => m['id'] == alarm.memberId,
        orElse: () => null,
      );
      if (member != null) {
        memberName = member['name'];
      }
    }

    if (alarm.status == AlarmStatus.ready) {
      alarms[index].status = AlarmStatus.dispensed;
      await prefs.setString(
        'alarms',
        jsonEncode(alarms.map((a) => a.toJson()).toList()),
      );

      // 新增歷史紀錄
      List<HistoryLog> logs = [];
      if (logsJson != null) {
        final List<dynamic> decodedLogs = jsonDecode(logsJson);
        logs = decodedLogs.map((item) => HistoryLog.fromJson(item)).toList();
      }

      String timeStr =
          "${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}";

      logs.insert(
        0,
        HistoryLog(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          memberName: memberName,
          action: "自動給藥",
          timeLabel: timeStr,
        ),
      );

      await prefs.setString(
        'logs',
        jsonEncode(logs.map((l) => l.toJson()).toList()),
      );

      debugPrint('🔔 發送通知: $memberName 的藥已發放');
      await NotificationService.showNotification(
        id: alarmId,
        title: '💊 $memberName 的藥已發放！',
        body: FormatUtils.formatMedicines(alarm.medicines),
      );
    } else {
      debugPrint('⚠️ 鬧鐘觸發但狀態非 ready: ${alarm.status}');
    }
  } else {
    debugPrint('⚠️ 找不到對應的鬧鐘 ID: $alarmId');
    await AndroidAlarmManager.cancel(alarmId);
  }
}

class BackgroundService {
  static const String _prefsKeyScheduledAlarmIds = 'scheduled_alarm_ids';

  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    await NotificationService.initialize();
  }

  static Future<void> syncAlarms(List<AlarmCardModel> activeAlarms) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> scheduledIdsStr =
        prefs.getStringList(_prefsKeyScheduledAlarmIds) ?? [];
    final Set<int> scheduledIds = scheduledIdsStr.map(int.parse).toSet();

    final Set<int> activeIds =
        activeAlarms.map((a) => _generateStableId(a.id)).toSet();

    final orphans = scheduledIds.difference(activeIds);

    for (final orphanId in orphans) {
      await AndroidAlarmManager.cancel(orphanId);
    }

    await prefs.setStringList(
      _prefsKeyScheduledAlarmIds,
      activeIds.map((id) => id.toString()).toList(),
    );
  }

  static Future<void> scheduleAlarm(
    AlarmCardModel alarm,
    String memberName,
  ) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final int alarmId = _generateStableId(alarm.id);
    await AndroidAlarmManager.oneShotAt(
      scheduledDate,
      alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      rescheduleOnReboot: true,
    );

    await _addScheduledId(alarmId);
  }

  static Future<void> cancelAlarm(String alarmId) async {
    final int id = _generateStableId(alarmId);
    await AndroidAlarmManager.cancel(id);
    await _removeScheduledId(id);
  }

  static Future<void> _addScheduledId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids =
        prefs.getStringList(_prefsKeyScheduledAlarmIds) ?? [];
    final strId = id.toString();
    if (!ids.contains(strId)) {
      ids.add(strId);
      await prefs.setStringList(_prefsKeyScheduledAlarmIds, ids);
    }
  }

  static Future<void> _removeScheduledId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids =
        prefs.getStringList(_prefsKeyScheduledAlarmIds) ?? [];
    final strId = id.toString();
    if (ids.contains(strId)) {
      ids.remove(strId);
      await prefs.setStringList(_prefsKeyScheduledAlarmIds, ids);
    }
  }
}
