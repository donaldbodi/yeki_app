// Vérifie la logique de `DevoirDetailController` (P7.4) sans réseau —
// en particulier le REGROUPEMENT DES QUESTIONS PAR ÉNONCÉ, cœur du
// problème dénoncé par le commanditaire (« un énoncé a plusieurs
// questions, CES questions ») : `ListeQuestionsDevoirView` renvoie les
// questions à plat, ce contrôleur doit les répartir correctement selon
// `enonceDevoirId` (ajouté au serializer teacher-safe en P7.4).
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/devoirs_cours/presentation/devoir_detail_controller.dart';
import 'package:yeki/models/devoir_models.dart';
import 'package:yeki/repositories/devoir_repository.dart';

class _FakeDevoirRepository extends DevoirRepository {
  _FakeDevoirRepository({
    required this.devoirs,
    required this.enonces,
    required this.questions,
  });

  final List<DevoirListItem> devoirs;
  final List<EnonceDevoirItem> enonces;
  final List<QuestionDevoirItem> questions;

  @override
  Future<List<DevoirListItem>> listerParCours(int coursId) async => devoirs;

  @override
  Future<List<EnonceDevoirItem>> listerEnonces(int devoirId) async => enonces;

  @override
  Future<List<QuestionDevoirItem>> listerQuestions(int devoirId) async => questions;
}

DevoirListItem _devoir({bool estPublie = false}) => DevoirListItem(
  id: 1,
  titre: 'Devoir',
  description: '',
  dateDebut: null,
  dateLimite: null,
  estOuvert: true,
  estExpire: false,
  estPublie: estPublie,
  nbQuestions: 3,
  noteSur: 20,
  coefficient: 1.0,
  dureeMinutes: 60,
  tentativesMax: 1,
  typeCorrection: 'auto',
);

QuestionDevoirItem _question({required int id, required int? enonceDevoirId}) => QuestionDevoirItem(
  id: id,
  enonce: 'Q$id',
  typeQuestion: 'texte',
  points: 1.0,
  ordre: 1,
  choix: const [],
  reponseAttendue: 'x',
  reponseExemple: '',
  enonceDevoirId: enonceDevoirId,
);

void main() {
  group('DevoirDetailController', () {
    test('regroupe correctement les questions PAR énoncé', () async {
      final repo = _FakeDevoirRepository(
        devoirs: [_devoir()],
        enonces: const [
          EnonceDevoirItem(id: 10, contenu: 'Énoncé 1', ordre: 1),
          EnonceDevoirItem(id: 20, contenu: 'Énoncé 2', ordre: 2),
        ],
        questions: [
          _question(id: 1, enonceDevoirId: 10),
          _question(id: 2, enonceDevoirId: 10),
          _question(id: 3, enonceDevoirId: 20),
        ],
      );
      final controller = DevoirDetailController(devoirId: 1, coursId: 1, repository: repo);

      await controller.charger();

      expect(controller.enonces.length, 2);
      final enonce1 = controller.enonces.firstWhere((e) => e.id == 10);
      final enonce2 = controller.enonces.firstWhere((e) => e.id == 20);
      expect(enonce1.questions.map((q) => q.id).toList(), [1, 2]);
      expect(enonce2.questions.map((q) => q.id).toList(), [3]);
    });

    test('peutModifier reflète est_publie', () async {
      final repoPublie = _FakeDevoirRepository(
        devoirs: [_devoir(estPublie: true)],
        enonces: const [EnonceDevoirItem(id: 10, contenu: 'E', ordre: 1)],
        questions: const [],
      );
      final controllerPublie = DevoirDetailController(devoirId: 1, coursId: 1, repository: repoPublie);
      await controllerPublie.charger();
      expect(controllerPublie.peutModifier, isFalse);

      final repoBrouillon = _FakeDevoirRepository(
        devoirs: [_devoir(estPublie: false)],
        enonces: const [EnonceDevoirItem(id: 10, contenu: 'E', ordre: 1)],
        questions: const [],
      );
      final controllerBrouillon = DevoirDetailController(devoirId: 1, coursId: 1, repository: repoBrouillon);
      await controllerBrouillon.charger();
      expect(controllerBrouillon.peutModifier, isTrue);
    });

    test('devoir introuvable dans la liste du cours → état erreur', () async {
      final repo = _FakeDevoirRepository(devoirs: const [], enonces: const [], questions: const []);
      final controller = DevoirDetailController(devoirId: 999, coursId: 1, repository: repo);

      await controller.charger();

      expect(controller.etat, DevoirDetailEtat.erreur);
    });
  });
}
