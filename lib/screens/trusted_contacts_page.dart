// ignore_for_file: deprecated_member_use, unused_element, unused_import, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'contacts_list_page.dart';
import 'package:safety/models/trusted_contact.dart';
import 'package:provider/provider.dart';
import 'package:safety/utils/theme_provider.dart';

// Add this gradient constant
const LinearGradient _blueGradient = LinearGradient(
  colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const Color primaryBlue = Color(0xFF2196F3);

class TrustedContactsPage extends StatefulWidget {
  const TrustedContactsPage({super.key});

  @override
  State<TrustedContactsPage> createState() => _TrustedContactsPageState();
}

class _TrustedContactsPageState extends State<TrustedContactsPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  List<TrustedContact> trustedContacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrustedContacts();
  }

  Future<void> _loadTrustedContacts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('trusted_contacts');

      if (contactsJson != null && mounted) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        setState(() {
          trustedContacts = decoded
              .map((contact) => TrustedContact.fromMap(contact))
              .toList();
          isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading trusted contacts: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addContact() async {
    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        final Contact? contact =
            await ContactsService.openDeviceContactPicker();
        if (contact != null) {
          final phoneNumber = contact.phones?.isNotEmpty == true
              ? contact.phones!.first.value ?? ''
              : '';

          if (phoneNumber.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No phone number found for this contact'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final newContact = TrustedContact(
            name: contact.displayName ?? 'Unknown',
            phoneNumber: phoneNumber,
            relationship: 'Trusted Contact',
          );

          if (mounted) {
            setState(() {
              trustedContacts.add(newContact);
            });
          }

          await _saveTrustedContacts();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Contact added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission to access contacts was denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add contact'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveTrustedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson =
          jsonEncode(trustedContacts.map((c) => c.toMap()).toList());
      await prefs.setString('trusted_contacts', contactsJson);
    } catch (e) {
      print('Error saving trusted contacts: $e');
    }
  }

  Future<void> _removeContact(int index) async {
    if (mounted) {
      setState(() {
        trustedContacts.removeAt(index);
      });
    }
    await _saveTrustedContacts();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        margin: EdgeInsets.all(16),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              )
            : trustedContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No trusted contacts yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add contacts that you trust in case of emergency',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: trustedContacts.length,
                    itemBuilder: (context, index) {
                      final contact = trustedContacts[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            contact.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Text(
                            contact.phoneNumber,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeContact(index),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
