// lib/services/sync_service.dart

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'offline_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Timer? _syncTimer;
  final List<Map<String, dynamic>> _pendingActions = [];

  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => syncAll());
  }
  
  void stopAutoSync() {
    _syncTimer?.cancel();
  }
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  void addPendingAction(String endpoint, Map<String, dynamic> data, String method) {
    _pendingActions.add({
      'endpoint': endpoint,
      'data': data,
      'method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> syncAll() async {
    if (!OfflineService.isOnline) return;
    if (_pendingActions.isEmpty) return;
    
    final token = await _getToken();
    if (token == null) return;
    
    final List<Map<String, dynamic>> succeeded = [];

    for (final action in _pendingActions) {
      try {
        await ApiClient().request(
          action['method'] as String,
          action['endpoint'] as String,
          data: action['data'],
        );
        succeeded.add(action);
      } on ApiException {
        // Ignoré : reste en attente pour la prochaine tentative de sync.
      }
    }

    for (final action in succeeded) {
      _pendingActions.remove(action);
    }
  }

  Future<void> syncDevoirs() async {
    if (!OfflineService.isOnline) return;

    final token = await _getToken();
    if (token == null) return;

    try {
      final data = await ApiClient().get('/devoirs/');
      if (data is List) {
        await OfflineService.cacheDevoirs('all_devoirs', data);
      }
    } on ApiException {
      // Ignoré.
    }
  }

  Future<Map<String, dynamic>?> submitDevoir(
    int devoirId,
    Map<String, String> reponses,
  ) async {
    final token = await _getToken();

    if (OfflineService.isOnline && token != null) {
      try {
        final data = await ApiClient().post(
          '/devoirs/$devoirId/soumettre/',
          data: {'reponses': reponses},
        );
        await OfflineService.clearDevoirDraft(devoirId);
        return Map<String, dynamic>.from(data as Map);
      } on ApiException {
        OfflineService.isOnline = false;
      }
    }
    
    await OfflineService.saveDevoirDraft(devoirId, reponses.map((k, v) => MapEntry(int.parse(k), v)));
    addPendingAction('devoirs/$devoirId/soumettre/', {'reponses': reponses}, 'POST');
    
    return {
      'statut': 'offline',
      'message': 'Devoir sauvegardé en brouillon. Sera synchronisé automatiquement.',
      'offline': true,
    };
  }
}