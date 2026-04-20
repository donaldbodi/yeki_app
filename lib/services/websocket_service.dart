// lib/services/websocket_service.dart
// Version simplifiée

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }
  
  WebSocketService._();
  
  WebSocketChannel? _channel;
  final Map<String, List<void Function(Map<String, dynamic>)>> _listeners = {};
  bool _connected = false;
  Timer? _reconnectTimer;
  
  static const String _wsUrl = 'wss://yeki.pythonanywhere.com/ws/forum/';
  
  void connect({String room = 'global'}) async {
    if (_connected) return;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) return;
    
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse('$_wsUrl$room/?token=$token'));
      
      _channel!.stream.listen(
        (data) {
          final message = jsonDecode(data as String);
          _handleMessage(message);
        },
        onError: (error) {
          _connected = false;
          _attemptReconnect(room);
        },
        onDone: () {
          _connected = false;
          _attemptReconnect(room);
        },
      );
      
      _connected = true;
    } catch (e) {
      _attemptReconnect(room);
    }
  }
  
  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String? ?? 'message';
    _notifyListeners(type, message);
    _notifyListeners('all', message);
  }
  
  void _attemptReconnect(String room) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect(room: room);
    });
  }
  
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connected = false;
  }
  
  void subscribe(String eventType, void Function(Map<String, dynamic>) callback) {
    _listeners.putIfAbsent(eventType, () => []).add(callback);
  }
  
  void unsubscribe(String eventType, void Function(Map<String, dynamic>) callback) {
    _listeners[eventType]?.remove(callback);
  }
  
  void _notifyListeners(String eventType, Map<String, dynamic> data) {
    for (final callback in _listeners[eventType] ?? []) {
      callback(data);
    }
  }
  
  void sendMessage(Map<String, dynamic> message) {
    if (_connected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }
  
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
  }) {
    sendMessage({
      'type': 'new_question',
      'contenu': contenu,
      'source': source,
      if (coursId != null) 'cours_id': coursId,
      if (leconId != null) 'lecon_id': leconId,
      if (leconTitre != null) 'lecon_titre': leconTitre,
      if (exerciceId != null) 'exercice_id': exerciceId,
      if (exerciceTitre != null) 'exercice_titre': exerciceTitre,
      if (devoirId != null) 'devoir_id': devoirId,
      if (devoirTitre != null) 'devoir_titre': devoirTitre,
    });
  }
  
  void sendNewReponse(int questionId, String contenu) {
    sendMessage({
      'type': 'new_reponse',
      'question_id': questionId,
      'contenu': contenu,
    });
  }
  
  bool get isConnected => _connected;
}