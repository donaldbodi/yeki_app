// Vérifie `ClassementOlympiadeController` (P8.3) sans réseau. Le parsing de
// l'enveloppe paginée (`{results, count, next, previous}`, bug corrigé —
// l'ancien fichier faisait `jsonDecode(...) as List`) vit dans
// `OlympiadeRepository.classement()`, déjà relu manuellement ; ce test
// vérifie que le contrôleur réagit correctement à ce que le repository lui
// renvoie (même patron que les autres contrôleurs de ce ticket).
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/olympiades/presentation/classement_olympiade_controller.dart';
import 'package:yeki/models/olympiade_models.dart';
import 'package:yeki/repositories/olympiade_repository.dart';

class _FakeOlympiadeRepository extends OlympiadeRepository {
  _FakeOlympiadeRepository({this.entrees, this.erreur});

  final List<ClassementOlympiadeEntry>? entrees;
  final Object? erreur;

  @override
  Future<List<ClassementOlympiadeEntry>> classement(int olympiadeId) async {
    if (erreur != null) throw erreur!;
    return entrees ?? [];
  }
}

ClassementOlympiadeEntry _entree({required int rang, required String nomComplet, required String mention}) =>
    ClassementOlympiadeEntry(
      rang: rang,
      nomComplet: nomComplet,
      username: nomComplet.toLowerCase(),
      note: 18.0,
      noteSur20: 18.0,
      mention: mention,
    );

void main() {
  group('ClassementOlympiadeController', () {
    test('charger() peuple entrees dans l\'ordre renvoyé par le repository', () async {
      final repo = _FakeOlympiadeRepository(
        entrees: [
          _entree(rang: 1, nomComplet: 'Awa Ngo', mention: 'Excellent'),
          _entree(rang: 2, nomComplet: 'Jean Fotso', mention: 'Très bien'),
        ],
      );
      final c = ClassementOlympiadeController(olympiadeId: 1, repository: repo);

      await c.charger();

      expect(c.etat, ClassementOlympiadeEtat.pret);
      expect(c.entrees.length, 2);
      expect(c.entrees.first.nomComplet, 'Awa Ngo');
    });

    test('liste vide (aucun participant classé) → état pret, entrees vides', () async {
      final repo = _FakeOlympiadeRepository(entrees: []);
      final c = ClassementOlympiadeController(olympiadeId: 1, repository: repo);

      await c.charger();

      expect(c.etat, ClassementOlympiadeEtat.pret);
      expect(c.entrees, isEmpty);
    });

    test('échec réseau → état erreur, pas d\'exception non gérée', () async {
      final repo = _FakeOlympiadeRepository(erreur: Exception('réseau indisponible'));
      final c = ClassementOlympiadeController(olympiadeId: 1, repository: repo);

      await c.charger();

      expect(c.etat, ClassementOlympiadeEtat.erreur);
      expect(c.erreurMessage, isNotNull);
    });
  });
}
