import 'package:flutter/material.dart';
import 'cursus_page.dart';
import 'concours_page.dart';
import 'devoirs_page.dart';
import 'profil_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    CursusPage(),
    ConcoursPage(),
    DevoirsPage(),
    ProfilPage(),
  ];

  final List<IconData> _icons = [
    Icons.menu_book_rounded,
    Icons.emoji_events_rounded,
    Icons.assignment_rounded,
    Icons.person_rounded,
  ];

  final List<String> _labels = [
    'Cursus',
    'Prépa',
    'Devoirs',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        height: 58,
        decoration: BoxDecoration(
          /*gradient: const LinearGradient(
            colors: [Color(0xFFE6F2F2), Color(0xFFFAF3EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),*/
          border: Border(
            top: BorderSide(
              width: 0.25,
              color: Colors.teal.withOpacity(0.4),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xff3498db),
          unselectedItemColor: Color(0xff404040).withOpacity(0.6),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          onTap: (index) => setState(() => _currentIndex = index),
          items: List.generate(_icons.length, (index) {
            final isSelected = _currentIndex == index;
            return BottomNavigationBarItem(
              icon: Icon(
                _icons[index],
                size: isSelected ? 26 : 22,
              ),
              label: _labels[index],
            );
          }),
        ),
      ),
    );
  }
}
