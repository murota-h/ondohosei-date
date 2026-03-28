import 'package:flutter/material.dart';
import 'screens/title_screen.dart';

void main() {
  runApp(const CrankCorrectionApp());
}

class CrankCorrectionApp extends StatelessWidget {
  const CrankCorrectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '温度補正システム',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const TitleScreen(),
    );
  }
}
