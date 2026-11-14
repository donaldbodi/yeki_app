// Vérifie le lot « Overlays » ajouté en P4.7 : YkMenu, YkTooltip, YkPopover,
// YkOnboardingSpot, YkPaywall.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  late final SemanticsHandle semanticsHandle;
  setUpAll(() {
    semanticsHandle = TestWidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  });
  tearDownAll(() => semanticsHandle.dispose());

  group('YkMenu', () {
    testWidgets('ouvre le menu et transmet la valeur sélectionnée', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _host(
          YkMenu<String>(
            items: const [
              YkMenuItem(value: 'edit', label: 'Modifier', icon: Icons.edit_outlined),
              YkMenuItem(value: 'delete', label: 'Supprimer', icon: Icons.delete_outline),
            ],
            onSelected: (v) => selected = v,
            child: const YkButton(label: 'Ouvrir', onPressed: null),
          ),
        ),
      );
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer'), findsOneWidget);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(selected, 'delete');
    });
  });

  group('YkTooltip', () {
    testWidgets('affiche le message au survol/appui long', (tester) async {
      await tester.pumpWidget(
        _host(YkTooltip(message: 'Points gagnés', child: const Icon(Icons.info_outline))),
      );
      expect(find.byType(Tooltip), findsOneWidget);
      await tester.longPress(find.byType(Icon));
      await tester.pumpAndSettle();
      expect(find.text('Points gagnés'), findsOneWidget);
    });
  });

  group('YkPopover', () {
    testWidgets('affiche le contenu au tap, referme au tap extérieur', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => YkButton(
              label: 'Ouvrir',
              onPressed: () => YkPopover.show(
                context: context,
                contentBuilder: (ctx) => const Text('Contenu du popover'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Contenu du popover'), findsOneWidget);

      // Tap sur la zone translucide de fermeture (coin haut-gauche, hors
      // du contenu du popover lui-même).
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Contenu du popover'), findsNothing);
    });

    testWidgets('un nouveau popover referme le précédent (hide avant show)', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                YkButton(
                  label: 'A',
                  onPressed: () =>
                      YkPopover.show(context: context, contentBuilder: (ctx) => const Text('Popover A')),
                ),
                YkButton(
                  label: 'B',
                  onPressed: () =>
                      YkPopover.show(context: context, contentBuilder: (ctx) => const Text('Popover B')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('Popover A'), findsOneWidget);

      // Le popover A a une barrière plein écran : ce 1er tap sur "B" la
      // traverse et referme A sans presser le bouton en dessous (comportement
      // normal d'une barrière modale) — il faut un 2e tap pour presser "B".
      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Popover A'), findsNothing);

      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(find.text('Popover B'), findsOneWidget);
      YkPopover.hide();
    });
  });

  group('YkOnboardingSpot', () {
    testWidgets('met en avant la cible et affiche titre/message, dismiss ferme et notifie', (
      tester,
    ) async {
      final targetKey = GlobalKey();
      var dismissed = false;
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, key: targetKey),
              Builder(
                builder: (context) => YkButton(
                  label: 'Mettre en avant',
                  onPressed: () => YkOnboardingSpot.show(
                    context: context,
                    targetKey: targetKey,
                    title: 'Votre classement',
                    message: 'Suivez votre rang ici.',
                    onDismiss: () => dismissed = true,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Mettre en avant'));
      await tester.pumpAndSettle();
      expect(find.text('Votre classement'), findsOneWidget);
      expect(find.text('Suivez votre rang ici.'), findsOneWidget);

      await tester.tap(find.text('Compris'));
      await tester.pumpAndSettle();
      expect(find.text('Votre classement'), findsNothing);
      expect(dismissed, isTrue);
    });
  });

  group('YkPaywall', () {
    testWidgets('affiche titre, fonctionnalités, et déclenche onSelect du plan choisi', (
      tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: YkPaywall(
              title: 'Débloquez le premium',
              description: 'Accédez à tout le contenu.',
              features: const ['Exercices illimités', 'Support prioritaire'],
              plans: [
                YkPaywallPlan(label: 'Mensuel', priceLabel: '1 500 FCFA/mois', onSelect: () => chosen = 'mensuel'),
                YkPaywallPlan(label: 'Annuel', priceLabel: '13 000 FCFA/an', onSelect: () => chosen = 'annuel'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Débloquez le premium'), findsOneWidget);
      expect(find.text('Exercices illimités'), findsOneWidget);
      expect(find.textContaining('1 500 FCFA/mois'), findsOneWidget);

      final carteAnnuel = find.ancestor(of: find.text('Annuel'), matching: find.byType(YkCard));
      await tester.tap(find.descendant(of: carteAnnuel, matching: find.widgetWithText(YkButton, 'Choisir')));
      expect(chosen, 'annuel');
    });

    testWidgets('n\'affiche jamais de valeur figée — tout le texte vient des paramètres', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          YkPaywall(
            title: 'X',
            description: 'Y',
            features: const [],
            plans: [YkPaywallPlan(label: 'Unique', priceLabel: 'Gratuit', onSelect: () {})],
          ),
        ),
      );
      expect(find.textContaining('FCFA'), findsNothing);
      expect(find.text('Unique'), findsOneWidget);
      expect(find.text('Gratuit'), findsOneWidget);
    });

    testWidgets('badge + ancien prix barré + économie réalisée s\'affichent quand fournis', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: YkPaywall(
              title: 'Offre',
              description: 'Desc',
              features: const [],
              plans: [
                YkPaywallPlan(
                  label: 'Mensuel',
                  priceLabel: '1 000 FCFA/mois',
                  badge: 'Promotion',
                  ancienPrixLabel: '1 500 FCFA/mois',
                  onSelect: () {},
                ),
                YkPaywallPlan(
                  label: 'Annuel',
                  priceLabel: '10 000 FCFA/an',
                  economieLabel: 'Économisez 2 000 FCFA vs mensuel',
                  onSelect: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Promotion'), findsOneWidget);
      expect(find.text('1 500 FCFA/mois'), findsOneWidget);
      expect(find.text('Économisez 2 000 FCFA vs mensuel'), findsOneWidget);
    });

    testWidgets('le présentiel est une carte séparée, jamais dans la liste des plans', (
      tester,
    ) async {
      var presentielChoisi = false;
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: YkPaywall(
              title: 'Offre',
              description: 'Desc',
              features: const [],
              plans: [YkPaywallPlan(label: 'Mensuel', priceLabel: '1 000 FCFA/mois', onSelect: () {})],
              presentielLabel: 'Supplément présentiel',
              presentielDescription: 'Optionnel — sessions en salle',
              onSelectPresentiel: () => presentielChoisi = true,
            ),
          ),
        ),
      );
      expect(find.text('Supplément présentiel'), findsOneWidget);
      expect(find.text('Optionnel — sessions en salle'), findsOneWidget);
      // Une seule carte de plan (Mensuel) + la carte présentiel séparée = 2.
      expect(find.byType(YkCard), findsNWidgets(2));

      await tester.tap(find.text('Supplément présentiel'));
      expect(presentielChoisi, isTrue);
    });
  });
}
