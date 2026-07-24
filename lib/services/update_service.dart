// lib/services/update_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:yeki/core/constants/api_constants.dart';

/// Modèle d'information de mise à jour
class UpdateInfo {
  final int latestVersion;
  final int currentVersion;
  final String versionName;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;
  final bool isUpdateAvailable;
  final int fileSize;
  final String releaseDate;
  final bool isNoUpdate;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.versionName,
    required this.downloadUrl,
    required this.changelog,
    required this.forceUpdate,
    this.isUpdateAvailable = true,
    this.fileSize = 0,
    this.releaseDate = '',
    this.isNoUpdate = false,
  });

  factory UpdateInfo.noUpdate(int currentVersion) {
    return UpdateInfo(
      latestVersion: currentVersion,
      currentVersion: currentVersion,
      versionName: 'v1.0.0',
      downloadUrl: '',
      changelog: '',
      forceUpdate: false,
      isUpdateAvailable: false,
      isNoUpdate: true,
    );
  }

  factory UpdateInfo.fromJson(Map<String, dynamic> json, int currentVersion) {
    return UpdateInfo(
      latestVersion: json['version_code'] as int? ?? 1,
      currentVersion: currentVersion,
      versionName: json['version_name'] as String? ?? 'v1.0.0',
      downloadUrl: json['download_url'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
      isUpdateAvailable: json['is_update_available'] as bool? ?? false,
      fileSize: json['file_size'] as int? ?? 0,
      releaseDate: json['release_date'] as String? ?? '',
    );
  }
}

/// Résultat du nouveau mécanisme de vérification obligatoire (P5.1bis,
/// `/api/app/version/`) — volontairement minimal : le contrat de réponse
/// réel et l'écran de blocage complet arrivent en P12.1.
class MandatoryVersionInfo {
  final String message;

  const MandatoryVersionInfo({required this.message});
}

/// Service de mise à jour
class UpdateService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String prefSkipVersion = 'skip_version';
  static const String prefLastCheck = 'last_update_check';

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// ✅ Initialisation du service (requise pour Firebase)
  static Future<void> initialize() async {
    // Vérifier que Firebase Storage est disponible
    try {
      await _storage.ref('').listAll().timeout(const Duration(seconds: 5));
      debugPrint('✅ UpdateService initialisé avec succès');
    } catch (e) {
      debugPrint('⚠️ UpdateService: Firebase Storage non disponible: $e');
      // L'initialisation ne doit pas bloquer l'application
    }
  }

  /// Vérifie si une mise à jour est disponible
  static Future<UpdateInfo?> checkForUpdate({
    bool showNoUpdate = false,
    bool forceCheck = false,
  }) async {
    try {
      // Récupérer la version actuelle
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 1;
      final platform = _getPlatform();

      // Vérifier le cache (une fois par heure)
      if (!forceCheck) {
        final prefs = await SharedPreferences.getInstance();
        final lastCheck = prefs.getInt(prefLastCheck) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (!showNoUpdate && (now - lastCheck) < 3600000) {
          return null;
        }
        await prefs.setInt(prefLastCheck, now);
      }

      // Vérifier la version ignorée
      final prefs = await SharedPreferences.getInstance();
      final skippedVersion = prefs.getString(prefSkipVersion);

      // Appeler l'API Django
      final response = await http.get(
        Uri.parse('$baseUrl/latest-version/?platform=$platform'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updateInfo = UpdateInfo.fromJson(data, currentVersion);

        // Vérifier si l'utilisateur a ignoré cette version
        if (!updateInfo.forceUpdate && skippedVersion == updateInfo.versionName) {
          return null;
        }

        if (updateInfo.isUpdateAvailable || showNoUpdate) {
          return updateInfo;
        }
      }
    } catch (e) {
      debugPrint('Erreur vérification mise à jour: $e');
    }
    return null;
  }

  /// Vérifie si une mise à jour OBLIGATOIRE est requise, via le nouveau
  /// mécanisme `/api/app/version/` (P5.1bis) — coexiste temporairement
  /// avec [checkForUpdate] (`/latest-version/`, fonctionnel dès
  /// aujourd'hui) : l'endpoint et l'écran de blocage réels arrivent en
  /// P12.1, cet appel est posé maintenant et sera câblé/réconcilié à ce
  /// moment-là.
  ///
  /// Tant que l'endpoint n'existe pas côté Django, cet appel échoue
  /// (404) — capturé ici, jamais remonté : une panne réseau/serveur ne
  /// doit JAMAIS bloquer l'utilisateur au splash.
  static Future<MandatoryVersionInfo?> checkMandatoryVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final response = await http
          .get(
            Uri.parse(
              '${ApiConstants.appVersion}?plateforme=$currentPlatform&build=${packageInfo.buildNumber}',
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['obligatoire'] == true) {
          return MandatoryVersionInfo(
            message: data['message'] as String? ?? 'Une mise à jour est requise pour continuer.',
          );
        }
      }
    } catch (e) {
      debugPrint('Vérification version obligatoire (endpoint P12.1) : $e');
    }
    return null;
  }

  /// Vérifie rapidement si une mise à jour est disponible
  static Future<bool> isUpdateAvailable() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 1;
      final platform = _getPlatform();

      final response = await http.get(
        Uri.parse('$baseUrl/check-update/?platform=$platform&current_version=$currentVersion'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['update_available'] as bool? ?? false;
      }
    } catch (e) {
      debugPrint('Erreur vérification mise à jour rapide: $e');
    }
    return false;
  }

  /// Télécharge et installe la mise à jour
  static Future<bool> downloadAndInstallUpdate(UpdateInfo info) async {
    if (kIsWeb) {
      debugPrint('Mise à jour non supportée sur le Web');
      return false;
    }

    // Vérifier les permissions
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        return false;
      }
    }

    try {
      final directory = await _getDownloadDirectory();
      final fileName = 'yeki_${info.versionName.replaceAll('v', '')}.apk';
      final savePath = '${directory.path}/$fileName';

      // Supprimer l'ancien fichier s'il existe
      final existingFile = File(savePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      // Télécharger depuis Firebase Storage ou URL directe
      bool downloadSuccess = false;

      // Méthode 1: URL directe (si disponible)
      if (info.downloadUrl.isNotEmpty) {
        try {
          downloadSuccess = await _downloadFromUrl(info.downloadUrl, savePath);
        } catch (e) {
          debugPrint('Erreur téléchargement URL directe: $e');
          downloadSuccess = false;
        }
      }

      // Méthode 2: Firebase Storage
      if (!downloadSuccess) {
        try {
          downloadSuccess = await _downloadFromFirebaseStorage(info, savePath);
        } catch (e) {
          debugPrint('Erreur téléchargement Firebase Storage: $e');
          downloadSuccess = false;
        }
      }

      if (!downloadSuccess) {
        return false;
      }

      // Ouvrir l'APK pour installation
      await OpenFile.open(savePath);

      // Sauvegarder pour installation différée
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('downloaded_apk_path', savePath);
      await prefs.setString('downloaded_version', info.versionName);

      return true;
    } catch (e) {
      debugPrint('Erreur téléchargement: $e');
      return false;
    }
  }

  /// Télécharger depuis URL directe
  static Future<bool> _downloadFromUrl(String url, String savePath) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return await file.exists();
      }
      return false;
    } catch (e) {
      debugPrint('Erreur _downloadFromUrl: $e');
      return false;
    }
  }

  /// Télécharger depuis Firebase Storage
  static Future<bool> _downloadFromFirebaseStorage(UpdateInfo info, String savePath) async {
    try {
      final ref = _storage.refFromURL(info.downloadUrl);
      
      // Télécharger avec progression
      final file = File(savePath);
      await ref.writeToFile(file);
      
      return await file.exists();
    } catch (e) {
      debugPrint('Erreur _downloadFromFirebaseStorage: $e');
      return false;
    }
  }

  /// Télécharger avec progression (pour UI)
  static Stream<double> downloadWithProgress(UpdateInfo info) async* {
    if (info.downloadUrl.isEmpty) {
      yield 0.0;
      return;
    }

    try {
      final ref = _storage.refFromURL(info.downloadUrl);
      final directory = await _getDownloadDirectory();
      final fileName = 'yeki_${info.versionName.replaceAll('v', '')}.apk';
      final savePath = '${directory.path}/$fileName';

      // Supprimer l'ancien fichier
      final existingFile = File(savePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      final file = File(savePath);
      
      // Téléchargement avec progression
      final task = ref.writeToFile(file);
      
      // Écouter la progression
      await for (final snapshot in task.snapshotEvents) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        yield progress;
      }
      
      yield 1.0;
    } catch (e) {
      debugPrint('Erreur téléchargement progression: $e');
      yield 0.0;
    }
  }

  static Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final downloadsDir = await getExternalStorageDirectory();
      if (downloadsDir != null) {
        final yekiDir = Directory('${downloadsDir.path}/Yeki');
        if (!await yekiDir.exists()) {
          await yekiDir.create(recursive: true);
        }
        return yekiDir;
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }

  /// Détection de plateforme déjà utilisée par [checkForUpdate] — exposée
  /// pour réutilisation (ex. [checkMandatoryVersion]) sans dupliquer la
  /// logique (règle 1).
  static String get currentPlatform => _getPlatform();

  /// Ignorer cette version
  static Future<void> skipVersion(String versionName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefSkipVersion, versionName);
  }

  // ─────────────────────────────────────────────────────────────
  //  AFFICHAGE DIALOGUES
  // ─────────────────────────────────────────────────────────────

  /// Affiche le dialogue de mise à jour
  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
    if (info.isNoUpdate) {
      _showNoUpdateSnackbar(context);
      return;
    }

    if (info.forceUpdate) {
      await _showForceUpdateDialog(context, info);
    } else {
      await _showOptionalUpdateDialog(context, info);
    }
  }

  static Future<void> _showForceUpdateDialog(BuildContext context, UpdateInfo info) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.system_update_alt, color: Color(0xFF135F74), size: 28),
            SizedBox(width: 10),
            Text('Mise à jour obligatoire'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Une nouvelle version (${info.versionName}) est disponible.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF135F74).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Nouveautés :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    info.changelog,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (info.fileSize > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '📦 Taille: ${(info.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await downloadAndInstallUpdate(info);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Erreur lors du téléchargement'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135F74),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Télécharger maintenant'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showOptionalUpdateDialog(BuildContext context, UpdateInfo info) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.system_update_alt, color: Color(0xFF135F74), size: 24),
            SizedBox(width: 10),
            Text('Nouvelle mise à jour'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${info.versionName} disponible.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF135F74).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Nouveautés :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    info.changelog,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await skipVersion(info.versionName);
              Navigator.pop(ctx, false);
            },
            child: const Text('Ignorer cette version'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135F74),
              foregroundColor: Colors.white,
            ),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await downloadAndInstallUpdate(info);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors du téléchargement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void _showNoUpdateSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Vous utilisez déjà la dernière version'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}