// lib/features/onboarding/presentation/onboarding_page.dart
//
// Carrousel de bienvenue affiché aux nouveaux utilisateurs, et rejouable
// à tout moment depuis Paramètres. Refondu en P5.2 (rituel P5.0) — fiche
// d'écarts : docs/ecarts/onboarding.md. Aucune maquette ne couvre cet
// écran (le seul écran « Onboarding » de la maquette est en réalité un
// tout autre écran, un choix de niveau/cursus post-inscription) : le
// contenu suit directement le texte du ticket.
//
// Déplacé depuis lib/views/pages/onboarding.dart, même convention que
// Splash (P5.1) : lib/features/<nom>/presentation/. `lib/features/`
// interdit `setState` (règle 7 de check_design_system.sh) — l'index de
// page actif est piloté par un `ValueNotifier<int>`, jamais `setState`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';

class _OnboardingSlide {
  const _OnboardingSlide({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;
}

// Thèmes demandés par le ticket P5.2. Copie française à affiner
// ultérieurement — placeholders raisonnables, pas bloquants. Icônes en
// attendant de vraies illustrations (aucune n'existe pour ces thèmes,
// aucune maquette pour cet écran — voir fiche d'écarts, décision actée).
const List<_OnboardingSlide> _kSlides = [
  _OnboardingSlide(
    icon: Icons.auto_stories_rounded,
    title: 'Découvrez Yéki',
    description:
        "Votre plateforme d'apprentissage pensée pour les élèves camerounais : cours, exercices, olympiades et bien plus.",
  ),
  _OnboardingSlide(
    icon: Icons.menu_book_rounded,
    title: 'Cours et exercices',
    description:
        'Suivez des cours interactifs et entraînez-vous avec des exercices corrigés, adaptés à votre niveau.',
  ),
  _OnboardingSlide(
    icon: Icons.emoji_events_rounded,
    title: 'Classement et olympiades',
    description:
        'Comparez votre progression à celle de votre département et participez aux olympiades nationales.',
  ),
  _OnboardingSlide(
    icon: Icons.smart_toy_rounded,
    title: 'Yéki IA',
    description:
        'Posez vos questions à tout moment : Yéki IA vous accompagne pour mieux comprendre vos cours.',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPage = ValueNotifier(0);

  @override
  void dispose() {
    _pageController.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  /// Marque l'onboarding comme terminé puis quitte l'écran.
  ///
  /// Branché sur l'état d'authentification (règle 4, écart #6 de la
  /// fiche) : un utilisateur DÉJÀ authentifié qui rejoue l'onboarding
  /// depuis Paramètres ne doit jamais être renvoyé vers `/login` (non-
  /// sens produit) — simple retour en arrière. Le parcours initial
  /// (post-inscription, pas encore connecté) conserve le comportement
  /// existant.
  Future<void> _terminer() async {
    if (authState.value.isAuthenticated) {
      if (mounted) context.pop();
      return;
    }
    await authState.finishOnboarding();
    if (mounted) context.goNamed(AppRoute.login);
  }

  void _suivant() {
    _pageController.nextPage(duration: YkMotion.normal, curve: YkMotion.normalCurve);
  }

  @override
  Widget build(BuildContext context) {
    final breakpoint = YkBreakpoints.of(context);
    final isCompact = breakpoint == YkBreakpoint.compact || breakpoint == YkBreakpoint.medium;

    return Scaffold(
      body: YkGradientBackground(
        gradient: YkColors.onboardingGradient,
        child: Stack(
          children: [
            const Positioned(
              top: -60,
              right: -60,
              child: YkRadialGlow(color: YkColors.primary300, alpha: 0.35, size: 280),
            ),
            const Positioned(
              bottom: -80,
              left: -80,
              child: YkRadialGlow(color: YkColors.warning, alpha: 0.2, size: 320),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Padding(
                    padding: EdgeInsets.all(YkSpacing.lg),
                    child: isCompact ? _buildCompactLayout(context) : _buildWideLayout(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        SizedBox(height: 420, child: _buildPageView(context)),
        SizedBox(height: YkSpacing.md),
        _buildIndicator(context),
        const Spacer(),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue sur Yéki',
                style: YkTypography.display(context).copyWith(color: YkColors.textPrimary(context)),
              ),
              SizedBox(height: YkSpacing.sm),
              Text(
                "Votre écosystème d'apprentissage intelligent.",
                style: YkTypography.bodyLg(context).copyWith(color: YkColors.textSecondary(context)),
              ),
              SizedBox(height: YkSpacing.lg),
              _buildIndicator(context),
            ],
          ),
        ),
        SizedBox(width: YkSpacing.xl),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 440, child: _buildPageView(context)),
              SizedBox(height: YkSpacing.lg),
              _buildFooter(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageView(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => _currentPage.value = index,
      itemCount: _kSlides.length,
      itemBuilder: (context, index) {
        final slide = _kSlides[index];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: YkSpacing.xs),
          child: YkCard(
            variant: YkCardVariant.glass,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: YkColors.accent(context).withValues(alpha: 0.12),
                  child: Icon(slide.icon, size: 56, color: YkColors.accent(context)),
                ),
                SizedBox(height: YkSpacing.lg),
                Text(
                  slide.title,
                  style: YkTypography.h2(context).copyWith(color: YkColors.textPrimary(context)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: YkSpacing.xs),
                Text(
                  slide.description,
                  style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicator(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPage,
      builder: (context, current, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _kSlides.length; i++)
              AnimatedContainer(
                duration: YkMotion.fast,
                margin: EdgeInsets.symmetric(horizontal: YkSpacing.xxs),
                width: i == current ? 24 : 8,
                height: 8,
                child: Material(
                  color: i == current ? YkColors.accent(context) : YkColors.border(context),
                  borderRadius: BorderRadius.circular(YkRadius.full),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPage,
      builder: (context, current, _) {
        final isLast = current == _kSlides.length - 1;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            YkButton(label: 'Passer', variant: YkButtonVariant.ghost, onPressed: _terminer),
            YkButton(label: isLast ? 'Commencer' : 'Suivant', onPressed: isLast ? _terminer : _suivant),
          ],
        );
      },
    );
  }
}
