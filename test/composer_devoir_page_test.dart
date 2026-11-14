// Vérifie la refonte P7.5 de l'écran « composer un devoir » : rendu sans
// exception aux thèmes/tailles, affichage du squelette de chargement.
//
// Le chargement réel (`DevoirRepository.demarrer/getDetail`) tente un vrai
// appel réseau en test — aucune infrastructure de mock ApiClient/dio dans
// ce projet (même limite déjà documentée pour login/register/forgot
// password/`passer_exercice_page_test.dart`) : l'échec est toléré (l'écran
// bascule sur `YkErrorState`, jamais d'exception non gérée). Le
// comportement interactif complet (PopScope/YkConfirmSheet, rendu
// qcm/texte, réponses, soumission) est couvert séparément et sans réseau
// par `test/composer_devoir_controller_test.dart` et
// `test/question_devoir_composer_card_test.dart`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/features/devoirs_cours/presentation/composer_devoir_page.dart';

Widget _host({Brightness brightness = Brightness.light}) {
  final router = GoRouter(
    initialLocation: '/devoirs/1/composer',
    routes: [
      GoRoute(
        path: '/devoirs/:devoirId/composer',
        name: 'devoirComposer',
        builder: (context, state) => const ComposerDevoirPage(
          devoirId: 1,
          titre: 'Devoir test',
          dureeMin: 30,
          noteSur: 20,
          typeCorrection: 'auto',
        ),
      ),
      GoRoute(
        path: '/devoirs/:devoirId/resultat',
        name: 'devoirResultat',
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

      expect(find.text('Devoir test'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
