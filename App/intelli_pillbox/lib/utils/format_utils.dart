import 'package:flutter/material.dart';
import '../models/app_models.dart';

class FormatUtils {
  // 格式化藥物列表
  // 將藥物列表轉換為易讀的字串格式，包含名稱、數量和單位
  static String formatMedicines(List<Medicine> medicines) {
    if (medicines.isEmpty) return "• 無詳細藥物資訊";
    return medicines
        .map((m) {
          String amountStr = m.amount.toString().replaceAll(
            RegExp(r"([.]*0)(?!.*\d)"),
            "",
          );
          return "• ${m.name} $amountStr ${m.unit}";
        })
        .join("\n");
  }
}

// TimeOfDay 擴充功能
// 增加 format 屬性，將 TimeOfDay 格式化為 "HH:mm" 字串
extension TimeOfDayFormat on TimeOfDay {
  String get format {
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }
}
