// lib/features/onboarding/presentation/onboarding_page.dart
//
// Écran de bienvenue affiché au premier lancement (avant la connexion), et
// rejouable depuis Paramètres. Refonte : logo YEKI en haut, les trois
// illustrations du projet (`assets/images/onboard1..3.png`, déclarées mais
// jamais utilisées jusqu'ici), un message court par écran, un seul bouton
// principal. Le dernier écran propose « Créer un compte » et « J'ai déjà un
// compte ».
//
// Toujours sur fond clair (comme avant : `onboardingGradient`), donc couleurs
// de texte fixes plutôt que celles du thème. `lib/features/` interdit
// `setState` (règle 7 de check_design_system.sh) : l'écran actif est piloté
// par un `ValueNotifier<int>`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/router/route_names.dart';

class _Ecran {
  const _Ecran({required this.image, required this.titre, required this.texte});

  final String image;
  final String titre;
  final String texte;
}

const List<_Ecran> _kEcrans = [
  _Ecran(
    image: 'assets/images/onboard1.png',
    titre: 'Bienvenue sur Yéki',
    texte:
        "La plateforme d'apprentissage pensée pour les élèves camerounais : tous vos cours au même endroit, à votre rythme.",
  ),
  _Ecran(
    image: 'assets/images/onboard2.png',
    titre: 'Exercez-vous et progressez',
    texte:
        'Exercices corrigés, devoirs et olympiades : mesurez vos progrès et comparez-vous à votre département.',
  ),
  _Ecran(
    image: 'assets/images/onboard3.png',
    titre: 'Jamais seul pour apprendre',
    texte: 'Posez vos questions sur le forum, échangez avec vos enseignants et faites-vous aider par Yéki IA.',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _ecranActif = ValueNotifier(0);

  @override
  void dispose() {
    _pageController.dispose();
    _ecranActif.dispose();
    super.dispose();
  }

  /// Un utilisateur déjà connecté qui rejoue l'onboarding depuis Paramètres
  /// revient simplement en arrière ; sinon l'onboarding est marqué comme vu
  /// puis l'utilisateur part vers [destination].
  Future<void> _terminer(String destination) async {
    if (authState.value.isAuthenticated) {
      if (mounted) context.pop();
      return;
    }
    await authState.finishOnboarding();
    if (mounted) context.goNamed(destination);
  }

  void _suivant() {
    _pageController.nextPage(duration: YkMotion.normal, curve: YkMotion.normalCurve);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.neutral0,
      body: YkGradientBackground(
        gradient: YkColors.onboardingGradient,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: EdgeInsets.fromLTRB(YkSpacing.lg, YkSpacing.sm, YkSpacing.lg, YkSpacing.lg),
                child: ValueListenableBuilder<int>(
                  valueListenable: _ecranActif,
                  builder: (context, actif, _) {
                    final dernier = actif == _kEcrans.length - 1;
                    return Column(
                      children: [
                        _buildHaut(dernier),
                        Expanded(child: _buildEcrans()),
                        SizedBox(height: YkSpacing.md),
                        _buildIndicateur(actif),
                        SizedBox(height: YkSpacing.lg),
                        _buildActions(dernier),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHaut(bool dernier) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const YkBrandLogo(size: 34, nameColor: YkColors.primary700),
          const Spacer(),
          if (!dernier)
            TextButton(
              onPressed: () => _terminer(AppRoute.login),
              style: TextButton.styleFrom(foregroundColor: YkColors.neutral600),
              child: const Text('Passer'),
            ),
        ],
      ),
    );
  }

  Widget _buildEcrans() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => _ecranActif.value = index,
      itemCount: _kEcrans.length,
      itemBuilder: (context, index) {
        final ecran = _kEcrans[index];
        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, contraintes) {
                  final cote = contraintes.biggest.shortestSide;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      YkRadialGlow(color: YkColors.primary300, alpha: 0.35, size: cote * 0.95),
                      Padding(
                        padding: EdgeInsets.all(YkSpacing.sm),
                        child: Image.asset(
                          ecran.image,
                          fit: BoxFit.contain,
                          cacheWidth: 900,
                          semanticLabel: ecran.titre,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: YkSpacing.md),
            Text(
              ecran.titre,
              textAlign: TextAlign.center,
              style: YkTypography.h1(context).copyWith(color: YkColors.neutral900),
            ),
            SizedBox(height: YkSpacing.sm),
            Text(
              ecran.texte,
              textAlign: TextAlign.center,
              style: YkTypography.bodyLg(context).copyWith(color: YkColors.neutral600),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIndicateur(int actif) {
    return Semantics(
      label: 'Écran ${actif + 1} sur ${_kEcrans.length}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _kEcrans.length; i++)
            AnimatedContainer(
              duration: YkMotion.fast,
              margin: EdgeInsets.symmetric(horizontal: YkSpacing.xxs),
              width: i == actif ? 28 : 8,
              height: 8,
              child: Material(
                color: i == actif ? YkColors.primary700 : YkColors.primary100,
                borderRadius: BorderRadius.circular(YkRadius.full),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(bool dernier) {
    final rejoue = authState.value.isAuthenticated;
    if (!dernier) {
      return SizedBox(
        width: double.infinity,
        child: YkButton(label: 'Suivant', size: YkButtonSize.lg, onPressed: _suivant),
      );
    }
    if (rejoue) {
      return SizedBox(
        width: double.infinity,
        child: YkButton(label: 'Terminer', size: YkButtonSize.lg, onPressed: () => _terminer(AppRoute.login)),
      );
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: YkButton(
            label: 'Créer un compte',
            size: YkButtonSize.lg,
            onPressed: () => _terminer(AppRoute.register),
          ),
        ),
        SizedBox(height: YkSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: YkButton(
            label: "J'ai déjà un compte",
            variant: YkButtonVariant.secondary,
            size: YkButtonSize.lg,
            onPressed: () => _terminer(AppRoute.login),
          ),
        ),
      ],
    );
  }
}
