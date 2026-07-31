import 'package:flutter/foundation.dart';

import 'package:yeki/models/paiement_models.dart';
import 'package:yeki/models/repetiteur_models.dart';
import 'package:yeki/repositories/auth_repository.dart';
import 'package:yeki/repositories/paiement_repository.dart';
import 'package:yeki/repositories/repetiteur_repository.dart';

/// État + logique du dashboard Service Client (P9.5) — un seul contrôleur
/// pour les 4 onglets (paiements/retraits/répétiteurs/statistiques), même
/// écran. `ChangeNotifier` plutôt que `setState` (interdit sous
/// `lib/features/`, règle 7).
class ServiceClientController extends ChangeNotifier {
  ServiceClientController({
    PaiementRepository? paiementRepository,
    RepetiteurRepository? repetiteurRepository,
    AuthRepository? authRepository,
  }) : _paiementRepo = paiementRepository ?? PaiementRepository(),
       _repetiteurRepo = repetiteurRepository ?? RepetiteurRepository(),
       _authRepo = authRepository ?? AuthRepository();

  final PaiementRepository _paiementRepo;
  final RepetiteurRepository _repetiteurRepo;
  final AuthRepository _authRepo;

  // ── Profil connecté (nom affiché dans le chrome YkAdaptiveScaffold) ──
  String userName = 'Service Client';

  Future<void> chargerProfil() async {
    try {
      final profil = await _authRepo.getCurrentUser();
      final nom = '${profil.firstName} ${profil.lastName}'.trim();
      userName = nom.isNotEmpty ? nom : profil.username;
      notifyListeners();
    } catch (_) {
      // Non bloquant — le chrome affiche "Service Client" par défaut.
    }
  }

  // ── Paiements ────────────────────────────────────────────────────
  bool chargementPaiements = true;
  bool enErreurPaiements = false;
  List<DemandePaiementManuel> paiements = const [];

  // ── Retraits ─────────────────────────────────────────────────────
  bool chargementRetraits = true;
  bool enErreurRetraits = false;
  List<DemandeRetrait> retraits = const [];

  // ── Répétiteurs ──────────────────────────────────────────────────
  bool chargementRepetiteurs = true;
  bool enErreurRepetiteurs = false;
  List<RepetiteurCandidat> candidats = const [];

  // ── Statistiques ─────────────────────────────────────────────────
  bool chargementStats = true;
  bool enErreurStats = false;
  ServiceClientStatistiques? statistiques;

  Future<void> chargerTout() => Future.wait([
    chargerProfil(),
    chargerPaiements(),
    chargerRetraits(),
    chargerRepetiteurs(),
    chargerStatistiques(),
  ]);

  Future<void> chargerPaiements() async {
    chargementPaiements = true;
    enErreurPaiements = false;
    notifyListeners();
    try {
      paiements = await _paiementRepo.fileAttentePaiements();
    } catch (_) {
      enErreurPaiements = true;
    } finally {
      chargementPaiements = false;
      notifyListeners();
    }
  }

  Future<void> chargerRetraits() async {
    chargementRetraits = true;
    enErreurRetraits = false;
    notifyListeners();
    try {
      retraits = await _paiementRepo.fileAttenteRetraits();
    } catch (_) {
      enErreurRetraits = true;
    } finally {
      chargementRetraits = false;
      notifyListeners();
    }
  }

  Future<void> chargerRepetiteurs() async {
    chargementRepetiteurs = true;
    enErreurRepetiteurs = false;
    notifyListeners();
    try {
      candidats = await _repetiteurRepo.candidats();
    } catch (_) {
      enErreurRepetiteurs = true;
    } finally {
      chargementRepetiteurs = false;
      notifyListeners();
    }
  }

  Future<void> chargerStatistiques() async {
    chargementStats = true;
    enErreurStats = false;
    notifyListeners();
    try {
      statistiques = await _paiementRepo.statistiquesServiceClient();
    } catch (_) {
      enErreurStats = true;
    } finally {
      chargementStats = false;
      notifyListeners();
    }
  }

  /// Nombre total de demandes en attente (paiements + retraits) — pour le
  /// badge de la destination de navigation.
  int get demandesEnAttenteTotal =>
      paiements.where((d) => d.statut == 'en_attente').length +
      retraits.where((d) => d.statut == 'en_attente').length;

  Future<void> validerPaiement(int id, {int? montantConstate}) async {
    await _paiementRepo.validerPaiement(id, montantConstate: montantConstate);
    await Future.wait([chargerPaiements(), chargerStatistiques()]);
  }

  Future<void> refuserPaiement(int id, String motif) async {
    await _paiementRepo.refuserPaiement(id, motif);
    await Future.wait([chargerPaiements(), chargerStatistiques()]);
  }

  Future<void> validerRetrait(int id) async {
    await _paiementRepo.validerRetrait(id);
    await Future.wait([chargerRetraits(), chargerStatistiques()]);
  }

  Future<void> refuserRetrait(int id, String motif) async {
    await _paiementRepo.refuserRetrait(id, motif);
    await Future.wait([chargerRetraits(), chargerStatistiques()]);
  }

  Future<void> toggleRepetiteur(int profileId, bool valeur) async {
    await _repetiteurRepo.toggleIsRepetiteur(profileId, valeur);
    await chargerRepetiteurs();
  }

  Future<void> creerFiche({
    required int enseignantId,
    required int coursId,
    required String ville,
    required String telephone,
    int? tarifMensuel,
  }) async {
    await _repetiteurRepo.creerFiche(
      enseignantId: enseignantId,
      coursId: coursId,
      ville: ville,
      telephone: telephone,
      tarifMensuel: tarifMensuel,
    );
    await chargerRepetiteurs();
  }

  Future<void> editerFiche(
    int ficheId, {
    String? ville,
    String? telephone,
    bool? disponible,
    int? tarifMensuel,
  }) async {
    await _repetiteurRepo.editerFiche(
      ficheId,
      ville: ville,
      telephone: telephone,
      disponible: disponible,
      tarifMensuel: tarifMensuel,
    );
    await chargerRepetiteurs();
  }

  Future<void> retirerFiche(int ficheId) async {
    await _repetiteurRepo.retirerFiche(ficheId);
    await chargerRepetiteurs();
  }
}
