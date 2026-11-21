// Vérifie la refonte P6.5 de l'onglet « Exercices » d'un cours : rendu
// sans exception (réseau réel non mocké, voir passer_exercice_page_test.dart)
// aux deux rôles (apprenant sans `role`, enseignant avec `role`), et
// qu'un changement de `moduleId`/`leconId` depuis le parent (bascule
// d'onglet interne, sans nouvelle `Key`) ne casse pas `didUpdateWidget`
// — le correctif du bug de filtre lui-même est vérifié au niveau du
// contrôleur (test/exercices_cours_controller_test.dart, sans réseau).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/exercices_cours/presentation/exercices_cours_page.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

Widget _host({RoleEnseignant? role, int? moduleId, int? leconId}) {
  return MaterialApp(
    home: Scaffold(
      body: ExercicesCoursPage(
        coursId: '1',
        coursTitre: 'Cours test',
        courseColor: const Color(0xFF2884A0),
        role: role,
        moduleId: moduleId,
        leconId: leconId,
      ),
    ),
  );
}

void main() {
  group('Rendu', () {
    testWidgets('se rend sans exception côté apprenant', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('se rend sans exception côté enseignant', (tester) async {
      await tester.pumpWidget(_host(role: RoleEnseignant.enseignantPrincipal));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('un changement de moduleId/leconId sans Key ne casse pas didUpdateWidget', (tester) async {
      await tester.pumpWidget(_host(moduleId: 1, leconId: 10));
      await tester.pump();

      await tester.pumpWidget(_host(moduleId: 2, leconId: 20));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
