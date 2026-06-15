// lib/views/pages/onboarding.dart
// ═══════════════════════════════════════════════════════════════════════════
// PAGE D'ONBOARDING — CORRIGÉE AVEC DESIGN SYSTEM GLOBAL
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:yeki/main.dart';
import 'package:yeki/core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Apprenez à votre rythme',
      'desc': 'Des cours captivants, interactifs et adaptés à tous les niveaux pour booster vos compétences.',
      'image': 'assets/images/onboard1.png',
    },
    {
      'title': 'Préparez vos concours',
      'desc': 'Un espace dédié aux concours nationaux et internationaux pour maximiser vos chances de réussite.',
      'image': 'assets/images/onboard2.png',
    },
    {
      'title': 'Collaborez et discutez',
      'desc': 'Participez à des forums d\'échanges avec enseignants et camarades, partout et à tout moment.',
      'image': 'assets/images/onboard3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.primaryDark,
      body: Stack(
        children: [
          // ÉLÉMENTS DÉCORATIFS (Cercles subtils)
          Positioned(
            top: -100,
            right: -100,
            child: _buildCircle(300, YekiColors.white.withValues(alpha: 0.03)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildCircle(200, YekiColors.accent.withValues(alpha: 0.05)),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) => _buildPage(_pages[index]),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'YEKI',
            style: TextStyle(
              color: YekiColors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontSize: 20,
            ),
          ),
          TextButton(
            onPressed: () => YekiAuth.finishOnboarding(context),
            style: TextButton.styleFrom(
              foregroundColor: YekiColors.white.withValues(alpha: 0.5),
            ),
            child: const Text(
              'Passer',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, String> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration avec Glassmorphism
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: YekiColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: YekiColors.white.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      data['image']!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.auto_awesome_motion,
                        size: 80,
                        color: YekiColors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: YekiColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              data['desc']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: YekiColors.white.withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final bool isLastPage = _currentPage == _pages.length - 1;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicateurs de progression épurés
          Row(
            children: List.generate(_pages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                width: index == _currentPage ? 28 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? YekiColors.accent
                      : YekiColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          // Bouton d'action
          GestureDetector(
            onTap: () {
              if (!isLastPage) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutQuart,
                );
              } else {
                YekiAuth.finishOnboarding(context);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: isLastPage ? 28 : 20,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: YekiColors.accent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: YekiColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLastPage) ...[
                    const Text(
                      'Démarrer',
                      style: TextStyle(
                        color: YekiColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: YekiColors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}