// Vérifie la refonte P7.4 de l'onglet « Devoirs » d'un cours : rendu
// sans exception (réseau réel non mocké, voir
// passer_exercice_page_test.dart) aux deux rôles.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/devoirs_cours/presentation/devoirs_cours_page.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

Widget _host({RoleEnseignant? role}) {
  return MaterialApp(
    home: Scaffold(
      body: DevoirsCoursPage(
        coursId: '1',
        coursTitre: 'Cours test',
        courseColor: const Color(0xFF2884A0),
        role: role,
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
  });
}
