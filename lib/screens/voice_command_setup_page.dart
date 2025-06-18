// ignore_for_file: sort_child_properties_last, deprecated_member_use, avoid_print, unused_element, unused_import, unused_field, use_build_context_synchronously, unnecessary_brace_in_string_interps

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart'; // For toast messages
import 'package:provider/provider.dart';
import 'package:safety/utils/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'dart:io';
import 'package:safety/services/emergency_service.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';

class VoiceCommandSetupPage extends StatefulWidget {
  const VoiceCommandSetupPage({super.key});

  @override
  State<VoiceCommandSetupPage> createState() => _VoiceCommandSetupPageState();
}

class _VoiceCommandSetupPageState extends State<VoiceCommandSetupPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final EmergencyService _emergencyService = EmergencyService();
  bool _isListening = false;
  String _customCommand = '';
  double _sensitivity = 0.5;
  bool _isTestMode = false;
  bool _emergencyButtonEnabled = false;
  bool _shakeDetectionEnabled = false;
  String _testModeFeedback = '';
  bool _sendLocation = false;
  String _recordedFilePath = '';
  List<Map<String, dynamic>> _savedCommands = [];
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentlyPlayingPath;
  DateTime? _volumeButtonPressStart;
  bool _isVolumeButtonPressed = false;
  StreamSubscription? _volumeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _fetchSavedCommands();
    _loadSettings();
    _initRecorderAndPlayer();
    _requestPermissions();
    _emergencyService.initialize();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _speech.cancel();
    _emergencyService.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyButtonEnabled =
          prefs.getBool('emergency_button_enabled') ?? false;
      _shakeDetectionEnabled =
          prefs.getBool('shake_detection_enabled') ?? false;
      _sendLocation = prefs.getBool('send_location_enabled') ?? false;
      _sensitivity = prefs.getDouble('voice_sensitivity') ?? 0.5;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emergency_button_enabled', _emergencyButtonEnabled);
    await prefs.setBool('shake_detection_enabled', _shakeDetectionEnabled);
    await prefs.setBool('send_location_enabled', _sendLocation);
    await prefs.setDouble('voice_sensitivity', _sensitivity);

    // Update emergency service settings
    await _emergencyService.toggleShakeDetection(_shakeDetectionEnabled);
    await _emergencyService.toggleEmergencyButton(_emergencyButtonEnabled);
  }

  Future<void> _requestPermissions() async {
    // Request microphone permission
    var micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Microphone permission is required for voice commands'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      print('Initializing speech recognition...');

      // First check if speech recognition is available
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('Speech status changed: $status');
          if (mounted) {
            setState(() {
              if (status == 'listening') {
                _isListening = true;
                _customCommand = 'Listening...';
              } else if (status == 'notListening') {
                _isListening = false;
              }
            });
          }
        },
        onError: (error) {
          print('Speech error occurred: $error');
          if (mounted) {
            setState(() {
              _isListening = false;
              _customCommand = 'Error: ${error.errorMsg}';
            });
          }
        },
        debugLogging: true,
      );

      if (!available) {
        print('Speech recognition not available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available on this device'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('Speech recognition initialized successfully');
    } catch (e) {
      print('Error in speech initialization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing speech: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
            _volumeButtonPressStart = DateTime.now();
            _isVolumeButtonPressed = true;
            _checkVolumeButtonHold();
          }
        } else if (event is RawKeyUpEvent) {
          if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
            _isVolumeButtonPressed = false;
            _volumeButtonPressStart = null;
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Voice Commands',
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
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recording Section
                _buildSectionCard(
                  title: 'Record Voice Command',
                  icon: Icons.mic,
                  child: Column(
                    children: [
                      Text(
                        _customCommand.isEmpty
                            ? 'No command recorded yet'
                            : _customCommand,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isRecording) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Microphone Active',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed:
                            _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                            color: isDarkMode ? Colors.white : Colors.blue),
                        label: Text(
                          _isRecording ? 'Stop Recording' : 'Record Command',
                          style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.blue),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? Colors.grey[850] : Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isDarkMode ? Colors.white : Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _customCommand.isNotEmpty &&
                                    _customCommand !=
                                        'No command recorded yet' &&
                                    _customCommand !=
                                        'Recording in progress...' &&
                                    _recordedFilePath.isNotEmpty
                                ? _saveCommand
                                : null,
                            child: const Text('Save Command'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDarkMode ? Colors.grey[850] : Colors.white,
                              foregroundColor:
                                  isDarkMode ? Colors.white : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Saved Commands Section
                _buildSavedCommandsSection(),

                const SizedBox(height: 16),

                // Sensitivity Adjustment Section
                _buildSectionCard(
                  title: 'Sensitivity',
                  icon: Icons.tune,
                  child: _buildSensitivitySlider(),
                ),

                const SizedBox(height: 16),

                // Test Mode Section
                _buildSectionCard(
                  title: 'Test Voice Command',
                  icon: Icons.check_circle,
                  child: _buildTestModeSection(),
                ),

                const SizedBox(height: 16),

                // Backup Activation Section
                _buildSectionCard(
                  title: 'Backup Activation',
                  icon: Icons.security,
                  child: Column(
                    children: [
                      _buildBackupOption(
                        'Shake Detection',
                        Icons.vibration,
                        _shakeDetectionEnabled,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.volume_up,
                            color: Color(0xFF2196F3)),
                        title: const Text(
                          'Volume Button SOS',
                          style: TextStyle(color: Color(0xFF2196F3)),
                        ),
                        subtitle: const Text(
                          'Hold volume down button for 3 seconds to trigger SOS',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline,
                              color: Color(0xFF2196F3)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Volume Button SOS'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('To trigger SOS using volume button:'),
                                    SizedBox(height: 8),
                                    Text(
                                        '• Press and hold the volume down button'),
                                    Text('• Keep holding for 3 seconds'),
                                    Text(
                                        '• Your location will be sent to emergency contacts'),
                                    Text(
                                        '• Emergency services will be notified'),
                                    SizedBox(height: 8),
                                    Text(
                                      'Note: This feature works even when the app is in the background.',
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Got it!'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Live Location Trigger Section
                _buildSectionCard(
                  title: 'Live Location Trigger',
                  icon: Icons.location_on,
                  child: _buildLocationTrigger(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBackupOption(String title, IconData icon, bool isEnabled) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: Color(0xFF2196F3))),
      secondary: Icon(icon, color: const Color(0xFF2196F3)),
      value: isEnabled,
      onChanged: (bool value) async {
        setState(() {
          if (title == 'Shake Detection') {
            _shakeDetectionEnabled = value;
          }
        });
        await _saveSettings();

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${title} ${value ? 'enabled' : 'disabled'}'),
            backgroundColor: value ? Colors.green : Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );

        // If shake detection is enabled, show instructions
        if (title == 'Shake Detection' && value) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Shake Detection Enabled'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shake detection is now active.'),
                  SizedBox(height: 8),
                  Text('To trigger emergency:'),
                  Text('• Shake your phone 3 times quickly'),
                  Text('• Your location will be sent to emergency contacts'),
                  Text('• Emergency services will be notified'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Got it!'),
                ),
              ],
            ),
          );
        }
      },
      activeColor: Colors.blue,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.blue.withOpacity(0.5),
    );
  }

  Widget _buildSensitivitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Voice Recognition Sensitivity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
            ),
            IconButton(
              icon: Icon(Icons.info_outline, color: Color(0xFF2196F3)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('About Sensitivity'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This setting controls how easily the app recognizes your voice commands:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        Text(
                            '• Low: For quiet environments, requires clear speech'),
                        Text('• Medium: Good for everyday use'),
                        Text(
                            '• High: Better for noisy places or when speaking softly'),
                        SizedBox(height: 12),
                        Text(
                          'Tip: If commands aren\'t being recognized, try increasing the sensitivity. If you get too many accidental triggers, try decreasing it.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Got it!'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Current: ${_getSensitivityLabel()}',
          style: TextStyle(fontSize: 16, color: Color(0xFF2196F3)),
        ),
        Slider(
          value: _sensitivity,
          onChanged: (value) async {
            setState(() => _sensitivity = value);
            await _saveSettings();

            // Show feedback when sensitivity changes
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sensitivity set to ${_getSensitivityLabel()}'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          },
          activeColor: const Color(0xFF2196F3),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Low', style: TextStyle(color: Color(0xFF2196F3))),
            Text('Medium', style: TextStyle(color: Color(0xFF2196F3))),
            Text('High', style: TextStyle(color: Color(0xFF2196F3))),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationTrigger() {
    return SwitchListTile(
      title: const Text('Send Location on Command Activation',
          style: TextStyle(color: Color(0xFF2196F3))),
      value: _sendLocation,
      onChanged: (bool value) async {
        setState(() {
          _sendLocation = value;
        });
        await _saveSettings();

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location sharing ${value ? 'enabled' : 'disabled'}'),
            backgroundColor: value ? Colors.green : Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      },
      activeColor: Colors.blue,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.blue.withOpacity(0.5),
    );
  }

  String _getSensitivityLabel() {
    if (_sensitivity < 0.33) return 'Low';
    if (_sensitivity < 0.66) return 'Medium';
    return 'High';
  }

  Future<void> _initRecorderAndPlayer() async {
    try {
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();

      // Request microphone permission first
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw 'Microphone permission not granted';
      }

      // Initialize recorder
      await _recorder!.openRecorder();
      await _recorder!
          .setSubscriptionDuration(const Duration(milliseconds: 10));

      // Initialize player
      await _player!.openPlayer();

      print('Recorder and player initialized successfully');
    } catch (e) {
      print('Error initializing recorder and player: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isListening = false;
          _customCommand = 'No speech detected';
        });
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check permissions first
      var micStatus = await Permission.microphone.status;
      if (micStatus != PermissionStatus.granted) {
        await _requestPermissions();
        return;
      }

      // Check if recorder is initialized
      if (_recorder == null) {
        await _initRecorderAndPlayer();
      }

      // Get temporary directory for recording
      Directory tempDir = await getTemporaryDirectory();
      String filePath =
          '${tempDir.path}/command_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Start recording with noise reduction
      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
        audioSource: AudioSource.microphone,
        enableVoiceProcessing: true,
      );

      // Update state to show recording has started
      setState(() {
        _isRecording = true;
        _isListening = true;
        _recordedFilePath = filePath;
        _customCommand = 'Listening...';
      });

      // Initialize speech recognition if not already initialized
      if (!_speech.isAvailable) {
        await _initializeSpeech();
      }

      // Function to start listening with retry
      Future<void> startListening() async {
        try {
          await _speech.listen(
            onResult: (result) {
              if (mounted) {
                setState(() {
                  if (result.recognizedWords.isNotEmpty) {
                    _customCommand = result.recognizedWords;
                  }
                });
              }
            },
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 2),
            partialResults: true,
            onSoundLevelChange: (level) {
              if (mounted) {
                setState(() {
                  if (level > 0.1) {
                    _customCommand = 'Listening... (Sound detected)';
                  } else {
                    // If sound level is too low for 2 seconds, stop recording
                    Future.delayed(const Duration(seconds: 2), () async {
                      if (_isRecording && !_speech.isListening) {
                        await _stopRecording();
                      }
                    });
                  }
                });
              }
            },
            cancelOnError: false,
            listenMode: stt.ListenMode.dictation,
            localeId: 'en_US',
          );
        } catch (e) {
          // Silently retry on timeout
          if (e.toString().contains('timeout')) {
            await Future.delayed(const Duration(milliseconds: 500));
            await startListening();
          }
        }
      }

      // Start the listening process
      await startListening();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isListening = false;
          _customCommand = '';
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_recorder != null && _recorder!.isRecording) {
        await _recorder!.stopRecorder();
      }

      if (_speech.isListening) {
        await _speech.stop();
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
          _isListening = false;
          if (_customCommand == 'Listening...' ||
              _customCommand == 'Listening... (Sound detected)') {
            _customCommand = '';
          } else if (_customCommand.isNotEmpty) {
            // Show success message when command is captured
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('✅ Command captured successfully: "$_customCommand"'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isListening = false;
          _customCommand = '';
        });
      }
    }
  }

  void _saveCommand() async {
    if (_customCommand.isEmpty ||
        _customCommand == 'No speech detected' ||
        _customCommand == 'Listening...' ||
        _customCommand == 'Listening... (Sound detected)' ||
        _recordedFilePath.isEmpty) {
      return;
    }

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Show saving indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving command...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Save to Firestore
      await firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .doc()
          .set({
        'command': _customCommand,
        'recorded_file_path': _recordedFilePath,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Command saved: "$_customCommand"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() {
          _customCommand = '';
          _recordedFilePath = '';
        });

        // Refresh the commands list
        await _fetchSavedCommands();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save command. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _fetchSavedCommands() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        print('User not logged in!');
        if (mounted) {
          setState(() {
            _savedCommands = []; // Clear list if no user
          });
        }
        return;
      }

      QuerySnapshot snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .orderBy('timestamp', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _savedCommands = snapshot.docs.map((doc) {
            return {
              'id': doc.id, // Store document ID for deletion
              'command': doc['command'] as String,
              'recorded_file_path': doc['recorded_file_path']
                  as String?, // Make sure this is retrieved
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching commands: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load saved commands'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _deleteCommand(String docId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) return;

      await firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .doc(docId)
          .delete();

      // Update local state and show feedback
      if (mounted) {
        setState(() {
          _savedCommands.removeWhere((cmd) => cmd['id'] == docId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Command deleted successfully!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      // Re-fetch to ensure list is in sync with Firestore
      await _fetchSavedCommands();
    } catch (e) {
      print('Error deleting command: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete command. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildSavedCommandsSection() {
    return _buildSectionCard(
      title: 'Saved Commands',
      icon: Icons.list,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_savedCommands.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No commands saved yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _savedCommands.length,
              itemBuilder: (context, index) {
                final commandData = _savedCommands[index];
                final commandText = commandData['command'] as String;
                final recordedFilePath =
                    commandData['recorded_file_path'] as String?;
                final docId = commandData['id'] as String;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.mic, color: Color(0xFF2196F3)),
                    title: Text(
                      commandText,
                      style: const TextStyle(color: Color(0xFF2196F3)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (recordedFilePath != null &&
                            recordedFilePath.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              _currentlyPlayingPath == recordedFilePath &&
                                      _isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.blue,
                            ),
                            onPressed: () =>
                                _playSpecificSavedCommand(recordedFilePath),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCommand(docId),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _playSpecificSavedCommand(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    if (!await File(filePath).exists()) return;

    try {
      if (_player == null) {
        await _initRecorderAndPlayer();
      }

      // If the same file is already playing, pause it
      if (_currentlyPlayingPath == filePath && _isPlaying) {
        await _player!.pausePlayer();
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      // If a different file is playing, stop it first
      if (_currentlyPlayingPath != filePath && _isPlaying) {
        await _player!.stopPlayer();
        setState(() {
          _isPlaying = false;
        });
      }

      // Start playing the new file
      await _player!.startPlayer(
        fromURI: filePath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingPath = null;
          });
        },
      );

      setState(() {
        _isPlaying = true;
        _currentlyPlayingPath = filePath;
      });
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _isPlaying = false;
        _currentlyPlayingPath = null;
      });
    }
  }

  Future<void> _pausePlayback() async {
    if (_player != null && _isPlaying) {
      await _player!.pausePlayer();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _resumePlayback() async {
    if (_player != null && !_isPlaying && _currentlyPlayingPath != null) {
      await _player!.resumePlayer();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Widget _buildTestModeSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Column(
      children: [
        const Text(
          'Try your saved commands to test recognition',
          style: TextStyle(fontSize: 16, color: Color(0xFF2196F3)),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _toggleTestMode,
          icon: Icon(_isTestMode ? Icons.stop : Icons.play_arrow),
          label: Text(_isTestMode ? 'Stop Testing' : 'Start Test'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
            foregroundColor: isDarkMode ? Colors.white : Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDarkMode ? Colors.white : Colors.blue,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleTestMode() async {
    if (_isTestMode) {
      await _speech.stop();
      setState(() {
        _isTestMode = false;
      });
    } else {
      if (_savedCommands.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please save at least one command before testing'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_isTestMode) {
              setState(() {
                _isTestMode = false;
              });
            }
          }
        },
        onError: (error) {
          setState(() {
            _isTestMode = false;
          });
        },
      );

      if (available) {
        setState(() {
          _isTestMode = true;
        });
        await _startListening();
      }
    }
  }

  Future<void> _startListening() async {
    try {
      // Start recording first
      Directory tempDir = await getTemporaryDirectory();
      String testFilePath =
          '${tempDir.path}/test_command_${DateTime.now().millisecondsSinceEpoch}.aac';

      if (_recorder == null) {
        await _initRecorderAndPlayer();
      }

      // Start recording
      await _recorder!.startRecorder(
        toFile: testFilePath,
        codec: Codec.aacADTS,
        audioSource: AudioSource.microphone,
      );

      // Show recording indicator
      setState(() {
        _isTestMode = true;
      });

      // Show recording indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording... Speak your command now'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Wait for 3 seconds to record
      await Future.delayed(const Duration(seconds: 3));

      // Stop recording
      await _recorder!.stopRecorder();

      // Process the recorded audio
      bool found = false;
      String matched = '';
      double bestSimilarity = 0.0;

      print('Comparing audio files...');

      // Get the test file size
      File testFile = File(testFilePath);
      int testFileSize = await testFile.length();

      // If test file is too small, it means no significant audio was recorded
      if (testFileSize < 500) {
        // Reduced minimum size requirement
        setState(() {
          _isTestMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No command detected. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      for (var cmd in _savedCommands) {
        String savedAudioPath = cmd['recorded_file_path'] as String;
        if (savedAudioPath.isNotEmpty) {
          print('Comparing with saved audio: $savedAudioPath');

          // Compare the audio files
          double similarity =
              await _compareAudioFiles(testFilePath, savedAudioPath);
          if (similarity > bestSimilarity) {
            bestSimilarity = similarity;
            if (similarity > 0.4) {
              // Reduced threshold from 0.6 to 0.4
              found = true;
              matched = cmd['command'] as String;
              print('Audio match found with similarity: ${similarity * 100}%');
            }
          }
        }
      }

      setState(() {
        _isTestMode = false;
        if (found) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Command matched: "$matched"'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No matching command found'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });

      // Clean up the test file
      try {
        File(testFilePath).delete();
      } catch (e) {
        print('Error deleting test file: $e');
      }
    } catch (e) {
      print('Error in test mode: $e');
      setState(() {
        _isTestMode = false;
      });
    }
  }

  List<int> _createAudioFingerprint(List<int> audioData) {
    List<int> fingerprint = [];
    int sampleSize = 200; // Increased sample size

    if (audioData.length < sampleSize) {
      return audioData;
    }

    // Take evenly spaced samples
    int step = audioData.length ~/ sampleSize;
    for (int i = 0; i < sampleSize; i++) {
      int index = i * step;
      if (index < audioData.length) {
        // Take average of surrounding values
        int sum = 0;
        int count = 0;
        for (int j = -2; j <= 2; j++) {
          int pos = index + j;
          if (pos >= 0 && pos < audioData.length) {
            sum += audioData[pos];
            count++;
          }
        }
        fingerprint.add(sum ~/ count);
      }
    }

    return fingerprint;
  }

  Future<double> _compareAudioFiles(String file1, String file2) async {
    try {
      // Get file sizes
      File f1 = File(file1);
      File f2 = File(file2);

      if (!await f1.exists() || !await f2.exists()) {
        print('One or both files do not exist');
        return 0.0;
      }

      int size1 = await f1.length();
      int size2 = await f2.length();

      print('File sizes - Test: $size1, Saved: $size2');

      // If sizes are very different, they're probably not the same
      if ((size1 - size2).abs() > 10000) {
        // Increased tolerance
        print('File sizes too different');
        return 0.0;
      }

      // Read the audio data
      List<int> bytes1 = await f1.readAsBytes();
      List<int> bytes2 = await f2.readAsBytes();

      // Create audio fingerprints by sampling
      List<int> fingerprint1 = _createAudioFingerprint(bytes1);
      List<int> fingerprint2 = _createAudioFingerprint(bytes2);

      // Compare fingerprints
      int matchCount = 0;
      int minLength = fingerprint1.length < fingerprint2.length
          ? fingerprint1.length
          : fingerprint2.length;

      // Calculate average values
      double avg1 = fingerprint1.reduce((a, b) => a + b) / fingerprint1.length;
      double avg2 = fingerprint2.reduce((a, b) => a + b) / fingerprint2.length;

      // Compare relative to averages
      for (int i = 0; i < minLength; i++) {
        double val1 = fingerprint1[i] / avg1;
        double val2 = fingerprint2[i] / avg2;
        if ((val1 - val2).abs() < 0.3) {
          // Increased tolerance from 0.2 to 0.3
          matchCount++;
        }
      }

      // Calculate similarity percentage
      double similarity = matchCount / minLength;
      print('Audio similarity: ${similarity * 100}%');

      return similarity;
    } catch (e) {
      print('Error comparing audio files: $e');
      return 0.0;
    }
  }

  void _checkVolumeButtonHold() async {
    while (_isVolumeButtonPressed) {
      if (_volumeButtonPressStart != null) {
        final holdDuration =
            DateTime.now().difference(_volumeButtonPressStart!);
        if (holdDuration.inSeconds >= 3) {
          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SOS triggered! Sending emergency alert...'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );

          // Trigger emergency
          await _emergencyService.triggerEmergencyButton();
          _isVolumeButtonPressed = false;
          _volumeButtonPressStart = null;
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
