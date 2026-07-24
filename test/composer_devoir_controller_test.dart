// Vérifie la logique de `ComposerDevoirController` sans dépendre du réseau
// (aucune infrastructure de mock ApiClient/dio dans ce projet, voir les
// tests d'autres écrans refondus) : construction directe de l'état, sans
// passer par `charger()`. Reproduit explicitement le scénario du bug
// signalé en P7.5 (devoir MIXTE qcm+texte) et la distinction de politique
// de sortie devoir/exercice (NE PAS confondre, ticket P7.5).
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/devoirs_cours/presentation/composer_devoir_controller.dart';
import 'package:yeki/models/devoir_models.dart';

DevoirAComposer _devoirMixteDeTest({int nbSorties = 0, int tentativesMax = 2}) {
  return DevoirAComposer.fromJson({
    'id': 1,
    'titre': 'Devoir test',
    'description': '',
    'date_debut': '2026-07-01T00:00:00Z',
    'date_limite': '2026-07-22T00:00:00Z',
    'duree_minutes': 30,
    'note_sur': 20,
    'coefficient': 1.0,
    'type_correction': 'auto',
    'sorties_max': tentativesMax,
    'nb_sorties': nbSorties,
    'enonces': [
      {
        'id': 1,
        'contenu': '<p>Lisez attentivement.</p>',
        'ordre': 1,
        'questions': [
          {'id': 1, 'enonce': 'Question QCM', 'type_question': 'qcm', 'points': 1.0, 'ordre': 1, 'choix': [
            {'id': 1, 'texte': 'A'},
            {'id': 2, 'texte': 'B'},
          ]},
          {'id': 2, 'enonce': 'Question texte libre', 'type_question': 'texte', 'points': 1.0, 'ordre': 2, 'choix': []},
        ],
      },
    ],
  });
}

void main() {
  group('ComposerDevoirController — devoir mixte qcm+texte (bug P7.5)', () {
    test('repondre() enregistre une réponse QCM ET une réponse texte libre', () {
      final controller = ComposerDevoirController(devoirId: 1)
        ..devoir = _devoirMixteDeTest()
        ..etat = ComposerDevoirEtat.pret;

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.repondre(1, 'A'); // réponse QCM
      controller.repondre(2, 'Ma réponse rédigée.'); // réponse texte libre

      expect(controller.reponses[1], 'A');
      expect(controller.reponses[2], 'Ma réponse rédigée.');
      expect(notifications, greaterThan(0));
    });

    test('toutesRepondues compte les DEUX types de question', () {
      final controller = ComposerDevoirController(devoirId: 1)
        ..devoir = _devoirMixteDeTest()
        ..etat = ComposerDevoirEtat.pret;

      expect(controller.toutesRepondues, isFalse);

      controller.repondre(1, 'A');
      expect(controller.toutesRepondues, isFalse);

      controller.repondre(2, 'Ma réponse.');
      expect(controller.toutesRepondues, isTrue);
    });
  });

  group('ComposerDevoirController — politique de sortie (NE PAS confondre avec P4.4)', () {
    test('sortieEpuiseraLesTentatives faux tant que la prochaine sortie reste sous le max', () {
      final controller = ComposerDevoirController(devoirId: 1)
        ..devoir = _devoirMixteDeTest(nbSorties: 0, tentativesMax: 2)
        ..etat = ComposerDevoirEtat.pret;

      expect(controller.sortieEpuiseraLesTentatives, isFalse);
    });

    test('sortieEpuiseraLesTentatives vrai quand la prochaine sortie atteint le max', () {
      final controller = ComposerDevoirController(devoirId: 1)
        ..devoir = _devoirMixteDeTest(nbSorties: 1, tentativesMax: 2)
        ..etat = ComposerDevoirEtat.pret;

      expect(controller.sortieEpuiseraLesTentatives, isTrue);
    });
  });
}
