// Vérifie la refonte P5.2 de l'écran Onboarding : rendu sans exception
// aux ruptures/thèmes, navigation Suivant/Passer entre les 4 pages,
// persistance de fin d'onboarding (authState.finishOnboarding()) pour un
// parcours non authentifié, et le vrai correctif fonctionnel — un
// utilisateur DÉJÀ authentifié qui rejoue l'onboarding depuis Paramètres
// ne doit jamais être renvoyé vers /login (voir docs/ecarts/onboarding.md,
// écart #6).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/features/onboarding/presentation/onboarding_page.dart';

Widget _host({Brightness brightness = Brightness.light, Size? size}) {
  final app = MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: const OnboardingPage(),
  );
  if (size == null) return app;
  return MediaQuery(data: MediaQueryData(size: size), child: app);
}

void main() {
  setUp(() {
    authState.value = const YekiAuthSnapshot();
    SharedPreferences.setMockInitialValues({});
  });

  group('Rendu', () {
    testWidgets('se rend sans exception, clair et sombre, compact et large', (tester) async {
      for (final brightness in Brightness.values) {
        for (final size in [const Size(360, 800), const Size(1400, 900)]) {
          await tester.pumpWidget(_host(brightness: brightness, size: size));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('affiche la première page et le libellé "Suivant"', (tester) async {
      await tester.pumpWidget(_host());
      await tester.pump();
      expect(find.text('Découvrez Yéki'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);
      expect(find.text('Commencer'), findsNothing);
    });
  });

  group('Navigation entre pages', () {
    testWidgets('Suivant avance les 4 pages, "Commencer" apparaît sur la dernière', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pump();

      for (final title in ['Cours et exercices', 'Classement et olympiades', 'Yéki IA']) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Commencer'), findsOneWidget);
      expect(find.text('Suivant'), findsNothing);
    });
  });

  group('Complétion — parcours initial (non authentifié)', () {
    testWidgets('Passer appelle finishOnboarding() et redirige vers /login', (tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            name: 'onboarding',
            builder: (context, state) => const OnboardingPage(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const Text('Écran de connexion'),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      expect(authState.value.onboardingDone, isFalse);
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(authState.value.onboardingDone, isTrue);
      expect(find.text('Écran de connexion'), findsOneWidget);
    });
  });

  group('Complétion — rejoué depuis Paramètres (déjà authentifié)', () {
    testWidgets('Passer revient en arrière, ne navigue JAMAIS vers /login', (tester) async {
      authState.value = const YekiAuthSnapshot(
        bootstrapped: true,
        token: 'token-test',
        role: 'apprenant',
        onboardingDone: true,
      );
      final router = GoRouter(
        initialLocation: '/parametres',
        routes: [
          GoRoute(path: '/parametres', builder: (context, state) => const Text('Paramètres')),
          GoRoute(
            path: '/onboarding',
            name: 'onboarding',
            builder: (context, state) => const OnboardingPage(),
          ),
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const Text('Écran de connexion'),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      router.push('/onboarding');
      await tester.pumpAndSettle();
      expect(find.text('Découvrez Yéki'), findsOneWidget);

      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();

      expect(find.text('Écran de connexion'), findsNothing);
      expect(find.text('Paramètres'), findsOneWidget);
    });
  });
}
