import 'package:flutter/material.dart';
import '../models/app_models.dart';

class FormatUtils {
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

extension TimeOfDayFormat on TimeOfDay {
  String get format {
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }
}
