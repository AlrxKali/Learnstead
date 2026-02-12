import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LearnsteadApp());
}

class LearnsteadApp extends StatelessWidget {
  const LearnsteadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learnstead',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6F9A84),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
    );
  }
}
