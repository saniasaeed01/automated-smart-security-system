import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  bool _isShakeDetectionEnabled = false;
  bool _isEmergencyButtonEnabled = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final double _shakeThreshold = 15.0; // Adjust this value based on testing
  Timer? _shakeTimer;
  int _shakeCount = 0;
  DateTime? _volumeButtonPressStart;
  bool _isVolumeButtonPressed = false;

  // Add getters for enabled states
  bool get isShakeDetectionEnabled => _isShakeDetectionEnabled;
  bool get isEmergencyButtonEnabled => _isEmergencyButtonEnabled;

  Future<void> initialize() async {
    await _loadSettings();
    if (_isShakeDetectionEnabled) {
      _startShakeDetection();
    }
    _setupVolumeButtonListener();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isShakeDetectionEnabled =
        prefs.getBool('shake_detection_enabled') ?? false;
    _isEmergencyButtonEnabled =
        prefs.getBool('emergency_button_enabled') ?? false;
  }

  Future<void> toggleShakeDetection(bool enabled) async {
    _isShakeDetectionEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shake_detection_enabled', enabled);

    if (enabled) {
      _startShakeDetection();
    } else {
      _stopShakeDetection();
    }
  }

  Future<void> toggleEmergencyButton(bool enabled) async {
    _isEmergencyButtonEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emergency_button_enabled', enabled);
  }

  void _startShakeDetection() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      double acceleration = _calculateAcceleration(event);

      if (acceleration > _shakeThreshold) {
        _shakeCount++;
        if (_shakeCount >= 3) {
          // Require 3 shakes within 1 second
          _handleEmergency();
          _shakeCount = 0;
        }

        // Reset shake count after 1 second
        _shakeTimer?.cancel();
        _shakeTimer = Timer(const Duration(seconds: 1), () {
          _shakeCount = 0;
        });
      }
    });
  }

  void _stopShakeDetection() {
    _accelerometerSubscription?.cancel();
    _shakeTimer?.cancel();
    _shakeCount = 0;
  }

  double _calculateAcceleration(AccelerometerEvent event) {
    return (event.x * event.x + event.y * event.y + event.z * event.z).abs();
  }

  Future<void> _handleEmergency() async {
    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Get user ID
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Save emergency alert to Firestore
      await FirebaseFirestore.instance.collection('emergency_alerts').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(position.latitude, position.longitude),
        'type': 'shake_detection',
        'status': 'active'
      });

      // TODO: Add additional emergency actions here
      // For example: Send SMS, make phone calls, etc.
    } catch (e) {
      print('Error handling emergency: $e');
    }
  }

  Future<void> triggerEmergencyButton() async {
    if (!_isEmergencyButtonEnabled) return;
    await _handleEmergency();
  }

  void _setupVolumeButtonListener() {
    SystemChannels.platform.setMethodCallHandler((call) async {
      if (call.method == 'SystemChrome.systemUIChange') {
        if (call.arguments['type'] == 'volume') {
          if (call.arguments['action'] == 'down') {
            _volumeButtonPressStart = DateTime.now();
            _isVolumeButtonPressed = true;
            _checkVolumeButtonHold();
          } else if (call.arguments['action'] == 'up') {
            _isVolumeButtonPressed = false;
            _volumeButtonPressStart = null;
          }
        }
      }
      return null;
    });
  }

  void _checkVolumeButtonHold() async {
    while (_isVolumeButtonPressed) {
      if (_volumeButtonPressStart != null) {
        Duration holdDuration =
            DateTime.now().difference(_volumeButtonPressStart!);
        if (holdDuration.inSeconds >= 3) {
          // Trigger emergency
          await _handleEmergency();
          _isVolumeButtonPressed = false;
          _volumeButtonPressStart = null;
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void dispose() {
    _stopShakeDetection();
  }
}
