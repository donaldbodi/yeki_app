// lib/services/websocket_service.dart
// Service WebSocket pour le forum avec reconnexion automatique

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _currentRoom;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 5;
  static const Duration RECONNECT_DELAY = Duration(seconds: 3);
  
  final Map<String, List<void Function(Map<String, dynamic>)>> _listeners = {};
  
  bool get isConnected => _channel != null;
  String? get currentRoom => _currentRoom;
  
  /// Initialise la connexion WebSocket pour une salle spécifique
  Future<void> connect({String? room}) async {
    if (_isConnecting) return;
    
    final String roomName = room ?? 'global';
    
    // Si déjà connecté à la même room, ne rien faire
    if (_currentRoom == roomName && _channel != null) {
      return;
    }
    
    // Fermer l'ancienne connexion
    await disconnect();
    
    _isConnecting = true;
    _reconnectAttempts = 0;
    _currentRoom = roomName;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        debugPrint('WebSocket: Token non disponible');
        _isConnecting = false;
        return;
      }
      
      final wsUrl = _buildWebSocketUrl(roomName, token);
      debugPrint('WebSocket: Connexion à $wsUrl');
      
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        pingInterval: const Duration(seconds: 30),
      );
      
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      _isConnecting = false;
      _reconnectAttempts = 0;
      
    } catch (e) {
      debugPrint('WebSocket: Erreur de connexion - $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }
  
  String _buildWebSocketUrl(String room, String token) {
    final scheme = kReleaseMode ? 'wss' : 'ws';
    final host = 'yeki.pythonanywhere.com';
    return '$scheme://$host/ws/forum/$room/?token=$token';
  }
  
  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> message = jsonDecode(data);
      final type = message['type'];
      
      debugPrint('WebSocket: Message reçu - type=$type');
      
      if (_listeners.containsKey(type)) {
        for (final listener in _listeners[type]!) {
          listener(message);
        }
      }
      
      if (_listeners.containsKey('*')) {
        for (final listener in _listeners['*']!) {
          listener(message);
        }
      }
    } catch (e) {
      debugPrint('WebSocket: Erreur parsing message - $e');
    }
  }
  
  void _onError(Object error) {
    debugPrint('WebSocket: Erreur - $error');
    _channel = null;
    _scheduleReconnect();
  }
  
  void _onDone() {
    debugPrint('WebSocket: Connexion fermée');
    _channel = null;
    _scheduleReconnect();
  }
  
  void _scheduleReconnect() {
    if (_reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
      debugPrint('WebSocket: Maximum de tentatives de reconnexion atteint');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(RECONNECT_DELAY, () {
      _reconnectAttempts++;
      debugPrint('WebSocket: Tentative de reconnexion $_reconnectAttempts/$MAX_RECONNECT_ATTEMPTS');
      connect(room: _currentRoom);
    });
  }
  
  /// Fermer la connexion
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    
    _currentRoom = null;
    _isConnecting = false;
  }
  
  /// S'abonner à un type d'événement
  void subscribe(String eventType, void Function(Map<String, dynamic>) callback) {
    _listeners.putIfAbsent(eventType, () => []).add(callback);
  }
  
  /// Se désabonner
  void unsubscribe(String eventType, void Function(Map<String, dynamic>) callback) {
    if (_listeners.containsKey(eventType)) {
      _listeners[eventType]!.remove(callback);
    }
  }
  
  /// Envoyer un message
  void send(Map<String, dynamic> message) {
    if (_channel == null) {
      debugPrint('WebSocket: Impossible d\'envoyer, non connecté');
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('WebSocket: Erreur envoi - $e');
    }
  }
  
  /// Envoyer une nouvelle question
  void sendNewQuestion({
    required String contenu,
    required String source,
    int? coursId,
    int? leconId,
    String? leconTitre,
    int? exerciceId,
    String? exerciceTitre,
    int? devoirId,
    String? devoirTitre,
    String? imageData,
    String? audioData,
  }) {
    final Map<String, dynamic> message = {
      'type': 'new_question',
      'contenu': contenu,
      'source': source,
    };
    
    if (coursId != null) message['cours_id'] = coursId;
    if (leconId != null) message['lecon_id'] = leconId;
    if (leconTitre != null) message['lecon_titre'] = leconTitre;
    if (exerciceId != null) message['exercice_id'] = exerciceId;
    if (exerciceTitre != null) message['exercice_titre'] = exerciceTitre;
    if (devoirId != null) message['devoir_id'] = devoirId;
    if (devoirTitre != null) message['devoir_titre'] = devoirTitre;
    if (imageData != null) message['image_data'] = imageData;
    if (audioData != null) message['audio_data'] = audioData;
    
    send(message);
  }
  
  /// Envoyer une nouvelle réponse
  void sendNewReponse(int questionId, String contenu) {
    send({
      'type': 'new_reponse',
      'question_id': questionId,
      'contenu': contenu,
    });
  }
  
  /// Envoyer un like
  void sendLike(int reponseId) {
    send({
      'type': 'like',
      'reponse_id': reponseId,
    });
  }
  
  /// Rejoindre un cours spécifique
  void joinCours(int coursId) {
    send({
      'type': 'join_cours',
      'cours_id': coursId,
    });
  }
  
  /// Envoyer un ping (garder la connexion active)
  void sendPing() {
    send({'type': 'ping'});
  }
}