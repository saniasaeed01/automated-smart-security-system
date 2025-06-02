// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

class SendSMSScreen extends StatefulWidget {
  const SendSMSScreen({Key? key}) : super(key: key);

  @override
  State<SendSMSScreen> createState() => _SendSMSScreenState();
}

class _SendSMSScreenState extends State<SendSMSScreen> {
  bool attachLocation = true;
  final TextEditingController _messageController = TextEditingController(
    text:
        "I am in danger! Please help me. My live location: [Auto Attach Location]",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade400,
              Colors.green.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      "Emergency SMS",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Send instant alerts to your trusted contacts",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Trusted Contacts Section
                      const Text(
                        "Trusted Contacts",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact Cards
                      _buildContactCard("John Doe", "+1234567890"),
                      _buildContactCard("Jane Smith", "+0987654321"),

                      // Add New Contact Button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Add contact logic
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add New Contact"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      // Message Input Section
                      const SizedBox(height: 24),
                      const Text(
                        "Emergency Message",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                const BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                      ),

                      // Location Toggle
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            const Icon(Icons.location_on, color: Colors.green),
                        title: const Text("Attach Live Location"),
                        trailing: Switch(
                          value: attachLocation,
                          onChanged: (value) {
                            setState(() {
                              attachLocation = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ),

                      // Send Button
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Send SMS logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Emergency SMS sent successfully ✅"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Send Now 📩",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildContactCard(String name, String phone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.person, color: Colors.green),
        ),
        title: Text(name),
        subtitle: Text(phone),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.message, color: Colors.green),
              onPressed: () {
                // Message action
              },
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () {
                // Call action
              },
            ),
          ],
        ),
      ),
    );
  }
}
