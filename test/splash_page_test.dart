// Vérifie l'écran Splash (P5.1 maquette, corrigé en P5.1bis d'après un
// ticket fonctionnel prioritaire — voir docs/ecarts/splash.md) : rendu
// sans exception quel que soit le thème ambiant et la préférence
// d'animations réduites, présence d'un Semantics de chargement, et
// surtout — le vrai correctif fonctionnel de P5.1bis — que
// `authState.bootstrap()` n'est plus retardé par un délai artificiel
// (l'ancien `_kMinSplashDuration` de 2s minimum, supprimé) ni par les
// vérifications de version, qui tournent en tâche de fond.
//
// Limite assumée : `UpdateService.checkForUpdate()` et le nouveau
// `checkMandatoryVersion()` tentent chacun un vrai appel réseau
// (http.get, timeout 5-15s, déjà encapsulés dans un try/catch renvoyant
// `null` sur toute erreur — aucun risque de crash). Le délai réel avant
// que ces appels échouent dépend du réseau/DNS de la machine, pas du
// temps simulé de `flutter_test` — même limite déjà rencontrée avec
// `test/providers_test.dart`. Ces vérifications de version, désormais en
// tâche de fond (`unawaited`), ne sont plus testées de façon
// déterministe ici — mais elles ne bloquent plus non plus
// `authState.bootstrap()`, ce qui est justement le point vérifié plus
// bas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/features/splash/presentation/splash_page.dart';

Widget _host(Widget child) => ProviderScope(child: child);

void main() {
  late final SemanticsHandle semanticsHandle;
  setUpAll(() {
    semanticsHandle = TestWidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  });
  tearDownAll(() => semanticsHandle.dispose());

  // Mock du canal `flutter_secure_storage` centralisé dans
  // `test/flutter_test_config.dart` (chargé automatiquement pour tout ce
  // dossier) — voir ce fichier pour l'explication complète.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> drainPendingTimers(WidgetTester tester) async {
    // Purge le filet de sécurité de 2s (`Future.any([bootstrap(),
    // Future.delayed(2s)])`) avant la fin du test (sans quoi
    // `!timersPending` échoue au tearDown).
    await tester.pump(const Duration(seconds: 3));
  }

  group('Rendu', () {
    testWidgets('se rend sans exception, clair et sombre', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          _host(MaterialApp(theme: ThemeData(brightness: brightness), home: const SplashPage())),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        await drainPendingTimers(tester);
      }
    });

    testWidgets('respecte disableAnimations (pas de crash)', (tester) async {
      await tester.pumpWidget(
        _host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(home: SplashPage()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await drainPendingTimers(tester);
    });
  });

  group('Accessibilité', () {
    testWidgets('expose un Semantics de chargement', (tester) async {
      await tester.pumpWidget(_host(const MaterialApp(home: SplashPage())));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.bySemanticsLabel(RegExp('Chargement de Yéki en cours')), findsWidgets);
      await drainPendingTimers(tester);
    });
  });

  group('P5.1bis — bootstrap non retardé', () {
    testWidgets(
      'authState.bootstrap() se termine bien avant le filet de sécurité de 2s '
      '(preuve qu\'aucun délai minimum artificiel ne le retarde plus)',
      (tester) async {
        addTearDown(() => authState.value = const YekiAuthSnapshot());
        await tester.pumpWidget(_host(const MaterialApp(home: SplashPage())));
        // Une lecture SharedPreferences mockée résout en un seul micro-tick.
        // Depuis P5.3, bootstrap() lit aussi flutter_secure_storage (canal
        // de plateforme réel, ex. Credential Manager sur Windows — non
        // mocké dans cet environnement de test) avant de retomber sur
        // SharedPreferences : un peu plus lent qu'un micro-tick pur, mais
        // ce test vérifie l'absence d'un délai ARTIFICIEL de plusieurs
        // secondes (l'ancien `_kMinSplashDuration`), pas une latence nulle
        // — 500 ms restent très loin des 2 s du filet de sécurité.
        await tester.pump(const Duration(milliseconds: 500));
        expect(authState.value.bootstrapped, isTrue);
        await drainPendingTimers(tester);
      },
    );
  });
}
