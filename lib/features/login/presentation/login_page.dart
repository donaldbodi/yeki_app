// lib/features/login/presentation/login_page.dart
//
// Écran de connexion. Refondu en P5.3 (rituel P5.0) — fiche d'écarts :
// docs/ecarts/login.md. Bascule complète vers YkForm/YkTextField et
// AuthRepository (donc ApiException), abandon du http.post brut et des
// classes Yeki* legacy.
//
// `StatefulWidget` simple (pas de besoin Riverpod, même précédent
// qu'Onboarding). `lib/features/` interdit `setState` (règle 7 de
// check_design_system.sh) : tout l'état passe par `YkFormController`
// (déjà un ChangeNotifier) ou des ValueNotifier.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/auth_repository.dart';
import 'package:yeki/services/push_notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _identCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _formController = YkFormController();

  // Case « Se souvenir de moi » : conservée telle quelle depuis l'écran
  // legacy, sans aucun effet fonctionnel (déjà le cas avant refonte) —
  // décision actée avec l'utilisateur, voir docs/ecarts/login.md §5.
  final ValueNotifier<bool> _rememberMe = ValueNotifier(false);

  // Non-null = compte enseignant en attente de validation (403
  // `account_inactive`, hors enveloppe standard — voir
  // ApiException.fromEnvelope et docs/ecarts/login.md §6).
  final ValueNotifier<String?> _accountInactiveMessage = ValueNotifier(null);

  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    // Constantes utilisées directement (pas `YkMotion.duration(context,
    // ...)`) pour éviter tout accès à `MediaQuery` dans `initState` —
    // interdit par Flutter avant que l'arbre d'héritage soit disponible
    // (même piège rencontré et documenté en P5.1/Splash).
    _entranceController = AnimationController(vsync: this, duration: YkMotion.normal);
    _fade = CurvedAnimation(parent: _entranceController, curve: YkMotion.normalCurve);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceController, curve: YkMotion.normalCurve));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _identCtrl.dispose();
    _pwdCtrl.dispose();
    _formController.dispose();
    _rememberMe.dispose();
    _accountInactiveMessage.dispose();
    super.dispose();
  }

  /// Appelé par [YkFormSubmitButton] via `YkFormController.submit()`.
  ///
  /// `isThrottled`/`isAccountInactive` sont interceptés ICI, avant que
  /// `YkFormController.submit()` ne les traite : ce sont deux états
  /// écran entiers (message ponctuel, panneau dédié), pas des erreurs de
  /// champ. Tout le reste (identifiants incorrects, champs requis) est
  /// relancé (`rethrow`) pour que le mécanisme standard de `YkForm`
  /// s'en charge (mapping par champ / résumé en tête).
  Future<void> _submitLogin() async {
    _accountInactiveMessage.value = null;
    try {
      final result = await AuthRepository().login(
        identifiant: _identCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
      );
      // Pas de navigation explicite : `authState.login()` met à jour
      // `.value`, ce qui déclenche seul la ré-évaluation du guard
      // (`GoRouter(refreshListenable: authState)`).
      await authState.login(token: result.token, role: result.role);
      // Jamais attendu : l'enregistrement du jeton push ne doit pas
      // retarder la redirection post-connexion.
      unawaited(PushNotificationService().initialiser());
    } on ApiException catch (e) {
      if (e.isThrottled) {
        if (mounted) {
          final seconds = e.retryAfterSeconds;
          YkSnack.error(
            context,
            seconds != null
                ? 'Trop de tentatives. Réessayez dans $seconds secondes.'
                : 'Trop de tentatives. Réessayez dans quelques instants.',
          );
        }
        return;
      }
      if (e.isAccountInactive) {
        _accountInactiveMessage.value = e.message;
        return;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: YkRadialGlow(color: YkColors.accent(context), alpha: 0.16, size: 380),
            ),
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(YkSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(position: _slide, child: _buildContent(context)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: CircleAvatar(
            radius: 31,
            backgroundColor: YkColors.primary700,
            child: Image.asset('assets/images/yeki_logo_icon_transparent.png', width: 36),
          ),
        ),
        SizedBox(height: YkSpacing.lg),
        Text(
          'Bon retour 👋',
          textAlign: TextAlign.center,
          style: YkTypography.h1(context).copyWith(color: YkColors.textPrimary(context)),
        ),
        SizedBox(height: YkSpacing.xxs),
        Text(
          'Connectez-vous pour reprendre votre progression.',
          textAlign: TextAlign.center,
          style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
        ),
        SizedBox(height: YkSpacing.xl),
        YkForm(
          controller: _formController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              YkTextField(
                controller: _identCtrl,
                name: 'identifier',
                required: true,
                label: 'Téléphone ou e-mail',
                hint: '6XX XX XX XX ou exemple@email.com',
                prefixIcon: Icons.person_outline_rounded,
              ),
              SizedBox(height: YkSpacing.md),
              YkTextField(
                controller: _pwdCtrl,
                name: 'password',
                type: YkTextFieldType.password,
                required: true,
                label: 'Mot de passe',
                prefixIcon: Icons.lock_outline_rounded,
              ),
              SizedBox(height: YkSpacing.sm),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: YkSpacing.sm,
                runSpacing: YkSpacing.xxs,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _rememberMe,
                    builder: (context, value, _) => YkChip(
                      label: 'Se souvenir de moi',
                      variant: YkChipVariant.filter,
                      selected: value,
                      onSelected: (v) => _rememberMe.value = v,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pushNamed(AppRoute.forgotPassword),
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ],
              ),
              SizedBox(height: YkSpacing.sm),
              ValueListenableBuilder<String?>(
                valueListenable: _accountInactiveMessage,
                builder: (context, message, _) {
                  if (message == null) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(bottom: YkSpacing.md),
                    child: _AccountInactivePanel(message: message),
                  );
                },
              ),
              YkFormSubmitButton(
                controller: _formController,
                label: 'Se connecter',
                successMessage: 'Connexion réussie.',
                onValidSubmit: _submitLogin,
              ),
            ],
          ),
        ),
        SizedBox(height: YkSpacing.lg),
        Center(
          child: TextButton(
            key: const Key('loginRegisterLink'),
            onPressed: () => context.pushNamed(AppRoute.register),
            child: Text.rich(
              TextSpan(
                style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
                children: [
                  const TextSpan(text: "Pas encore de compte ? "),
                  TextSpan(
                    text: "S'inscrire",
                    style: TextStyle(
                      color: YkColors.accent(context),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Uniquement pertinent depuis un navigateur (l'app EST déjà l'app
        // sur mobile/desktop natif, inutile de proposer de la télécharger)
        // — exigence CDC §10 : téléchargement des versions Android/iOS/
        // Desktop DEPUIS la version Web de l'application elle-même.
        if (kIsWeb)
          Center(
            child: TextButton.icon(
              onPressed: () => context.pushNamed(AppRoute.download),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text("Télécharger l'application"),
            ),
          ),
      ],
    );
  }
}

/// Panneau « compte enseignant en attente de validation » — état 403
/// `account_inactive`, voir `docs/ecarts/login.md` §6. Reprend les mêmes
/// textes que l'écran legacy, recomposés avec `YkCard`/`YkTypography`.
class _AccountInactivePanel extends StatelessWidget {
  const _AccountInactivePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return YkCard(
      variant: YkCardVariant.filled,
      accentColor: YkColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: YkColors.warning),
              SizedBox(width: YkSpacing.xs),
              Expanded(
                child: Text(
                  'Compte en attente de validation',
                  style: YkTypography.label(context).copyWith(color: YkColors.warning),
                ),
              ),
            ],
          ),
          SizedBox(height: YkSpacing.xs),
          Text(
            message,
            style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email_outlined, size: 16, color: YkColors.accent(context)),
              SizedBox(width: YkSpacing.xxs),
              Text(
                'Vérifiez votre boîte email',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.accent(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
