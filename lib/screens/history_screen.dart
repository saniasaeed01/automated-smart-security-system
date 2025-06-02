import 'package:flutter/material.dart';
import 'settings_screen_template.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenTemplate(
      title: 'History',
      icon: Icons.history,
      content: ListView.builder(
        itemCount: 10,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                'Activity ${index + 1}',
                style: const TextStyle(color: Colors.blue),
              ),
              subtitle: Text(
                'Details about activity ${index + 1}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          );
        },
      ),
    );
  }
}
