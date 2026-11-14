// Vérifie le rendu de `DetailReponseDevoirTile` (P7.6) : toutes les
// options QCM affichées (pas seulement celle sélectionnée — corrige le
// bug historique « l'apprenant ne voit pas la bonne réponse »), rendu
// texte libre, et état neutre quand `estCorrect` est `null` (correction
// manuelle pas encore faite — à ne jamais confondre avec `false`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/devoirs_cours/presentation/widgets/detail_reponse_devoir_tile.dart';
import 'package:yeki/models/devoir_models.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('DetailReponseDevoirTile', () {
    testWidgets('QCM : affiche TOUTES les options, y compris la bonne réponse non sélectionnée', (
      tester,
    ) async {
      final detail = DetailReponseDevoir.fromJson({
        'question_id': 1,
        'question_enonce': 'Capitale de la France ?',
        'type_question': 'qcm',
        'reponse_utilisateur': 'Lyon',
        'choix_selectionne': 'Lyon',
        'choix': [
          {'id': 1, 'texte': 'Paris', 'est_correct': true},
          {'id': 2, 'texte': 'Lyon', 'est_correct': false},
        ],
        'est_correct': false,
        'points_obtenus': 0,
        'points_max': 1.0,
        'bonne_reponse': 'Paris',
        'reponse_exemple': '',
        'commentaire_enseignant': '',
      });

      await tester.pumpWidget(_host(DetailReponseDevoirTile(detail: detail, index: 1)));

      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('Lyon'), findsOneWidget);
      // Une croix pour l'en-tête (question incorrecte) + une pour le
      // choix sélectionné à tort — la bonne réponse (Paris), elle,
      // porte une coche même si non sélectionnée.
      expect(find.byIcon(Icons.cancel_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('texte libre : affiche la réponse rédigée et l\'exemple', (tester) async {
      final detail = DetailReponseDevoir.fromJson({
        'question_id': 2,
        'question_enonce': 'Expliquez le théorème.',
        'type_question': 'texte',
        'reponse_utilisateur': 'Ma réponse rédigée.',
        'choix_selectionne': null,
        'choix': [],
        'est_correct': true,
        'points_obtenus': 2.0,
        'points_max': 2.0,
        'bonne_reponse': null,
        'reponse_exemple': 'Un exemple de bonne réponse.',
        'commentaire_enseignant': '',
      });

      await tester.pumpWidget(_host(DetailReponseDevoirTile(detail: detail, index: 2)));

      // `_ligne` rend via `RichText`/`TextSpan` (texte label+valeur sur
      // une seule ligne stylée différemment) — `findRichText: true`
      // requis pour que le finder les voie.
      expect(find.textContaining('Ma réponse rédigée.', findRichText: true), findsOneWidget);
      expect(find.textContaining('Un exemple de bonne réponse.'), findsOneWidget);
    });

    testWidgets('estCorrect null → état neutre « en attente », pas vert ni rouge', (tester) async {
      final detail = DetailReponseDevoir.fromJson({
        'question_id': 3,
        'question_enonce': 'Question en attente.',
        'type_question': 'texte',
        'reponse_utilisateur': 'Réponse.',
        'choix_selectionne': null,
        'choix': [],
        'est_correct': null,
        'points_obtenus': null,
        'points_max': 1.0,
        'bonne_reponse': null,
        'reponse_exemple': '',
        'commentaire_enseignant': '',
      });

      await tester.pumpWidget(_host(DetailReponseDevoirTile(detail: detail, index: 3)));

      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    });
  });
}
