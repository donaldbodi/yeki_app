import 'package:flutter/foundation.dart';

import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/models/olympiade_models.dart';
import 'package:yeki/repositories/olympiade_repository.dart';

enum OlympiadesEtat { chargement, pret, erreur }

/// État + logique de l'écran « olympiades » (P8.3) — liste des
/// olympiades accessibles à l'apprenant connecté. `ChangeNotifier`
/// plutôt que `setState` (interdit sous `lib/features/`, règle 7).
class OlympiadesController extends ChangeNotifier {
  OlympiadesController({OlympiadeRepository? repository})
    : _repo = repository ?? OlympiadeRepository();

  final OlympiadeRepository _repo;

  OlympiadesEtat etat = OlympiadesEtat.chargement;
  String? erreurMessage;
  List<OlympiadeApprenant> toutes = [];

  /// 'tous' | 'inscription' | 'en_cours' | 'terminee' — filtre client,
  /// même patron que l'ancien écran (`/olympiades/pour-moi/` filtre déjà
  /// par niveau côté serveur, la phase reste un filtre d'affichage).
  String phaseFiltre = 'tous';

  List<OlympiadeApprenant> get affichees =>
      phaseFiltre == 'tous' ? toutes : toutes.where((o) => o.statut == phaseFiltre).toList();

  void filtrerPar(String phase) {
    phaseFiltre = phase;
    notifyListeners();
  }

  Future<void> charger() async {
    etat = OlympiadesEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      toutes = await _repo.pourMoi();
      etat = OlympiadesEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = OlympiadesEtat.erreur;
    } catch (e) {
      debugPrint('OlympiadesController.charger() — exception non-ApiException : ${e.runtimeType} : $e');
      erreurMessage = 'Impossible de charger les olympiades. Vérifiez votre connexion.';
      etat = OlympiadesEtat.erreur;
    }
    notifyListeners();
  }
}
