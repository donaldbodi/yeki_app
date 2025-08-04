import 'package:flutter/material.dart';
import 'package:yeki/views/pages/onboarding.dart';

final ThemeData theme = ThemeData(
  primaryColor: Color(0xFF008080),
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.teal,
    accentColor: Colors.orange,
    backgroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      padding: EdgeInsets.symmetric(vertical: 14),
      textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF4F4F4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  ),
  textTheme: TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
  ),
);


void main() {
  runApp(const YekiApp());
}

class YekiApp extends StatelessWidget {
  const YekiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yéki',
      theme: theme,
      home: const OnboardingPage(), // ← commence par la page de loading
    );
  }
}

