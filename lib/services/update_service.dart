// lib/services/update_service.dart

import 'dart:io';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:yeki/core/network/api_client.dart';

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

  /// Empreinte SHA-256 (hex) du binaire, vérifiée avant installation
  /// (P12.1) — vide si le backend ne l'a pas encore renseignée pour
  /// cette version (transition, ne bloque pas l'installation).
  final String checksumSha256;

  /// Canal de diffusion ('stable'/'beta'/'alpha') de cette version.
  final String canal;

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
    this.checksumSha256 = '',
    this.canal = 'stable',
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
      checksumSha256: json['checksum_sha256'] as String? ?? '',
      canal: json['canal'] as String? ?? 'stable',
    );
  }
}

/// Service de mise à jour
class UpdateService {
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
      final data = await ApiClient().get('/latest-version/', query: {'platform': platform});
      final updateInfo = UpdateInfo.fromJson(data, currentVersion);

      // Vérifier si l'utilisateur a ignoré cette version
      if (!updateInfo.forceUpdate && skippedVersion == updateInfo.versionName) {
        return null;
      }

      if (updateInfo.isUpdateAvailable || showNoUpdate) {
        return updateInfo;
      }
    } catch (e) {
      debugPrint('Erreur vérification mise à jour: $e');
    }
    return null;
  }

  /// Vérifie si une mise à jour OBLIGATOIRE est requise, via
  /// `/api/app/version/` (P12.1) — coexiste avec [checkForUpdate]
  /// (`/latest-version/`, flux optionnel) : renvoie un [UpdateInfo]
  /// complet (téléchargement + checksum inclus) plutôt qu'un message
  /// seul, pour pouvoir être passé tel quel à [showUpdateDialog] et
  /// déclencher un vrai téléchargement+installation vérifiés.
  ///
  /// Une panne réseau/serveur ne doit JAMAIS bloquer l'utilisateur au
  /// splash — capturée ici, jamais remontée.
  static Future<UpdateInfo?> checkMandatoryVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 1;
      final data = await ApiClient().get(
        '/app/version/',
        query: {'plateforme': currentPlatform, 'build': packageInfo.buildNumber},
      ) as Map<String, dynamic>;

      final obligatoire = data['obligatoire'] as bool? ?? false;
      final disponible = data['mise_a_jour_disponible'] as bool? ?? false;
      if (!obligatoire && !disponible) {
        return null;
      }
      return UpdateInfo(
        latestVersion: data['version_code'] as int? ?? currentVersion,
        currentVersion: currentVersion,
        versionName: data['version_name'] as String? ?? 'v1.0.0',
        downloadUrl: data['download_url'] as String? ?? '',
        changelog: data['changelog'] as String? ?? (data['message'] as String? ?? ''),
        forceUpdate: obligatoire,
        isUpdateAvailable: disponible,
        fileSize: data['file_size'] as int? ?? 0,
        checksumSha256: data['checksum_sha256'] as String? ?? '',
        canal: data['canal'] as String? ?? 'stable',
      );
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

      final data = await ApiClient().get(
        '/check-update/',
        query: {'platform': platform, 'current_version': currentVersion.toString()},
      );
      return data['update_available'] as bool? ?? false;
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

      // Vérification d'intégrité (P12.1) — ferme la faille de sécurité
      // centrale du ticket : jusqu'ici, aucune vérification n'existait
      // entre le téléchargement et `OpenFile.open`. Un checksum vide
      // (version pas encore rétro-remplie côté admin) n'est PAS bloquant
      // (arbitrage tranché) ; un checksum présent mais qui ne correspond
      // pas au fichier téléchargé l'est toujours.
      final downloadedFile = File(savePath);
      if (info.checksumSha256.isNotEmpty) {
        final empreinteReelle = await _calculerSha256(downloadedFile);
        if (empreinteReelle.toLowerCase() != info.checksumSha256.toLowerCase()) {
          debugPrint('Échec de vérification d\'intégrité, fichier supprimé');
          if (await downloadedFile.exists()) {
            await downloadedFile.delete();
          }
          return false;
        }
      } else {
        debugPrint('Aucun checksum fourni pour cette version — installation non vérifiée');
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

  /// Télécharger depuis URL directe — en flux (`downloadStream`, déjà
  /// utilisé par `download_manager.dart`/`lecture_lecon_page.dart`), pas
  /// de chargement de tout l'APK en mémoire d'un coup.
  static Future<bool> _downloadFromUrl(String url, String savePath) async {
    try {
      final response = await ApiClient().downloadStream(url);
      final file = File(savePath);
      final sink = file.openWrite();
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
      }
      await sink.close();
      return await file.exists();
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

  /// Calcule l'empreinte SHA-256 (hex) d'un fichier en flux (P12.1) —
  /// évite de charger tout le fichier une seconde fois en mémoire.
  static Future<String> _calculerSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
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
    // Bug corrigé : un build desktop natif (Windows/macOS/Linux) retombait
    // sur 'web' par défaut alors que le backend a déjà un choix
    // `platform="desktop"` dédié (`AppVersion.PLATFORM_CHOICES`) —
    // interrogeait donc la mauvaise plateforme pour son propre mécanisme
    // de mise à jour in-app.
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) return 'desktop';
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