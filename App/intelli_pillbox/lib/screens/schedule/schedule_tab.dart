import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import 'add_alarm_form.dart';
import 'alarm_card.dart';
import '../setting_screen.dart';

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final alarms = provider.alarms;
    final allTaken =
        alarms.isNotEmpty && alarms.every((a) => a.status == AlarmStatus.taken);

    return Scaffold(
      appBar: AppBar(
        title: const Text('給藥排程'),
        actions: [
          if (allTaken)
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('補藥重置'),
              onPressed: () {
                provider.refillAll();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已完成補藥，排程重置')));
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: alarms.length < 8
          ? FloatingActionButton(
              onPressed: () => _showAddAlarmDialog(context),
              child: const Icon(Icons.add_alarm),
            )
          : null,
      body: alarms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.alarm_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('目前沒有給藥排程'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alarms.length,
              itemBuilder: (ctx, index) {
                return AlarmCard(alarm: alarms[index]);
              },
            ),
    );
  }

  // 顯示新增鬧鐘對話框
  // 開啟一個 BottomSheet 讓使用者輸入新鬧鐘的資訊
  void _showAddAlarmDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const AddAlarmForm(),
    );
  }
}
