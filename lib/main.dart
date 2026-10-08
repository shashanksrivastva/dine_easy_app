import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }

  runApp(const DineEasyApp());
}

class DineEasyApp extends StatelessWidget {
  const DineEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DineEasy',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFF8EF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF47B20)),
      ),
      home: currentUser != null
          ? DashboardScreen(
              userName: currentUser.phoneNumber ??
                  currentUser.displayName ??
                  'User',
            )
          : const LoginScreen(),
    );
  }
}
