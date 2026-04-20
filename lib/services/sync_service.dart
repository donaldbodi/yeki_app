// lib/services/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  
  Timer? _syncTimer;
  final List<Map<String, dynamic>> _pendingActions = [];
  
  static const String _baseUrl = 'https://yeki.pythonanywhere.com/api';
  
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
        http.Response? response;
        final url = Uri.parse('$_baseUrl/${action['endpoint']}');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        };
        
        switch (action['method']) {
          case 'POST':
            response = await http.post(url, headers: headers, body: jsonEncode(action['data']));
            break;
          case 'PUT':
            response = await http.put(url, headers: headers, body: jsonEncode(action['data']));
            break;
          case 'PATCH':
            response = await http.patch(url, headers: headers, body: jsonEncode(action['data']));
            break;
          case 'DELETE':
            response = await http.delete(url, headers: headers);
            break;
        }
        
        if (response != null && (response.statusCode >= 200 && response.statusCode < 300)) {
          succeeded.add(action);
        }
      } catch (e) {
        // Ignorer
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
      final response = await http.get(
        Uri.parse('$_baseUrl/devoirs/'),
        headers: {'Authorization': 'Token $token'},
      );
      
      if (response.statusCode == 200) {
        final devoirs = jsonDecode(response.body);
        await OfflineService.cacheDevoirs('all_devoirs', devoirs);
      }
    } catch (e) {
      // Ignorer
    }
  }
  
  Future<Map<String, dynamic>?> submitDevoir(
    int devoirId,
    Map<String, String> reponses,
  ) async {
    final token = await _getToken();
    
    if (OfflineService.isOnline && token != null) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/devoirs/$devoirId/soumettre/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
          body: jsonEncode({'reponses': reponses}),
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          await OfflineService.clearDevoirDraft(devoirId);
          return jsonDecode(response.body);
        }
      } catch (e) {
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