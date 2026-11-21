// lib/services/download_manager.dart
// ═══════════════════════════════════════════════════════════════════════════
// GESTIONNAIRE DE TÉLÉCHARGEMENT DE FICHIERS - CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/services/acces_hors_ligne_service.dart';
import 'package:yeki/services/offline_encryption_service.dart';

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Map<String, StreamController<double>> _progressControllers = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, String> _downloadPaths = {};

  /// Cours de chaque fichier téléchargé (fileId → coursId), pour appliquer
  /// la règle d'abonnement du département concerné
  /// (`AccesHorsLigneService`).
  final Map<String, int> _coursParFichier = {};

  // Bug corrigé : la liste des téléchargements n'existait qu'en mémoire —
  // après un redémarrage de l'app, les fichiers restaient sur le téléphone
  // mais plus rien ne les retrouvait. Elle est désormais enregistrée.
  static const _cleRegistre = 'yeki_telechargements';
  bool _registreCharge = false;

  /// Recharge la liste des téléchargements enregistrée (à appeler au
  /// démarrage, avant toute lecture de statut).
  Future<void> initialiser() async {
    if (kIsWeb || _registreCharge) return;
    _registreCharge = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(_cleRegistre);
      if (brut == null) return;
      final registre = Map<String, dynamic>.from(jsonDecode(brut) as Map);
      registre.forEach((fileId, valeur) {
        final entree = Map<String, dynamic>.from(valeur as Map);
        final chemin = entree['chemin'] as String?;
        if (chemin == null || !File(chemin).existsSync()) return;
        _downloadPaths[fileId] = chemin;
        final coursId = (entree['cours_id'] as num?)?.toInt();
        if (coursId != null) _coursParFichier[fileId] = coursId;
      });
    } catch (_) {
      // Registre illisible : on repart d'une liste vide, sans bloquer l'app.
    }
  }

  Future<void> _enregistrerRegistre() async {
    final prefs = await SharedPreferences.getInstance();
    final registre = {
      for (final e in _downloadPaths.entries)
        e.key: {'chemin': e.value, if (_coursParFichier[e.key] != null) 'cours_id': _coursParFichier[e.key]},
    };
    await prefs.setString(_cleRegistre, jsonEncode(registre));
  }

  /// Fichiers téléchargés rattachés à un cours (fileId → coursId).
  Map<String, int> get fichiersParCours => Map.unmodifiable(_coursParFichier);

  Future<String> _getDownloadDirectory() async {
    if (kIsWeb) {
      return '/tmp/yeki_downloads';
    }
    if (Platform.isAndroid) {
      final downloadsDir = await getExternalStorageDirectory();
      if (downloadsDir != null) {
        final yekiDir = Directory('${downloadsDir.path}/Yeki');
        if (!await yekiDir.exists()) {
          await yekiDir.create(recursive: true);
        }
        return yekiDir.path;
      }
    }
    final appDir = await getApplicationDocumentsDirectory();
    final yekiDir = Directory('${appDir.path}/Yeki');
    if (!await yekiDir.exists()) {
      await yekiDir.create(recursive: true);
    }
    return yekiDir.path;
  }

  Stream<double> getProgress(String fileId) {
    if (!_progressControllers.containsKey(fileId)) {
      _progressControllers[fileId] = StreamController<double>.broadcast();
    }
    return _progressControllers[fileId]!.stream;
  }

  DownloadStatus getStatus(String fileId) {
    if (kIsWeb) return DownloadStatus.notDownloaded;
    final path = _downloadPaths[fileId];
    if (path != null && File(path).existsSync()) {
      return DownloadStatus.downloaded;
    }
    if (_cancelTokens.containsKey(fileId)) {
      return DownloadStatus.downloading;
    }
    return DownloadStatus.notDownloaded;
  }

  Future<bool> isDownloaded(String fileId) async {
    if (kIsWeb) return false;
    final path = _downloadPaths[fileId];
    if (path != null) {
      return await File(path).exists();
    }
    return false;
  }

  String? getDownloadedPath(String fileId) {
    if (kIsWeb) return null;
    final path = _downloadPaths[fileId];
    if (path != null && File(path).existsSync()) {
      return path;
    }
    return null;
  }

  Future<void> downloadFile({
    required String url,
    required String fileId,
    required String fileName,
    required String fileType,
    int? coursId,
    VoidCallback? onComplete,
    void Function(String error)? onError,
  }) async {
    // Support Web : désactiver le téléchargement
    if (kIsWeb) {
      onError?.call('Téléchargement non supporté sur le Web');
      return;
    }
    
    if (await isDownloaded(fileId)) {
      onComplete?.call();
      return;
    }

    final cancelToken = CancelToken();
    _cancelTokens[fileId] = cancelToken;

    final controller = _progressControllers[fileId];
    controller?.add(0.0);

    try {
      final dirPath = await _getDownloadDirectory();
      final filePath = '$dirPath/${_sanitizeFileName(fileName)}';
      // Téléchargement en clair vers un fichier temporaire — le flux
      // chunk par chunk est conservé tel quel (pas de régression mémoire
      // pendant le téléchargement) ; seul le fichier FINAL conservé sur
      // disque est chiffré (P12.3).
      final tmpFile = File('$filePath.tmp');

      final response = await ApiClient().downloadStream(url);
      final totalBytes = int.tryParse(response.headers.value('content-length') ?? '');
      var receivedBytes = 0;
      final sink = tmpFile.openWrite();

      await for (final chunk in response.data!.stream) {
        if (cancelToken.isCancelled) {
          await sink.close();
          await tmpFile.delete();
          controller?.addError('Annulé');
          return;
        }

        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes != null && totalBytes > 0) {
          final progress = receivedBytes / totalBytes;
          controller?.add(progress);
        }
      }
      await sink.close();

      // Chiffrement (P12.3) — le clair n'existe plus que le temps de ce
      // passage ; ce qui reste sur disque est le fichier chiffré.
      final octetsClairs = await tmpFile.readAsBytes();
      await OfflineEncryptionService.encryptBytesToFile(octetsClairs, filePath);
      await tmpFile.delete();

      _downloadPaths[fileId] = filePath;
      if (coursId != null) _coursParFichier[fileId] = coursId;
      await _enregistrerRegistre();
      controller?.add(1.0);
      controller?.close();
      _progressControllers.remove(fileId);
      _cancelTokens.remove(fileId);
      onComplete?.call();
    } catch (e) {
      controller?.addError(e.toString());
      controller?.close();
      _progressControllers.remove(fileId);
      _cancelTokens.remove(fileId);
      onError?.call(e.toString());
    }
  }

  Future<void> deleteDownloadedFile(String fileId) async {
    if (kIsWeb) return;
    final path = _downloadPaths[fileId];
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _downloadPaths.remove(fileId);
    _coursParFichier.remove(fileId);
    await _enregistrerRegistre();
  }

  void cancelDownload(String fileId) {
    if (kIsWeb) return;
    final cancelToken = _cancelTokens[fileId];
    cancelToken?.cancel();
    _cancelTokens.remove(fileId);
    final controller = _progressControllers[fileId];
    controller?.addError('Annulé');
    controller?.close();
    _progressControllers.remove(fileId);
  }

  /// Ouvre le fichier téléchargé avec une application externe
  /// (`OpenFile.open`) — le fichier conservé sur disque est chiffré
  /// (P12.3), donc déchiffré vers un fichier temporaire avant ouverture.
  /// Limite assumée : `OpenFile.open` ne renvoie aucun signal de fin de
  /// lecture côté application externe, donc ce fichier temporaire déchiffré
  /// ne peut pas être supprimé de façon fiable après usage (même limite
  /// que le fichier de mise à jour téléchargé en P12.1, qui persiste lui
  /// aussi dans un dossier durable une fois ouvert).
  Future<void> openDownloadedFile(String fileId) async {
    if (kIsWeb) return;
    if (!await AccesHorsLigneService.peutLire(_coursParFichier[fileId])) {
      throw const AbonnementTermineException();
    }
    final path = _downloadPaths[fileId];
    if (path != null && await File(path).exists()) {
      final fichierTemp = await OfflineEncryptionService.decryptToTempFile(
        path,
        _sanitizeFileName('open_$fileId'),
      );
      await OpenFile.open(fichierTemp.path);
    }
  }

  /// Déchiffre le fichier téléchargé vers un fichier temporaire, pour un
  /// lecteur (PDF/vidéo) que l'appelant contrôle directement — à
  /// supprimer par l'appelant une fois la lecture terminée (le clair ne
  /// doit exister que le temps de la lecture).
  Future<File?> openForPlayback(String fileId) async {
    if (kIsWeb) return null;
    if (!await AccesHorsLigneService.peutLire(_coursParFichier[fileId])) {
      throw const AbonnementTermineException();
    }
    final path = _downloadPaths[fileId];
    if (path == null || !await File(path).exists()) return null;
    return OfflineEncryptionService.decryptToTempFile(
      path,
      _sanitizeFileName('play_$fileId'),
    );
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');
  }
}

/// Média téléchargé d'un cours dont l'abonnement est terminé : il faut
/// repayer un abonnement pour le relire (voir `AccesHorsLigneService`).
class AbonnementTermineException implements Exception {
  const AbonnementTermineException();

  @override
  String toString() => 'Votre abonnement est terminé : abonnez-vous à nouveau pour lire ce média.';
}

class CancelToken {
  bool _isCancelled = false;
  void cancel() => _isCancelled = true;
  bool get isCancelled => _isCancelled;
}