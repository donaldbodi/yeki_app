// Vérifie la logique de `PasserExerciceController` sans dépendre du
// réseau (aucune infrastructure de mock ApiClient/dio dans ce projet,
// voir les tests d'autres écrans refondus) : construction directe de
// l'état, sans passer par `charger()`.
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/exercice/presentation/passer_exercice_controller.dart';
import 'package:yeki/models/exercice_models.dart';

ExerciceAPasser _exerciceDeTest({int tentativesRestantes = 1}) {
  return ExerciceAPasser.fromDetailJson({
    'id': 1,
    'titre': 'Exercice test',
    'enonce': 'Répondez aux questions.',
    'duree_minutes': 10,
    'duree_totale': 600,
    'temps_restant': 600,
    'tentatives_max': 2,
    'tentatives_restantes': tentativesRestantes,
    'questions': [
      {'id': 1, 'text': 'Q1', 'type': 'texte', 'points': 1.0, 'choix': []},
      {'id': 2, 'text': 'Q2', 'type': 'texte', 'points': 1.0, 'choix': []},
    ],
  });
}

void main() {
  group('PasserExerciceController', () {
    test('repondre() enregistre la réponse et notifie les auditeurs', () {
      final controller = PasserExerciceController(exerciceId: 1)
        ..exercice = _exerciceDeTest()
        ..etat = PasserExerciceEtat.pret;

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.repondre(1, 'ma réponse');

      expect(controller.reponses[1], 'ma réponse');
      expect(notifications, greaterThan(0));
    });

    test('toutesRepondues est faux tant que des questions manquent', () {
      final controller = PasserExerciceController(exerciceId: 1)
        ..exercice = _exerciceDeTest()
        ..etat = PasserExerciceEtat.pret;

      expect(controller.toutesRepondues, isFalse);

      controller.repondre(1, 'a');
      expect(controller.toutesRepondues, isFalse);

      controller.repondre(2, 'b');
      expect(controller.toutesRepondues, isTrue);
    });

    test('tentativesEpuisees vrai quand tentatives_restantes = 0', () {
      final exercice = _exerciceDeTest(tentativesRestantes: 0);
      expect(exercice.tentativesEpuisees, isTrue);
    });
  });
}
