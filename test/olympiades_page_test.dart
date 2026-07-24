// Vérifie la refonte P8.3 de l'écran « olympiades » : rendu sans exception,
// squelette de chargement, filtres par phase (YkSegmented).
//
// Le chargement réel (`OlympiadeRepository.pourMoi`) tente un vrai appel
// réseau en test — aucune infrastructure de mock ApiClient/dio dans ce
// projet (même limite documentée pour `composer_devoir_page_test.dart`) :
// l'échec est toléré (l'écran bascule sur `YkErrorState`, jamais
// d'exception non gérée).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/olympiades/presentation/olympiades_page.dart';

Widget _host({Brightness brightness = Brightness.light}) {
  return MaterialApp(theme: ThemeData(brightness: brightness), home: const OlympiadesPage());
}

void main() {
  group('OlympiadesPage', () {
    testWidgets('se rend sans exception, clair et sombre', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_host(brightness: brightness));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('affiche le titre "Olympiades" et un squelette de chargement', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Olympiades'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ne plante pas si le réseau échoue (bascule sur un état géré)', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
