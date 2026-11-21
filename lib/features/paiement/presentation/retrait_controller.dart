import 'package:flutter/foundation.dart';

import 'package:yeki/models/paiement_models.dart';
import 'package:yeki/repositories/paiement_repository.dart';
import 'package:yeki/repositories/wallet_repository.dart';

/// État + logique de l'écran de demande de retrait (cadres,
/// `AppRoute.retrait`). `ChangeNotifier` plutôt que `setState` (interdit
/// sous `lib/features/`, règle 7).
///
/// Pas de minimum de retrait figé ici (règle 3) : `ParametreSysteme
/// ['retrait_minimum']` n'est vérifié que côté backend
/// (`DemanderRetraitView`) — son message d'erreur (`{"detail": "..."}`)
/// est déjà transporté tel quel par `ApiException` (voir
/// `ApiException.fromEnvelope`), aucune valeur à dupliquer côté client.
class RetraitController extends ChangeNotifier {
  RetraitController({WalletRepository? walletRepository, PaiementRepository? paiementRepository})
    : _walletRepo = walletRepository ?? WalletRepository(),
      _paiementRepo = paiementRepository ?? PaiementRepository();

  final WalletRepository _walletRepo;
  final PaiementRepository _paiementRepo;

  bool chargement = true;
  bool enErreur = false;
  int solde = 0;
  ParametresPublics? parametres;

  Future<void> charger() async {
    chargement = true;
    enErreur = false;
    notifyListeners();
    try {
      final resultats = await Future.wait([_walletRepo.solde(), _paiementRepo.parametresPublics()]);
      solde = resultats[0] as int;
      parametres = resultats[1] as ParametresPublics;
    } catch (_) {
      enErreur = true;
    } finally {
      chargement = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> demanderRetrait(Map<String, dynamic> payload) {
    return _paiementRepo.demanderRetrait(payload);
  }
}
