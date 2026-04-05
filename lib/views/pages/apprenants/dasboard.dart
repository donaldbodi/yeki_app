import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/concours_pages.dart';
import 'package:yeki/views/pages/apprenants/devoirs_page.dart';
import 'package:yeki/views/pages/apprenants/formations_pages.dart';
import 'package:yeki/views/pages/apprenants/olympiades_page.dart';
import 'cursus_page.dart';

// Palette de couleurs raffinée
const Color brandPrimary = Color(0xFF135F74); 
const Color bgLight = Color(0xFFF8FAFC); 
const Color inactiveGrey = Color(0xFF94A3B8);
const Color white = Color(0xFFFFFFFF);

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CursusPage(),
    const ConcoursPage(),
    const FormationsPage(),
    const OlympiadesPage(),
    const DevoirsPage(estEnseignantPrincipal: false),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(Icons.school_rounded, Icons.school_outlined, 'Cursus'),
    _NavItem(Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Prépa'),
    _NavItem(Icons.account_balance_rounded, Icons.account_balance_outlined, 'Formation'),
    _NavItem(Icons.military_tech_rounded, Icons.military_tech_outlined, 'Olympiade'),
    _NavItem(Icons.edit_note_rounded, Icons.edit_note_outlined, 'Devoirs'),
  ];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      backgroundColor: bgLight,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      height: 70, // Hauteur légèrement augmentée pour le confort visuel
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          // Ombre principale portée
          BoxShadow(
            color: brandPrimary.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          // Lueur interne très subtile
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (i) => _buildNavTile(i)),
        ),
      ),
    );
  }

  Widget _buildNavTile(int index) {
    final item = _navItems[index];
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            // Background pour l'onglet courant (Pilule)
            color: isSelected ? brandPrimary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? item.iconFilled : item.iconOutlined,
                color: isSelected ? brandPrimary : inactiveGrey,
                size: 24, // Taille d'icône premium
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? brandPrimary : inactiveGrey,
                  fontSize: 11, // Police agrandie
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData iconFilled, iconOutlined;
  final String label;
  const _NavItem(this.iconFilled, this.iconOutlined, this.label);
}