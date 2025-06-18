// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print, unused_element

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safety/screens/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety/screens/notifications.dart';
import 'package:safety/screens/trusted_contacts_page.dart';
import 'package:safety/screens/location.dart';
import 'package:safety/screens/voice_command_setup_page.dart';
import 'package:safety/screens/audio.dart';
import 'package:safety/screens/emergency_test_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:safety/utils/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety/services/sms_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AudioRecordPage _audioPage = AudioRecordPage();

  final List<Widget> _pages = [
    const HomeScreenContent(),
    const TrustedContactsPage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.microphone,
      Permission.contacts,
      Permission.sms,
    ].request();

    // Show dialog if any permission is denied
    if (statuses.values.any((status) => status.isDenied)) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Permissions Required'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Please enable the following permissions to use all features:'),
                  SizedBox(height: 10),
                  if (statuses[Permission.location]?.isDenied ?? false)
                    Text('• Location access for tracking'),
                  if (statuses[Permission.microphone]?.isDenied ?? false)
                    Text('• Microphone access for audio recording'),
                  if (statuses[Permission.contacts]?.isDenied ?? false)
                    Text('• Contacts access for emergency contacts'),
                  if (statuses[Permission.sms]?.isDenied ?? false)
                    Text('• SMS access for emergency alerts'),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Open Settings'),
                  onPressed: () {
                    openAppSettings();
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Continue Anyway'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(
              Icons.security,
              color: isDarkMode ? Colors.white : Color(0xFF2196F3),
              size: 40,
            ),
            SizedBox(width: 12),
            Text(
              'AutoSecure',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Color(0xFF2196F3),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 4,
        shadowColor:
            isDarkMode ? Colors.black : Color(0xFF2196F3).withOpacity(0.3),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.transparent,
                  spreadRadius: 0,
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.pushNamed(context, '/voice-commands');
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      // child: Icon(
                      //   Icons.mic_outlined,
                      //   color: isDarkMode ? Colors.white : Color(0xFF2196F3),
                      //   size: 28,
                      // ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: isDarkMode ? Colors.white : Color(0xFF2196F3),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black
                  : Color(0xFF2196F3).withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Trusted Contacts',
            ),
            // Remove or uncomment if you have RecordingsHistoryPage
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.mic),
            //   label: 'Recordings',
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          selectedItemColor: isDarkMode ? Colors.white : Color(0xFF2196F3),
          unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey,
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenContentState createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;
  Position? currentPosition;
  // ignore: unused_field
  static const LatLng _defaultLocation = LatLng(0, 0);
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // ignore: unused_field
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _pulseController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _pulseController.forward();
        }
      });
    _pulseController.forward();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          currentPosition = position;
        });

        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _showMapScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    Colors.grey[900]!,
                    Colors.grey[850]!,
                    Colors.grey[800]!,
                  ]
                : [
                    Colors.white,
                    Colors.grey[100]!,
                    Colors.grey[200]!,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  children: [
                    Text(
                      'Are you in emergency?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDarkMode ? Colors.white : Color(0xFF2196F3),
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.2)
                                : Color(0xFF2196F3).withOpacity(0.2),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Press the SOS button below and help will reach you shortly',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        height: 1.3,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.red.shade300,
                                    Colors.red.shade400,
                                    Colors.red.shade600,
                                    Colors.red.shade700,
                                  ],
                                  stops: [0.2, 0.5, 0.8, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.shade400.withOpacity(0.6),
                                    blurRadius: 30,
                                    spreadRadius: _pulseAnimation.value * 5,
                                  ),
                                  BoxShadow(
                                    color: Colors.red.shade700.withOpacity(0.4),
                                    blurRadius: 50,
                                    spreadRadius: _pulseAnimation.value * 15,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    // Get current user
                                    User? currentUser =
                                        FirebaseAuth.instance.currentUser;
                                    if (currentUser == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please log in to use this feature'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Fetch latest SOS status from Firestore
                                    DocumentSnapshot userDoc =
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(currentUser.uid)
                                            .get();

                                    bool isSOSDeviceConnected = false;
                                    if (userDoc.exists) {
                                      isSOSDeviceConnected =
                                          userDoc['sosDeviceStatus'] ?? false;
                                    }

                                    if (isSOSDeviceConnected) {
                                      try {
                                        // Get current location
                                        Position position =
                                            await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.high,
                                        );
                                        String location =
                                            'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

                                        // Get trusted contacts from SharedPreferences
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        final contactsJson = prefs.getString(
                                                'trusted_contacts') ??
                                            '[]';
                                        final List<dynamic> contacts =
                                            jsonDecode(contactsJson);

                                        List<String> phoneNumbers = [];
                                        for (var contact in contacts) {
                                          if (contact['phoneNumber'] != null &&
                                              contact['phoneNumber']
                                                  .toString()
                                                  .isNotEmpty) {
                                            phoneNumbers.add(
                                                contact['phoneNumber']
                                                    .toString());
                                          }
                                        }

                                        if (phoneNumbers.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'No trusted contacts found. Please add contacts first.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        // Show loading indicator
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.red),
                                            ),
                                          ),
                                        );

                                        // Send SMS messages
                                        final smsService = SMSService();
                                        bool hasSMSPermission = await smsService
                                            .requestSMSPermission();

                                        if (!hasSMSPermission) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'SMS permission is required to send emergency alerts'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        for (String phoneNumber
                                            in phoneNumbers) {
                                          final message = '''
🚨 EMERGENCY ALERT 🚨

I need immediate help!

📍 My Location: $location

⏰ Time: ${DateTime.now().toString()}

Please respond immediately!
''';
                                          try {
                                            await smsService.sendEmergencySMS(
                                                phoneNumber, message);
                                            await Future.delayed(
                                                Duration(seconds: 1));
                                          } catch (e) {
                                            print(
                                                'Failed to send SMS to $phoneNumber: $e');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to send SMS to $phoneNumber'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            continue;
                                          }
                                        }

                                        // Hide loading indicator
                                        Navigator.pop(context);

                                        // Show success message
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Emergency SMS sent to ${phoneNumbers.length} contacts'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        // Hide loading indicator if showing
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to send emergency alert: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Please enable SOS device in settings to use this feature'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  customBorder: CircleBorder(),
                                  child: Center(
                                    child: Text(
                                      'SOS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.mic,
                            label: 'Voice SOS',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const VoiceCommandSetupPage(),
                                ),
                              );
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.location_on,
                            label: 'Location',
                            onPressed: _showMapScreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return SizedBox(
      width: 160,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          foregroundColor: isDarkMode ? Colors.white : Color(0xFF2196F3),
          elevation: 12,
          shadowColor:
              isDarkMode ? Colors.black : Color(0xFF2196F3).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: isDarkMode ? Colors.white : Color(0xFF2196F3),
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
