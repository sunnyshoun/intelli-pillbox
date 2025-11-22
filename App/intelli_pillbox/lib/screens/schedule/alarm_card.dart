import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';
import 'add_alarm_form.dart';

class AlarmCard extends StatelessWidget {
  final AlarmCardModel alarm;

  const AlarmCard({super.key, required this.alarm});

  void _showDeleteConfirmDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('確認刪除'),
            content: const Text('確定要刪除這個給藥排程嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(ctx);
                  provider.deleteAlarm(alarm.id);
                },
                child: const Text('刪除'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final memberName = provider.getMemberName(alarm.memberId);
    final theme = Theme.of(context);

    Color cardColor;
    Color textColor;
    String statusText;
    bool canEdit = alarm.status == AlarmStatus.ready;
    bool canDelete = alarm.status != AlarmStatus.dispensed;

    switch (alarm.status) {
      case AlarmStatus.ready:
        cardColor = theme.colorScheme.surfaceContainer;
        textColor = theme.colorScheme.onSurface;
        statusText = "準備中";
        break;
      case AlarmStatus.dispensed:
        cardColor = Colors.amber.shade200;
        textColor = Colors.black87;
        statusText = "待取藥";
        break;
      case AlarmStatus.taken:
        cardColor = Colors.green.withOpacity(0.15);
        textColor = Colors.grey.shade700;
        statusText = "已服用";
        break;
    }

    return Card(
      color: cardColor,
      elevation: alarm.status == AlarmStatus.ready ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_filled, color: textColor),
                    const SizedBox(width: 8),
                    Text(
                      alarm.time.format(context),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Chip(
                      label: Text(statusText),
                      backgroundColor: Colors.white.withOpacity(0.5),
                    ),
                    if (canEdit)
                      IconButton(
                        icon: Icon(Icons.edit, color: textColor),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (ctx) => AddAlarmForm(alarmToEdit: alarm),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '服用者: $memberName',
              style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              children:
                  alarm.medicines
                      .map(
                        (m) => Text(
                          '• ${m.name} ${m.amount}${m.unit}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (alarm.status == AlarmStatus.dispensed)
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('模擬: 確認取藥'),
                    onPressed: () => provider.simulateTakeMedicine(alarm.id),
                  )
                else
                  const SizedBox(),
                if (canDelete)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed:
                        () => _showDeleteConfirmDialog(context, provider),
                    child: const Text("刪除"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
