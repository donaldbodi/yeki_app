import 'package:flutter/material.dart';
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
      'desc': 'Des cours captivants et adaptés à tous les niveaux.',
      'image': 'assets/images/onboard1.png',
    },
    {
      'title': 'Préparez vos concours',
      'desc': 'Un espace dédié aux concours nationaux et internationaux.',
      'image': 'assets/images/onboard2.png',
    },
    {
      'title': 'Collaborez et discutez',
      'desc': 'Participez à des forums d’échange avec enseignants et pairs.',
      'image': 'assets/images/onboard3.png',
    },
  ];

  void _onNext() {
    if (_currentPage < _onboardData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    /*const SizedBox(height: 30),

                    // Logo animé
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: 1.0,
                      child: Image.asset(
                        'assets/images/yeki_logo.png',
                        height: 65,
                      ),
                    ),

                    const SizedBox(height: 30),*/

                    // PageView
                    SizedBox(
                      height: 420,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentPage = index),
                        itemCount: _onboardData.length,
                        itemBuilder: (context, index) {
                          final item = _onboardData[index];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(item['image']!, height: 250),
                              const SizedBox(height: 40),
                              Text(
                                item['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008080),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                item['desc']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardData.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFFFF5722)
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Bouton Suivant / Commencer
                    ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008080),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50), // ✨ Coin modéré
                          side: const BorderSide(
                            color: Color(0xFFd0d0d0), // ✨ Gris clair comme Facebook
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Text(
                        _currentPage == _onboardData.length - 1 ? "Commencer" : "Suivant",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
