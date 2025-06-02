// ignore_for_file: avoid_print

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String? _savedCommand;
  // ignore: unused_field
  double _sensitivity = 0.5;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _savedCommand = prefs.getString('voice_command');
    _sensitivity = prefs.getDouble('sensitivity') ?? 0.5;

    await _speech.initialize(
      onStatus: (status) => print('Voice service status: $status'),
      onError: (error) => print('Voice service error: $error'),
    );
  }

  Future<void> startListening({
    required Function(String) onCommand,
    required Function(String) onResult,
  }) async {
    if (!_isListening && _savedCommand != null) {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          String text = result.recognizedWords.toLowerCase();
          onResult(text);

          if (text.contains(_savedCommand!.toLowerCase())) {
            onCommand(text);
          }
        },
      );
    }
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }
}
