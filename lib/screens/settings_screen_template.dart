// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class SettingsScreenTemplate extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget content;
  final VoidCallback? onLogout;

  const SettingsScreenTemplate({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          if (onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          onLogout?.call();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/signin',
                              (route) => false,
                            );
                          }
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          // Content section
          Expanded(child: content),
        ],
      ),
    );
  }
}
