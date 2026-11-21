// Vérifie la logique de `DevoirsCoursController` sans dépendre du
// réseau — `DevoirRepository` sous-classé (même patron que
// test/exercices_cours_controller_test.dart, P6.5).
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/devoirs_cours/presentation/devoirs_cours_controller.dart';
import 'package:yeki/models/devoir_models.dart';
import 'package:yeki/repositories/devoir_repository.dart';

class _FakeDevoirRepository extends DevoirRepository {
  _FakeDevoirRepository({required this.devoirs});

  final List<DevoirListItem> devoirs;
  int appelsDupliquer = 0;
  int appelsPublier = 0;

  @override
  Future<List<DevoirListItem>> listerParCours(int coursId) async => devoirs;

  @override
  Future<int> dupliquer(int devoirId) async {
    appelsDupliquer++;
    return 999;
  }

  @override
  Future<String> publier(int devoirId) async {
    appelsPublier++;
    return 'Devoir publié.';
  }
}

DevoirListItem _devoir({int id = 1, bool estPublie = false}) => DevoirListItem(
  id: id,
  titre: 'Devoir $id',
  description: '',
  dateDebut: null,
  dateLimite: null,
  estOuvert: true,
  estExpire: false,
  estPublie: estPublie,
  nbQuestions: 2,
  noteSur: 20,
  coefficient: 1.0,
  dureeMinutes: 60,
  tentativesMax: 1,
  typeCorrection: 'auto',
);

void main() {
  group('DevoirsCoursController', () {
    test('charger() peuple devoirs', () async {
      final repo = _FakeDevoirRepository(devoirs: [_devoir(id: 1), _devoir(id: 2)]);
      final controller = DevoirsCoursController(coursId: 1, canEdit: true, repository: repo);

      await controller.charger();

      expect(controller.devoirs.length, 2);
      expect(controller.etat, DevoirsCoursEtat.pret);
    });

    test('dupliquer() délègue au repository et recharge', () async {
      final repo = _FakeDevoirRepository(devoirs: [_devoir(id: 1)]);
      final controller = DevoirsCoursController(coursId: 1, canEdit: true, repository: repo);
      await controller.charger();

      final ok = await controller.dupliquer(1);

      expect(ok, isTrue);
      expect(repo.appelsDupliquer, 1);
    });

    test('publier() renvoie le message de l\'API', () async {
      final repo = _FakeDevoirRepository(devoirs: [_devoir(id: 1)]);
      final controller = DevoirsCoursController(coursId: 1, canEdit: true, repository: repo);
      await controller.charger();

      final message = await controller.publier(1);

      expect(message, 'Devoir publié.');
      expect(repo.appelsPublier, 1);
    });
  });
}
