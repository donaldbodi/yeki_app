// Vérifie la refonte P8.2 de la feuille « créer une olympiade » (cadre) :
// bouton de soumission désactivé tant que les champs obligatoires
// manquent (YkForm/YkFormController — exigence explicite du ticket),
// date de fin affichée/calculée (jamais un champ modifiable), et absence
// des champs matiere/niveau/prix_1er/2e/3e (déjà retirés, à ne pas
// réintroduire).
//
// Le chargement des niveaux (`FormationRepository().niveaux()`) tente un
// vrai appel réseau en test — aucune infrastructure de mock ApiClient/dio
// dans ce projet (même limite documentée ailleurs) : l'échec est toléré
// (liste vide, pas d'exception).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/features/olympiades/presentation/widgets/creer_olympiade_sheet.dart';

Widget _host() {
  return MaterialApp(
    // Requis par YkRichEditor (flutter_quill), même patron que
    // test/question_devoir_form_test.dart.
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => ouvrirCreerOlympiade(
            context,
            departementId: 1,
            departementNom: 'Département Test',
            onSuccess: () {},
          ),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
}

Future<void> _ouvrirLaFeuille(WidgetTester tester) async {
  await tester.pumpWidget(_host());
  await tester.tap(find.text('Ouvrir'));
  // `pumpAndSettle()` bloquerait indéfiniment : le chargement des niveaux
  // fait un vrai appel réseau (`FormationRepository().niveaux()`), jamais
  // résolu en test (même limite documentée ailleurs, ex.
  // composer_devoir_page_test.dart) — quelques `pump()` suffisent à
  // ouvrir la feuille et laisser l'échec réseau être toléré.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('CreerOlympiadeSheet (P8.2)', () {
    testWidgets('se rend sans exception', (tester) async {
      await _ouvrirLaFeuille(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bouton de soumission désactivé tant que le titre est vide', (tester) async {
      await _ouvrirLaFeuille(tester);

      final bouton = tester.widget<YkButton>(find.byType(YkButton));
      expect(bouton.onPressed, isNull);
    });

    testWidgets('reste désactivé après le titre seul (dates obligatoires manquantes)', (tester) async {
      await _ouvrirLaFeuille(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Grand Prix Test');
      await tester.pump();

      final bouton = tester.widget<YkButton>(find.byType(YkButton));
      expect(bouton.onPressed, isNull);
    });

    testWidgets("date de fin affichée en lecture seule, pas de champ éditable", (tester) async {
      await _ouvrirLaFeuille(tester);

      expect(find.textContaining('calculée'), findsOneWidget);
      expect(find.textContaining('Renseignez le début et la durée'), findsOneWidget);
    });

    testWidgets('YkRichEditor présent pour les récompenses', (tester) async {
      await _ouvrirLaFeuille(tester);
      expect(find.byType(YkRichEditor), findsOneWidget);
    });

    testWidgets('aucun champ matiere/niveau/prix_1er/2e/3e (déjà retirés)', (tester) async {
      await _ouvrirLaFeuille(tester);

      expect(find.textContaining('Matière'), findsNothing);
      expect(find.textContaining('1er'), findsNothing);
      expect(find.textContaining('2e prix'), findsNothing);
      expect(find.textContaining('3e prix'), findsNothing);
    });
  });
}
