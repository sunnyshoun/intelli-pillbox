import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../providers/app_provider.dart';

class AddAlarmForm extends StatefulWidget {
  final AlarmCardModel? alarmToEdit;

  const AddAlarmForm({super.key, this.alarmToEdit});

  @override
  State<AddAlarmForm> createState() => _AddAlarmFormState();
}

class _AddAlarmFormState extends State<AddAlarmForm> {
  late TimeOfDay _selectedTime;
  String? _selectedMemberId;
  late List<Medicine> _meds;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final members = context.read<AppProvider>().members;
      if (widget.alarmToEdit != null) {
        _selectedTime = widget.alarmToEdit!.time;
        _selectedMemberId = widget.alarmToEdit!.memberId;
        _meds = List.from(widget.alarmToEdit!.medicines);
      } else {
        _selectedTime = TimeOfDay.now();
        _meds = [];
        if (members.isNotEmpty) {
          _selectedMemberId = members.first.id;
        }
      }
      _isInit = true;
    }
  }

  Future<void> _showAddMedicineDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String unit = '顆';

    final Medicine? result = await showDialog<Medicine>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('新增藥物'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '藥物名稱',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: '數量',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: unit,
                        items:
                            ['顆', 'g', 'mg', 'ml', '包']
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => unit = v!),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty &&
                        amountController.text.isNotEmpty) {
                      Navigator.pop(
                        ctx,
                        Medicine(
                          name: nameController.text,
                          amount: double.tryParse(amountController.text) ?? 0,
                          unit: unit,
                        ),
                      );
                    }
                  },
                  child: const Text('加入'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _meds.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = context.read<AppProvider>().members;
    final isEditing = widget.alarmToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEditing ? '編輯給藥排程' : '新增給藥排程',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (t != null) setState(() => _selectedTime = t);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '設定時間',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        _selectedTime.format(context),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedMemberId,
            decoration: const InputDecoration(
              labelText: '服用者',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
              filled: true,
              fillColor: Colors.white10,
            ),
            items:
                members
                    .map(
                      (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                    )
                    .toList(),
            onChanged: (val) => setState(() => _selectedMemberId = val),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('藥物清單', style: Theme.of(context).textTheme.titleMedium),
              OutlinedButton.icon(
                onPressed: _showAddMedicineDialog,
                icon: const Icon(Icons.add),
                label: const Text('新增藥物'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_meds.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('尚無藥物，請點擊右上方新增'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _meds
                      .map(
                        (m) => Chip(
                          avatar: CircleAvatar(
                            child: Text(m.unit.isNotEmpty ? m.unit[0] : ''),
                          ),
                          label: Text('${m.name} ${m.amount}${m.unit}'),
                          onDeleted: () => setState(() => _meds.remove(m)),
                        ),
                      )
                      .toList(),
            ),
          const SizedBox(height: 32),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed:
                _meds.isEmpty
                    ? null
                    : () {
                      if (_selectedMemberId != null) {
                        if (isEditing) {
                          context.read<AppProvider>().updateAlarm(
                            widget.alarmToEdit!.id,
                            _selectedTime,
                            _meds,
                            _selectedMemberId!,
                          );
                        } else {
                          context.read<AppProvider>().addAlarm(
                            _selectedTime,
                            _meds,
                            _selectedMemberId!,
                          );
                        }
                        Navigator.pop(context);
                      }
                    },
            child: Text(
              isEditing ? '更新設定' : '儲存設定',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
