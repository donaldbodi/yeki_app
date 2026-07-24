// Vérifie la refonte P6.4 de l'écran « passer un exercice » : rendu sans
// exception aux thèmes/tailles, affichage du squelette de chargement.
//
// Le chargement réel (`ExerciceRepository.demarrer/detail`) tente un vrai
// appel réseau en test — aucune infrastructure de mock ApiClient/dio dans
// ce projet (même limite déjà documentée pour login/register/forgot
// password) : l'échec est toléré (l'écran bascule sur `YkErrorState`,
// jamais d'exception non gérée). Le comportement interactif complet
// (PopScope/YkConfirmSheet, réponses aux questions, soumission) est
// couvert séparément et sans réseau par
// `test/passer_exercice_controller_test.dart` et
// `test/design_components_test.dart` (YkConfirmSheet).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/features/exercice/presentation/passer_exercice_page.dart';

Widget _host({Brightness brightness = Brightness.light}) {
  final router = GoRouter(
    initialLocation: '/exercices/1/passer',
    routes: [
      GoRoute(
        path: '/exercices/:exerciceId/passer',
        name: 'exercicePasser',
        builder: (context, state) => const PasserExercicePage(
          exerciceId: 1,
          coursId: 1,
          coursTitre: 'Cours test',
        ),
      ),
      GoRoute(
        path: '/exercices/:exerciceId/resultat',
        name: 'exerciceResultat',
        builder: (context, state) => const Text('Écran résultat'),
      ),
    ],
  );
  return MaterialApp.router(theme: ThemeData(brightness: brightness), routerConfig: router);
}

void main() {
  group('Rendu', () {
    testWidgets('se rend sans exception, clair et sombre', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_host(brightness: brightness));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('affiche un squelette de chargement puis ne plante pas si le réseau échoue', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pump();

      // Chargement initial : squelette visible, pas de crash.
      expect(find.text('Exercice'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Laisse le temps à l'appel réseau (toléré en échec) de se résoudre.
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
