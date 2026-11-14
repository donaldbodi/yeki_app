// Vérifie le parsing des DTOs légers de FormationRepository (P5.4) — pas
// d'appel réseau réel (même limite documentée que P5.3 : aucune
// infrastructure de mock ApiClient/dio dans ce projet).
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/repositories/formation_repository.dart';

void main() {
  group('ParcoursOption.fromJson', () {
    test('parse id/nom/type_parcours', () {
      final p = ParcoursOption.fromJson({'id': 3, 'nom': 'Cursus Général', 'type_parcours': 'cursus'});
      expect(p.id, 3);
      expect(p.nom, 'Cursus Général');
      expect(p.typeParcours, 'cursus');
    });

    test('tolère nom/type_parcours absents', () {
      final p = ParcoursOption.fromJson({'id': 1});
      expect(p.id, 1);
      expect(p.nom, '');
      expect(p.typeParcours, '');
    });
  });

  group('DepartementOption.fromJson', () {
    test('parse id/nom/parcours', () {
      final d = DepartementOption.fromJson({'id': 7, 'nom': 'Terminale C', 'parcours': 3});
      expect(d.id, 7);
      expect(d.nom, 'Terminale C');
      expect(d.parcoursId, 3);
    });

    test('tolère parcours absent (null)', () {
      final d = DepartementOption.fromJson({'id': 7, 'nom': 'Terminale C'});
      expect(d.parcoursId, isNull);
    });
  });
}
