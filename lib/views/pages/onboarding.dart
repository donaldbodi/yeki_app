// Nouvelle version améliorée de OnboardingPage
// (code complet remis à neuf)

import 'package:flutter/material.dart';
import 'package:yeki/views/pages/mise_a_jour.dart';
import '../auth/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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

  @override
  void initState() {
    super.initState();
    UpdateChecker.checkForUpdate(context);
  }

  void _onNext() {
    if (_currentPage < _onboardData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutExpo,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background dégradé haut niveau
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF008080),
                  Color(0xFF00E6E6),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Effet glass blur
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
  colors: [
    Color(0x2200E6E6),
    Color(0x22008080),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
),

              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _onboardData.length,
                    itemBuilder: (context, index) {
                      final item = _onboardData[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedOpacity(
                                opacity: _currentPage == index ? 1 : 0.3,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                                child: SizedBox(
                                  height: 260,
                                  child: Image.asset(item['image']!),
                                ),
                              ),
                              const SizedBox(height: 45),
                              Text(
                                item['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                item['desc']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white.withOpacity(0.85),
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 32 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF008080),
                      elevation: 8,
                      shadowColor: Colors.black26,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _onboardData.length - 1
                              ? "Commencer l'aventure"
                              : "Suivant",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          )
        ],
      ),
    );
  }
}
