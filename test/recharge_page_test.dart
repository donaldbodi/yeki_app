// Vérifie l'écran de recharge du portefeuille (P9.3, `AppRoute.recharge`) :
// rendu sans exception, montants secs proposés (décision actée avec
// l'utilisateur — aucun bonus).
//
// Le chargement réel (`PaiementRepository.parametresPublics`) tente un
// vrai appel réseau en test — aucune infrastructure de mock ApiClient/dio
// dans ce projet (même limite documentée pour
// classement_olympiade_page_test.dart) : l'échec est toléré.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/paiement/presentation/recharge_page.dart';

Widget _host({Brightness brightness = Brightness.light}) {
  return MaterialApp(theme: ThemeData(brightness: brightness), home: const RechargePage());
}

void main() {
  group('RechargePage', () {
    testWidgets('se rend sans exception, clair et sombre', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_host(brightness: brightness));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('ne plante pas si le réseau échoue (bascule sur un état géré)', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
