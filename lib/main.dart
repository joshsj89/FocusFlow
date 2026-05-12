import 'package:flutter/material.dart';
import 'package:focusflow/screens/account_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B6CF7),
        ),
        textTheme: GoogleFonts.openSansTextTheme(),
      ),
      // Note:
      // we'll add auth and logins stuff later:
      // set home to AuthScreen and navigate to /home on success
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/account': (context) => const AccountScreen(),
      },
    );
  }
}
