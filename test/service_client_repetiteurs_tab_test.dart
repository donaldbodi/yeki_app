// Vérifie l'onglet « Répétiteurs » du dashboard Service Client (P9.5) :
// bascule is_repetiteur, liste des fiches par candidat, état vide/erreur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/service_client/presentation/service_client_controller.dart';
import 'package:yeki/features/service_client/presentation/widgets/repetiteurs_tab.dart';
import 'package:yeki/models/repetiteur_models.dart';

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

RepetiteurFiche _fiche() => const RepetiteurFiche(
  id: 1,
  enseignantId: 42,
  nom: 'Jean Dupont',
  coursId: 7,
  coursTitre: 'Mathématiques Terminale',
  matiere: 'Mathématiques',
  ville: 'Douala',
  telephone: '699000000',
  disponible: true,
  tarifMensuel: 7500,
  noteMoyenne: 4.5,
);

RepetiteurCandidat _candidat({bool isRepetiteur = true, List<RepetiteurFiche> fiches = const []}) =>
    RepetiteurCandidat(id: 42, nom: 'Jean Dupont', username: 'jdupont', isRepetiteur: isRepetiteur, fiches: fiches);

void main() {
  group('RepetiteursTab', () {
    testWidgets('affiche un état vide sans candidat', (tester) async {
      final controller = ServiceClientController()
        ..chargementRepetiteurs = false
        ..candidats = const [];
      await tester.pumpWidget(_host(RepetiteursTab(controller: controller)));
      expect(find.text('Aucun enseignant trouvé'), findsOneWidget);
    });

    testWidgets('affiche un état d\'erreur si le chargement a échoué', (tester) async {
      final controller = ServiceClientController()
        ..chargementRepetiteurs = false
        ..enErreurRepetiteurs = true;
      await tester.pumpWidget(_host(RepetiteursTab(controller: controller)));
      expect(find.text('Impossible de charger les répétiteurs.'), findsOneWidget);
    });

    testWidgets('affiche le nom du candidat et son interrupteur is_repetiteur', (tester) async {
      final controller = ServiceClientController()
        ..chargementRepetiteurs = false
        ..candidats = [_candidat(isRepetiteur: false)];
      await tester.pumpWidget(_host(RepetiteursTab(controller: controller)));
      expect(find.text('Jean Dupont'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('affiche les fiches existantes quand is_repetiteur est vrai', (tester) async {
      final controller = ServiceClientController()
        ..chargementRepetiteurs = false
        ..candidats = [_candidat(isRepetiteur: true, fiches: [_fiche()])];
      await tester.pumpWidget(_host(RepetiteursTab(controller: controller)));
      expect(find.textContaining('Mathématiques Terminale'), findsOneWidget);
      expect(find.text('Ajouter à un cours'), findsOneWidget);
    });

    testWidgets('ne montre ni fiche ni bouton "ajouter" si is_repetiteur est faux', (tester) async {
      final controller = ServiceClientController()
        ..chargementRepetiteurs = false
        ..candidats = [_candidat(isRepetiteur: false, fiches: [_fiche()])];
      await tester.pumpWidget(_host(RepetiteursTab(controller: controller)));
      expect(find.textContaining('Mathématiques Terminale'), findsNothing);
      expect(find.text('Ajouter à un cours'), findsNothing);
    });
  });
}
