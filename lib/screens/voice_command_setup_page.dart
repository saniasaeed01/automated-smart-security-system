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

class VoiceCommandSetupPage extends StatefulWidget {
  const VoiceCommandSetupPage({super.key});

  @override
  State<VoiceCommandSetupPage> createState() => _VoiceCommandSetupPageState();
}

class _VoiceCommandSetupPageState extends State<VoiceCommandSetupPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isListening = false;
  String _customCommand = '';
  double _sensitivity = 0.5;
  bool _isTestMode = false;
  bool _emergencyButtonEnabled = false;
  bool _shakeDetectionEnabled = false;
  final bool _commandSaved = false;
  String _testModeFeedback = '';
  bool _sendLocation = false;
  String _recordedFilePath = '';
  List<String> _savedCommands = [];
  String? _userVoiceId; // Store user's voice ID
  bool _isVoiceEnrolled = false; // Track if user has enrolled their voice

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _fetchSavedCommands();
    _loadSettings();
    _checkVoiceEnrollment();
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
  }

  Future<void> _checkVoiceEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userVoiceId = prefs.getString('user_voice_id');
      _isVoiceEnrolled = _userVoiceId != null;
    });
  }

  Future<void> _enrollVoice() async {
    setState(() {
      _isListening = true;
      _testModeFeedback =
          'Please say "My voice is my password" to enroll your voice...';
    });

    bool available = await _speech.initialize(
      onStatus: (status) => print('Voice enrollment status: $status'),
      onError: (error) => print('Voice enrollment error: $error'),
    );

    if (available) {
      await _speech.listen(
        onResult: (result) async {
          String spokenText = result.recognizedWords.toLowerCase().trim();
          if (spokenText.contains("my voice is my password")) {
            // Store voice characteristics
            final prefs = await SharedPreferences.getInstance();
            String voiceId = DateTime.now().millisecondsSinceEpoch.toString();

            // Store voice characteristics
            await prefs.setString('user_voice_id', voiceId);
            await prefs.setString('voice_characteristics', spokenText);

            setState(() {
              _userVoiceId = voiceId;
              _isVoiceEnrolled = true;
              _isListening = false;
              _testModeFeedback = '✅ Voice enrolled successfully!';
            });
          } else {
            setState(() {
              _isListening = false;
              _testModeFeedback =
                  '❌ Please say exactly "My voice is my password"';
            });
          }
        },
      );
    }
  }

  void _initializeSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      // Show error message if speech recognition is not available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
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
              // Combined Voice Command Section
              _buildSectionCard(
                title: 'Voice Command Setup 🛡️',
                icon: Icons.mic,
                child: Column(
                  children: [
                    // Voice Enrollment Status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isVoiceEnrolled
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _isVoiceEnrolled ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isVoiceEnrolled
                                ? Icons.check_circle
                                : Icons.warning,
                            color:
                                _isVoiceEnrolled ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isVoiceEnrolled
                                  ? '✅ Voice enrolled and ready for commands'
                                  : '⚠️ Please enroll your voice first to use voice commands',
                              style: TextStyle(
                                color: _isVoiceEnrolled
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Voice Enrollment/Re-enrollment Button
                    if (!_isVoiceEnrolled)
                      ElevatedButton.icon(
                        onPressed: _enrollVoice,
                        icon: Icon(_isListening ? Icons.stop : Icons.mic),
                        label: Text(
                            _isListening ? 'Enrolling...' : 'Enroll Voice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? Colors.grey[850] : Colors.white,
                          foregroundColor:
                              isDarkMode ? Colors.white : Colors.blue,
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
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _reEnrollVoice,
                            icon: Icon(Icons.edit),
                            label: Text('Edit Voice'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDarkMode ? Colors.grey[850] : Colors.white,
                              foregroundColor:
                                  isDarkMode ? Colors.white : Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color:
                                      isDarkMode ? Colors.white : Colors.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _deleteVoiceEnrollment,
                            icon: Icon(Icons.delete, color: Colors.red),
                            label: Text('Delete Voice',
                                style: TextStyle(color: Colors.red)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDarkMode ? Colors.grey[850] : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Command Recording Section
                    if (_isVoiceEnrolled) ...[
                      Text(
                        _customCommand.isEmpty
                            ? 'No command recorded yet'
                            : 'Current command: $_customCommand',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isListening
                                  ? _stopListening
                                  : _startRecording,
                              icon: Icon(_isListening ? Icons.stop : Icons.mic,
                                  color:
                                      isDarkMode ? Colors.white : Colors.blue),
                              label: Text(
                                _isListening
                                    ? 'Recording...'
                                    : 'Record Emergency Command',
                                style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.blue),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? Colors.grey[850]
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color:
                                        isDarkMode ? Colors.white : Colors.blue,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _customCommand.isNotEmpty
                                  ? _saveCommand
                                  : null,
                              child: const Text('Save Command'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? Colors.grey[850]
                                    : Colors.white,
                                foregroundColor:
                                    isDarkMode ? Colors.white : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _playRecordedCommand,
                        child: const Text('Play Recorded Command'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode ? Colors.grey[850] : Colors.white,
                          foregroundColor:
                              isDarkMode ? Colors.white : Colors.blue,
                        ),
                      ),
                    ],

                    if (_testModeFeedback.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testModeFeedback.contains('✅')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _testModeFeedback.contains('✅')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          _testModeFeedback,
                          style: TextStyle(
                            color: _testModeFeedback.contains('✅')
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Display Saved Commands
              _buildSectionCard(
                title: 'Saved Voice Commands',
                icon: Icons.list,
                child: ExpansionTile(
                  title: const Text(
                    'Tap to view saved commands',
                    style: TextStyle(color: Colors.grey),
                  ),
                  children: List.generate(_savedCommands.length, (index) {
                    return ListTile(
                      title: Text('${index + 1}. ${_savedCommands[index]}',
                          style: const TextStyle(color: Color(0xFF2196F3))),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteCommand(_savedCommands[index]);
                        },
                      ),
                    );
                  }),
                ),
              ),

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
                      'Emergency Button',
                      Icons.touch_app,
                      _emergencyButtonEnabled,
                    ),
                    const Divider(),
                    _buildBackupOption(
                      'Shake Detection',
                      Icons.vibration,
                      _shakeDetectionEnabled,
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
          if (title == 'Emergency Button') {
            _emergencyButtonEnabled = value;
          } else if (title == 'Shake Detection') {
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

  void _startRecording() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() async {
              _customCommand = result.recognizedWords;
              _isListening = false;
              _testModeFeedback = 'Command recognized! System ready.';
              _recordedFilePath =
                  await _saveAudioToFile(result.recognizedWords);
            });
          },
        );
      }
    }
  }

  Future<String> _saveAudioToFile(String command) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/recorded_command.wav';
    // Here you should implement the logic to actually save the audio data
    // For example, you might need to write the audio data to the file
    return filePath;
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<bool> _verifyVoice(String spokenText) async {
    final prefs = await SharedPreferences.getInstance();
    String? enrolledVoiceCharacteristics =
        prefs.getString('voice_characteristics');

    if (enrolledVoiceCharacteristics == null) {
      print('No enrolled voice found'); // Debug print
      return false;
    }

    print('Enrolled voice: $enrolledVoiceCharacteristics'); // Debug print
    print('Current spoken text: $spokenText'); // Debug print

    // First check if the user is enrolled
    if (!_isVoiceEnrolled) {
      print('User not enrolled'); // Debug print
      return false;
    }

    // Check if the spoken text matches the enrollment phrase
    if (!spokenText.contains("my voice is my password")) {
      print('Spoken text does not match enrollment phrase'); // Debug print
      return false;
    }

    // In a real implementation, you would use voice biometrics here
    // For now, we'll use a simple check that the user is enrolled and saying the right phrase
    bool isVoiceMatch =
        _isVoiceEnrolled && spokenText.contains("my voice is my password");

    print('Voice match result: $isVoiceMatch'); // Debug print
    return isVoiceMatch;
  }

  void _toggleTestMode() async {
    if (_isTestMode) {
      await _speech.stop();
      setState(() {
        _isTestMode = false;
        _testModeFeedback = '';
      });
    } else {
      if (!_isVoiceEnrolled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enroll your voice first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

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
        onStatus: (status) => print('Test mode status: $status'),
        onError: (error) => print('Test mode error: $error'),
      );

      if (available) {
        setState(() {
          _isTestMode = true;
          _testModeFeedback = 'Listening for command...';
        });

        await _speech.listen(
          onResult: (result) async {
            await _speech.stop();
            await Future.delayed(Duration(milliseconds: 100));

            String spokenText = result.recognizedWords.toLowerCase().trim();
            print('Spoken text: $spokenText'); // Debug print

            // First verify the voice by asking for the enrollment phrase
            setState(() {
              _testModeFeedback =
                  'Please say "My voice is my password" to verify your voice...';
            });

            bool isVoiceMatch = await _verifyVoice(spokenText);
            print('Voice match: $isVoiceMatch'); // Debug print

            if (!isVoiceMatch) {
              if (mounted) {
                setState(() {
                  _isTestMode = false;
                  _testModeFeedback =
                      '❌ Voice not recognized!\nPlease use your enrolled voice.\nMake sure you are speaking clearly.';
                });
              }
              return;
            }

            // If voice is verified, now listen for the actual command
            setState(() {
              _testModeFeedback = 'Voice verified! Now say your command...';
            });

            await _speech.listen(
              onResult: (result) async {
                await _speech.stop();
                String commandText =
                    result.recognizedWords.toLowerCase().trim();

                // Then check if the command matches
                bool isCommandMatch = false;
                String matchedCommand = '';

                for (String savedCommand in _savedCommands) {
                  String normalizedSavedCommand =
                      savedCommand.toLowerCase().trim();
                  print(
                      'Comparing with saved command: $normalizedSavedCommand'); // Debug print

                  // More flexible matching
                  if (commandText.contains(normalizedSavedCommand) ||
                      normalizedSavedCommand.contains(commandText) ||
                      _calculateSimilarity(
                              commandText, normalizedSavedCommand) >
                          0.7) {
                    isCommandMatch = true;
                    matchedCommand = savedCommand;
                    break;
                  }
                }

                if (mounted) {
                  setState(() {
                    _isTestMode = false;
                    if (isCommandMatch) {
                      _testModeFeedback =
                          '✅ Test Successful!\nVoice and command recognized correctly.\nMatched command: $matchedCommand';
                    } else {
                      _testModeFeedback =
                          '❌ Command not recognized!\nVoice matched but command was incorrect.\nYou said: "$commandText"\nTry saying one of these commands: ${_savedCommands.join(", ")}';
                    }
                  });
                }
              },
            );
          },
        );
      }
    }
  }

  // Add a function to calculate string similarity
  double _calculateSimilarity(String s1, String s2) {
    // Convert strings to sets of characters
    Set<String> set1 = s1.split('').toSet();
    Set<String> set2 = s2.split('').toSet();

    // Calculate intersection and union
    Set<String> intersection = set1.intersection(set2);
    Set<String> union = set1.union(set2);

    // Calculate Jaccard similarity
    return intersection.length / union.length;
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
        const SizedBox(height: 8),
        Text(
          'Saved Commands: ${_savedCommands.join(", ")}',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF2196F3),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Voice Status: ${_isVoiceEnrolled ? "✅ Enrolled" : "❌ Not Enrolled"}',
          style: TextStyle(
            fontSize: 14,
            color: _isVoiceEnrolled ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
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
        if (_testModeFeedback.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _testModeFeedback.contains('✅')
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    _testModeFeedback.contains('✅') ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              _testModeFeedback,
              style: TextStyle(
                color:
                    _testModeFeedback.contains('✅') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  void _saveCommand() async {
    if (!_isVoiceEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enroll your voice first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference commandRef = firestore
        .collection('users')
        .doc(userId)
        .collection('voice_commands')
        .doc();
    await commandRef.set({
      'command': _customCommand,
      'recorded_file_path': _recordedFilePath,
      'emergency_button_enabled': _emergencyButtonEnabled,
      'shake_detection_enabled': _shakeDetectionEnabled,
      'sensitivity': _sensitivity,
      'voice_id': _userVoiceId, // Store the voice ID with the command
      'timestamp': FieldValue.serverTimestamp(),
    });
    setState(() {
      _savedCommands.add(_customCommand);
      _customCommand = '';
      _showSavedFeedback();
    });
  }

  void _showSavedFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voice command saved successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _setPredefinedCommand(String command) {
    setState(() {
      _customCommand = command;
    });
  }

  void _playRecordedCommand() async {
    if (_recordedFilePath.isNotEmpty) {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recorded command to play.')),
      );
    }
  }

  // Fetch saved commands from Firebase
  void _fetchSavedCommands() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userId = FirebaseAuth.instance.currentUser!.uid;
    QuerySnapshot snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('voice_commands')
        .get();

    setState(() {
      _savedCommands =
          snapshot.docs.map((doc) => doc['command'] as String).toList();
    });
  }

  void _deleteCommand(String command) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Find the document to delete
      QuerySnapshot snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('voice_commands')
          .where('command', isEqualTo: command)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Delete the document
        await snapshot.docs.first.reference.delete();

        // Update local state
        if (mounted) {
          setState(() {
            _savedCommands.remove(command);
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Command deleted successfully!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // If document not found in Firebase, still remove from local state
        if (mounted) {
          setState(() {
            _savedCommands.remove(command);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Command removed'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting command: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete command. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _reEnrollVoice() async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Voice Enrollment'),
          content: Text(
              'Are you sure you want to re-enroll your voice? This will replace your current voice enrollment.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isListening = true;
        _testModeFeedback =
            'Please say "My voice is my password" to re-enroll your voice...';
      });

      bool available = await _speech.initialize(
        onStatus: (status) => print('Voice re-enrollment status: $status'),
        onError: (error) => print('Voice re-enrollment error: $error'),
      );

      if (available) {
        await _speech.listen(
          onResult: (result) async {
            String spokenText = result.recognizedWords.toLowerCase().trim();
            if (spokenText.contains("my voice is my password")) {
              final prefs = await SharedPreferences.getInstance();
              String voiceId = DateTime.now().millisecondsSinceEpoch.toString();

              await prefs.setString('user_voice_id', voiceId);
              await prefs.setString('voice_characteristics', spokenText);

              setState(() {
                _userVoiceId = voiceId;
                _isVoiceEnrolled = true;
                _isListening = false;
                _testModeFeedback = '✅ Voice re-enrolled successfully!';
              });
            } else {
              setState(() {
                _isListening = false;
                _testModeFeedback =
                    '❌ Please say exactly "My voice is my password"';
              });
            }
          },
        );
      }
    }
  }

  Future<void> _deleteVoiceEnrollment() async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Voice Enrollment'),
          content: Text(
              'Are you sure you want to delete your voice enrollment? You will need to re-enroll your voice to use voice commands.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_voice_id');
      await prefs.remove('voice_characteristics');

      setState(() {
        _userVoiceId = null;
        _isVoiceEnrolled = false;
        _testModeFeedback =
            'Voice enrollment deleted. Please enroll your voice again.';
      });

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice enrollment deleted successfully'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
