// lib/services/download_manager.dart
// ═══════════════════════════════════════════════════════════════════════════
// GESTIONNAIRE DE TÉLÉCHARGEMENT DE FICHIERS - CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, VoidCallback;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

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
      final file = File(filePath);

      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        final totalBytes = response.contentLength;
        var receivedBytes = 0;
        final sink = file.openWrite();

        await for (final chunk in response.stream) {
          if (cancelToken.isCancelled) {
            await sink.close();
            await file.delete();
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

        _downloadPaths[fileId] = filePath;
        controller?.add(1.0);
        controller?.close();
        _progressControllers.remove(fileId);
        _cancelTokens.remove(fileId);
        onComplete?.call();
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
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

  Future<void> openDownloadedFile(String fileId) async {
    if (kIsWeb) return;
    final path = _downloadPaths[fileId];
    if (path != null && await File(path).exists()) {
      await OpenFile.open(path);
    }
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