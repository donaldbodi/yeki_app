import 'package:flutter/foundation.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/formation_repository.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart' show DepartementItem;

enum ConcoursDetailEtat { chargement, pret, erreur }

/// État + logique de l'écran « détail concours » (P8.3). `ChangeNotifier`
/// plutôt que `setState` (interdit sous `lib/features/`, règle 7).
class ConcoursDetailController extends ChangeNotifier {
  ConcoursDetailController({
    required this.concoursId,
    DepartementItem? precharge,
    FormationRepository? repository,
  }) : _repo = repository ?? FormationRepository(),
       departement = precharge,
       etat = precharge != null ? ConcoursDetailEtat.pret : ConcoursDetailEtat.chargement;

  final int concoursId;
  final FormationRepository _repo;

  ConcoursDetailEtat etat;
  String? erreurMessage;
  DepartementItem? departement;

  Future<void> charger() async {
    etat = ConcoursDetailEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      departement = await _repo.detailApprenant(concoursId);
      etat = ConcoursDetailEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = ConcoursDetailEtat.erreur;
    } catch (_) {
      erreurMessage = 'Impossible de charger le concours. Vérifiez votre connexion.';
      etat = ConcoursDetailEtat.erreur;
    }
    notifyListeners();
  }
}
