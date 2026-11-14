// Vérifie le correctif du bug « Refaire l'exercice » (docs/ecarts/
// resultat_exercice.md) : le bouton reste actif même à sec dans
// l'ancienne version — ici masqué dès que `tentativesEpuisees` est vrai.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/exercice/presentation/widgets/resultat_actions_row.dart';

void main() {
  testWidgets('affiche les deux boutons quand des tentatives restent', (tester) async {
    var refaireAppele = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultatActionsRow(
            tentativesEpuisees: false,
            onVoirTentatives: () {},
            onRefaire: () => refaireAppele = true,
          ),
        ),
      ),
    );

    expect(find.text('Toutes les tentatives'), findsOneWidget);
    expect(find.text("Refaire l'exercice"), findsOneWidget);

    await tester.tap(find.text("Refaire l'exercice"));
    expect(refaireAppele, isTrue);
  });

  testWidgets('masque « Refaire l\'exercice » quand les tentatives sont épuisées', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultatActionsRow(tentativesEpuisees: true, onVoirTentatives: () {}, onRefaire: () {}),
        ),
      ),
    );

    expect(find.text('Toutes les tentatives'), findsOneWidget);
    expect(find.text("Refaire l'exercice"), findsNothing);
  });
}
