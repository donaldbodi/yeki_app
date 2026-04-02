// lib/services/update_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String API_URL = "https://yeki.pythonanywhere.com/api/latest-version/";
  
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 1;
      final platform = _getPlatform();
      
      final response = await http.get(
        Uri.parse("$API_URL?platform=$platform"),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version_code'] as int;
        final downloadUrl = data['download_url'] as String;
        final changelog = data['changelog'] as String;
        final forceUpdate = data['force_update'] as bool? ?? false;
        final versionName = data['version_name'] as String? ?? 'v1.0.0';
        
        if (latestVersion > currentVersion) {
          return UpdateInfo(
            latestVersion: latestVersion,
            versionName: versionName,
            downloadUrl: downloadUrl,
            changelog: changelog,
            forceUpdate: forceUpdate,
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur vérification mise à jour: $e");
    }
    return null;
  }
  
  static String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'desktop';
  }
  
  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
    if (info.forceUpdate) {
      // Mise à jour obligatoire - l'utilisateur ne peut pas fermer
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update_alt, color: Color(0xFF2884A0)),
              SizedBox(width: 10),
              Text('Mise à jour obligatoire'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Une nouvelle version est disponible.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2884A0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version ${info.versionName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text('Nouveautés :', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(info.changelog),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _downloadAndInstall(info.downloadUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2884A0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Mettre à jour maintenant'),
            ),
          ],
        ),
      );
    } else {
      // Mise à jour optionnelle - l'utilisateur peut ignorer
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.system_update_alt, color: Color(0xFF2884A0)),
              SizedBox(width: 10),
              Text('Nouvelle mise à jour'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Une nouvelle version est disponible.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2884A0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version ${info.versionName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text('Nouveautés :', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(info.changelog),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2884A0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      );
      
      if (result == true) {
        await _downloadAndInstall(info.downloadUrl);
      }
    }
  }
  
  static Future<void> _downloadAndInstall(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Impossible de lancer l'URL: $url");
    }
  }
}

class UpdateInfo {
  final int latestVersion;
  final String versionName;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;
  
  UpdateInfo({
    required this.latestVersion,
    required this.versionName,
    required this.downloadUrl,
    required this.changelog,
    required this.forceUpdate,
  });
}