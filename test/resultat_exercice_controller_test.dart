// Vérifie la logique de `ResultatExerciceController` sans dépendre du
// réseau — `ExerciceRepository` sous-classé (même patron que
// `test/exercices_cours_controller_test.dart`).
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/exercice/presentation/resultat_exercice_controller.dart';
import 'package:yeki/models/exercice_models.dart';
import 'package:yeki/repositories/exercice_repository.dart';

ResultatExercice _resultatDeTest({bool tentativesEpuisees = false}) {
  return ResultatExercice(
    exerciceId: 1,
    exerciceTitre: 'Exercice test',
    note: 15,
    noteSur: 20,
    score: 3,
    total: 5,
    detail: const [],
    historique: const [],
    tentativesRestantes: tentativesEpuisees ? 0 : 1,
    tentativesMax: 2,
    tentativesEpuisees: tentativesEpuisees,
  );
}

class _FakeExerciceRepository extends ExerciceRepository {
  _FakeExerciceRepository({this.resultatFake, this.historiqueFake = const [], this.echoueResultat = false});

  final ResultatExercice? resultatFake;
  final List<TentativeHistorique> historiqueFake;
  final bool echoueResultat;
  int appelsHistorique = 0;

  @override
  Future<ResultatExercice> resultat(int exerciceId) async {
    if (echoueResultat) throw Exception('réseau indisponible');
    return resultatFake!;
  }

  @override
  Future<List<TentativeHistorique>> historique(int exerciceId) async {
    appelsHistorique++;
    return historiqueFake;
  }
}

void main() {
  group('ResultatExerciceController', () {
    test('charger() peuple resultat et passe à l\'état prêt', () async {
      final repo = _FakeExerciceRepository(resultatFake: _resultatDeTest());
      final controller = ResultatExerciceController(exerciceId: 1, repository: repo);

      await controller.charger();

      expect(controller.etat, ResultatExerciceEtat.pret);
      expect(controller.resultat?.note, 15);
    });

    test('charger() passe à l\'état erreur si le réseau échoue', () async {
      final repo = _FakeExerciceRepository(resultatFake: null, echoueResultat: true);
      final controller = ResultatExerciceController(exerciceId: 1, repository: repo);

      await controller.charger();

      expect(controller.etat, ResultatExerciceEtat.erreur);
      expect(controller.erreurMessage, isNotNull);
    });

    test('tentativesEpuisees vrai quand tentatives_restantes = 0', () async {
      final repo = _FakeExerciceRepository(resultatFake: _resultatDeTest(tentativesEpuisees: true));
      final controller = ResultatExerciceController(exerciceId: 1, repository: repo);

      await controller.charger();

      expect(controller.resultat!.tentativesEpuisees, isTrue);
    });

    test('chargerHistoriqueComplet() ne relance pas le fetch une deuxième fois', () async {
      final repo = _FakeExerciceRepository(
        resultatFake: _resultatDeTest(),
        historiqueFake: [
          TentativeHistorique(
            id: 1,
            tentativeNumero: 1,
            date: DateTime(2026, 1, 1),
            score: 3,
            total: 5,
            noteSur20: 12,
            estSoumise: true,
            reponses: const [],
          ),
        ],
      );
      final controller = ResultatExerciceController(exerciceId: 1, repository: repo);

      await controller.chargerHistoriqueComplet();
      await controller.chargerHistoriqueComplet();

      expect(repo.appelsHistorique, 1);
      expect(controller.historiqueComplet?.length, 1);
    });
  });
}
