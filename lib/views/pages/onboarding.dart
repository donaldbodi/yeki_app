import 'package:flutter/material.dart';
import 'dart:ui';
import '../auth/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Définition de la nouvelle palette basée sur #1958AF
  static const Color mainColor = Color(0xFF3271C8);
  static const Color darkVariant = Color(0xFF1958AF);//172039
  static const Color lightVariant = Color(0xFF9CA7D7);

  final List<Map<String, String>> _onboardData = [
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
      'desc': 'Participez à des forums d’échanges avec enseignants et camarades, partout et à tout moment.',
      'image': 'assets/images/onboard3.png',
    },
  ];

  void _onNext() {
    if (_currentPage < _onboardData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutQuart,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildAnimatedBackground(size),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      "Passer",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _onboardData.length,
                    itemBuilder: (context, index) {
                      return _buildPageContent(index, size);
                    },
                  ),
                ),
                _buildBottomControls(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _currentPage == 0 
            ? [mainColor, darkVariant]
            : _currentPage == 1
                ? [lightVariant, mainColor]
                : [mainColor, const Color(0xFF1F667C)], // Variante plus profonde pour la fin
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: _circle(200, Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: _circle(300, Colors.white.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildPageContent(int index, Size size) {
    final item = _onboardData[index];
    bool isActive = _currentPage == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(bottom: isActive ? 0 : 40),
            height: size.height * 0.35,
            child: Image.asset(item['image']!, fit: BoxFit.contain),
          ),
          const SizedBox(height: 50),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: isActive ? 1 : 0,
            child: Text(
              item['title']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: isActive ? 1 : 0,
            child: Text(
              item['desc']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.85),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    bool isLastPage = _currentPage == _onboardData.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _onboardData.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 60,
            width: isLastPage ? 180 : 60,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: mainColor, // Utilisation de la nouvelle couleur ici
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isLastPage ? 15 : 50),
                ),
                elevation: 10,
                padding: EdgeInsets.zero,
              ),
              child: isLastPage
                  ? const Text(
                      "C'EST PARTI !",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                    )
                  : const Icon(Icons.arrow_forward_ios_rounded, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}