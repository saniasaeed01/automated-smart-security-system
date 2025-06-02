// ignore_for_file: use_super_parameters, unused_import

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:safety/utils/theme.dart' as app_theme;
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/onboarding_screen.dart';
import 'screens/voice_commands_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:safety/utils/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'AutoSecure',
          theme: themeProvider.currentTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const FirebaseCheckWrapper(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/home': (context) => const HomeScreen(),
            // '/voice-commands': (context) => const VoiceCommandsListScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// This widget checks if Firebase initialized correctly
class FirebaseCheckWrapper extends StatelessWidget {
  const FirebaseCheckWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                User? user = snapshot.data;
                if (user != null) {
                  // User is signed in, navigate to home screen
                  return const HomeScreen(); // Replace with your home screen widget
                } else {
                  // User is not signed in, navigate to login screen
                  return const LoginScreen(); // Replace with your login screen widget
                }
              }
              // While checking the authentication state, show a loading indicator
              return const Center(child: CircularProgressIndicator());
            },
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Firebase Error: ${snapshot.error}')),
          );
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
