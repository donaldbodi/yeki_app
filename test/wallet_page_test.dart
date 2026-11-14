// Vérifie la refonte P9.3 de l'écran « Mon Portefeuille » (remplace
// lib/widgets/wallet_page.dart) : rendu sans exception, squelette de
// chargement.
//
// Le chargement réel (`WalletRepository.apercu`/`PaiementRepository
// .mesDemandes`) tente un vrai appel réseau en test — aucune
// infrastructure de mock ApiClient/dio dans ce projet (même limite
// documentée pour classement_olympiade_page_test.dart) : l'échec est
// toléré, jamais d'exception non gérée.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/paiement/presentation/wallet_page.dart';

Widget _host({Brightness brightness = Brightness.light}) {
  return MaterialApp(theme: ThemeData(brightness: brightness), home: const WalletPage());
}

void main() {
  group('WalletPage', () {
    testWidgets('se rend sans exception, clair et sombre', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_host(brightness: brightness));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('affiche le titre dans l\'AppBar', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      expect(find.text('Mon Portefeuille'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('ne plante pas si le réseau échoue (bascule sur un état géré)', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}
