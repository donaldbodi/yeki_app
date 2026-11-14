// Vérifie le lot « Feedback » ajouté en P4.7 : YkOfflineBanner, YkToast,
// YkCelebration.
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

  group('YkOfflineBanner', () {
    testWidgets('invisible si en ligne, visible avec le compteur si hors ligne', (tester) async {
      await tester.pumpWidget(_host(const YkOfflineBanner(isOffline: false)));
      expect(find.byIcon(Icons.wifi_off), findsNothing);

      await tester.pumpWidget(_host(const YkOfflineBanner(isOffline: true, pendingSyncCount: 3)));
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.textContaining('3 en attente'), findsOneWidget);
    });

    testWidgets('état fourni par l\'appelant — ne lit jamais OfflineService directement', (
      tester,
    ) async {
      // Le composant n'a aucune dépendance à OfflineService : sa seule
      // source de vérité est le paramètre `isOffline` reçu.
      await tester.pumpWidget(_host(const YkOfflineBanner(isOffline: true)));
      expect(find.text('Hors ligne'), findsOneWidget);
    });
  });

  group('YkToast', () {
    testWidgets('affiche le message puis se referme après duration', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => YkButton(
              label: 'Afficher',
              onPressed: () => YkToast.show(context, 'Enregistré', duration: const Duration(seconds: 2)),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Afficher'));
      await tester.pump();
      expect(find.text('Enregistré'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2, milliseconds: 100));
      expect(find.text('Enregistré'), findsNothing);
    });

    testWidgets('un nouveau toast remplace le précédent', (tester) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                YkButton(
                  label: 'Toast A',
                  onPressed: () => YkToast.show(context, 'A', duration: const Duration(seconds: 5)),
                ),
                YkButton(
                  label: 'Toast B',
                  onPressed: () => YkToast.show(context, 'B', duration: const Duration(seconds: 5)),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Toast A'));
      await tester.pump();
      await tester.tap(find.text('Toast B'));
      await tester.pump();
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);

      // Purge les 2 minuteries de fermeture avant la fin du test.
      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('YkCelebration', () {
    testWidgets('affiche le titre et la statistique mise en avant', (tester) async {
      await tester.pumpWidget(
        _host(
          const YkCelebration(
            title: 'Félicitations !',
            statLabel: 'Nouveau rang au département',
            statValue: '#3',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Félicitations !'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('Nouveau rang au département'), findsOneWidget);
    });

    testWidgets('onDismiss affiché seulement si fourni', (tester) async {
      await tester.pumpWidget(
        _host(const YkCelebration(title: 'Bravo', statLabel: 'Rang', statValue: '#1')),
      );
      expect(find.text('Continuer'), findsNothing);

      var dismissed = false;
      await tester.pumpWidget(
        _host(
          YkCelebration(
            title: 'Bravo',
            statLabel: 'Rang',
            statValue: '#1',
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.tap(find.text('Continuer'));
      expect(dismissed, isTrue);
    });
  });
}
