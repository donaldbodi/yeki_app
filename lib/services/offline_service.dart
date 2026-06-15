// lib/services/offline_service.dart
// Version avec méthodes statiques

import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:yeki/services/download_manager.dart';

// Modèles pour le stockage local
@HiveType(typeId: 0)
class CachedDevoir {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final Map<String, dynamic> data;
  
  @HiveField(2)
  final DateTime cachedAt;
  
  CachedDevoir({
    required this.id,
    required this.data,
    required this.cachedAt,
  });
}

@HiveType(typeId: 1)
class CachedQuestion {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final Map<String, dynamic> data;
  
  @HiveField(2)
  final DateTime cachedAt;
  
  CachedQuestion({
    required this.id,
    required this.data,
    required this.cachedAt,
  });
}

@HiveType(typeId: 2)
class PendingAction {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String endpoint;
  
  @HiveField(2)
  final Map<String, dynamic> data;
  
  @HiveField(3)
  final String method;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  int retryCount;
  
  PendingAction({
    required this.id,
    required this.endpoint,
    required this.data,
    required this.method,
    required this.createdAt,
    this.retryCount = 0,
  });
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();
  
  static const String _devoirsBox = 'devoirs_cache';
  static const String _questionsBox = 'questions_cache';
  static const String _pendingBox = 'pending_actions';
  static const String _settingsBox = 'offline_settings';
  
  static late Box<CachedDevoir> _devoirsCache;
  static late Box<CachedQuestion> _questionsCache;
  static late Box<PendingAction> _pendingActions;
  static late Box _settingsCache;
  
  static bool _initialized = false;
  
  // État de connexion (static)
  static bool _isOnline = true;
  static bool get isOnline => _isOnline;
  static set isOnline(bool value) => _isOnline = value;
  
  static final List<void Function(bool)> _connectionListeners = [];
  
  static Timer? _syncTimer;
  static bool _isSyncing = false;
  
  static Future<void> init() async {
    if (_initialized) return;
    
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    
    Hive.registerAdapter(CachedDevoirAdapter());
    Hive.registerAdapter(CachedQuestionAdapter());
    Hive.registerAdapter(PendingActionAdapter());
    
    _devoirsCache = await Hive.openBox<CachedDevoir>(_devoirsBox);
    _questionsCache = await Hive.openBox<CachedQuestion>(_questionsBox);
    _pendingActions = await Hive.openBox<PendingAction>(_pendingBox);
    _settingsCache = await Hive.openBox(_settingsBox);
    
    await _loadSettings();
    _startAutoSync();
    
    _initialized = true;
  }
  
  static Future<void> _loadSettings() async {
    _isOnline = _settingsCache.get('is_online', defaultValue: true);
  }
  
  static void addConnectionListener(void Function(bool isOnline) listener) {
    _connectionListeners.add(listener);
  }

  static String? getDownloadedFilePath(String fileId) {
    // Cette méthode était appelée mais inexistante
    final downloadManager = DownloadManager();
    return downloadManager.getDownloadedPath(fileId);
  }
  
  static void removeConnectionListener(void Function(bool isOnline) listener) {
    _connectionListeners.remove(listener);
  }
  
  static void _notifyConnectionListeners(bool online) {
    for (final listener in _connectionListeners) {
      listener(online);
    }
  }
  
  static void setOnline(bool online) {
    _isOnline = online;
    _settingsCache.put('is_online', online);
    _notifyConnectionListeners(online);
    if (online) {
      _syncPendingActions();
    }
  }
  
  static void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline) {
        _syncPendingActions();
      }
    });
  }
  
  // ============ GESTION DU CACHE ============
  
  static Future<void> cacheDevoirs(String key, List<dynamic> devoirs) async {
    final cached = CachedDevoir(
      id: key.hashCode,
      data: {'key': key, 'devoirs': devoirs},
      cachedAt: DateTime.now(),
    );
    await _devoirsCache.put(key, cached);
  }
  
  static List<dynamic>? getCachedDevoirs(String key) {
    final cached = _devoirsCache.get(key);
    if (cached != null) {
      return cached.data['devoirs'] as List<dynamic>?;
    }
    return null;
  }
  
  static Future<void> cacheQuestion(int questionId, Map<String, dynamic> question) async {
    final cached = CachedQuestion(
      id: questionId,
      data: question,
      cachedAt: DateTime.now(),
    );
    await _questionsCache.put(questionId.toString(), cached);
  }
  
  static Map<String, dynamic>? getCachedQuestion(int questionId) {
    final cached = _questionsCache.get(questionId.toString());
    return cached?.data;
  }
  
  static Future<void> cacheQuestionsList(String key, List<dynamic> questions) async {
    await _questionsCache.put(key, CachedQuestion(
      id: key.hashCode,
      data: {'questions': questions},
      cachedAt: DateTime.now(),
    ));
  }
  
  static List<dynamic>? getCachedQuestionsList(String key) {
    final cached = _questionsCache.get(key);
    if (cached != null && cached.data['questions'] != null) {
      return cached.data['questions'] as List<dynamic>?;
    }
    return null;
  }
  
  // ============ ACTIONS EN ATTENTE ============
  
  static Future<void> addPendingAction({
    required String endpoint,
    required Map<String, dynamic> data,
    required String method,
  }) async {
    final action = PendingAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      endpoint: endpoint,
      data: data,
      method: method,
      createdAt: DateTime.now(),
      retryCount: 0,
    );
    await _pendingActions.put(action.id, action);
    
    if (_isOnline) {
      _syncPendingActions();
    }
  }
  
  static Future<void> _syncPendingActions() async {
    if (_isSyncing || _pendingActions.isEmpty) return;
    
    _isSyncing = true;
    final token = await _getToken();
    
    if (token == null) {
      _isSyncing = false;
      return;
    }
    
    final List<String> succeeded = [];
    final List<String> failed = [];
    
    for (final key in _pendingActions.keys) {
      final action = _pendingActions.get(key);
      if (action == null) continue;
      
      try {
        final success = await _executeAction(action, token);
        if (success) {
          succeeded.add(key);
        } else {
          action.retryCount++;
          await _pendingActions.put(key, action);
          if (action.retryCount >= 5) {
            failed.add(key);
          }
        }
      } catch (e) {
        action.retryCount++;
        await _pendingActions.put(key, action);
        if (action.retryCount >= 5) {
          failed.add(key);
        }
      }
    }
    
    for (final key in succeeded) {
      await _pendingActions.delete(key);
    }
    
    for (final key in failed) {
      await _pendingActions.delete(key);
    }
    
    _isSyncing = false;
  }
  
  static Future<bool> _executeAction(PendingAction action, String token) async {
    final url = Uri.parse('https://yeki.pythonanywhere.com/api/${action.endpoint}');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
    
    try {
      http.Response? response;
      
      switch (action.method.toUpperCase()) {
        case 'POST':
          response = await http.post(url, headers: headers, body: jsonEncode(action.data));
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: jsonEncode(action.data));
          break;
        case 'PATCH':
          response = await http.patch(url, headers: headers, body: jsonEncode(action.data));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
      }
      
      return response != null && response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  // ============ GESTION DES BROUILLONS ============
  
  static Future<void> saveDevoirDraft(int devoirId, Map<int, String> reponses) async {
    await _settingsCache.put('draft_$devoirId', {
      'reponses': reponses.map((k, v) => MapEntry(k.toString(), v)),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
  
  static Map<int, String>? getDevoirDraft(int devoirId) {
    final draft = _settingsCache.get('draft_$devoirId');
    if (draft != null) {
      final reponses = Map<int, String>.from(
        (draft['reponses'] as Map).map((k, v) => MapEntry(int.parse(k), v as String))
      );
      return reponses;
    }
    return null;
  }
  
  static Future<void> clearDevoirDraft(int devoirId) async {
    await _settingsCache.delete('draft_$devoirId');
  }
  
  // ============ NETTOYAGE ============
  
  static Future<void> clearOldCache({int olderThanDays = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
    
    for (final key in _devoirsCache.keys) {
      final cached = _devoirsCache.get(key);
      if (cached != null && cached.cachedAt.isBefore(cutoff)) {
        await _devoirsCache.delete(key);
      }
    }
    
    for (final key in _questionsCache.keys) {
      final cached = _questionsCache.get(key);
      if (cached != null && cached.cachedAt.isBefore(cutoff)) {
        await _questionsCache.delete(key);
      }
    }
  }
  
  static Future<void> clearAllCache() async {
    await _devoirsCache.clear();
    await _questionsCache.clear();
    await _settingsCache.clear();
  }
  
  static Future<int> getCacheSize() async {
    int total = 0;
    total += _devoirsCache.length * 1024;
    total += _questionsCache.length * 512;
    return total;
  }
  
  static void dispose() {
    _syncTimer?.cancel();
    Hive.close();
  }
}

// ============ ADAPTATEURS HIVE ============

class CachedDevoirAdapter extends TypeAdapter<CachedDevoir> {
  @override
  final int typeId = 0;
  
  @override
  CachedDevoir read(BinaryReader reader) {
    return CachedDevoir(
      id: reader.readInt(),
      data: reader.readMap().cast<String, dynamic>(),
      cachedAt: DateTime.parse(reader.readString()),
    );
  }
  
  @override
  void write(BinaryWriter writer, CachedDevoir obj) {
    writer.writeInt(obj.id);
    writer.writeMap(obj.data);
    writer.writeString(obj.cachedAt.toIso8601String());
  }
}

class CachedQuestionAdapter extends TypeAdapter<CachedQuestion> {
  @override
  final int typeId = 1;
  
  @override
  CachedQuestion read(BinaryReader reader) {
    return CachedQuestion(
      id: reader.readInt(),
      data: reader.readMap().cast<String, dynamic>(),
      cachedAt: DateTime.parse(reader.readString()),
    );
  }
  
  @override
  void write(BinaryWriter writer, CachedQuestion obj) {
    writer.writeInt(obj.id);
    writer.writeMap(obj.data);
    writer.writeString(obj.cachedAt.toIso8601String());
  }
}

class PendingActionAdapter extends TypeAdapter<PendingAction> {
  @override
  final int typeId = 2;
  
  @override
  PendingAction read(BinaryReader reader) {
    return PendingAction(
      id: reader.readString(),
      endpoint: reader.readString(),
      data: reader.readMap().cast<String, dynamic>(),
      method: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
      retryCount: reader.readInt(),
    );
  }
  
  @override
  void write(BinaryWriter writer, PendingAction obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.endpoint);
    writer.writeMap(obj.data);
    writer.writeString(obj.method);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeInt(obj.retryCount);
  }
}