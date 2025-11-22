import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';
import '../utils/format_utils.dart';

class AppProvider with ChangeNotifier, WidgetsBindingObserver {
  final Uuid _uuid = const Uuid();
  SharedPreferences? _prefs;
  Timer? _refreshTimer;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  List<FamilyMember> _members = [
    FamilyMember(id: '1', name: '我', relationship: '本人'),
  ];

  List<AlarmCardModel> _alarms = [];
  List<HistoryLog> _logs = [];

  List<FamilyMember> get members => _members;
  List<AlarmCardModel> get alarms => _alarms;

  AppProvider() {
    _initLoad();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _syncStateFromStorage(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncStateFromStorage();
    }
  }

  Future<void> _initLoad() async {
    _prefs = await SharedPreferences.getInstance();
    await NotificationService.initialize();

    final themeIndex = _prefs?.getInt('themeMode');
    if (themeIndex != null) _themeMode = ThemeMode.values[themeIndex];

    final String? membersJson = _prefs?.getString('members');
    if (membersJson != null) {
      final List<dynamic> decoded = jsonDecode(membersJson);
      _members = decoded.map((item) => FamilyMember.fromJson(item)).toList();
    }

    final String? alarmsJson = _prefs?.getString('alarms');
    if (alarmsJson != null) {
      final List<dynamic> decoded = jsonDecode(alarmsJson);
      _alarms = decoded.map((item) => AlarmCardModel.fromJson(item)).toList();
    }

    final String? logsJson = _prefs?.getString('logs');
    if (logsJson != null) {
      final List<dynamic> decoded = jsonDecode(logsJson);
      _logs = decoded.map((item) => HistoryLog.fromJson(item)).toList();
    }

    await BackgroundService.syncAlarms(_alarms);
    await _scheduleAllAlarms();
    notifyListeners();
  }

  Future<void> _saveData() async {
    if (_prefs == null) return;
    await _prefs!.setInt('themeMode', _themeMode.index);
    await _prefs!.setString(
      'members',
      jsonEncode(_members.map((m) => m.toJson()).toList()),
    );
    await _prefs!.setString(
      'alarms',
      jsonEncode(_alarms.map((a) => a.toJson()).toList()),
    );
    await _prefs!.setString(
      'logs',
      jsonEncode(_logs.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> _showTakenNotification(
    String memberName,
    List<Medicine> medicines,
  ) async {
    await NotificationService.showNotification(
      id: _uuid.v4().hashCode,
      title: '✅ $memberName 已成功取藥：',
      body: FormatUtils.formatMedicines(medicines),
      channelId: 'pill_taken_channel',
      channelName: '取藥確認',
      channelDescription: '確認使用者已取藥',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  Future<void> _scheduleAllAlarms() async {
    for (var alarm in _alarms) {
      if (alarm.status == AlarmStatus.ready) {
        await BackgroundService.scheduleAlarm(
          alarm,
          getMemberName(alarm.memberId),
        );
      }
    }
  }

  Future<void> _syncStateFromStorage() async {
    if (_prefs == null) return;

    await _prefs!.reload();

    final String? alarmsJson = _prefs!.getString('alarms');
    if (alarmsJson != null) {
      final String currentJson = jsonEncode(
        _alarms.map((a) => a.toJson()).toList(),
      );

      if (alarmsJson != currentJson) {
        final List<dynamic> decoded = jsonDecode(alarmsJson);
        _alarms = decoded.map((item) => AlarmCardModel.fromJson(item)).toList();
        notifyListeners();
      }
    }
  }

  void addMember(String name, String relationship) async {
    _members.add(
      FamilyMember(id: _uuid.v4(), name: name, relationship: relationship),
    );
    await _saveData();
    notifyListeners();
  }

  void updateMember(String id, String name, String relationship) async {
    final index = _members.indexWhere((m) => m.id == id);
    if (index != -1) {
      _members[index].name = name;
      _members[index].relationship = relationship;
      await _saveData();
      notifyListeners();
    }
  }

  void deleteMember(String id) async {
    if (id == '1') return;

    _members.removeWhere((m) => m.id == id);
    _alarms.removeWhere((a) => a.memberId == id);

    await _saveData();
    notifyListeners();
  }

  void reorderMembers(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final FamilyMember item = _members.removeAt(oldIndex);
    _members.insert(newIndex, item);
    await _saveData();
    notifyListeners();
  }

  String getMemberName(String id) {
    return _members
        .firstWhere(
          (m) => m.id == id,
          orElse: () => FamilyMember(id: '', name: '未知', relationship: ''),
        )
        .name;
  }

  void addAlarm(TimeOfDay time, List<Medicine> meds, String memberId) async {
    if (_alarms.length >= 8) return;
    final newAlarm = AlarmCardModel(
      id: _uuid.v4(),
      time: time,
      medicines: meds,
      memberId: memberId,
    );
    _alarms.add(newAlarm);
    _sortAlarms();
    await _saveData();
    await BackgroundService.scheduleAlarm(newAlarm, getMemberName(memberId));
    notifyListeners();
  }

  void updateAlarm(
    String id,
    TimeOfDay time,
    List<Medicine> meds,
    String memberId,
  ) async {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index].time = time;
      _alarms[index].medicines = meds;
      _alarms[index].memberId = memberId;
      _alarms[index].status =
          AlarmStatus.ready; // Reset status to ready on update
      _sortAlarms();
      await _saveData();
      await BackgroundService.cancelAlarm(id);
      await BackgroundService.scheduleAlarm(
        _alarms[index],
        getMemberName(memberId),
      );
      notifyListeners();
    }
  }

  void deleteAlarm(String id) async {
    await BackgroundService.cancelAlarm(id);
    _alarms.removeWhere((a) => a.id == id);
    await _saveData();
    notifyListeners();
  }

  void _sortAlarms() {
    _alarms.sort((a, b) {
      int aMin = a.time.hour * 60 + a.time.minute;
      int bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });
  }

  void simulateTakeMedicine(String alarmId) async {
    int index = _alarms.indexWhere((a) => a.id == alarmId);
    if (index != -1 && _alarms[index].status == AlarmStatus.dispensed) {
      _alarms[index].status = AlarmStatus.taken;
      _addLog(alarmId, "服用者已取藥");
      await _showTakenNotification(
        getMemberName(_alarms[index].memberId),
        _alarms[index].medicines,
      );
      await _saveData();
      notifyListeners();
    }
  }

  void refillAll() async {
    for (var alarm in _alarms) {
      alarm.status = AlarmStatus.ready;
    }
    await _saveData();
    await _scheduleAllAlarms();
    notifyListeners();
  }

  void _addLog(String alarmId, String action) {
    var alarm = _alarms.firstWhere(
      (a) => a.id == alarmId,
      orElse:
          () => AlarmCardModel(
            id: '',
            time: TimeOfDay.now(),
            medicines: [],
            memberId: '',
          ),
    );
    if (alarm.id == '') return;
    var memberName = getMemberName(alarm.memberId);
    String timeStr =
        "${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}";
    _logs.insert(
      0,
      HistoryLog(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        memberName: memberName,
        action: action,
        timeLabel: timeStr,
      ),
    );
  }

  void simulateDispense(String alarmId) async {
    int index = _alarms.indexWhere((a) => a.id == alarmId);
    if (index != -1 && _alarms[index].status == AlarmStatus.ready) {
      _alarms[index].status = AlarmStatus.dispensed;
      _addLog(alarmId, "手動模擬給藥");
      await _saveData();
      notifyListeners();
    }
  }

  void toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      _themeMode = ThemeMode.light;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    await _saveData();
    notifyListeners();
  }

  List<HistoryLog> getLogsByDate(DateTime date) {
    return _logs
        .where(
          (log) =>
              log.timestamp.year == date.year &&
              log.timestamp.month == date.month &&
              log.timestamp.day == date.day,
        )
        .toList();
  }
}
