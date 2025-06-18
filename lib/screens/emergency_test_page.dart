import 'package:flutter/material.dart';
import '../services/emergency_service.dart';

class EmergencyTestPage extends StatefulWidget {
  const EmergencyTestPage({super.key});

  @override
  State<EmergencyTestPage> createState() => _EmergencyTestPageState();
}

class _EmergencyTestPageState extends State<EmergencyTestPage> {
  final EmergencyService _emergencyService = EmergencyService();
  bool _isShakeEnabled = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _emergencyService.initialize();
    setState(() {
      _isShakeEnabled = _emergencyService.isShakeDetectionEnabled;
      _isButtonEnabled = _emergencyService.isEmergencyButtonEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Features Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Shake Detection',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Switch(
                      value: _isShakeEnabled,
                      onChanged: (value) async {
                        await _emergencyService.toggleShakeDetection(value);
                        setState(() {
                          _isShakeEnabled = value;
                        });
                      },
                    ),
                    const Text(
                      'Shake your phone 3 times quickly to trigger emergency alert',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Emergency Button',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Switch(
                      value: _isButtonEnabled,
                      onChanged: (value) async {
                        await _emergencyService.toggleEmergencyButton(value);
                        setState(() {
                          _isButtonEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isButtonEnabled
                          ? () => _emergencyService.triggerEmergencyButton()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'EMERGENCY',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emergencyService.dispose();
    super.dispose();
  }
}
