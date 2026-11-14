import 'package:flutter/foundation.dart';

import 'package:yeki/models/paiement_models.dart';
import 'package:yeki/repositories/paiement_repository.dart';

/// État + logique de l'écran de paiement unifié (P9.3, remplace
/// `lib/views/pages/apprenants/paiement_page.dart`). `ChangeNotifier`
/// plutôt que `setState` (interdit sous `lib/features/`, règle 7) — y
/// compris pour la périodicité choisie et l'inclusion du présentiel.
class PaiementController extends ChangeNotifier {
  PaiementController({PaiementRepository? repository}) : _repo = repository ?? PaiementRepository();

  final PaiementRepository _repo;

  bool chargementParametres = true;
  bool enErreur = false;
  ParametresPublics? parametres;

  /// `mensuel` | `annuel` — pertinent seulement pour `accesDepartement`
  /// quand un prix annuel réel est fourni (jamais de ratio de remise
  /// figé, règle 3 — voir `paiement_page.dart`).
  String periodicite = 'mensuel';
  bool inclurePresentiel = false;

  /// Dernière demande de paiement manuel « formation » validée —
  /// vérifiée à la demande de l'utilisateur (pas de webhook consommé
  /// ici) pour proposer le téléchargement de la facture présentiel.
  DemandePaiementManuel? demandeFormationValidee;
  bool verificationEnCours = false;

  Future<void> charger() async {
    chargementParametres = true;
    enErreur = false;
    notifyListeners();
    try {
      parametres = await _repo.parametresPublics();
    } catch (_) {
      enErreur = true;
    } finally {
      chargementParametres = false;
      notifyListeners();
    }
  }

  void choisirPeriodicite(String p) {
    periodicite = p;
    notifyListeners();
  }

  void togglePresentiel() {
    inclurePresentiel = !inclurePresentiel;
    notifyListeners();
  }

  Future<Map<String, dynamic>> soumettreManuel(Map<String, dynamic> payload) => _repo.soumettreManuel(payload);

  /// `YkManualPaymentFlow.onVerifierStatut`.
  Future<String> verifierStatut(int demandeId) async {
    final demandes = await _repo.mesDemandes();
    for (final d in demandes) {
      if (d.id == demandeId) return d.statut;
    }
    return 'en_attente';
  }

  Future<void> rafraichirDemandeFormation() async {
    verificationEnCours = true;
    notifyListeners();
    try {
      final demandes = await _repo.mesDemandes(statut: 'validee');
      final formations = demandes.where((d) => d.categorie == 'formation');
      demandeFormationValidee = formations.isEmpty ? null : formations.first;
    } catch (_) {
      // Non bloquant — l'utilisateur peut retaper sur « Vérifier le statut ».
    } finally {
      verificationEnCours = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> initierCinetpay(Map<String, dynamic> payload) => _repo.initierCinetpay(payload);

  Future<Map<String, dynamic>> verifierCinetpay(String reference) => _repo.verifier(reference);
}
