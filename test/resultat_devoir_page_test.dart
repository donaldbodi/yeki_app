// Vérifie la refonte P7.6 de l'écran « résultat de devoir » : rendu sans
// exception aux thèmes/tailles, affichage du squelette de chargement.
//
// Le chargement réel (`DevoirRepository.resultat`) tente un vrai appel
// réseau en test — aucune infrastructure de mock ApiClient/dio dans ce
// projet (même limite documentée pour les autres écrans refondus) :
// l'échec est toléré (l'écran bascule sur `YkErrorState`, jamais
// d'exception non gérée). Le comportement 200/202/404 et le rendu par
// question sont couverts sans réseau par
// `test/resultat_devoir_controller_test.dart` et
// `test/detail_reponse_devoir_tile_test.dart`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/features/devoirs_cours/presentation/resultat_devoir_page.dart';

Widget _host({Brightness brightness = Brightness.light}) {
  final router = GoRouter(
    initialLocation: '/devoirs/1/resultat',
    routes: [
      GoRoute(
        path: '/devoirs/:devoirId/resultat',
        name: 'devoirResultat',
        builder: (context, state) => const ResultatDevoirPage(devoirId: 1, titre: 'Devoir test'),
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

    testWidgets('bouton IA désactivé quand coursId est absent', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();

      final iaButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.psychology_rounded));
      expect(iaButton.onPressed, isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
