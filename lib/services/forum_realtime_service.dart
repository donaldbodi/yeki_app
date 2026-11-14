// lib/services/forum_realtime_service.dart
//
// WebSocket du forum : le serveur signale un changement (identifiants seuls),
// l'écran recharge ensuite par l'API REST, qui reste seule à appliquer la
// matrice d'accès. Voir docs/FORUM_TEMPS_REEL.md (dépôt backend).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:yeki/core/constants/api_constants.dart';

class ForumEvenement {
  final String type;
  final int? questionId;

  const ForumEvenement({required this.type, this.questionId});
}

class ForumRealtimeConnexion {
  final String room;
  final void Function(ForumEvenement) onEvenement;

  /// Passage connecté/déconnecté : l'écran y cale la fréquence de son sondage.
  final void Function(bool connecte)? onEtat;

  /// Refus définitif du serveur (jeton invalide, pas d'accès au forum).
  final VoidCallback? onRefus;

  ForumRealtimeConnexion({
    required this.room,
    required this.onEvenement,
    this.onEtat,
    this.onRefus,
  });

  // Exigence de docs/FORUM_TEMPS_REEL.md : reconnexion bornée, jamais de boucle.
  static const int _maxTentatives = 3;
  static const Duration _dureeStable = Duration(seconds: 30);
  static const Set<int> _fermeturesDefinitives = {4401, 4403};

  WebSocketChannel? _canal;
  StreamSubscription<dynamic>? _abonnement;
  Timer? _relance;
  DateTime? _ouvertLe;
  int _tentatives = 0;
  bool _actif = false;

  /// Invalide une connexion en cours d'établissement après `arreter()` : un
  /// aller-retour rapide de l'app ouvrirait sinon deux sockets.
  int _generation = 0;

  void demarrer() {
    if (_actif) return;
    _actif = true;
    _tentatives = 0;
    _connecter();
  }

  void arreter() {
    _actif = false;
    _generation++;
    _relance?.cancel();
    _fermerCanal();
  }

  void _fermerCanal() {
    _abonnement?.cancel();
    _abonnement = null;
    _canal?.sink.close();
    _canal = null;
  }

  Future<void> _connecter() async {
    final generation = _generation;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (generation != _generation || token == null || token.isEmpty) return;

    final canal = WebSocketChannel.connect(
      Uri.parse(ApiConstants.forumWebSocket(room)),
      protocols: ['yeki', 'token.$token'],
    );
    try {
      await canal.ready;
    } catch (e) {
      debugPrint('Forum temps réel — connexion impossible : $e');
      if (generation == _generation) _relancer();
      return;
    }
    if (generation != _generation) {
      canal.sink.close();
      return;
    }

    _canal = canal;
    _ouvertLe = DateTime.now();
    onEtat?.call(true);
    _abonnement = canal.stream.listen(
      _recevoir,
      onError: (Object e) => debugPrint('Forum temps réel — erreur : $e'),
      onDone: () => _surFermeture(canal.closeCode),
    );
  }

  void _recevoir(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      onEvenement(ForumEvenement(
        type: data['evenement'] as String,
        questionId: data['question_id'] as int?,
      ));
    } catch (e) {
      debugPrint('Forum temps réel — message ignoré : $e');
    }
  }

  void _surFermeture(int? code) {
    _fermerCanal();
    onEtat?.call(false);
    if (_fermeturesDefinitives.contains(code)) {
      _actif = false;
      onRefus?.call();
      return;
    }
    // Seule une connexion qui a tenu remet le compteur à zéro : un serveur qui
    // accepte puis coupe aussitôt ne doit pas produire de boucle sans fin.
    final ouvertLe = _ouvertLe;
    if (ouvertLe != null && DateTime.now().difference(ouvertLe) >= _dureeStable) {
      _tentatives = 0;
    }
    _relancer();
  }

  void _relancer() {
    if (!_actif) return;
    if (_tentatives >= _maxTentatives) {
      _actif = false;
      debugPrint('Forum temps réel — abandon après $_maxTentatives tentatives, repli sur le sondage.');
      return;
    }
    final delai = Duration(seconds: 2 << _tentatives);
    _tentatives++;
    _relance = Timer(delai, _connecter);
  }
}
