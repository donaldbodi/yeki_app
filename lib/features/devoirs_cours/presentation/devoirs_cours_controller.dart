import 'package:flutter/foundation.dart';

import 'package:yeki/core/design/components/inputs/yk_file_upload.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/models/devoir_models.dart';
import 'package:yeki/repositories/devoir_repository.dart';

enum DevoirsCoursEtat { chargement, pret, erreur }

/// État + logique de l'onglet « Devoirs » d'un cours (P7.4, refonte de
/// l'ancien `devoirs_cours_page.dart`). `ChangeNotifier` (pas de
/// `setState`, règle 7) — même patron que `ExercicesCoursController`
/// (P6.5).
class DevoirsCoursController extends ChangeNotifier {
  DevoirsCoursController({required this.coursId, required this.canEdit, DevoirRepository? repository})
    : _repo = repository ?? DevoirRepository();

  final int coursId;
  final bool canEdit;
  final DevoirRepository _repo;

  DevoirsCoursEtat etat = DevoirsCoursEtat.chargement;
  String? erreurMessage;
  List<DevoirListItem> devoirs = const [];

  Future<void> charger() async {
    etat = DevoirsCoursEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      devoirs = await _repo.listerParCours(coursId);
      etat = DevoirsCoursEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = DevoirsCoursEtat.erreur;
    } catch (e) {
      debugPrint('DevoirsCoursController.charger() — exception non-ApiException : ${e.runtimeType} : $e');
      erreurMessage = 'Impossible de charger les devoirs.';
      etat = DevoirsCoursEtat.erreur;
    }
    notifyListeners();
  }

  Future<bool> creer({
    required String titre,
    required String description,
    required String enonce,
    required DateTime dateDebut,
    required DateTime dateLimite,
    required int dureeMinutes,
    required double noteSur,
    required double coefficient,
    required int tentativesMax,
    required String typeCorrection,
    YkPickedFile? fichierCorrection,
  }) async {
    try {
      await _repo.creer(
        coursId: coursId,
        titre: titre,
        description: description,
        enonce: enonce,
        dateDebut: dateDebut,
        dateLimite: dateLimite,
        dureeMinutes: dureeMinutes,
        noteSur: noteSur,
        coefficient: coefficient,
        tentativesMax: tentativesMax,
        typeCorrection: typeCorrection,
        fichierCorrection: fichierCorrection,
      );
      await charger();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dupliquer(int devoirId) async {
    try {
      await _repo.dupliquer(devoirId);
      await charger();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Renvoie le message d'avertissement de l'API si succès, `null` sinon
  /// — l'écran appelant doit déjà avoir averti l'enseignant AVANT
  /// l'appel (`YkDialog.confirm`), ce message vient en confirmation.
  Future<String?> publier(int devoirId) async {
    try {
      final message = await _repo.publier(devoirId);
      await charger();
      return message;
    } catch (_) {
      return null;
    }
  }
}
