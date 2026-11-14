// lib/services/cache_manager.dart

import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart' as dio;
import 'package:hive/hive.dart';
import 'package:yeki/core/network/api_client.dart';

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();
  
  static const String _cacheBoxName = 'media_cache';
  late Box _cacheBox;
  bool _initialized = false;
  
  final Map<String, StreamController<double>> _progressControllers = {};
  final Map<String, dio.CancelToken> _cancelTokens = {};
  
  Future<void> init() async {
    if (_initialized) return;
    
    // ✅ Support Web : utiliser un répertoire virtuel
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    _cacheBox = await Hive.openBox(_cacheBoxName);
    _initialized = true;
  }
  
  Future<String> _getCacheDirectory() async {
    if (kIsWeb) {
      return '/tmp/yeki_media';
    }
    final cacheDir = await getTemporaryDirectory();
    final mediaDir = Directory('${cacheDir.path}/yeki_media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir.path;
  }
  
  Future<bool> isCached(String fileId) async {
    if (kIsWeb) return false;
    final info = _cacheBox.get(fileId);
    if (info == null) return false;
    final file = File(info['path']);
    return await file.exists();
  }
  
  DownloadStatus getStatus(String fileId) {
    if (kIsWeb) return DownloadStatus.notDownloaded;
    final info = _cacheBox.get(fileId);
    if (info == null) return DownloadStatus.notDownloaded;
    if (info['status'] == 'downloading') return DownloadStatus.downloading;
    if (info['status'] == 'failed') return DownloadStatus.failed;
    return DownloadStatus.downloaded;
  }
  
  Stream<double> getProgress(String fileId) {
    if (!_progressControllers.containsKey(fileId)) {
      _progressControllers[fileId] = StreamController<double>.broadcast();
    }
    return _progressControllers[fileId]!.stream;
  }
  
  Future<void> downloadFile({
    required String url,
    required String fileId,
    required String fileName,
    required String fileType,
    VoidCallback? onComplete,
    void Function(String error)? onError,
  }) async {
    // ✅ Support Web : désactiver le téléchargement
    if (kIsWeb) {
      onError?.call('Téléchargement non supporté sur le Web');
      return;
    }
    
    if (await isCached(fileId)) {
      onComplete?.call();
      return;
    }
    
    final cancelToken = dio.CancelToken();
    _cancelTokens[fileId] = cancelToken;

    await _cacheBox.put(fileId, {
      'status': 'downloading',
      'url': url,
      'fileName': fileName,
      'fileType': fileType,
      'startedAt': DateTime.now().toIso8601String(),
    });

    final controller = _progressControllers[fileId];
    IOSink? sink;
    File? file;

    try {
      final cacheDir = await _getCacheDirectory();
      final filePath = '$cacheDir/${_sanitizeFileName(fileName)}';
      file = File(filePath);

      final response = await ApiClient().downloadStream(
        url,
        cancelToken: cancelToken,
      );

      final totalBytes = response.data?.contentLength;
      var receivedBytes = 0;
      sink = file.openWrite();

      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes != null && totalBytes > 0) {
          controller?.add(receivedBytes / totalBytes);
        }
      }
      await sink.close();

      await _cacheBox.put(fileId, {
        'status': 'downloaded',
        'path': filePath,
        'size': await file.length(),
        'downloadedAt': DateTime.now().toIso8601String(),
        'url': url,
        'fileName': fileName,
        'fileType': fileType,
      });

      controller?.close();
      _progressControllers.remove(fileId);
      _cancelTokens.remove(fileId);
      onComplete?.call();
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.cancel) {
        // Annulation demandée par l'utilisateur (cancelDownload) : on
        // nettoie silencieusement, sans marquer 'failed'.
        await sink?.close();
        if (file != null && await file.exists()) await file.delete();
        return;
      }
      await _cacheBox.put(fileId, {
        'status': 'failed',
        'error': e.toString(),
        'url': url,
        'fileName': fileName,
        'fileType': fileType,
      });
      onError?.call(e.toString());
    } catch (e) {
      await _cacheBox.put(fileId, {
        'status': 'failed',
        'error': e.toString(),
        'url': url,
        'fileName': fileName,
        'fileType': fileType,
      });
      onError?.call(e.toString());
    }
  }
  
  String? getCachedPath(String fileId) {
    if (kIsWeb) return null;
    final info = _cacheBox.get(fileId);
    if (info != null && info['status'] == 'downloaded') {
      return info['path'];
    }
    return null;
  }
  
  Future<void> deleteDownloadedFile(String fileId) async {
    if (kIsWeb) return;
    final info = _cacheBox.get(fileId);
    if (info != null && info['path'] != null) {
      final file = File(info['path']);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _cacheBox.delete(fileId);
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
    
    _cacheBox.delete(fileId);
  }
  
  Future<void> clearAllCache() async {
    if (kIsWeb) return;
    for (final key in _cacheBox.keys) {
      final info = _cacheBox.get(key);
      if (info != null && info['path'] != null) {
        final file = File(info['path']);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    await _cacheBox.clear();
  }
  
  Future<int> getCacheSize() async {
    if (kIsWeb) return 0;
    int total = 0;
    for (final key in _cacheBox.keys) {
      final info = _cacheBox.get(key);
      if (info != null && info['status'] == 'downloaded' && info['size'] != null) {
        total += info['size'] as int;
      }
    }
    return total;
  }
  
  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');
  }
}