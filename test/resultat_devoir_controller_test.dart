// Vérifie la logique de `ResultatDevoirController` sans dépendre du
// réseau — `DevoirRepository` sous-classé (même patron que
// `test/devoir_detail_controller_test.dart`). Couvre spécifiquement la
// distinction 200/202/404 : `resultat()` renvoie un `Map` brut pour 200
// ET 202 (Dio n'échoue pas sur 202, voir `DevoirRepository.resultat`),
// seul le 404 lève une exception.
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/devoirs_cours/presentation/resultat_devoir_controller.dart';
import 'package:yeki/repositories/devoir_repository.dart';

class _FakeDevoirRepository extends DevoirRepository {
  _FakeDevoirRepository({this.reponse, this.erreur});

  final Map<String, dynamic>? reponse;
  final Exception? erreur;

  @override
  Future<Map<String, dynamic>> resultat(int devoirId) async {
    if (erreur != null) throw erreur!;
    return reponse!;
  }
}

Map<String, dynamic> _resultat200({double? note = 15.0}) => {
  'devoir_titre': 'Devoir test',
  'statut': note != null ? 'corrige' : 'en_retard',
  'note': note,
  'note_sur': 20,
  'commentaire': '',
  'est_en_retard': note == null,
  'est_suspecte': false,
  'fichier_correction_url': null,
  'questions_detail': [],
};

void main() {
  group('ResultatDevoirController', () {
    test('forme 200 avec note → état prêt', () async {
      final controller = ResultatDevoirController(
        devoirId: 1,
        repository: _FakeDevoirRepository(reponse: _resultat200()),
      );

      await controller.charger();

      expect(controller.etat, ResultatDevoirEtat.pret);
      expect(controller.resultat?.note, 15.0);
    });

    test('forme 202 ({detail} seul, sans devoir_titre) → en attente de correction', () async {
      final controller = ResultatDevoirController(
        devoirId: 1,
        repository: _FakeDevoirRepository(
          reponse: {'detail': 'Résultat en attente de correction par l\'enseignant.'},
        ),
      );

      await controller.charger();

      expect(controller.etat, ResultatDevoirEtat.enAttenteCorrection);
      expect(controller.erreurMessage, contains('attente'));
    });

    test('200 mais note null (devoir manuel en retard, piège backend) → en attente', () async {
      final controller = ResultatDevoirController(
        devoirId: 1,
        repository: _FakeDevoirRepository(reponse: _resultat200(note: null)),
      );

      await controller.charger();

      expect(controller.etat, ResultatDevoirEtat.enAttenteCorrection);
    });

    test('404 (ApiException) → état erreur avec le message backend', () async {
      final controller = ResultatDevoirController(
        devoirId: 1,
        repository: _FakeDevoirRepository(erreur: Exception('Devoir encore en cours de composition.')),
      );

      await controller.charger();

      expect(controller.etat, ResultatDevoirEtat.erreur);
      expect(controller.erreurMessage, isNotNull);
    });

    test('basculerCorrectionVisible() inverse la visibilité et notifie', () {
      final controller = ResultatDevoirController(devoirId: 1, repository: _FakeDevoirRepository());
      var notifications = 0;
      controller.addListener(() => notifications++);

      expect(controller.correctionVisible, isTrue);
      controller.basculerCorrectionVisible();
      expect(controller.correctionVisible, isFalse);
      expect(notifications, greaterThan(0));
    });
  });
}
