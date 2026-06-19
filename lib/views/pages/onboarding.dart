// lib/views/pages/onboarding.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/views/auth/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Réintégration de vos chemins d'images d'origine à la place des émojis
  final List<Map<String, String>> _pages = [
    {
      'title': 'Apprenez à votre rythme',
      'desc': 'Des cours captivants, interactifs et adaptés à tous les niveaux pour booster vos compétences.',
      'image': 'assets/images/onboard1.png', // Remplacez par vos chemins exacts (ex: .png ou .svg)
    },
    {
      'title': 'Préparez vos concours',
      'desc': 'Un espace dédié aux concours nationaux et internationaux pour maximiser vos chances de réussite.',
      'image': 'assets/images/onboard2.png',
    },
    {
      'title': 'Collaborez & Échangez',
      'desc': 'Participez à des forums dynamiques avec des enseignants passionnés et vos pairs à tout moment.',
      'image': 'assets/images/onboard3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = YekiResponsive.isMobile(context);
    final double padding = YekiResponsive.dynamicPadding(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: YekiGradients.mainBackground)),
          
          // Sphères de fond décoratives (effet de profondeur sous le verre)
          Positioned(
            top: -40, 
            right: -40, 
            child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: YekiColors.primaryLight.withValues(alpha: 0.25))),
          ),
          Positioned(
            bottom: -40, 
            left: -40, 
            child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: YekiColors.accent.withValues(alpha: 0.15))),
          ),

          SafeArea(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: YekiResponsive.maxContentWidth(context)),
                padding: EdgeInsets.all(padding),
                child: isMobile ? _buildMobileLayout() : _buildWideLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout Mobile verticalisé
  Widget _buildMobileLayout() {
    return Column(
      children: [
        const Spacer(),
        // Hauteur fixe adaptée aux mobiles pour accueillir l'image + le texte confortablement
        SizedBox(height: 440, child: _buildPageView()),
        const SizedBox(height: 20),
        _buildPageIndicator(),
        const Spacer(),
        _buildFooterButtons(),
      ],
    );
  }

  /// Layout Grande résolution (Tablette & Desktop) horizontalisé
  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bienvenue sur YÉKI", style: YekiTextStyles.h1(context).copyWith(fontSize: 44, color: YekiColors.primaryDark)),
              const SizedBox(height: 16),
              Text("Votre écosystème d'apprentissage intelligent, maintenant parfaitement adapté à votre grand écran.", style: YekiTextStyles.body(context)),
              const SizedBox(height: 32),
              _buildPageIndicator(),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 460, child: _buildPageView()),
              const SizedBox(height: 24),
              _buildFooterButtons(),
            ],
          ),
        ),
      ],
    );
  }

  /// Le carrousel de cartes en verre
  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (idx) => setState(() => _currentPage = idx),
      itemCount: _pages.length,
      itemBuilder: (_, index) {
        final item = _pages[index];
        return YekiGlassCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Zone d'image flexible et sécurisée contre les débordements
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.asset(
                    item['image']!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback visuel élégant si le fichier image est introuvable temporairement
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: YekiColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.image_not_supported_rounded, color: YekiColors.primary, size: 40),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Text(
                      item['title']!, 
                      style: YekiTextStyles.h2(context), 
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item['desc']!, 
                      style: YekiTextStyles.body(context), 
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: YekiResponsive.isMobile(context) ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: List.generate(_pages.length, (index) {
        final isSel = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isSel ? 24 : 8,
          decoration: BoxDecoration(color: isSel ? YekiColors.primary : YekiColors.textLight, borderRadius: BorderRadius.circular(4)),
        );
      }),
    );
  }

  Widget _buildFooterButtons() {
    final isLast = _currentPage == _pages.length - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
          child: const Text('PASSER', style: TextStyle(color: YekiColors.textMedium, fontWeight: FontWeight.bold)),
        ),
        YekiButton(
          label: isLast ? 'COMMENCER' : 'SUIVANT',
          width: 160,
          color: YekiColors.accent,
          onPressed: () {
            if (isLast) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            } else {
              _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic);
            }
          },
        ),
      ],
    );
  }
}