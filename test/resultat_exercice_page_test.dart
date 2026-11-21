// Vérifie la refonte P6.5 de l'écran « résultat d'exercice » : rendu
// sans exception (le chargement réel tente un vrai appel réseau en
// test — aucune infrastructure de mock ApiClient/dio dans ce projet,
// voir passer_exercice_page_test.dart — l'échec est toléré, l'écran
// bascule sur `YkErrorState`) et affichage de `YkCelebration` dès
// l'arrivée quand `rangGagne` est transmis (indépendant du chargement
// réseau, voir resultat_exercice_page.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/features/exercice/presentation/resultat_exercice_page.dart';

Widget _host({bool? rangGagne, int? nouveauRang}) {
  final router = GoRouter(
    initialLocation: '/exercices/1/resultat',
    routes: [
      GoRoute(
        path: '/exercices/:exerciceId/resultat',
        name: 'exerciceResultat',
        builder: (context, state) => ResultatExercicePage(
          exerciceId: 1,
          exerciceTitre: 'Exercice test',
          rangGagne: rangGagne,
          nouveauRang: nouveauRang,
        ),
      ),
      GoRoute(
        path: '/exercices/:exerciceId/passer',
        name: 'exercicePasser',
        builder: (context, state) => const Text('Écran passer'),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('Rendu', () {
    testWidgets('se rend sans exception', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('affiche YkCelebration dès l\'arrivée quand rangGagne=true', (tester) async {
      await tester.pumpWidget(_host(rangGagne: true, nouveauRang: 5));
      await tester.pump();

      expect(find.byType(YkCelebration), findsOneWidget);
      expect(find.textContaining('#5'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('n\'affiche pas YkCelebration sans rangGagne', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();

      expect(find.byType(YkCelebration), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
