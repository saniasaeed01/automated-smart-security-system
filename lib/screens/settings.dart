// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_import, avoid_print, unused_field

import 'package:flutter/material.dart';
import 'package:safety/screens/login_screen.dart';
import 'profile_edit_page.dart';
import 'settings_screen_template.dart';
import 'history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:safety/utils/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;
  bool _sosDeviceStatus = false;
  bool _isLocationEnabled = true;
  bool _isLoading = true;
  String userName = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isDarkMode = prefs.getBool('dark_mode') ?? false;
        _isNotificationsEnabled =
            prefs.getBool('notifications_enabled') ?? true;
        _isLocationEnabled = prefs.getBool('location_enabled') ?? true;
        _sosDeviceStatus = prefs.getBool('sos_device_status') ?? false;
        email = currentUser.email ?? '';
      });

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (snapshot.exists && mounted) {
        setState(() {
          _sosDeviceStatus = snapshot['sosDeviceStatus'] ?? false;
          userName = snapshot['userName'] ?? 'User';
        });

        await prefs.setBool('sos_device_status', _sosDeviceStatus);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSOSDevice(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'sosDeviceStatus': value});

      await prefs.setBool('sos_device_status', value);

      setState(() {
        _sosDeviceStatus = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS device ${value ? 'enabled' : 'disabled'}'),
          backgroundColor: value ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      print('Error toggling SOS device: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update SOS device status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _isNotificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileCard(context),
                  SizedBox(height: 20),
                  _buildSettingsToggles(themeProvider),
                  SizedBox(height: 20),
                  _buildLanguageAndInfo(),
                  SizedBox(height: 20),
                  _buildSignOutButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(Icons.person,
                size: 50, color: Theme.of(context).primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            userName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            email,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProfileEditPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsToggles(ThemeProvider themeProvider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _buildSettingItem(
            'Dark Mode',
            Icons.dark_mode,
            Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
          ),
          Divider(height: 1),
          _buildSettingItem(
            'SOS Device',
            Icons.security,
            Switch(
              value: _sosDeviceStatus,
              onChanged: (value) => _toggleSOSDevice(value),
            ),
          ),
          Divider(height: 1),
          _buildSettingItem(
            'Notifications',
            Icons.notifications,
            Switch(
              value: _isNotificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),
          Divider(height: 1),
          _buildSettingItem(
            'Location Services',
            Icons.location_on,
            Switch(
              value: _isLocationEnabled,
              onChanged: (value) {
                // Implement if needed
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageAndInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _buildSettingItem(
            'Language',
            Icons.language,
            DropdownButton<String>(
              value: 'English',
              items: ['English', 'اردو'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                // Handle language change
              },
            ),
          ),
          Divider(height: 1),
          _buildSettingItem(
            'About',
            Icons.info,
            Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // About screen logic
            },
          ),
          Divider(height: 1),
          _buildSettingItem(
            'Help & Support',
            Icons.help,
            Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Support screen logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text('Sign Out'),
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, Widget trailing,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}
