import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LucidApp());
}

class LucidApp extends StatelessWidget {
  const LucidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const WelcomeScreen(),
    );
  }
}