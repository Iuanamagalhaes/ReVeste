import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() {
  runApp(const ReVesteApp());
}

class ReVesteApp extends StatelessWidget {
  const ReVesteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}