import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_models.dart';
import 'setting_screen.dart';

class FamilyTab extends StatelessWidget {
  const FamilyTab({super.key});

  // 顯示家人編輯/新增對話框
  // 根據是否傳入 member 決定是新增還是編輯模式
  void _showFamilyDialog(BuildContext context, {FamilyMember? member}) {
    final isEdit = member != null;
    final isMe = isEdit && member.id == '1';

    final nameController = TextEditingController(
      text: isEdit ? member.name : '',
    );
    final relationController = TextEditingController(
      text: isEdit ? member.relationship : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '編輯家人' : '新增家人'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '姓名'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: relationController,
              readOnly: isMe,
              decoration: InputDecoration(
                labelText: '關係 (如: 父親)',
                filled: isMe,
                fillColor: isMe ? Colors.grey.shade200 : null,
                helperText: isMe ? '本人身分無法修改關係' : null,
              ),
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
              if (nameController.text.isNotEmpty) {
                if (isEdit) {
                  context.read<AppProvider>().updateMember(
                    member.id,
                    nameController.text,
                    relationController.text,
                  );
                } else {
                  context.read<AppProvider>().addMember(
                    nameController.text,
                    relationController.text,
                  );
                }
                Navigator.pop(ctx);
              }
            },
            child: Text(isEdit ? '儲存' : '新增'),
          ),
        ],
      ),
    );
  }

  // 顯示刪除確認對話框
  // 確認是否刪除家人及其相關排程
  void _showDeleteConfirmDialog(BuildContext context, FamilyMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確定刪除？'),
        content: Text('確定要刪除 ${member.name} 嗎？\n這將一併刪除該家人的所有給藥排程。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppProvider>().deleteMember(member.id);
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<AppProvider>().members;

    return Scaffold(
      appBar: AppBar(
        title: const Text('家人管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFamilyDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('新增家人'),
      ),
      body: members.isEmpty
          ? const Center(child: Text('尚無家人資料'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              onReorder: (oldIndex, newIndex) {
                context.read<AppProvider>().reorderMembers(oldIndex, newIndex);
              },
              itemBuilder: (ctx, index) {
                final m = members[index];
                final isMe = m.id == '1';

                return Card(
                  key: ValueKey(m.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(m.name.isNotEmpty ? m.name[0] : '?'),
                    ),
                    title: Text(m.name),
                    subtitle: Text(m.relationship),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showFamilyDialog(context, member: m);
                        } else if (value == 'delete') {
                          _showDeleteConfirmDialog(context, m);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        List<PopupMenuEntry<String>> menuItems = [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('編輯'),
                              ],
                            ),
                          ),
                        ];

                        if (!isMe) {
                          menuItems.add(
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '刪除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return menuItems;
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
