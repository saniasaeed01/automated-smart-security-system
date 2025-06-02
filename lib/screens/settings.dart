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
  bool _isSOSDeviceConnected = false;
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

      // Load settings from SharedPreferences first (faster)
      setState(() {
        _isDarkMode = prefs.getBool('dark_mode') ?? false;
        _isNotificationsEnabled =
            prefs.getBool('notifications_enabled') ?? true;
        _isLocationEnabled = prefs.getBool('location_enabled') ?? true;
        email = currentUser.email ?? '';
      });

      // Then load Firestore data
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (snapshot.exists && mounted) {
        setState(() {
          _isSOSDeviceConnected = snapshot['isSOSDeviceConnected'] ?? false;
          userName = snapshot['userName'] ?? 'User';
          _isLoading = false;
        });

        // Cache the SOS device status
        await prefs.setBool('sos_device_connected', _isSOSDeviceConnected);
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleSOSDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newState = !_isSOSDeviceConnected;

      // Update Firestore
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userRef.update({
        'isSOSDeviceConnected': newState,
      });

      // Update local state and SharedPreferences
      setState(() {
        _isSOSDeviceConnected = newState;
      });
      await prefs.setBool('sos_device_connected', newState);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SOS device ${newState ? 'enabled' : 'disabled'}'),
            backgroundColor: newState ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      print('Error toggling SOS device: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update SOS device status'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).primaryColor,
                          ),
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
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileEditPage(),
                              ),
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
                  ),
                  SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          'Dark Mode',
                          Icons.dark_mode,
                          Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                          ),
                        ),
                        Divider(height: 1),
                        _buildSettingItem(
                          'SOS Device',
                          Icons.security,
                          Switch(
                            value: _isSOSDeviceConnected,
                            onChanged: (value) {
                              _toggleSOSDevice();
                            },
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
                              // Handle location services toggle
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
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
                            // Handle about tap
                          },
                        ),
                        Divider(height: 1),
                        _buildSettingItem(
                          'Help & Support',
                          Icons.help,
                          Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Handle help & support tap
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
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
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData icon,
    Widget trailing, {
    VoidCallback? onTap,
  }) {
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
}
