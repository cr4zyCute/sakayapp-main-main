import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SwitchListTile(
            title: const Text("Enable Notifications"),
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            activeColor: Colors.blueAccent,
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: _darkModeEnabled,
            onChanged: (val) => setState(() => _darkModeEnabled = val),
            activeColor: Colors.blueAccent,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Save settings logic here
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Settings saved")));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text("Save Settings", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
