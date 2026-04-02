import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const int CURRENT_VERSION = 2; // Version actuelle de ton APK
  static const String API_URL = "https://yeki.pythonanywhere.com/api/latest-version/";

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(API_URL));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int latestVersion = data["version_code"];
        final String latestName = data["version_name"];
        final String apkUrl = data["apk_url"];
        final String changelog = data["changelog"];

        if (latestVersion > CURRENT_VERSION) {
          _showUpdateDialog(context, latestName, changelog, apkUrl);
        }
      } else {
        debugPrint("Erreur API: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur mise à jour: $e");
    }
  }

  static void _showUpdateDialog(
      BuildContext context, String version, String changelog, String apkUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // L'utilisateur doit choisir
      builder: (context) {
        return AlertDialog(
          title: Text("🚀 Nouvelle mise à jour"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Version $version est disponible."),
              SizedBox(height: 10),
              Text(changelog),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Plus tard"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri url = Uri.parse(apkUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: Icon(Icons.download),
              label: Text("Télécharger"),
            ),
          ],
        );
      },
    );
  }
}
