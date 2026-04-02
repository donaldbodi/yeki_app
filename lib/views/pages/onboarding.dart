import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:yeki/main.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _ctrl = PageController();
  int _current = 0;

  // Palette : Ta couleur + Couleur chaude contrastée
  static const Color mainBlue = Color(0xFF2884A0); 
  static const Color darkBlue = Color(0xFF164A5A); // Version sombre pour le dégradé
  static const Color accentWarm = Color(0xFFF39C12); // Orange chaud pour les boutons

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
      body: Container(
        // Dégradé utilisant ta couleur principale
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [mainBlue, darkBlue],
          ),
        ),
        child: Stack(
          children: [
            // Effet de grain ou halo pour la texture
            Positioned(
              bottom: -50,
              right: -50,
              child: CircleAvatar(
                radius: 150,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: PageView.builder(
                      controller: _ctrl,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemCount: _pages.length,
                      itemBuilder: (context, i) => _buildPage(_pages[i]),
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('YEKI', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18)),
          TextButton(
            onPressed: () => YekiAuth.finishOnboarding(context),
            child: Text('Passer', 
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
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
          // Illustration avec bordure fine et légère ombre
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                data['image']!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.auto_awesome_motion, size: 80, color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            data['desc']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    bool isLast = _current == _pages.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicateurs blancs pour le contraste sur fond bleu
          Row(
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 8),
              width: i == _current ? 24 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: i == _current ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
          ),

          // Bouton avec la couleur CHAUDE (Orange/Ambre)
          GestureDetector(
            onTap: () {
              if (!isLast) {
                _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
              } else {
                YekiAuth.finishOnboarding(context);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: isLast ? 24 : 16, vertical: 16),
              decoration: BoxDecoration(
                color: accentWarm,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: accentWarm.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  if (isLast) ...[
                    const Text('Commencer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 10),
                  ],
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}