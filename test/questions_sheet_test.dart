// Vérifie le correctif du bug critique QCM (docs/ecarts/exercices_cours.md) :
// l'ancien `_QuestionsSheetState._submit` n'envoyait JAMAIS `est_correct`
// par choix — chaque QCM créé restait donc in-corrigeable. Ce test
// construit une question à 2 choix, sélectionne le SECOND comme
// correct, et vérifie que le payload capturé porte bien
// `estCorrect: true` sur ce choix précis (et seulement celui-ci).
import 'package:flutter/material.dart';
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

    // Formulaire QCM par défaut, 2 champs de choix visibles.
    final champs = find.byType(TextFormField);
    expect(champs, findsNWidgets(3)); // énoncé + 2 choix

    await tester.enterText(champs.at(0), 'Capitale du Cameroun ?');
    await tester.enterText(champs.at(1), 'Yaoundé');
    await tester.enterText(champs.at(2), 'Douala');

    // Sélectionne le 2e choix (initialement non coché) comme correct.
    final choixNonCoche = find.ancestor(
      of: find.byIcon(Icons.circle_outlined),
      matching: find.byType(InkWell),
    );
    expect(choixNonCoche, findsOneWidget);
    await tester.tap(choixNonCoche);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();

    expect(choixCapture, isNotNull);
    expect(choixCapture!.length, 2);
    expect(choixCapture![0].texte, 'Yaoundé');
    expect(choixCapture![0].estCorrect, isFalse);
    expect(choixCapture![1].texte, 'Douala');
    expect(choixCapture![1].estCorrect, isTrue);
  });
}
