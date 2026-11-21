import 'package:flutter/foundation.dart';

import 'package:yeki/models/paiement_models.dart';
import 'package:yeki/repositories/paiement_repository.dart';

/// Montants secs proposés — décision actée avec l'utilisateur (P9.3) :
/// aucun barème de bonus, contrairement à l'ancien
/// `lib/services/recharge_wallet_page.dart` (supprimé).
const List<int> montantsRechargeSuggeres = [1000, 2000, 5000, 10000, 20000, 50000];

/// État + logique de l'écran de recharge (`AppRoute.recharge`).
/// `ChangeNotifier` plutôt que `setState` (interdit sous `lib/features/`,
/// règle 7) — y compris pour le montant sélectionné, ci-dessous.
class RechargeController extends ChangeNotifier {
  RechargeController({PaiementRepository? repository}) : _repo = repository ?? PaiementRepository();

  final PaiementRepository _repo;

  bool chargementParametres = true;
  bool enErreur = false;
  ParametresPublics? parametres;
  int? montantChoisi;

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

  void choisirMontant(int? montant) {
    montantChoisi = montant;
    notifyListeners();
  }

  Future<Map<String, dynamic>> soumettre(Map<String, dynamic> payload) {
    return _repo.soumettreManuel({...payload, 'categorie': 'recharge'});
  }

  /// `YkManualPaymentFlow.onVerifierStatut` — recherche la demande dans
  /// `mesDemandes()` (pas d'endpoint de détail unitaire côté backend).
  /// `en_attente` par défaut si introuvable (ex. latence de réplication).
  Future<String> verifierStatut(int demandeId) async {
    final demandes = await _repo.mesDemandes();
    for (final d in demandes) {
      if (d.id == demandeId) return d.statut;
    }
    return 'en_attente';
  }
}
