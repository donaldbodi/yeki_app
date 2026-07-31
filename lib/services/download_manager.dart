// lib/services/download_manager.dart
// ═══════════════════════════════════════════════════════════════════════════
// GESTIONNAIRE DE TÉLÉCHARGEMENT DE FICHIERS - CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:yeki/core/network/api_client.dart';
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

class CancelToken {
  bool _isCancelled = false;
  void cancel() => _isCancelled = true;
  bool get isCancelled => _isCancelled;
}