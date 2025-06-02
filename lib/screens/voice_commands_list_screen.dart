// import 'package:flutter/material.dart';

// class VoiceCommandsListScreen extends StatelessWidget {
//   const VoiceCommandsListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<VoiceCommandItem> commands = [
//       VoiceCommandItem(
//         command: "Call emergency",
//         description: "Opens emergency dialer",
//         action: "Opens phone dialer with emergency number",
//         icon: Icons.emergency,
//       ),
//       VoiceCommandItem(
//         command: "Start recording",
//         description: "Starts audio recording",
//         action: "Begins recording audio",
//         icon: Icons.mic,
//       ),
//       VoiceCommandItem(
//         command: "Send location",
//         description: "Shares current location",
//         action: "Sends location to emergency contacts",
//         icon: Icons.location_on,
//       ),
//       VoiceCommandItem(
//         command: "Open camera",
//         description: "Opens camera quickly",
//         action: "Launches camera in photo mode",
//         icon: Icons.camera_alt,
//       ),
//       VoiceCommandItem(
//         command: "Call contacts",
//         description: "Opens trusted contacts",
//         action: "Shows list of emergency contacts",
//         icon: Icons.contacts,
//       ),
//       VoiceCommandItem(
//         command: "Stop recording",
//         description: "Stops current recording",
//         action: "Stops and saves the recording",
//         icon: Icons.stop_circle,
//       ),
//       // Add more commands as needed
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Voice Commands'),
//         centerTitle: true,
//       ),
//       body: ListView.builder(
//         itemCount: commands.length,
//         itemBuilder: (context, index) {
//           final command = commands[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ListTile(
//               leading: Icon(
//                 command.icon,
//                 color: Theme.of(context).primaryColor,
//                 size: 28,
//               ),
//               title: Text(
//                 command.command,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(command.description),
//                   Text(
//                     command.action,
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//               trailing: IconButton(
//                 icon: const Icon(Icons.play_circle_outline),
//                 onPressed: () {
//                   // Add demo functionality
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Try saying: "${command.command}"'),
//                       duration: const Duration(seconds: 2),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           Navigator.pushNamed(context, '/voice-command-setup');
//         },
//         label: const Text('Customize Commands'),
//         icon: const Icon(Icons.edit),
//       ),
//     );
//   }
// }

// class VoiceCommandItem {
//   final String command;
//   final String description;
//   final String action;
//   final IconData icon;

//   VoiceCommandItem({
//     required this.command,
//     required this.description,
//     required this.action,
//     required this.icon,
//   });
// }
