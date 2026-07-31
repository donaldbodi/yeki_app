// lib/features/splash/presentation/splash_page.dart
//
// Écran affiché pendant la restauration de session (`authState.bootstrap()`)
// — `guards.dart` redirige automatiquement vers l'écran suivant dès que
// `authState.value.bootstrapped == true`.
//
// Refondu en P5.1 (maquette) puis corrigé en P5.1bis d'après un ticket
// fonctionnel plus détaillé et explicitement prioritaire sur la maquette
// (règle 4 : l'écrit prime) : fond `primary700` uni, animation
// `YkMotion.normal`, restauration de session jamais retardée par un appel
// réseau, délai maximum 2s. Fiche d'écarts : `docs/ecarts/splash.md`
// (section « P5.1bis »).
//
// `ConsumerStatefulWidget` : `lib/features/` interdit `setState` (règle 7
// de `check_design_system.sh`) — le numéro de version vient d'un
// `FutureProvider` (`appVersionProvider`), pas d'un champ local mutable.
// `Scaffold` simple (pas `YkAdaptiveScaffold`, conçu pour la coquille
// applicative authentifiée avec navigation par rôle, inapplicable ici).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/providers/app_info_provider.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/services/push_notification_service.dart';
import 'package:yeki/services/update_service.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    // `YkMotion.duration(context, ..., isOpacity: true)` renverrait de
    // toute façon toujours `YkMotion.normal` (un fondu reste joué même en
    // « animations réduites », traitement délibéré du token) — la
    // constante est utilisée directement pour éviter tout accès à
    // `MediaQuery` dans `initState` (interdit par Flutter avant que
    // l'arbre d'héritage ne soit disponible).
    _entranceController = AnimationController(vsync: this, duration: YkMotion.normal);
    _logoOpacity = CurvedAnimation(parent: _entranceController, curve: YkMotion.normalCurve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });

    _bootstrap();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// Restauration de session : ne doit JAMAIS être retardée par un appel
  /// réseau (règles 6/7 du ticket P5.1bis — « un splash qui dure est un
  /// splash qui ment sur la performance », « ne jamais bloquer un
  /// utilisateur au splash parce que le serveur ne répond pas »).
  ///
  /// Les vérifications de version partent en tâche de fond
  /// (`unawaited`) et ne conditionnent jamais `authState.bootstrap()`.
  /// Le filet de sécurité de 2s couvre le cas, improbable, où
  /// `bootstrap()` (une simple lecture locale `SharedPreferences`)
  /// traînerait anormalement — il continue de toute façon en fond,
  /// `Future.any` n'annule rien.
  Future<void> _bootstrap() async {
    unawaited(_checkVersionsInBackground());
    await Future.any([
      authState.bootstrap(),
      Future.delayed(const Duration(seconds: 2)),
    ]);
    // Session restaurée (redémarrage app, utilisateur déjà connecté) :
    // (ré)enregistrer le jeton push — jamais attendu, ne doit jamais
    // retarder la sortie du splash (même règle que le reste de cette
    // méthode).
    if (authState.value.isAuthenticated) {
      unawaited(PushNotificationService().initialiser());
    }
  }

  Future<void> _checkVersionsInBackground() async {
    final updateInfo = await UpdateService.checkForUpdate();
    if (updateInfo != null && mounted) {
      await UpdateService.showUpdateDialog(context, updateInfo);
    }

    // `/api/app/version/` (P12.1) — `checkMandatoryVersion()` renvoie
    // maintenant un `UpdateInfo` complet (téléchargement + checksum
    // inclus), réutilisable tel quel par `showUpdateDialog` : quand
    // `forceUpdate == true`, celui-ci route déjà vers le dialogue non
    // dismissible qui télécharge + vérifie + installe. Limite assumée :
    // si l'utilisateur a déjà quitté Splash quand cet appel de fond se
    // résout, `context` peut être démonté (`mounted` vérifié ci-dessus).
    final mandatory = await UpdateService.checkMandatoryVersion();
    if (mandatory != null && mounted) {
      await UpdateService.showUpdateDialog(context, mandatory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = ref.watch(appVersionProvider).value ?? '';

    return Scaffold(
      backgroundColor: YkColors.primary700,
      body: Stack(
        children: [
          Center(
            child: Semantics(
              label: 'Chargement de Yéki en cours',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: Image.asset(
                      'assets/images/yeki_logo_icon_transparent.png',
                      width: 132,
                    ),
                  ),
                  SizedBox(height: YkSpacing.lg),
                  Text(
                    'Yéki',
                    style: YkTypography.display(context).copyWith(
                      color: Colors.white,
                      letterSpacing: -1.6,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: YkSpacing.lg),
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (version.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: ExcludeSemantics(
                child: Center(
                  child: Text(
                    version,
                    style: YkTypography.caption(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
