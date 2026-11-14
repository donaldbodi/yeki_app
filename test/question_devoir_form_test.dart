// Vérifie le formulaire ADAPTATIF de question devoir (P7.4) : le QCM
// disparaît du sélecteur si le devoir est en correction manuelle
// (l'ancien écran ne connaissait pas du tout `type_correction`), et la
// sélection du choix correct envoie bien `est_correct` par option
// (même vérification que P6.5 pour les exercices — bug identique
// possible ici : un seul `bonne_reponse` texte au lieu d'un
// `est_correct` par choix).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/devoirs_cours/presentation/widgets/question_devoir_form.dart';
import 'package:yeki/models/devoir_models.dart';

Widget _host({
  required String typeCorrection,
  QuestionDevoirItem? existant,
  required Future<bool> Function({
    required String enonce,
    required String typeQuestion,
    required double points,
    String? reponseAttendue,
    String? reponseExemple,
    List<ChoixReponseItem>? choix,
  })
  onSubmit,
}) {
  return MaterialApp(
    // Requis par YkRichEditor (flutter_quill) — même délégué que
    // main.dart (P4.5), sans quoi le rendu lève
    // MissingFlutterQuillLocalizationException dans les tests.
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        child: QuestionDevoirForm(existant: existant, typeCorrection: typeCorrection, onSubmit: onSubmit),
      ),
    ),
  );
}

void main() {
  testWidgets('QCM absent du sélecteur si correction manuelle', (tester) async {
    await tester.pumpWidget(_host(typeCorrection: 'manuel', onSubmit: ({
      required enonce,
      required typeQuestion,
      required points,
      reponseAttendue,
      reponseExemple,
      choix,
    }) async => true));
    await tester.pumpAndSettle();

    expect(find.text('QCM'), findsNothing);
    expect(find.textContaining('Réponse attendue'), findsWidgets);
  });

  testWidgets('QCM disponible si correction automatique', (tester) async {
    await tester.pumpWidget(_host(typeCorrection: 'auto', onSubmit: ({
      required enonce,
      required typeQuestion,
      required points,
      reponseAttendue,
      reponseExemple,
      choix,
    }) async => true));
    await tester.pumpAndSettle();

    expect(find.text('QCM'), findsOneWidget);
  });

  testWidgets('sélectionner le 2e choix comme correct envoie est_correct=true sur CE choix', (tester) async {
    List<ChoixReponseItem>? choixCapture;

    // Énoncé pré-rempli via `existant` (mode édition) — sans cela, la
    // validation « énoncé requis » bloquerait la soumission ; taper du
    // texte dans le `YkRichEditor` (éditeur riche Quill) n'est pas
    // faisable via `tester.enterText` (pas un `TextField` standard).
    final existant = QuestionDevoirItem(
      id: 1,
      enonce: '<p>Capitale du Cameroun ?</p>',
      typeQuestion: 'qcm',
      points: 1.0,
      ordre: 1,
      choix: const [
        ChoixReponseItem(id: 1, texte: 'Yaoundé', estCorrect: true),
        ChoixReponseItem(id: 2, texte: 'Douala', estCorrect: false),
      ],
      reponseAttendue: '',
      reponseExemple: '',
      enonceDevoirId: 1,
    );

    await tester.pumpWidget(
      _host(
        typeCorrection: 'auto',
        existant: existant,
        onSubmit: ({
          required enonce,
          required typeQuestion,
          required points,
          reponseAttendue,
          reponseExemple,
          choix,
        }) async {
          choixCapture = choix;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    // P17.9 : les choix sont désormais eux aussi des `YkRichEditor`, pas
    // des `TextFormField` — plus rien à saisir ici (déjà pré-remplis via
    // `existant`), seule la sélection du choix correct est exercée.
    // Sélectionne le choix actuellement NON coché ("Douala") comme
    // correct — il était initialement "Yaoundé" (estCorrect: true) via
    // `existant`.
    final choixNonCoche = find.ancestor(of: find.byIcon(Icons.circle_outlined), matching: find.byType(InkWell));
    expect(choixNonCoche, findsOneWidget);
    await tester.ensureVisible(choixNonCoche);
    await tester.tap(choixNonCoche);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(choixCapture, isNotNull);
    expect(choixCapture!.length, 2);
    expect(choixCapture![0].texte, 'Yaoundé');
    expect(choixCapture![0].estCorrect, isFalse);
    expect(choixCapture![1].texte, 'Douala');
    expect(choixCapture![1].estCorrect, isTrue);
  });
}
