import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/concours_pages.dart';
import 'package:yeki/views/pages/apprenants/devoirs_page.dart';
import 'package:yeki/views/pages/apprenants/formations_page.dart';
import 'package:yeki/views/pages/apprenants/olympiades_page.dart';
import 'cursus_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F7FA), // fond clair académique
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _pages[_currentIndex],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2884A0).withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,

            selectedItemColor: const Color(0xFF2884A0),
            unselectedItemColor: Colors.grey,

            showSelectedLabels: true,
            showUnselectedLabels: false,

            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              fontFamily: 'FredokaOne',
            ),

            items: [
              _buildNavItem(Icons.school_rounded, 'Cursus', 0),
              _buildNavItem(Icons.emoji_events_rounded, 'Prépa', 1),
              _buildNavItem(Icons.account_balance_rounded, 'Formations', 2),
              _buildNavItem(Icons.military_tech_rounded, 'Olympiade', 3),
              _buildNavItem(Icons.edit_note_rounded, 'Devoirs', 4),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(isSelected ? 10 : 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2884A0).withOpacity(0.12)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: isSelected ? 26 : 22,
          color: isSelected ? const Color(0xFF2884A0) : Colors.grey,
        ),
      ),
      label: label,
    );
  }
}