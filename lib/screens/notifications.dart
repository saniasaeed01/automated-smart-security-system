// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:safety/utils/theme_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class NotificationItem {
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

enum NotificationType {
  emergency,
  contact,
  system,
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications') ?? '[]';
      final List<dynamic> notifications = jsonDecode(notificationsJson);

      setState(() {
        _notifications = notifications.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notifications', '[]');
      setState(() {
        _notifications = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications cleared'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error clearing notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear notifications'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 4,
        shadowColor: isDarkMode ? Colors.black : Colors.grey.withOpacity(0.3),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.delete_sweep,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: _clearAllNotifications,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? Colors.white : Colors.blue,
                ),
              ),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 80,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final timestamp = DateTime.parse(notification['timestamp']);
                    final timeAgo = _getTimeAgo(timestamp);

                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDarkMode
                              ? Colors.grey[700]
                              : Colors.blue.withOpacity(0.1),
                          child: Icon(
                            Icons.notifications,
                            color: isDarkMode ? Colors.white : Colors.blue,
                          ),
                        ),
                        title: Text(
                          notification['message'] ?? 'Notification',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          timeAgo,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// Add this new method to check notification settings
Future<bool> isNotificationsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('notifications_enabled') ??
      true; // Default to true if not set
}

// Update the addNotification function to check settings
Future<void> addNotification(String message,
    {NotificationType type = NotificationType.system}) async {
  // Check if notifications are enabled
  if (!await isNotificationsEnabled()) return;

  final prefs = await SharedPreferences.getInstance();
  final notifications = prefs.getStringList('notifications') ?? [];

  // Add new notification with timestamp and type
  notifications.insert(
    0,
    '$message|${DateTime.now().toIso8601String()}|${type.index}|0',
  );

  // Keep only last 50 notifications
  if (notifications.length > 50) {
    notifications.removeLast();
  }

  await prefs.setStringList('notifications', notifications);
}

// Add a specific method for SOS alerts
Future<void> addSOSAlertNotification(String location) async {
  final message = 'SOS Alert: Emergency alert sent from $location';
  await addNotification(
    message,
    type: NotificationType.emergency,
  );
}
