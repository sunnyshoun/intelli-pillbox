import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    String themeText = '系統預設';
    IconData themeIcon = Icons.brightness_auto;

    switch (provider.themeMode) {
      case ThemeMode.system:
        themeText = '系統預設';
        themeIcon = Icons.brightness_auto;
        break;
      case ThemeMode.light:
        themeText = '亮色模式';
        themeIcon = Icons.light_mode;
        break;
      case ThemeMode.dark:
        themeText = '暗色模式';
        themeIcon = Icons.dark_mode;
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '一般設定',
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('外觀主題'),
            subtitle: Text(themeText),
            trailing: Icon(themeIcon),
            onTap: () {
              provider.toggleTheme();
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '裝置與通知 (開發中)',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.bluetooth, color: Colors.grey),
            title: Text('藍芽裝置設定', style: TextStyle(color: Colors.grey)),
            subtitle: Text('尚未連線'),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.notifications_outlined, color: Colors.grey),
            title: Text('通知設定', style: TextStyle(color: Colors.grey)),
            enabled: false,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('關於'),
            subtitle: const Text('智慧藥盒管理 v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '智慧藥盒',
                applicationVersion: '1.0.0',
                children: [const Text('這是一個使用 Flutter 開發的智慧藥盒管理 APP。')],
              );
            },
          ),
        ],
      ),
    );
  }
}
