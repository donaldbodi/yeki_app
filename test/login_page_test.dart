// Vérifie la refonte P5.3 de l'écran Connexion : rendu sans exception aux
// thèmes/tailles, présence des champs/actions attendus (YkForm/YkTextField,
// lien « mot de passe oublié », bouton « créer un compte »), et le bouton
// de soumission désactivé tant qu'un champ requis est vide.
//
// Les états déclenchés par une réponse serveur (throttling 429, compte
// enseignant inactif, erreur de champ depuis error.fields) NE SONT PAS
// testés ici : `AuthRepository`/`ApiClient` n'ont aucune infrastructure de
// mock dans ce projet (aucun `dio` adapter de test, confirmé absent de
// pubspec.yaml — cohérent avec `test/providers_test.dart`, qui tolère déjà
// l'absence de backend réel dans cet environnement). Ces trois
// comportements sont couverts directement, sans réseau, par
// `test/api_exception_test.dart` (tolérance `account_inactive`) et
// `test/yk_form_test.dart` (message de secours quand `error.fields` est
// vide) — voir ces deux fichiers.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/features/login/presentation/login_page.dart';

Widget _host({Brightness brightness = Brightness.light, Size? size}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const Text('Écran mot de passe oublié'),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const Text("Écran d'inscription"),
      ),
    ],
  );
  final app = MaterialApp.router(theme: ThemeData(brightness: brightness), routerConfig: router);
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

    testWidgets('affiche les champs, la case et les liens attendus', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      // Labels suffixés d'un astérisque automatique (required: true, voir
      // YkTextField._effectiveLabel) — recherche par sous-chaîne.
      expect(find.textContaining('Téléphone ou e-mail'), findsOneWidget);
      expect(find.textContaining('Mot de passe'), findsWidgets);
      expect(find.text('Se souvenir de moi'), findsOneWidget);
      expect(find.text('Mot de passe oublié ?'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.byKey(const Key('loginRegisterLink')), findsOneWidget);
      // Pas de bouton OTP/SMS — différé, voir docs/ecarts/login.md §5.
      expect(find.textContaining('code SMS'), findsNothing);
    });
  });

  group('Validation locale', () {
    testWidgets('le bouton "Se connecter" est désactivé tant que les champs requis sont vides', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Complétez les champs obligatoires'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '677123456');
      await tester.enterText(find.byType(TextFormField).last, 'motdepasse');
      await tester.pump();

      expect(find.byTooltip('Complétez les champs obligatoires'), findsNothing);
    });
  });

  group('Navigation', () {
    testWidgets('"Mot de passe oublié ?" ouvre l\'écran dédié', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();

      expect(find.text('Écran mot de passe oublié'), findsOneWidget);
    });

    testWidgets('"S\'inscrire" ouvre l\'écran d\'inscription', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('loginRegisterLink')));
      await tester.pumpAndSettle();

      expect(find.text("Écran d'inscription"), findsOneWidget);
    });
  });
}
