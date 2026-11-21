// Vérifie que `DetailReponse` normalise correctement les DEUX formes
// renvoyées par le backend pour le même concept (P6.2/P6.4) : la
// soumission immédiate (clés `correct`/`reponse_utilisateur`) et
// l'historique (clés `est_correct`/`reponse`) — mêmes champs Dart des
// deux côtés, jamais deux conventions mélangées dans l'UI.
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/models/exercice_models.dart';

void main() {
  group('DetailReponse', () {
    test('fromSoumission lit correct/reponse_utilisateur', () {
      final detail = DetailReponse.fromSoumission({
        'question_id': 12,
        'question': 'Capitale du Cameroun ?',
        'reponse_utilisateur': 'Yaoundé',
        'bonne_reponse': 'Yaoundé',
        'correct': true,
        'points_obtenus': 2.0,
        'points_max': 2.0,
        'explication': "C'est la capitale politique.",
      });

      expect(detail.questionId, 12);
      expect(detail.enonce, 'Capitale du Cameroun ?');
      expect(detail.reponseApprenant, 'Yaoundé');
      expect(detail.estCorrect, isTrue);
      expect(detail.pointsObtenus, 2.0);
      expect(detail.explication, "C'est la capitale politique.");
    });

    test('fromHistorique lit est_correct/reponse — mêmes champs Dart en sortie', () {
      final detail = DetailReponse.fromHistorique({
        'question_id': 12,
        'question': 'Capitale du Cameroun ?',
        'reponse': 'Douala',
        'bonne_reponse': 'Yaoundé',
        'est_correct': false,
        'points_obtenus': 0.0,
        'points_max': 2.0,
        'explication': "C'est la capitale politique.",
      });

      expect(detail.questionId, 12);
      expect(detail.reponseApprenant, 'Douala');
      expect(detail.estCorrect, isFalse);
      expect(detail.pointsObtenus, 0.0);
    });
  });

  group('SoumissionExercice', () {
    test('parse un gain de rang quand présent', () {
      final soumission = SoumissionExercice.fromJson({
        'score': 5.0,
        'total': 5.0,
        'note': 20.0,
        'note_sur': 20,
        'detail': [],
        'tentative_numero': 1,
        'tentatives_restantes': 0,
        'tentatives_epuisees': true,
        'message': 'Examen soumis avec succès.',
        'auto_soumis': false,
        'rang_gagne': true,
        'ancien_rang': 14,
        'nouveau_rang': 9,
      });

      expect(soumission.rangGagne, isTrue);
      expect(soumission.ancienRang, 14);
      expect(soumission.nouveauRang, 9);
      expect(soumission.tentativesEpuisees, isTrue);
    });

    test('rangGagne est null (pas false) quand absent de la réponse', () {
      final soumission = SoumissionExercice.fromJson({
        'score': 3.0,
        'total': 5.0,
        'note': 12.0,
        'note_sur': 20,
        'detail': [],
        'tentative_numero': 1,
        'tentatives_restantes': 1,
        'message': 'Examen soumis avec succès.',
        'auto_soumis': false,
      });

      expect(soumission.rangGagne, isNull);
      expect(soumission.ancienRang, isNull);
    });
  });

  group('ExerciceAPasser', () {
    test('tentativesEpuisees dérive de tentativesRestantes', () {
      final exercice = ExerciceAPasser.fromDetailJson({
        'id': 1,
        'titre': 'Ex',
        'enonce': 'E',
        'duree_minutes': 10,
        'duree_totale': 600,
        'temps_restant': 600,
        'tentatives_max': 2,
        'tentatives_restantes': 0,
        'questions': [],
      });

      expect(exercice.tentativesEpuisees, isTrue);
    });

    test('copyWith ne remplace que les champs fournis', () {
      final exercice = ExerciceAPasser.fromDetailJson({
        'id': 1,
        'titre': 'Ex',
        'enonce': 'E',
        'duree_minutes': 10,
        'duree_totale': 600,
        'temps_restant': 500,
        'tentatives_max': 2,
        'tentatives_restantes': 1,
        'questions': [],
      });

      final copie = exercice.copyWith(tempsRestantSecondes: 480);
      expect(copie.tempsRestantSecondes, 480);
      expect(copie.dureeTotaleSecondes, 600); // inchangé
    });
  });
}
