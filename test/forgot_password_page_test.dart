// Vérifie la refonte P5.5 de l'écran Mot de passe oublié : rendu sans
// exception aux thèmes/tailles, indicateur d'étapes, présence des champs
// de la 1re étape (email), et gating du bouton de soumission tant que le
// champ requis est vide.
//
// Comme pour login/register (voir leurs propres tests), la suite du
// parcours (envoi réel du code, vérification OTP, nouveau mot de passe)
// N'EST PAS testée ici : `AuthRepository`/`ApiClient` n'ont aucune
// infrastructure de mock dans ce projet — un appel réseau réel échouerait
// silencieusement (toléré par `YkFormController.submit`, qui affiche un
// message d'erreur générique plutôt que de laisser planter le test).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yeki/features/forgot_password/presentation/forgot_password_page.dart';

Widget _host({Brightness brightness = Brightness.light, Size? size}) {
  final app = MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: const ForgotPasswordPage(),
  );
  if (size == null) return app;
  return MediaQuery(data: MediaQueryData(size: size), child: app);
}

void main() {
  group('Rendu', () {
    testWidgets('se rend sans exception, clair et sombre, compact et large', (tester) async {
      for (final brightness in Brightness.values) {
        for (final size in [const Size(360, 800), const Size(1400, 900)]) {
          await tester.pumpWidget(_host(brightness: brightness, size: size));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets("affiche l'étape email avec l'indicateur d'étapes", (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe oublié'), findsOneWidget);
      expect(find.textContaining('Email'), findsWidgets);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Envoyer le code'), findsOneWidget);
    });
  });

  group('Validation locale — étape email', () {
    testWidgets('le bouton "Envoyer le code" est désactivé tant que l\'email est vide', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Complétez les champs obligatoires'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'aicha@yeki.test');
      await tester.pump();

      expect(find.byTooltip('Complétez les champs obligatoires'), findsNothing);
    });
  });
}
