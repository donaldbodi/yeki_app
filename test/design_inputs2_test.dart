// Vérifie le lot « Saisie » ajouté en P4.7 : YkDropdown, YkMultiSelect,
// YkSlider, YkStepper, YkDateTimePicker, YkOtpInput, YkColorPicker,
// YkIconPicker, YkSearchBar — rendu, interactions de base, et règles
// métier ciblées : YkColorPicker n'expose QUE YkCourseColors.palette ;
// YkSlider/YkStepper appliquent le `step` fourni par l'appelant (jamais un
// pas figé dans le composant) ; YkOtpInput avance automatiquement.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(body: Center(child: SingleChildScrollView(child: child))),
  );
}

void main() {
  late final SemanticsHandle semanticsHandle;
  setUpAll(() {
    semanticsHandle = TestWidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  });
  tearDownAll(() => semanticsHandle.dispose());

  group('YkDropdown', () {
    testWidgets('affiche le libellé et sélectionne un item', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _host(
          YkDropdown<String>(
            label: 'Niveau',
            value: null,
            items: const [
              YkDropdownItem(value: '6e', label: '6e'),
              YkDropdownItem(value: '5e', label: '5e'),
            ],
            onChanged: (v) => selected = v,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5e').last);
      await tester.pumpAndSettle();
      expect(selected, '5e');
    });

    testWidgets('isLoading affiche un skeleton, liste vide affiche emptyMessage', (tester) async {
      await tester.pumpWidget(
        _host(
          YkDropdown<String>(
            label: 'Niveau',
            value: null,
            items: const [],
            isLoading: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(YkSkeleton), findsOneWidget);

      await tester.pumpWidget(
        _host(
          YkDropdown<String>(
            label: 'Niveau',
            value: null,
            items: const [],
            emptyMessage: 'Aucun niveau',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Aucun niveau'), findsOneWidget);
    });
  });

  group('YkMultiSelect', () {
    testWidgets('ajoute/retire une valeur du set sélectionné', (tester) async {
      Set<String> selected = {};
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => YkMultiSelect<String>(
              items: const [
                YkMultiSelectItem(value: '6e', label: '6e'),
                YkMultiSelectItem(value: '5e', label: '5e'),
              ],
              selectedValues: selected,
              onChanged: (v) => setState(() => selected = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('6e'));
      await tester.pump();
      expect(selected, {'6e'});
    });
  });

  group('YkSlider', () {
    testWidgets('step est appliqué par l\'appelant, pas figé dans le composant', (tester) async {
      double? changed;
      await tester.pumpWidget(
        _host(
          YkSlider(
            value: 10,
            min: 0,
            max: 20,
            step: 0.25,
            onChanged: (v) => changed = v,
          ),
        ),
      );
      final slider = tester.widget<Slider>(find.byType(Slider));
      // 20/0.25 = 80 divisions — la preuve que le pas vient du paramètre
      // `step`, pas d'une constante interne au composant.
      expect(slider.divisions, 80);

      await tester.pumpWidget(
        _host(YkSlider(value: 10, min: 0, max: 20, step: 5, onChanged: (v) => changed = v)),
      );
      final sliderStep5 = tester.widget<Slider>(find.byType(Slider));
      expect(sliderStep5.divisions, 4);
      expect(changed, isNull); // pas encore interagi, juste vérifié la config
    });
  });

  group('YkStepper', () {
    testWidgets('incrémente/décrémente exactement de `step`', (tester) async {
      double value = 3;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => YkStepper(
              value: value,
              min: 0,
              max: 10,
              step: 0.25,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Augmenter'));
      await tester.pump();
      expect(value, 3.25);

      await tester.tap(find.bySemanticsLabel('Diminuer'));
      await tester.pump();
      expect(value, 3.0);
    });

    testWidgets('désactive le bouton diminuer à `min`', (tester) async {
      await tester.pumpWidget(
        _host(YkStepper(value: 0, min: 0, max: 10, step: 1, onChanged: (_) {})),
      );
      final decrement = tester.widget<YkIconButton>(find.widgetWithIcon(YkIconButton, Icons.remove));
      expect(decrement.onPressed, isNull);
    });
  });

  group('YkDateTimePicker', () {
    testWidgets('les 4 modes se rendent sans exception', (tester) async {
      for (final mode in YkDateTimePickerMode.values) {
        await tester.pumpWidget(
          _host(
            YkDateTimePicker(
              mode: mode,
              label: 'Test',
              onChanged: mode == YkDateTimePickerMode.range ? null : (_) {},
              onRangeChanged: mode == YkDateTimePickerMode.range ? (_) {} : null,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('range exige onRangeChanged, les autres modes exigent onChanged', (tester) async {
      expect(
        () => YkDateTimePicker(mode: YkDateTimePickerMode.date, label: 'Test'),
        throwsAssertionError,
      );
      expect(
        () => YkDateTimePicker(mode: YkDateTimePickerMode.range, label: 'Test'),
        throwsAssertionError,
      );
    });
  });

  group('YkOtpInput', () {
    testWidgets('avance automatiquement au champ suivant après une saisie', (tester) async {
      await tester.pumpWidget(_host(const YkOtpInput(length: 4, onCompleted: _noop)));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1');
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      final focusedField = tester.widget<TextField>(fields.at(1));
      expect(focusedField.focusNode!.hasFocus, isTrue);
    });

    testWidgets('onCompleted appelé une fois toutes les cases remplies', (tester) async {
      String? code;
      await tester.pumpWidget(_host(YkOtpInput(length: 3, onCompleted: (c) => code = c)));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1');
      await tester.pump();
      await tester.enterText(fields.at(1), '2');
      await tester.pump();
      await tester.enterText(fields.at(2), '3');
      await tester.pump();
      expect(code, '123');
    });
  });

  group('YkColorPicker — règle métier', () {
    testWidgets('n\'expose QUE YkCourseColors.palette, rien d\'autre', (tester) async {
      await tester.pumpWidget(
        _host(YkColorPicker(selectedHex: null, onChanged: (_) {})),
      );
      expect(find.byType(InkWell), findsNWidgets(YkCourseColors.palette.length));
      for (final swatch in YkCourseColors.palette) {
        expect(find.bySemanticsLabel(swatch.nom), findsOneWidget);
      }
    });

    testWidgets('onChanged reçoit le hex de la couleur choisie', (tester) async {
      String? hex;
      await tester.pumpWidget(
        _host(YkColorPicker(selectedHex: null, onChanged: (v) => hex = v)),
      );
      final firstSwatch = YkCourseColors.palette.first;
      await tester.tap(find.bySemanticsLabel(firstSwatch.nom));
      expect(hex, YkColorPicker.hexOf(firstSwatch.base));
    });
  });

  group('YkIconPicker', () {
    testWidgets('sélectionne une icône fournie par l\'appelant', (tester) async {
      IconData? selected;
      await tester.pumpWidget(
        _host(
          YkIconPicker(
            icons: const [Icons.school, Icons.book],
            selected: null,
            onChanged: (i) => selected = i,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.book));
      expect(selected, Icons.book);
    });
  });

  group('YkSearchBar', () {
    testWidgets('débat 300 ms avant d\'appeler onQueryChanged', (tester) async {
      final received = <String>[];
      await tester.pumpWidget(_host(YkSearchBar(onQueryChanged: received.add)));
      await tester.enterText(find.byType(TextField), 'maths');
      expect(received, isEmpty);
      await tester.pump(const Duration(milliseconds: 299));
      expect(received, isEmpty);
      await tester.pump(const Duration(milliseconds: 50));
      expect(received, ['maths']);
    });

    testWidgets('affiche l\'historique récent quand le champ est vide', (tester) async {
      await tester.pumpWidget(
        _host(YkSearchBar(recentSearches: const ['Physique'], onQueryChanged: (_) {})),
      );
      await tester.enterText(find.byType(TextField), 'x');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.text('Physique'), findsOneWidget);
    });
  });
}

void _noop(String _) {}
