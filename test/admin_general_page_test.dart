// Vérifie l'écran d'administration générale (P9.6, refonte de l'ancien
// `views/pages/enseignants/admin_general_page.dart`) : rendu sans
// exception, sur les 6 onglets. Le chargement réel (`AdminGeneralRepository`)
// tente un vrai appel réseau en test — aucune infrastructure de mock
// ApiClient/dio dans ce projet (même limite documentée pour
// retrait_page_test.dart) : l'échec est toléré, chaque onglet doit
// dégrader proprement vers un état d'erreur géré.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:yeki/features/admin_general/presentation/admin_general_page.dart';

Widget _host({Brightness brightness = Brightness.light}) {
  return MaterialApp(theme: ThemeData(brightness: brightness), home: const AdminGeneralPage());
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('AdminGeneralPage', () {
    testWidgets('se rend sans exception, clair et sombre', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_host(brightness: brightness));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('affiche les 6 onglets et permet de naviguer entre eux', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      for (final onglet in ['Parcours', 'Départements', 'Vue globale', 'Enseignants', 'Tous les cours', 'Transactions']) {
        expect(find.text(onglet), findsOneWidget);
      }

      // La barre d'onglets défile (6 > 4, voir YkTabs.isScrollable) : les
      // derniers onglets ne sont pas forcément dans le viewport initial.
      await tester.ensureVisible(find.text('Transactions'));
      await tester.tap(find.text('Transactions'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Enseignants'));
      await tester.tap(find.text('Enseignants'));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('le bouton créer un parcours n\'apparaît que sur l\'onglet Parcours', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.ensureVisible(find.text('Transactions'));
      await tester.tap(find.text('Transactions'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
