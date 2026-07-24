import 'package:flutter/foundation.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/models/olympiade_models.dart';
import 'package:yeki/repositories/olympiade_repository.dart';

enum ClassementOlympiadeEtat { chargement, pret, erreur }

/// État + logique de l'écran « classement d'olympiade » (P8.3).
/// `ChangeNotifier` plutôt que `setState` (interdit sous `lib/features/`,
/// règle 7).
class ClassementOlympiadeController extends ChangeNotifier {
  ClassementOlympiadeController({required this.olympiadeId, OlympiadeRepository? repository})
    : _repo = repository ?? OlympiadeRepository();

  final int olympiadeId;
  final OlympiadeRepository _repo;

  ClassementOlympiadeEtat etat = ClassementOlympiadeEtat.chargement;
  String? erreurMessage;
  List<ClassementOlympiadeEntry> entrees = [];

  Future<void> charger() async {
    etat = ClassementOlympiadeEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      entrees = await _repo.classement(olympiadeId);
      etat = ClassementOlympiadeEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = ClassementOlympiadeEtat.erreur;
    } catch (_) {
      erreurMessage = 'Impossible de charger le classement. Vérifiez votre connexion.';
      etat = ClassementOlympiadeEtat.erreur;
    }
    notifyListeners();
  }
}
