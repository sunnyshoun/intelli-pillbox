import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/app_models.dart';
import '../utils/format_utils.dart';
import 'notification_service.dart';

import 'package:uuid/uuid.dart';

// 產生穩定的 ID
// 根據字串 ID 生成一個穩定的整數 ID，用於 AlarmManager
int generateStableId(String id) {
  var hash = 0;
  for (var i = 0; i < id.length; i++) {
    hash = 31 * hash + id.codeUnitAt(i);
    hash &= 0x7FFFFFFF;
  }
  return hash;
}

// AlarmManager 回調函數
// 當鬧鐘觸發時，系統會呼叫此函式
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
// 執行給藥相關邏輯：檢查是否重複觸發、更新狀態、發送通知、記錄歷史
Future<void> _handleDispenseTask(int alarmId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // Ensure we have the latest data
  final String? alarmsJson = prefs.getString('alarms');
  final String? membersJson = prefs.getString('members');
  final String? logsJson = prefs.getString('logs');
  final String lastDispenseKey = 'last_dispense_$alarmId';

  if (alarmsJson == null) return;

  // 檢查是否在最近 1 分鐘內已經處理過
  final lastDispenseTimestamp = prefs.getInt(lastDispenseKey);
  final now = DateTime.now();
  if (lastDispenseTimestamp != null) {
    final lastDispense = DateTime.fromMillisecondsSinceEpoch(
      lastDispenseTimestamp,
    );
    if (now.difference(lastDispense).inSeconds < 60) {
      debugPrint(
        '⏭️ 跳過重複觸發: alarmId=$alarmId (已在 ${now.difference(lastDispense).inSeconds} 秒前處理)',
      );
      return;
    }
  }

  final List<dynamic> decoded = jsonDecode(alarmsJson);
  List<AlarmCardModel> alarms = decoded
      .map((item) => AlarmCardModel.fromJson(item))
      .toList();

  final index = alarms.indexWhere((a) => generateStableId(a.id) == alarmId);

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
      // 記錄本次處理時間戳
      await prefs.setInt(lastDispenseKey, now.millisecondsSinceEpoch);

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
  // SharedPreferences 中儲存已排程鬧鐘 ID 列表的鍵值
  static const String _prefsKeyScheduledAlarmIds = 'scheduled_alarm_ids';

  // 初始化背景服務
  // 初始化 AndroidAlarmManager 和 NotificationService
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
    await NotificationService.initialize();
  }

  // 同步鬧鐘
  // 比較 activeAlarms 和已排程的鬧鐘，取消不再需要的鬧鐘
  static Future<void> syncAlarms(List<AlarmCardModel> activeAlarms) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> scheduledIdsStr =
        prefs.getStringList(_prefsKeyScheduledAlarmIds) ?? [];
    final Set<int> scheduledIds = scheduledIdsStr.map(int.parse).toSet();

    final Set<int> activeIds = activeAlarms
        .map((a) => generateStableId(a.id))
        .toSet();

    final orphans = scheduledIds.difference(activeIds);

    for (final orphanId in orphans) {
      await AndroidAlarmManager.cancel(orphanId);
    }

    await prefs.setStringList(
      _prefsKeyScheduledAlarmIds,
      activeIds.map((id) => id.toString()).toList(),
    );
  }

  // 排程鬧鐘
  // 設定一個新的鬧鐘，如果時間已過則設為明天
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

    final int alarmId = generateStableId(alarm.id);
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

  // 取消鬧鐘
  // 根據 alarmId 取消已排程的鬧鐘
  static Future<void> cancelAlarm(String alarmId) async {
    final int id = generateStableId(alarmId);
    await AndroidAlarmManager.cancel(id);
    await _removeScheduledId(id);
  }

  // 新增已排程 ID
  // 將 alarmId 加入到 SharedPreferences 中的已排程列表
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

  // 移除已排程 ID
  // 從 SharedPreferences 中的已排程列表移除 alarmId
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
