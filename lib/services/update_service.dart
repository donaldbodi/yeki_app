// lib/services/update_service.dart
// Version corrigée pour awesome_notifications 0.11.0

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class UpdateService {
  static const String API_URL = "https://yeki.pythonanywhere.com/api/latest-version/";
  static const String PREF_LAST_CHECK = 'last_update_check';
  static const String PREF_PENDING_DOWNLOAD = 'pending_download';
  static const String PREF_SKIP_VERSION = 'skip_version';
  
  // ─────────────────────────────────────────────────────────────
  //  INITIALISATION
  // ─────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    // Initialiser le téléchargeur
    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: false,
    );
    
    // Initialiser les notifications
    await _initializeAwesomeNotifications();
    
    // Vérifier les permissions au démarrage
    await _requestPermissions();
  }
  
  // Initialisation awesome_notifications
  static Future<void> _initializeAwesomeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'update_channel',
          channelName: 'Mises à jour',
          channelDescription: 'Notifications de mise à jour',
          defaultColor: const Color(0xFF135F74),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'download_channel',
          channelName: 'Téléchargements',
          channelDescription: 'Téléchargements terminés',
          defaultColor: const Color(0xFF10B981),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
      ],
    );
    
    // Demander la permission
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
  
  // ─────────────────────────────────────────────────────────────
  //  VÉRIFICATION PRINCIPALE
  // ─────────────────────────────────────────────────────────────
  static Future<UpdateInfo?> checkForUpdate({bool showNoUpdate = false}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 1;
      final platform = _getPlatform();
      
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(PREF_LAST_CHECK) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final skippedVersion = prefs.getString(PREF_SKIP_VERSION);
      
      // Vérifier au maximum toutes les heures
      if (!showNoUpdate && (now - lastCheck) < 3600000) {
        return null;
      }
      
      await prefs.setInt(PREF_LAST_CHECK, now);
      
      final response = await http.get(
        Uri.parse("$API_URL?platform=$platform"),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version_code'] as int;
        final downloadUrl = data['download_url'] as String;
        final changelog = data['changelog'] as String;
        final forceUpdate = data['force_update'] as bool? ?? false;
        final versionName = data['version_name'] as String? ?? 'v1.0.0';
        final minVersion = data['min_version'] as int? ?? 1;
        
        // Vérifier si l'utilisateur a ignoré cette version
        if (!forceUpdate && skippedVersion == versionName) {
          return null;
        }
        
        final isForceUpdate = forceUpdate || (currentVersion < minVersion);
        
        if (latestVersion > currentVersion) {
          return UpdateInfo(
            latestVersion: latestVersion,
            currentVersion: currentVersion,
            versionName: versionName,
            downloadUrl: downloadUrl,
            changelog: changelog,
            forceUpdate: isForceUpdate,
          );
        } else if (showNoUpdate) {
          return UpdateInfo.noUpdate(currentVersion);
        }
      }
    } catch (e) {
      debugPrint("Erreur vérification mise à jour: $e");
    }
    return null;
  }
  
  // ─────────────────────────────────────────────────────────────
  //  TÉLÉCHARGEMENT
  // ─────────────────────────────────────────────────────────────
  static Future<bool> downloadUpdate(UpdateInfo info) async {
    if (!await _requestPermissions()) {
      debugPrint("Permissions refusées");
      return false;
    }
    
    try {
      final directory = await _getDownloadDirectory();
      final fileName = _getFileName(info.downloadUrl);
      final savePath = '${directory.path}/$fileName';
      
      // Supprimer l'ancien fichier s'il existe
      final existingFile = File(savePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }
      
      // Démarrer le téléchargement
      final taskId = await FlutterDownloader.enqueue(
        url: info.downloadUrl,
        savedDir: directory.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
      );
      
      // Sauvegarder les infos de téléchargement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREF_PENDING_DOWNLOAD, taskId!);
      await prefs.setString('pending_version', info.versionName);
      await prefs.setString('pending_path', savePath);
      
      // Écouter la progression
      FlutterDownloader.registerCallback((id, status, progress) {
        if (id == taskId) {
          _onDownloadProgress(id, status as DownloadTaskStatus, progress, savePath, info);
        }
      });
      
      // Afficher une notification de début (sans progress bar)
      await _showDownloadStartedNotification(info);
      
      return true;
    } catch (e) {
      debugPrint("Erreur téléchargement: $e");
      return false;
    }
  }
  
  static void _onDownloadProgress(String taskId, DownloadTaskStatus status, int progress, String savePath, UpdateInfo info) {
    if (status == DownloadTaskStatus.complete) {
      _onDownloadComplete(savePath, info);
    } else if (status == DownloadTaskStatus.failed) {
      _onDownloadFailed();
    }
  }
  
  static Future<void> _onDownloadComplete(String savePath, UpdateInfo info) async {
    // Vérifier l'intégrité du fichier
    final file = File(savePath);
    if (!await file.exists()) return;
    
    // Vérifier le hash
    final hash = await _calculateFileHash(file);
    final expectedHash = await _getExpectedHash(info.downloadUrl);
    if (expectedHash.isNotEmpty && hash != expectedHash) {
      debugPrint("Hash mismatch - fichier corrompu");
      await file.delete();
      await _showCorruptedNotification(info);
      return;
    }
    
    // Notifier l'utilisateur
    await _showDownloadCompleteNotification(savePath, info);
    
    // Sauvegarder pour installation différée
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloaded_apk_path', savePath);
    await prefs.setString('downloaded_version', info.versionName);
  }
  
  static void _onDownloadFailed() {
    debugPrint("Téléchargement échoué");
    _showDownloadFailedNotification();
  }
  
  // ─────────────────────────────────────────────────────────────
  //  INSTALLATION
  // ─────────────────────────────────────────────────────────────
  static Future<bool> installUpdate(String apkPath) async {
    if (Platform.isAndroid) {
      // Vérifier la permission d'installation
      if (!await Permission.requestInstallPackages.isGranted) {
        final result = await Permission.requestInstallPackages.request();
        if (!result.isGranted) {
          return false;
        }
      }
      
      final file = File(apkPath);
      if (!await file.exists()) return false;
      
      return true;
    } else if (Platform.isIOS) {
      return false;
    }
    return false;
  }
  
  // ─────────────────────────────────────────────────────────────
  //  IGNORER UNE VERSION
  // ─────────────────────────────────────────────────────────────
  static Future<void> skipVersion(String versionName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PREF_SKIP_VERSION, versionName);
  }
  
  // ─────────────────────────────────────────────────────────────
  //  NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────
  static Future<void> _showDownloadStartedNotification(UpdateInfo info) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(9999),
        channelKey: 'download_channel',
        title: 'Téléchargement en cours',
        body: 'Téléchargement de Yéki ${info.versionName}...',
        notificationLayout: NotificationLayout.Default,
        displayOnBackground: true,
        displayOnForeground: true,
        color: const Color(0xFF135F74),
      ),
    );
  }
  
  static Future<void> _showDownloadCompleteNotification(String path, UpdateInfo info) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(9999),
        channelKey: 'download_channel',
        title: 'Téléchargement terminé ✅',
        body: 'Yéki ${info.versionName} est prêt à être installé',
        notificationLayout: NotificationLayout.Default,
        displayOnBackground: true,
        displayOnForeground: true,
        color: const Color(0xFF10B981),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'INSTALL',
          label: 'Installer maintenant',
          autoDismissible: true,
        ),
      ],
    );
  }
  
  static Future<void> _showDownloadFailedNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(9999),
        channelKey: 'download_channel',
        title: 'Téléchargement échoué ❌',
        body: 'Une erreur est survenue lors du téléchargement. Veuillez réessayer.',
        notificationLayout: NotificationLayout.Default,
        displayOnBackground: true,
        displayOnForeground: true,
        color: const Color(0xFFEF4444),
      ),
    );
  }
  
  static Future<void> _showCorruptedNotification(UpdateInfo info) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(9999),
        channelKey: 'download_channel',
        title: 'Fichier corrompu ⚠️',
        body: 'Le fichier téléchargé est corrompu. Veuillez réessayer.',
        notificationLayout: NotificationLayout.Default,
        displayOnBackground: true,
        displayOnForeground: true,
        color: const Color(0xFFF97316),
      ),
    );
  }
  
  // ─────────────────────────────────────────────────────────────
  //  PERMISSIONS
  // ─────────────────────────────────────────────────────────────
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.storage,
        Permission.notification,
      ];
      
      // Pour Android 8+ (API 26+)
      if (await Permission.requestInstallPackages.status.isDenied) {
        permissions.add(Permission.requestInstallPackages);
      }
      
      final statuses = await permissions.request();
      
      final allGranted = statuses.values.every((status) => status.isGranted);
      
      if (!allGranted) {
        // Deuxième tentative
        final again = await permissions.request();
        return again.values.every((status) => status.isGranted);
      }
      return true;
    }
    return true;
  }
  
  // ─────────────────────────────────────────────────────────────
  //  UTILITAIRES
  // ─────────────────────────────────────────────────────────────
  static String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'desktop';
  }
  
  static Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final downloadDir = await getExternalStorageDirectory();
      if (downloadDir != null) {
        final yekiDir = Directory('${downloadDir.path}/Yeki');
        if (!await yekiDir.exists()) {
          await yekiDir.create(recursive: true);
        }
        return yekiDir;
      }
    }
    return await getApplicationDocumentsDirectory();
  }
  
  static String _getFileName(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    final fileName = segments.isNotEmpty ? segments.last : 'yeki_update.apk';
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
  
  static Future<String> _calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      return '';
    }
  }
  
  static Future<String> _getExpectedHash(String url) async {
    try {
      final response = await http.get(Uri.parse("$url.sha256"));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (_) {}
    return '';
  }
  
  // ─────────────────────────────────────────────────────────────
  //  AFFICHAGE DIALOGUE
  // ─────────────────────────────────────────────────────────────
  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo info, {bool isManual = false}) async {
    if (info.isNoUpdate && isManual) {
      _showNoUpdateSnackbar(context);
      return;
    }
    
    if (info.isNoUpdate) return;
    
    final isForce = info.forceUpdate;
    
    if (isForce) {
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
            Text('Une nouvelle version (${info.versionName}) est disponible.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF135F74).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋 Nouveautés :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(info.changelog),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await downloadUpdate(info);
              if (success && context.mounted) {
                _showDownloadStartedSnackbar(context);
              } else if (context.mounted) {
                _showErrorSnackbar(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135F74),
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
            Text('Version ${info.versionName} disponible.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF135F74).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋 Nouveautés :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(info.changelog),
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
            ),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final success = await downloadUpdate(info);
      if (success && context.mounted) {
        _showDownloadStartedSnackbar(context);
      } else if (context.mounted) {
        _showErrorSnackbar(context);
      }
    }
  }
  
  // ─────────────────────────────────────────────────────────────
  //  SNACKBARS
  // ─────────────────────────────────────────────────────────────
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
  
  static void _showDownloadStartedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📥 Téléchargement en arrière-plan...'),
        backgroundColor: Color(0xFF135F74),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  static void _showErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Erreur lors du téléchargement'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MODÈLE UpdateInfo
// ─────────────────────────────────────────────────────────────
class UpdateInfo {
  final int latestVersion;
  final int currentVersion;
  final String versionName;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;
  final bool isNoUpdate;
  
  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.versionName,
    required this.downloadUrl,
    required this.changelog,
    required this.forceUpdate,
    this.isNoUpdate = false,
  });
  
  UpdateInfo.noUpdate(this.currentVersion)
      : latestVersion = currentVersion,
        versionName = '',
        downloadUrl = '',
        changelog = '',
        forceUpdate = false,
        isNoUpdate = true;
}