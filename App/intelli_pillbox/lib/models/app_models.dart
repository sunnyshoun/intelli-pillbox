import 'package:flutter/material.dart';

// 藥物狀態列舉
// 定義藥物的三種狀態：準備中、已發放、已服用
enum AlarmStatus { ready, dispensed, taken }

// 藥物模型
// 儲存藥物的名稱、數量和單位
class Medicine {
  String name;
  double amount;
  String unit; // 顆, g, mg

  Medicine({required this.name, required this.amount, required this.unit});

  // 序列化
  // 將 Medicine 物件轉換為 JSON 格式
  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'unit': unit,
  };

  // 反序列化
  // 從 JSON 格式建立 Medicine 物件
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      amount: json['amount'],
      unit: json['unit'],
    );
  }
}

// 家人模型
// 儲存家庭成員的 ID、名稱和關係
class FamilyMember {
  final String id;
  String name;
  String relationship;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
  });

  // 序列化
  // 將 FamilyMember 物件轉換為 JSON 格式
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relationship': relationship,
  };

  // 反序列化
  // 從 JSON 格式建立 FamilyMember 物件
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['name'],
      relationship: json['relationship'],
    );
  }
}

// 給藥鬧鐘卡片模型
// 儲存鬧鐘的 ID、時間、藥物列表、成員 ID 和狀態
class AlarmCardModel {
  final String id;
  TimeOfDay time;
  List<Medicine> medicines;
  String memberId;
  AlarmStatus status;

  AlarmCardModel({
    required this.id,
    required this.time,
    required this.medicines,
    required this.memberId,
    this.status = AlarmStatus.ready,
  });

  // 序列化
  // 將 AlarmCardModel 物件轉換為 JSON 格式
  Map<String, dynamic> toJson() => {
    'id': id,
    // TimeOfDay 存為 "HH:mm" 字串
    'time': '${time.hour}:${time.minute}',
    'medicines': medicines.map((m) => m.toJson()).toList(),
    'memberId': memberId,
    'status': status.index, // Enum 存 index
  };

  // 反序列化
  // 從 JSON 格式建立 AlarmCardModel 物件
  factory AlarmCardModel.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String).split(':');
    return AlarmCardModel(
      id: json['id'],
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      medicines: (json['medicines'] as List)
          .map((m) => Medicine.fromJson(m))
          .toList(),
      memberId: json['memberId'],
      status: AlarmStatus.values[json['status'] ?? 0],
    );
  }
}

// 歷史紀錄模型
// 儲存歷史紀錄的 ID、時間戳、成員名稱、動作和時間標籤
class HistoryLog {
  final String id;
  final DateTime timestamp;
  final String memberName;
  final String action;
  final String timeLabel;

  HistoryLog({
    required this.id,
    required this.timestamp,
    required this.memberName,
    required this.action,
    required this.timeLabel,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'memberName': memberName,
    'action': action,
    'timeLabel': timeLabel,
  };

  factory HistoryLog.fromJson(Map<String, dynamic> json) {
    return HistoryLog(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      memberName: json['memberName'],
      action: json['action'],
      timeLabel: json['timeLabel'],
    );
  }
}
