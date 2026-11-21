// Vérifie que le formulaire de « préoccupation » (déjà câblé sur
// passer_exercice_page.dart, décision P6.4 : vérifier/préserver
// l'existant plutôt que reconstruire un modèle métier dédié) s'ouvre
// bien et réagit à la saisie — sans réseau (aucun `http.Client`
// injectable dans ce widget, décision actée de ne pas le refactorer
// pour ce ticket). L'appel réseau réel (`POST /api/forum/questions/`)
// est exercé manuellement/en amont (règle 7) ; ce test couvre le
// comportement local, déterministe, de la feuille elle-même.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeki/widgets/form_preoccupation_sheet.dart';

Widget _host() {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => ouvrirPreoccupation(
              context: context,
              source: 'exercice',
              exerciceId: 42,
              exerciceTitre: 'Exercice test',
              coursId: 7,
              coursTitre: 'Cours test',
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'faux-token-test'});
  });

  testWidgets("s'ouvre avec le contexte de l'exercice et un champ de saisie", (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Poser une question'), findsOneWidget);
    expect(find.textContaining('Exercice test'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('refuse un envoi vide sans tenter de requête réseau', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Envoyer au forum'));
    await tester.pump();

    expect(find.text('Écrivez votre question.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
