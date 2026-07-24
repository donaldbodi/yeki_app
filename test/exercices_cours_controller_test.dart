// Vérifie la logique de `ExercicesCoursController` sans dépendre du
// réseau (aucune infrastructure de mock ApiClient/dio dans ce projet,
// voir les tests d'autres écrans refondus) : `ExerciceRepository` est
// sous-classé pour renvoyer des données en mémoire — filtrage, et
// surtout le correctif du bug de filtre (`appliquerFiltresExternes`,
// docs/ecarts/exercices_cours.md §3.2).
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/exercices_cours/presentation/exercices_cours_controller.dart';
import 'package:yeki/models/exercice_models.dart';
import 'package:yeki/repositories/exercice_repository.dart';

class _FakeExerciceRepository extends ExerciceRepository {
  _FakeExerciceRepository({required this.exercices, this.modules = const []});

  final List<ExerciceListItem> exercices;
  final List<ModuleOption> modules;
  final List<Map<String, dynamic>> appelsListerParCours = [];

  @override
  Future<List<ExerciceListItem>> listerParCours(
    int coursId, {
    int? moduleId,
    int? leconId,
    bool inclureEpreuves = false,
  }) async {
    appelsListerParCours.add({'moduleId': moduleId, 'leconId': leconId});
    return exercices;
  }

  @override
  Future<List<ModuleOption>> listerModules(int coursId) async => modules;
}

ExerciceListItem _exercice({
  int id = 1,
  String titre = 'Ex',
  String typeExercice = 'general',
  int? moduleId,
  int? leconId,
  bool estEpreuve = false,
  int etoiles = 1,
}) {
  return ExerciceListItem(
    id: id,
    titre: titre,
    enonce: 'Énoncé',
    etoiles: etoiles,
    dureeMinutes: 10,
    tentativesMax: 1,
    nbQuestions: 2,
    typeExercice: typeExercice,
    estEpreuve: estEpreuve,
    moduleId: moduleId,
    leconId: leconId,
  );
}

void main() {
  group('ExercicesCoursController', () {
    test('charger() peuple exercices et modules', () async {
      final repo = _FakeExerciceRepository(
        exercices: [_exercice(id: 1), _exercice(id: 2)],
        modules: [const ModuleOption(id: 1, titre: 'Module 1', lecons: [])],
      );
      final controller = ExercicesCoursController(coursId: 1, canEdit: false, repository: repo);

      await controller.charger();

      expect(controller.exercices.length, 2);
      expect(controller.modules.length, 1);
      expect(controller.etat, ExercicesCoursEtat.pret);
    });

    test('appliquerFiltresExternes met à jour les filtres ET relance le fetch — corrige le bug de filtre', () async {
      final repo = _FakeExerciceRepository(exercices: [_exercice(id: 1, moduleId: 5)]);
      final controller = ExercicesCoursController(coursId: 1, canEdit: false, repository: repo);
      await controller.charger();
      expect(repo.appelsListerParCours.length, 1);

      await controller.appliquerFiltresExternes(moduleId: 5, leconId: 9);

      expect(controller.moduleFiltre, 5);
      expect(controller.leconFiltre, 9);
      expect(repo.appelsListerParCours.length, 2);
      expect(repo.appelsListerParCours.last, {'moduleId': 5, 'leconId': 9});
    });

    test('exercices filtre par type', () async {
      final repo = _FakeExerciceRepository(
        exercices: [
          _exercice(id: 1, typeExercice: 'general'),
          _exercice(id: 2, typeExercice: 'module', moduleId: 1),
          _exercice(id: 3, estEpreuve: true, typeExercice: 'epreuve'),
        ],
      );
      final controller = ExercicesCoursController(coursId: 1, canEdit: false, repository: repo);
      await controller.charger();

      controller.setTypeFiltre('epreuve');
      expect(controller.exercices.map((e) => e.id), [3]);

      controller.setTypeFiltre('module');
      expect(controller.exercices.map((e) => e.id), [2]);
    });

    test('exercices filtre par module puis par leçon', () async {
      final repo = _FakeExerciceRepository(
        exercices: [
          _exercice(id: 1, moduleId: 1, leconId: 10),
          _exercice(id: 2, moduleId: 1, leconId: 11),
          _exercice(id: 3, moduleId: 2, leconId: 20),
        ],
      );
      final controller = ExercicesCoursController(coursId: 1, canEdit: false, repository: repo);
      await controller.charger();

      controller.setModuleFiltre(1);
      expect(controller.exercices.map((e) => e.id).toSet(), {1, 2});

      controller.setLeconFiltre(11);
      expect(controller.exercices.map((e) => e.id), [2]);
    });

    test('exercices filtre par étoiles et recherche texte', () async {
      final repo = _FakeExerciceRepository(
        exercices: [
          _exercice(id: 1, titre: 'Dérivées', etoiles: 3),
          _exercice(id: 2, titre: 'Intégrales', etoiles: 1),
        ],
      );
      final controller = ExercicesCoursController(coursId: 1, canEdit: false, repository: repo);
      await controller.charger();

      controller.setEtoileFiltre(3);
      expect(controller.exercices.map((e) => e.id), [1]);

      controller.setEtoileFiltre(0);
      controller.setRecherche('intég');
      expect(controller.exercices.map((e) => e.id), [2]);
    });
  });
}
