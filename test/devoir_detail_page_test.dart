// Vérifie la refonte P7.4 de l'écran de composition d'un devoir : rendu
// sans exception (réseau réel non mocké, échec toléré — l'écran
// bascule sur `YkErrorState`, jamais d'exception non gérée).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/devoirs_cours/presentation/devoir_detail_page.dart';

void main() {
  testWidgets('se rend sans exception', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DevoirDetailPage(devoirId: 1, coursId: 1, coursTitre: 'Cours test'),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
