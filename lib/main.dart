// lib/main.dart
import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'constants.dart';

void main() {
  runApp(const SenemarketApp());
}

class SenemarketApp extends StatelessWidget {
  const SenemarketApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace App',
      theme: ThemeData(
        primaryColor: AppColors.primary20,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Cabin'),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
