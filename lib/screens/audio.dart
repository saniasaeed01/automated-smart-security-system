// ignore_for_file: avoid_print, deprecated_member_use, unused_element, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:record/record.dart'; // Add this package for audio recording
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart'
    as android;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:safety/screens/notifications.dart';

class AudioRecordPage extends StatefulWidget {
  const AudioRecordPage({super.key});

  @override
  State<AudioRecordPage> createState() => _AudioRecordPageState();
}

class _AudioRecordPageState extends State<AudioRecordPage> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String _recordedFilePath = '';

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      final status = await Permission.microphone.request();
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(),
          path:
              '/storage/emulated/0/Download/audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedFilePath = path ?? '';
      });
      print('Audio recorded to: $_recordedFilePath');
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recording'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 100,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? 'Recording...' : 'Press button to start recording',
              style: TextStyle(
                fontSize: 18,
                color: _isRecording ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isRecording ? Icons.stop : Icons.mic),
                  const SizedBox(width: 8),
                  Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                ],
              ),
            ),
            if (_recordedFilePath.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Last recording saved at:\n$_recordedFilePath',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RecordingsHistoryPage extends StatefulWidget {
  const RecordingsHistoryPage({super.key});

  @override
  State<RecordingsHistoryPage> createState() => _RecordingsHistoryPageState();
}

class _RecordingsHistoryPageState extends State<RecordingsHistoryPage> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  List<Recording> recordings = [
    Recording(
      id: '1',
      path: 'recording1.mp3',
      duration: '01:02:00',
      date: DateTime.now(),
      name: 'Recording 1',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      await Permission.microphone.request();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(),
          path:
              '/storage/emulated/0/Download/audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        // Add new recording to the list
        recordings.add(Recording(
          id: (recordings.length + 1).toString(),
          path: path ?? 'unknown',
          duration: '00:00:00', // You might want to calculate actual duration
          date: DateTime.now(),
          name: 'Recording ${recordings.length + 1}',
        ));
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recordings'),
          backgroundColor: Colors.green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ),
        body: Column(
          children: [
            // Recording controls
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'In case of an emergency, document a\nsituation confidentially.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white),
                        const SizedBox(width: 8),
                        Text(_isRecording
                            ? 'Stop Recording'
                            : 'Start Recording'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Recordings list
            Expanded(
              child: ListView.builder(
                itemCount: recordings.length,
                itemBuilder: (context, index) {
                  final recording = recordings[index];
                  return RecordingTile(
                    recording: recording,
                    onDelete: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Recording'),
                            content: const Text(
                                'Are you sure you want to delete this recording?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () {
                                  setState(() {
                                    recordings.removeAt(index);
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onNameEdit: (String newName) {
                      setState(() {
                        recordings[index].name = newName;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordingTile extends StatelessWidget {
  final Recording recording;
  final VoidCallback onDelete;
  final Function(String) onNameEdit;

  const RecordingTile({
    super.key,
    required this.recording,
    required this.onDelete,
    required this.onNameEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recording.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog(context);
                  },
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            // Implement play functionality
                          },
                          color: Colors.blue,
                        ),
                        Expanded(
                          child: CustomPaint(
                            painter: WaveformPainter(),
                            size: const Size(double.infinity, 20),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            recording.duration,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final TextEditingController editController =
        TextEditingController(text: recording.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Recording Name'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              hintText: 'Enter new name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                onNameEdit(editController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

// Custom painter for the waveform visualization
class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.5) // Changed to green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    var x = 0.0;
    final width = size.width;
    final height = size.height;

    path.moveTo(x, height / 2);
    while (x < width) {
      x += 5;
      path.lineTo(x, height / 2 + (math.sin(x / 10) * 8));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Model class for recording data
class Recording {
  final String id;
  String name;
  final String path;
  final String duration;
  final DateTime date;

  Recording({
    required this.id,
    required this.path,
    required this.duration,
    required this.date,
    required this.name,
  });
}
