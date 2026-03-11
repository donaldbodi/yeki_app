import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/dasboard.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'package:yeki/views/pages/onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ThemeData theme = ThemeData(
  primaryColor: const Color(0xFF1f9cf0),
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.teal,
    accentColor: Colors.orange,
    backgroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF4F4F4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
  ),
);

void main() {
  runApp(const YekiApp());
}

class YekiApp extends StatelessWidget {
  const YekiApp({super.key});

  Future<Widget> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role') ?? "";

    if (token != null && token.isNotEmpty) {
      // L'utilisateur est connecté
      if (role.contains('Enseignant')) {
        return const EnseignantHomePage();
      } else if (role == 'Apprenant') {
        return const Dashboard();
      } else {
        return const OnboardingPage();
      }
    } else {
      // L'utilisateur n’est pas connecté
      return const OnboardingPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yéki',
      theme: theme,
      home: FutureBuilder<Widget>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Une erreur est survenue")),
            );
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }
}
