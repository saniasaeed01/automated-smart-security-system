// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3).withOpacity(0.5), // Adjusted to a stronger blue
              Colors.white.withOpacity(0.8), // Slightly adjusted white opacity
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            spreadRadius: 2,
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Reset Icon
                          Icon(
                            Icons
                                .lock_outline_rounded, // Changed to simpler lock icon
                            size: 50, // Reduced size to match reference
                            color: Color(0xFF2196F3),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons
                                    .refresh_rounded, // Added refresh/reset icon
                                size: 24,
                                color: Color(0xFF2196F3),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // Forgot Password Heading
                          Text(
                            'Forgot Password',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),

                          // Instructional Text
                          Text(
                            'Enter your email to reset your password. We will send a password reset link to your email.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),

                          // Email Input Field
                          TextFormField(
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'Enter your email',
                              prefixIcon:
                                  Icon(Icons.email, color: Color(0xFF2196F3)),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 20),
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              hintStyle: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Reset Password Button
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Password reset link sent! Please check your email.",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  backgroundColor: Color(0xFF2196F3),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.all(10),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF2196F3),
                              foregroundColor:
                                  Colors.white, // Changed text color to white
                              padding: EdgeInsets.symmetric(vertical: 12),
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    30), // Made button more rounded
                              ),
                              elevation: 4,
                              shadowColor: Color(0xFF2196F3).withOpacity(0.3),
                            ),
                            child: Text(
                              "Reset Password",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Back to Login Button
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              "Back to Login",
                              style: TextStyle(
                                color: Color(
                                    0xFF2196F3), // Changed to match login screen's blue
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
