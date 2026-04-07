// lib/services/update_service.dart

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
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:crypto/crypto.dart';

// Callback pour WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'scheduledUpdateCheck':
        await UpdateService.checkForUpdateInBackground();
        break;
      case 'scheduledDownload':
        await UpdateService.processPendingDownloads();
        break;
    }
    return Future.value(true);
  });
}

class UpdateService {
  static const String API_URL = "https://yeki.pythonanywhere.com/api/latest-version/";
  static const String PREF_LAST_CHECK = 'last_update_check';
  static const String PREF_PENDING_DOWNLOAD = 'pending_download';
  static const String PREF_UPDATE_SCHEDULED = 'update_scheduled';
  
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
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
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(initSettings);
    
    // Initialiser WorkManager pour les tâches planifiées
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    
    // Planifier la vérification quotidienne
    await Workmanager().registerPeriodicTask(
      "scheduledUpdateCheck",
      "scheduledUpdateCheck",
      frequency: Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
    
    // Planifier le traitement des téléchargements en attente
    await Workmanager().registerPeriodicTask(
      "scheduledDownload",
      "scheduledDownload",
      frequency: Duration(hours: 6),
    );
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
        
        // Vérifier si mise à jour obligatoire
        final isForceUpdate = forceUpdate || (currentVersion < minVersion);
        
        if (latestVersion > currentVersion) {
          return UpdateInfo(
            latestVersion: latestVersion,
            currentVersion: currentVersion,
            versionName: versionName,
            downloadUrl: downloadUrl,
            changelog: changelog,
            forceUpdate: isForceUpdate,
            isIncremental: _isIncrementalUpdate(currentVersion, latestVersion),
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
  //  VÉRIFICATION EN ARRIÈRE-PLAN
  // ─────────────────────────────────────────────────────────────
  static Future<void> checkForUpdateInBackground() async {
    final updateInfo = await checkForUpdate();
    if (updateInfo != null && !updateInfo.forceUpdate) {
      // Notification silencieuse
      await _showBackgroundNotification(updateInfo);
    }
  }
  
  // ─────────────────────────────────────────────────────────────
  //  TÉLÉCHARGEMENT EN ARRIÈRE-PLAN
  // ─────────────────────────────────────────────────────────────
  static Future<bool> downloadInBackground(UpdateInfo info) async {
    // Vérifier les permissions
    if (!await _requestPermissions()) {
      debugPrint("Permissions refusées");
      return false;
    }
    
    try {
      // Obtenir le répertoire de téléchargement
      final directory = await _getDownloadDirectory();
      final fileName = _getFileName(info.downloadUrl);
      final savePath = '${directory.path}/$fileName';
      
      // Supprimer l'ancien fichier s'il existe
      final existingFile = File(savePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }
      
      // Calculer le hash du fichier existant pour mise à jour incrémentale
      String? existingHash;
      if (info.isIncremental && await existingFile.exists()) {
        existingHash = await _calculateFileHash(existingFile);
      }
      
      // Démarrer le téléchargement
      final taskId = await FlutterDownloader.enqueue(
        url: info.downloadUrl,
        savedDir: directory.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
        headers: info.isIncremental && existingHash != null
            ? {'If-None-Match': existingHash}
            : {},
      );
      
      // Sauvegarder les infos de téléchargement
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREF_PENDING_DOWNLOAD, taskId!);
      await prefs.setString('pending_version', info.versionName);
      
      // Écouter la progression
      FlutterDownloader.registerCallback((id, status, progress) {
        if (id == taskId) {
          _onDownloadProgress(id, status as DownloadTaskStatus, progress, savePath, info);
        }
      });
      
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
    if (hash != await _getExpectedHash(info.downloadUrl)) {
      debugPrint("Hash mismatch - fichier corrompu");
      await file.delete();
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
  }
  
  // ─────────────────────────────────────────────────────────────
  //  INSTALLATION AUTOMATIQUE
  // ─────────────────────────────────────────────────────────────
  static Future<bool> installAutomatically(String apkPath) async {
    if (Platform.isAndroid) {
      // Vérifier la permission d'installation
      if (!await Permission.requestInstallPackages.isGranted) {
        final result = await Permission.requestInstallPackages.request();
        if (!result.isGranted) {
          return false;
        }
      }
      
      // Ouvrir le fichier pour installation
      final file = File(apkPath);
      if (!await file.exists()) return false;
      
      // Utiliser intent pour lancer l'installation
      return true;
    } else if (Platform.isIOS) {
      // Sur iOS, rediriger vers l'App Store
      return false;
    }
    return false;
  }
  
  // ─────────────────────────────────────────────────────────────
  //  MISE À JOUR PLANIFIÉE
  // ─────────────────────────────────────────────────────────────
  static Future<void> scheduleUpdate(UpdateInfo info, {DateTime? scheduledTime}) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleTime = scheduledTime ?? _getOptimalUpdateTime();
    
    await prefs.setString(PREF_UPDATE_SCHEDULED, jsonEncode({
      'version': info.versionName,
      'url': info.downloadUrl,
      'time': scheduleTime.toIso8601String(),
    }));
    
    // Planifier la tâche
    await Workmanager().registerOneOffTask(
      "scheduledDownload",
      "scheduledDownload",
      initialDelay: scheduleTime.difference(DateTime.now()),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresCharging: true,
      ),
    );
    
    // Notifier l'utilisateur
    await _showScheduledNotification(scheduleTime);
  }
  
  static DateTime _getOptimalUpdateTime() {
    final now = DateTime.now();
    // Planifier entre 2h et 5h du matin
    DateTime optimal = DateTime(now.year, now.month, now.day, 3, 0);
    if (optimal.isBefore(now)) {
      optimal = optimal.add(const Duration(days: 1));
    }
    return optimal;
  }
  
  static Future<void> processPendingDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(PREF_UPDATE_SCHEDULED);
    if (pendingJson == null) return;
    
    final pending = jsonDecode(pendingJson);
    final scheduledTime = DateTime.parse(pending['time']);
    
    if (DateTime.now().isAfter(scheduledTime)) {
      // Télécharger et installer
      final info = UpdateInfo(
        latestVersion: 0,
        currentVersion: 0,
        versionName: pending['version'],
        downloadUrl: pending['url'],
        changelog: '',
        forceUpdate: false,
        isIncremental: false,
      );
      await downloadInBackground(info);
      await prefs.remove(PREF_UPDATE_SCHEDULED);
    }
  }
  
  // ─────────────────────────────────────────────────────────────
  //  MISE À JOUR INCRÉMENTALE
  // ─────────────────────────────────────────────────────────────
  static bool _isIncrementalUpdate(int currentVersion, int latestVersion) {
    // Mise à jour incrémentale seulement si écart <= 2 versions
    return (latestVersion - currentVersion) <= 2;
  }
  
  static Future<String> _calculateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
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
  //  NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────
  static Future<void> _showBackgroundNotification(UpdateInfo info) async {
    const androidDetails = AndroidNotificationDetails(
      'update_channel',
      'Mises à jour',
      channelDescription: 'Notifications de mise à jour',
      importance: Importance.low,
      priority: Priority.low,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notifications.show(
      Random().nextInt(9999),
      'Nouvelle mise à jour disponible',
      'Yéki ${info.versionName} est disponible',
      details,
    );
  }
  
  static Future<void> _showDownloadCompleteNotification(String path, UpdateInfo info) async {
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Téléchargements',
      channelDescription: 'Téléchargements terminés',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notifications.show(
      Random().nextInt(9999),
      'Téléchargement terminé',
      'Yéki ${info.versionName} est prêt à être installé',
      details,
      payload: path,
    );
  }
  
  static Future<void> _showScheduledNotification(DateTime time) async {
    const androidDetails = AndroidNotificationDetails(
      'schedule_channel',
      'Mises à jour planifiées',
      channelDescription: 'Mise à jour programmée',
      importance: Importance.defaultImportance,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notifications.show(
      Random().nextInt(9999),
      'Mise à jour programmée',
      'La mise à jour sera installée ce soir à ${time.hour}:${time.minute}',
      details,
    );
  }
  
  // ─────────────────────────────────────────────────────────────
  //  PERMISSIONS
  // ─────────────────────────────────────────────────────────────
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.storage,
        Permission.notification,
      ].request();
      
      final allGranted = statuses.values.every((status) => status.isGranted);
      
      if (!allGranted) {
        // Demander à nouveau
        final again = await [
          Permission.storage,
          Permission.notification,
        ].request();
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
      return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }
  
  static String _getFileName(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    return segments.isNotEmpty ? segments.last : 'yeki_update.apk';
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
            Icon(Icons.system_update_alt, color: Color(0xFF2884A0), size: 28),
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
                color: const Color(0xFF2884A0).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nouveautés :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(info.changelog),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.wifi_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                const Text('Téléchargement en arrière-plan', style: TextStyle(fontSize: 11)),
                const Spacer(),
                const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                const Text('Installation automatique', style: TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await downloadInBackground(info);
              if (success && context.mounted) {
                _showDownloadStartedSnackbar(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2884A0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Télécharger maintenant'),
          ),
          TextButton(
            onPressed: () async {
              await scheduleUpdate(info);
              Navigator.pop(ctx);
              _showScheduledSnackbar(context);
            },
            child: const Text('Programmer pour plus tard'),
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
            Icon(Icons.system_update_alt, color: Color(0xFF2884A0), size: 24),
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
                color: const Color(0xFF2884A0).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nouveautés :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mettre à jour'),
          ),
          TextButton(
            onPressed: () async {
              await scheduleUpdate(info);
              Navigator.pop(ctx, false);
              _showScheduledSnackbar(context);
            },
            child: const Text('Programmer'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final success = await downloadInBackground(info);
      if (success && context.mounted) {
        _showDownloadStartedSnackbar(context);
      }
    }
  }
  
  static void _showNoUpdateSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Vous utilisez déjà la dernière version'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  static void _showDownloadStartedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📥 Téléchargement en arrière-plan...'),
        backgroundColor: Color(0xFF2884A0),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  static void _showScheduledSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ Mise à jour programmée pour cette nuit'),
        backgroundColor: Color(0xFFE2A84B),
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
  final bool isIncremental;
  final bool isNoUpdate;
  
  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.versionName,
    required this.downloadUrl,
    required this.changelog,
    required this.forceUpdate,
    this.isIncremental = false,
    this.isNoUpdate = false,
  });
  
  UpdateInfo.noUpdate(this.currentVersion)
      : latestVersion = currentVersion,
        versionName = '',
        downloadUrl = '',
        changelog = '',
        forceUpdate = false,
        isIncremental = false,
        isNoUpdate = true;
}