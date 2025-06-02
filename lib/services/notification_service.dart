// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:flutter/material.dart';

// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();
//   int _unreadCount = 0;

//   Future<void> initialize() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const DarwinInitializationSettings iosSettings =
//         DarwinInitializationSettings();

//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     await _notifications.initialize(initSettings);
//     await _loadUnreadCount();
//   }

//   Future<void> _loadUnreadCount() async {
//     final prefs = await SharedPreferences.getInstance();
//     _unreadCount = prefs.getInt('unread_notifications') ?? 0;
//   }

//   Future<void> _saveUnreadCount() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('unread_notifications', _unreadCount);
//   }

//   Future<void> showSOSAlertNotification(
//       String userName, String location) async {
//     try {
//       _unreadCount++;
//       await _saveUnreadCount();

//       // Store notification in SharedPreferences
//       final prefs = await SharedPreferences.getInstance();
//       final notificationsJson = prefs.getString('notifications') ?? '[]';
//       final List<dynamic> notifications = jsonDecode(notificationsJson);

//       final notification = {
//         'type': 'sos_alert',
//         'message': '$userName needs immediate help!\nLocation: $location',
//         'timestamp': DateTime.now().toIso8601String(),
//       };

//       notifications.insert(0, notification);
//       await prefs.setString('notifications', jsonEncode(notifications));

//       const AndroidNotificationDetails androidDetails =
//           AndroidNotificationDetails(
//         'sos_alerts',
//         'SOS Alerts',
//         channelDescription: 'Notifications for SOS alerts',
//         importance: Importance.max,
//         priority: Priority.high,
//         showWhen: true,
//         enableVibration: true,
//         playSound: true,
//         sound: RawResourceAndroidNotificationSound('notification_sound'),
//         largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
//         color: Color(0xFFE53935),
//       );

//       const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         sound: 'notification_sound.aiff',
//       );

//       const NotificationDetails details = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );

//       await _notifications.show(
//         DateTime.now().millisecondsSinceEpoch.remainder(100000),
//         '🚨 Emergency Alert',
//         '$userName needs immediate help!\nLocation: $location',
//         details,
//         payload: jsonEncode(notification),
//       );
//     } catch (e) {
//       print('Error showing SOS notification: $e');
//     }
//   }

//   Future<void> markAllAsRead() async {
//     _unreadCount = 0;
//     await _saveUnreadCount();
//   }

//   int getUnreadCount() => _unreadCount;
// }
