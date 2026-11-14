import 'package:flutter/foundation.dart';

import 'package:yeki/core/design/components/inputs/yk_file_upload.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/models/devoir_models.dart';
import 'package:yeki/repositories/devoir_repository.dart';

enum DevoirDetailEtat { chargement, pret, erreur }

/// État + logique de l'écran de composition d'un devoir (P7.4) —
/// énoncés/questions regroupés, dupliquer/publier/modifier, soumissions.
/// `ChangeNotifier` (pas de `setState`, règle 7).
class DevoirDetailController extends ChangeNotifier {
  DevoirDetailController({
    required this.devoirId,
    required this.coursId,
    DevoirRepository? repository,
  }) : _repo = repository ?? DevoirRepository();

  final int devoirId;
  final int coursId;
  final DevoirRepository _repo;

  DevoirDetailEtat etat = DevoirDetailEtat.chargement;
  String? erreurMessage;

  DevoirListItem? devoir;
  List<EnonceDevoirItem> enonces = const [];

  List<SoumissionDevoirItem>? soumissions;
  bool chargementSoumissions = false;

  bool get peutModifier => devoir != null && !devoir!.estPublie;

  Future<void> charger() async {
    etat = DevoirDetailEtat.chargement;
    erreurMessage = null;
    notifyListeners();

    try {
      final devoirs = await _repo.listerParCours(coursId);
      devoir = devoirs.where((d) => d.id == devoirId).firstOrNull;
      if (devoir == null) {
        erreurMessage = 'Devoir introuvable.';
        etat = DevoirDetailEtat.erreur;
        notifyListeners();
        return;
      }

      final enoncesBruts = await _repo.listerEnonces(devoirId);
      final questions = await _repo.listerQuestions(devoirId);
      enonces = [
        for (final e in enoncesBruts)
          e.copyWith(questions: questions.where((q) => q.enonceDevoirId == e.id).toList()),
      ];
      etat = DevoirDetailEtat.pret;
    } on ApiException catch (e) {
      erreurMessage = e.message;
      etat = DevoirDetailEtat.erreur;
    } catch (_) {
      erreurMessage = 'Impossible de charger le devoir.';
      etat = DevoirDetailEtat.erreur;
    }
    notifyListeners();
  }

  Future<bool> modifier({
    required String titre,
    required String description,
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
      await _repo.modifier(
        devoirId: devoirId,
        titre: titre,
        description: description,
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

  Future<bool> dupliquer() async {
    try {
      await _repo.dupliquer(devoirId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> publier() async {
    try {
      final message = await _repo.publier(devoirId);
      await charger();
      return message;
    } catch (_) {
      return null;
    }
  }

  Future<bool> ajouterEnonce(String contenu) async {
    try {
      await _repo.ajouterEnonce(devoirId, contenu);
      await charger();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> modifierEnonce(int enonceId, String contenu) async {
    try {
      await _repo.modifierEnonce(enonceId, contenu);
      await charger();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> supprimerEnonce(int enonceId) async {
    try {
      await _repo.supprimerEnonce(enonceId);
      await charger();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ajouterQuestion({
    required int enonceId,
    required String enonce,
    required String typeQuestion,
    required double points,
    String? reponseAttendue,
    String? reponseExemple,
    List<ChoixReponseItem>? choix,
  }) async {
    try {
      await _repo.ajouterQuestion(
        enonceId: enonceId,
        enonce: enonce,
        typeQuestion: typeQuestion,
        points: points,
        reponseAttendue: reponseAttendue,
        reponseExemple: reponseExemple,
        choix: choix,
      );
      await charger();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> modifierQuestion({
    required int questionId,
    String? enonce,
    double? points,
    String? reponseAttendue,
    String? reponseExemple,
    List<ChoixReponseItem>? choix,
  }) async {
    try {
      await _repo.modifierQuestion(
        questionId: questionId,
        enonce: enonce,
        points: points,
        reponseAttendue: reponseAttendue,
        reponseExemple: reponseExemple,
        choix: choix,
      );
      await charger();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> supprimerQuestion(int questionId) async {
    try {
      await _repo.supprimerQuestion(questionId);
      await charger();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> chargerSoumissions() async {
    if (soumissions != null || chargementSoumissions) return;
    chargementSoumissions = true;
    notifyListeners();
    try {
      soumissions = await _repo.listerSoumissions(devoirId);
    } catch (_) {
      soumissions = const [];
    } finally {
      chargementSoumissions = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> detailSoumission(int soumissionId) async {
    try {
      return await _repo.detailSoumission(soumissionId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> corrigerSoumission(int soumissionId, {required double note, String commentaire = ''}) async {
    try {
      await _repo.corrigerSoumission(soumissionId, note: note, commentaire: commentaire);
      soumissions = null;
      await chargerSoumissions();
      return true;
    } catch (_) {
      return false;
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
