// lib/services/acces_hors_ligne_service.dart
//
// Médias téléchargés (vidéos, PDF) et abonnement (décision produit) :
// - le téléphone garde la date de fin d'abonnement de chaque cours dont un
//   média est téléchargé, mise à jour à chaque connexion à Internet ;
// - une fois l'abonnement terminé, les médias du cours ne sont plus
//   lisibles (`peutLire`) : il faut repayer un abonnement ;
// - si, en plus, l'apprenant ne s'est pas connecté depuis 30 jours après
//   cette fin, les médias sont effacés du téléphone (`nettoyer`).
// Sans abonnement connu (contenu gratuit, jamais abonné), rien n'est
// bloqué ni effacé. Rien de tout cela ne concerne le web (aucun
// téléchargement possible ; voir `cours_detail_page.dart`).

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeki/repositories/paiement_repository.dart';
import 'package:yeki/services/download_manager.dart';

class AccesHorsLigneService {
  AccesHorsLigneService._();

  static const Duration delaiSansConnexion = Duration(days: 30);
  static const _cleDerniereConnexion = 'yeki_derniere_connexion';
  static String _cleFin(int coursId) => 'yeki_fin_abonnement_cours_$coursId';

  /// Au démarrage de l'app : recharge les téléchargements, met à jour les
  /// fins d'abonnement si Internet répond, puis efface ce qui doit l'être.
  /// Ne bloque jamais le démarrage (appelé sans attendre).
  static Future<void> demarrer() async {
    if (kIsWeb) return;
    try {
      await DownloadManager().initialiser();
      await synchroniser();
      await nettoyer();
    } catch (e) {
      debugPrint('AccesHorsLigneService : $e');
    }
  }

  /// Interroge le serveur pour chaque cours dont un média est téléchargé.
  /// Une réponse reçue compte comme une connexion.
  static Future<void> synchroniser() async {
    final coursIds = DownloadManager().fichiersParCours.values.toSet();
    for (final coursId in coursIds) {
      try {
        // Enregistre lui-même la fin d'abonnement (voir statutAbonnement).
        await PaiementRepository().statutAbonnement(coursId);
      } catch (_) {
        return; // Hors ligne : on garde les dates déjà connues.
      }
    }
  }

  /// Enregistre la fin d'abonnement connue pour [coursId] et note la
  /// connexion (appelé aussi à chaque consultation du statut d'abonnement).
  static Future<void> enregistrerStatut(int coursId, {String? finIso}) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleDerniereConnexion, DateTime.now().toIso8601String());
    if (finIso != null && DateTime.tryParse(finIso) != null) {
      await prefs.setString(_cleFin(coursId), finIso);
    }
  }

  static DateTime? _fin(SharedPreferences prefs, int coursId) =>
      DateTime.tryParse(prefs.getString(_cleFin(coursId)) ?? '');

  /// Faux si l'abonnement connu pour [coursId] est terminé.
  static Future<bool> peutLire(int? coursId) async {
    if (kIsWeb || coursId == null) return true;
    final prefs = await SharedPreferences.getInstance();
    final fin = _fin(prefs, coursId);
    return fin == null || DateTime.now().isBefore(fin);
  }

  /// Efface les médias d'un cours dont l'abonnement est terminé depuis
  /// plus de 30 jours sans connexion.
  static Future<void> nettoyer() async {
    final prefs = await SharedPreferences.getInstance();
    final maintenant = DateTime.now();
    final derniereConnexion = DateTime.tryParse(prefs.getString(_cleDerniereConnexion) ?? '');
    final fichiers = Map<String, int>.from(DownloadManager().fichiersParCours);
    for (final entree in fichiers.entries) {
      final fin = _fin(prefs, entree.value);
      if (fin == null || maintenant.isBefore(fin)) continue;
      // Point de départ du délai : la plus récente entre la fin de
      // l'abonnement et la dernière connexion.
      final depart = derniereConnexion == null
          ? fin
          : DateTime.fromMillisecondsSinceEpoch(
              math.max(fin.millisecondsSinceEpoch, derniereConnexion.millisecondsSinceEpoch),
            );
      if (maintenant.difference(depart) >= delaiSansConnexion) {
        await DownloadManager().deleteDownloadedFile(entree.key);
      }
    }
  }
}
