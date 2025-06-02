// ignore_for_file: unused_import, avoid_print

import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SMSService {
  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();

  Future<void> sendWhatsAppDirect(String phoneNumber, String message) async {
    try {
      // Remove any non-digit characters from phone number
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      // Ensure number starts with country code
      if (!cleanNumber.startsWith('+')) {
        cleanNumber =
            '+92${cleanNumber.startsWith('0') ? cleanNumber.substring(1) : cleanNumber}';
      }

      final Uri whatsappUri = Uri.parse(
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      print('Error sending WhatsApp message: $e');
      rethrow;
    }
  }

  Future<void> sendEmergencyAlert(
      List<String> phoneNumbers, String location, String userName) async {
    if (phoneNumbers.isEmpty) {
      throw Exception('No phone numbers provided');
    }

    final message = '''
🚨 *EMERGENCY ALERT* 🚨

$userName needs immediate help!

📍 *Location:* $location

⏰ Time: ${DateTime.now().toString()}

Please respond immediately!
''';

    for (String phoneNumber in phoneNumbers) {
      try {
        await sendWhatsAppDirect(phoneNumber, message);
        // Add a small delay between messages to prevent rate limiting
        await Future.delayed(Duration(seconds: 1));
      } catch (e) {
        print('Failed to send alert to $phoneNumber: $e');
        // Continue with next number even if one fails
        continue;
      }
    }
  }
}
