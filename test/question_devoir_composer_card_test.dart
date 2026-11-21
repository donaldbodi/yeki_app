// Reproduit directement le bug BLOQUANT signalé en P7.5 : « l'apprenant ne
// voit pas le formulaire pour les questions de type texte libre ». Rendu
// isolé (sans réseau) des deux branches — QCM et texte libre — de
// `QuestionDevoirComposerCard`, la carte de question réutilisée par
// `ComposerDevoirPage` pour CHAQUE question d'un devoir. Ce test aurait
// échoué si le rendu conditionnel n'avait géré que 'qcm' (piste du ticket).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/devoirs_cours/presentation/widgets/question_devoir_composer_card.dart';
import 'package:yeki/models/devoir_models.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

QuestionDevoirComposer _question({required String type}) => QuestionDevoirComposer.fromJson({
  'id': 1,
  'enonce': 'Énoncé de test',
  'type_question': type,
  'points': 1.0,
  'ordre': 1,
  'choix': type == 'qcm'
      ? [
          {'id': 1, 'texte': 'Choix A'},
          {'id': 2, 'texte': 'Choix B'},
        ]
      : [],
});

void main() {
  group('QuestionDevoirComposerCard', () {
    testWidgets('question QCM affiche les choix', (tester) async {
      await tester.pumpWidget(
        _host(
          QuestionDevoirComposerCard(
            question: _question(type: 'qcm'),
            index: 1,
            reponseActuelle: null,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Choix A'), findsOneWidget);
      expect(find.text('Choix B'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('question TEXTE LIBRE affiche bien un champ de saisie (bug signalé P7.5)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          QuestionDevoirComposerCard(
            question: _question(type: 'texte'),
            index: 1,
            reponseActuelle: null,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('saisir une réponse texte libre déclenche onChanged', (tester) async {
      String? valeurRecue;
      await tester.pumpWidget(
        _host(
          QuestionDevoirComposerCard(
            question: _question(type: 'texte'),
            index: 1,
            reponseActuelle: null,
            onChanged: (v) => valeurRecue = v,
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Ma réponse rédigée.');
      expect(valeurRecue, 'Ma réponse rédigée.');
    });
  });
}
