// lib/services/cache_api_service.dart
//
// Cache hors ligne des réponses du serveur (mobile), « comme WhatsApp » :
// chaque réponse GET reçue est gardée sur le téléphone ; sans réseau,
// `HorsLigneInterceptor` la ressert telle quelle. Tous les écrans (cours,
// leçons, profil, tableaux de bord…) restent donc consultables hors ligne
// avec les dernières données reçues, sans code spécifique par écran.
//
// Box Hive chiffrée (même clé que les autres données hors ligne, P12.3),
// vidée à la déconnexion (données propres au compte connecté), et limitée
// en taille (les plus anciennes entrées partent d'abord).

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:hive/hive.dart';

import 'package:yeki/services/offline_encryption_service.dart';

class CacheApiService {
  CacheApiService._();

  static const _nomBox = 'yeki_cache_api';
  static const _maxEntrees = 800;
  static Box<String>? _box;

  /// À appeler au démarrage, après `OfflineService.init()` (qui initialise Hive).
  static Future<void> init() async {
    if (kIsWeb || _box != null) return;
    try {
      final cipher = await OfflineEncryptionService.hiveCipher();
      _box = await Hive.openBox<String>(_nomBox, encryptionCipher: cipher);
    } catch (e) {
      // Box illisible (clé changée, fichier abîmé) : on repart d'un cache vide.
      debugPrint('CacheApiService.init : $e');
      await Hive.deleteBoxFromDisk(_nomBox);
      final cipher = await OfflineEncryptionService.hiveCipher();
      _box = await Hive.openBox<String>(_nomBox, encryptionCipher: cipher);
    }
  }

  static String cle(String chemin, Map<String, dynamic> query) {
    if (query.isEmpty) return chemin;
    final cles = query.keys.toList()..sort();
    return '$chemin?${cles.map((k) => '$k=${query[k]}').join('&')}';
  }

  static Future<void> enregistrer(String cle, dynamic donnees) async {
    final box = _box;
    if (box == null || !(donnees is Map || donnees is List)) return;
    try {
      await box.put(cle, jsonEncode({'t': DateTime.now().toIso8601String(), 'd': donnees}));
      if (box.length > _maxEntrees) await _elaguer(box);
    } catch (e) {
      debugPrint('CacheApiService.enregistrer : $e');
    }
  }

  /// Dernière réponse connue pour [cle], ou `null`.
  static dynamic lire(String cle) {
    final brut = _box?.get(cle);
    if (brut == null) return null;
    try {
      return (jsonDecode(brut) as Map)['d'];
    } catch (_) {
      return null;
    }
  }

  static Future<void> vider() async {
    await _box?.clear();
  }

  static Future<void> _elaguer(Box<String> box) async {
    final dates = <String, String>{};
    for (final k in box.keys) {
      final brut = box.get(k);
      if (brut == null) continue;
      try {
        dates[k.toString()] = (jsonDecode(brut) as Map)['t'] as String? ?? '';
      } catch (_) {
        dates[k.toString()] = '';
      }
    }
    final triees = dates.keys.toList()..sort((a, b) => dates[a]!.compareTo(dates[b]!));
    await box.deleteAll(triees.take(box.length - _maxEntrees + 100));
  }
}
