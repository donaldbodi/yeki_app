// Vérifie YkCopyableCode (P9.3) : affichage du libellé/code et copie
// presse-papiers au tap.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yeki/core/design/components/components.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('affiche le libellé et le code', (tester) async {
    await tester.pumpWidget(_host(const YkCopyableCode(label: 'Code USSD Orange Money', code: '#150*1#')));
    expect(find.text('Code USSD Orange Money'), findsOneWidget);
    expect(find.text('#150*1#'), findsOneWidget);
  });

  testWidgets('affiche seulement le code si aucun libellé fourni', (tester) async {
    await tester.pumpWidget(_host(const YkCopyableCode(code: '694000000')));
    expect(find.text('694000000'), findsOneWidget);
  });

  testWidgets('copie le code dans le presse-papiers au tap et affiche une confirmation', (tester) async {
    final copies = <ClipboardData>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copies.add(ClipboardData(text: (call.arguments as Map)['text'] as String));
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(_host(const YkCopyableCode(label: 'Numéro de dépôt', code: '694000000')));
    await tester.tap(find.byType(YkCopyableCode));
    await tester.pump();

    expect(copies, hasLength(1));
    expect(copies.single.text, '694000000');
    expect(find.textContaining('Copié'), findsOneWidget);

    // Laisser le timer du toast se purger proprement (même convention que
    // design_feedback2_test.dart) plutôt que de laisser un Timer en attente.
    await tester.pump(const Duration(seconds: 3, milliseconds: 100));
  });
}
