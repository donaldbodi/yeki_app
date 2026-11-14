// Vérifie le correctif du bug critique QCM (docs/ecarts/exercices_cours.md) :
// l'ancien `_QuestionsSheetState._submit` n'envoyait JAMAIS `est_correct`
// par choix — chaque QCM créé restait donc in-corrigeable. Ce test
// construit une question à 2 choix, sélectionne le SECOND comme
// correct, et vérifie que le payload capturé porte bien
// `estCorrect: true` sur ce choix précis (et seulement celui-ci).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations, QuillEditor;
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/exercices_cours/presentation/widgets/questions_sheet.dart';
import 'package:yeki/models/exercice_models.dart';

Widget _host({required Future<bool> Function({
  required int exerciceId,
  required String text,
  required String typeQuestion,
  required double points,
  String? bonneReponse,
  List<ChoixQuestion>? choix,
}) ajouterQuestion}) {
  return MaterialApp(
    // Requis par YkRichEditor (flutter_quill), même délégué que
    // main.dart (P4.5) — sans lui le rendu lève
    // MissingFlutterQuillLocalizationException dans les tests.
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        child: QuestionsSheet(
          exerciceId: 1,
          exerciceTitre: 'Exercice test',
          canEdit: true,
          fetchQuestions: (_) async => const [],
          ajouterQuestion: ajouterQuestion,
        ),
      ),
    ),
  );
}

/// P17.9 : les champs « choix » sont désormais des `YkRichEditor`
/// (`flutter_quill`), pas des `TextField` — `tester.enterText` exige un
/// `EditableText` ancestor (absent ici) et `tester.testTextInput.enterText`
/// s'est avéré instable avec plusieurs éditeurs Quill simultanés (le
/// diff interne de `flutter_quill` plante en changeant de client). Écrit
/// directement dans le `QuillController` du i-ème éditeur — le widget
/// `QuillEditor` monté expose son `controller` publiquement, c'est le
/// même objet que `YkRichEditor` utilise en interne.
Future<void> _saisirChoix(WidgetTester tester, int index, String texte) async {
  final editeur = tester.widget<QuillEditor>(find.byType(QuillEditor).at(index));
  final doc = editeur.controller.document;
  editeur.controller.replaceText(0, doc.length - 1, texte, null);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sélectionner le 2e choix comme correct envoie est_correct=true sur CE choix', (tester) async {
    List<ChoixQuestion>? choixCapture;

    await tester.pumpWidget(
      _host(
        ajouterQuestion: ({
          required exerciceId,
          required text,
          required typeQuestion,
          required points,
          bonneReponse,
          choix,
        }) async {
          choixCapture = choix;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajouter une question'));
    await tester.pumpAndSettle();

    // Formulaire QCM par défaut : énoncé (TextFormField) + 2 choix
    // (YkRichEditor, plus des TextFormField depuis P17.9).
    expect(find.byType(TextFormField), findsOneWidget); // énoncé
    expect(find.byType(QuillEditor), findsNWidgets(2)); // 2 choix

    await tester.enterText(find.byType(TextFormField), 'Capitale du Cameroun ?');
    await _saisirChoix(tester, 0, 'Yaoundé');
    await _saisirChoix(tester, 1, 'Douala');

    // Sélectionne le 2e choix (initialement non coché) comme correct.
    final choixNonCoche = find.ancestor(
      of: find.byIcon(Icons.circle_outlined),
      matching: find.byType(InkWell),
    );
    expect(choixNonCoche, findsOneWidget);
    await tester.ensureVisible(choixNonCoche);
    await tester.tap(choixNonCoche);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Publier'));
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();

    expect(choixCapture, isNotNull);
    expect(choixCapture!.length, 2);
    // P17.9 : `YkRichEditor` émet du HTML assaini (`<p>...</p>`), pas le
    // texte brut d'un `TextField` — le libellé reste bien identifiable
    // dans le contenu, mais plus une égalité stricte au texte saisi.
    expect(choixCapture![0].texte, contains('Yaoundé'));
    expect(choixCapture![0].estCorrect, isFalse);
    expect(choixCapture![1].texte, contains('Douala'));
    expect(choixCapture![1].estCorrect, isTrue);
  });
}
