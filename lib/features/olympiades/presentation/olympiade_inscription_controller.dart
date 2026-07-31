import 'package:flutter/foundation.dart';

import 'package:yeki/repositories/olympiade_repository.dart';

/// État + logique de l'écran « inscription à une olympiade » (P8.3).
/// `ChangeNotifier` plutôt que `setState` (interdit sous `lib/features/`,
/// règle 7). Le paiement de participation lui-même est délégué à
/// `YkWalletDebitConfirmSheet` (composant partagé) — ce contrôleur n'expose
/// que les deux appels réseau bruts qu'il orchestre.
class OlympiadeInscriptionController extends ChangeNotifier {
  OlympiadeInscriptionController({required this.olympiadeId, OlympiadeRepository? repository})
    : _repo = repository ?? OlympiadeRepository();

  final int olympiadeId;
  final OlympiadeRepository _repo;

  bool accepteReglement = false;
  bool inscriptionEnCours = false;

  void toggleAccepte() {
    accepteReglement = !accepteReglement;
    notifyListeners();
  }

  /// Lève `ApiException` (code `PAYMENT_REQUIRED`, 402) si l'olympiade
  /// est payante et pas encore réglée — à l'appelant de proposer
  /// `YkWalletDebitConfirmSheet.show(onPayer: payerParticipation)` puis de
  /// rappeler cette méthode.
  Future<void> inscrire() async {
    inscriptionEnCours = true;
    notifyListeners();
    try {
      await _repo.inscrire(olympiadeId);
    } finally {
      inscriptionEnCours = false;
      notifyListeners();
    }
  }

  Future<void> payerParticipation(int montant) => _repo.payerParticipation(olympiadeId, montant);
}
