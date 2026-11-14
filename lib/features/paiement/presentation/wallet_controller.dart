import 'package:flutter/foundation.dart';

import 'package:yeki/repositories/paiement_repository.dart';
import 'package:yeki/repositories/wallet_repository.dart';

/// État + logique de l'écran « Mon Portefeuille » (P9.3, remplace
/// `lib/widgets/wallet_page.dart`). `ChangeNotifier` plutôt que
/// `setState` (interdit sous `lib/features/`, règle 7).
class WalletController extends ChangeNotifier {
  WalletController({WalletRepository? walletRepository, PaiementRepository? paiementRepository})
    : _walletRepo = walletRepository ?? WalletRepository(),
      _paiementRepo = paiementRepository ?? PaiementRepository();

  final WalletRepository _walletRepo;
  final PaiementRepository _paiementRepo;

  bool chargement = true;
  bool enErreur = false;
  int solde = 0;
  int totalRecharge = 0;
  int totalDepense = 0;
  List<Map<String, dynamic>> transactions = const [];
  List<Map<String, dynamic>> demandesEnAttente = const [];

  Future<void> charger() async {
    chargement = true;
    enErreur = false;
    notifyListeners();
    try {
      final apercu = await _walletRepo.apercu();
      solde = (apercu['solde'] as num?)?.toInt() ?? 0;
      totalRecharge = (apercu['total_recharge'] as num?)?.toInt() ?? 0;
      totalDepense = (apercu['total_depense'] as num?)?.toInt() ?? 0;
      transactions = List<Map<String, dynamic>>.from(
        (apercu['transactions'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final demandes = await _paiementRepo.mesDemandes(statut: 'en_attente');
      demandesEnAttente = demandes
          .where((d) => d.categorie == 'recharge')
          .map(
            (d) => {
              'id': d.id,
              'montant': d.montant,
              'operateur': d.operateur,
              'date_creation': d.dateCreation,
            },
          )
          .toList();
    } catch (e) {
      debugPrint('WalletController.charger() — exception non-ApiException : ${e.runtimeType} : $e');
      enErreur = true;
    } finally {
      chargement = false;
      notifyListeners();
    }
  }
}
