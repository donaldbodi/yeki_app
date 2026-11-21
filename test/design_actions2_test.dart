// Vérifie le lot « Actions » ajouté en P4.7 : YkFab, YkChip, YkSegmented,
// YkLink — rendu de toutes les variantes, interactions de base, clair/sombre
// sans exception.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  late final SemanticsHandle semanticsHandle;
  setUpAll(() {
    semanticsHandle = TestWidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  });
  tearDownAll(() => semanticsHandle.dispose());

  group('YkFab', () {
    testWidgets('toutes les variantes se rendent sans exception, clair et sombre', (tester) async {
      for (final variant in YkFabVariant.values) {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            _host(
              YkFab(icon: Icons.add, label: 'Ajouter', variant: variant, onPressed: () {}),
              brightness: brightness,
            ),
          );
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('expose un Semantics bouton avec le libellé', (tester) async {
      await tester.pumpWidget(_host(YkFab(icon: Icons.add, label: 'Ajouter', onPressed: () {})));
      expect(find.bySemanticsLabel('Ajouter'), findsOneWidget);
    });

    testWidgets('extended exige un libellé non vide', (tester) async {
      expect(
        () => YkFab(
          icon: Icons.add,
          label: '',
          variant: YkFabVariant.extended,
          onPressed: () {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('YkChip', () {
    testWidgets('toutes les variantes se rendent sans exception', (tester) async {
      for (final variant in YkChipVariant.values) {
        await tester.pumpWidget(_host(YkChip(label: 'Test', variant: variant)));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('filter bascule selected via onSelected', (tester) async {
      bool? selected;
      await tester.pumpWidget(
        _host(
          YkChip(
            label: 'Facile',
            variant: YkChipVariant.filter,
            onSelected: (v) => selected = v,
          ),
        ),
      );
      await tester.tap(find.byType(FilterChip));
      expect(selected, isTrue);
    });

    testWidgets('input expose onDeleted au InputChip natif', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        _host(YkChip(label: 'Test', variant: YkChipVariant.input, onDeleted: () => deleted = true)),
      );
      tester.widget<InputChip>(find.byType(InputChip)).onDeleted!();
      expect(deleted, isTrue);
    });
  });

  group('YkSegmented', () {
    testWidgets('accepte 2 à 5 segments, refuse en dehors', (tester) async {
      expect(
        () => YkSegmented<int>(
          segments: const [YkSegment(value: 1, label: 'Un')],
          selected: 1,
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('sélectionne un segment au tap', (tester) async {
      int? selected;
      await tester.pumpWidget(
        _host(
          YkSegmented<String>(
            segments: const [
              YkSegment(value: 'a', label: 'A'),
              YkSegment(value: 'b', label: 'B'),
            ],
            selected: 'a',
            onChanged: (v) => selected = v == 'b' ? 1 : 0,
          ),
        ),
      );
      await tester.tap(find.text('B'));
      expect(selected, 1);
    });
  });

  group('YkLink', () {
    testWidgets('déclenche onTap et expose un Semantics.link', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_host(YkLink(label: 'En savoir plus', onTap: () => tapped = true)));
      await tester.tap(find.text('En savoir plus'));
      expect(tapped, isTrue);
      expect(find.bySemanticsLabel(RegExp('En savoir plus')), findsWidgets);
    });

    testWidgets('external ajoute une icône et un libellé Semantics distinct', (tester) async {
      await tester.pumpWidget(_host(YkLink(label: 'Doc', external: true, onTap: () {})));
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('ouvre un lien externe')), findsWidgets);
    });
  });
}
