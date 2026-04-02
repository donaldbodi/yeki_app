// lib/views/pages/apprenants/dasboard.dart
import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/concours_pages.dart';
import 'package:yeki/views/pages/apprenants/devoirs_page.dart';
import 'package:yeki/views/pages/apprenants/formations_page.dart';
import 'package:yeki/views/pages/apprenants/olympiades_page.dart';
import 'cursus_page.dart';

const Color _navBlue  = Color(0xFF2884A0);
const Color _navBg    = Color(0xFFF8FAFC);

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animCtrl;

  final List<Widget> _pages = [
    const CursusPage(),
    const ConcoursPage(),
    const FormationsPage(),
    const OlympiadesPage(),
    const DevoirsPage(estEnseignantPrincipal: false),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(Icons.school_rounded,        Icons.school_outlined,        'Cursus'),
    _NavItem(Icons.emoji_events_rounded,  Icons.emoji_events_outlined,  'Prépa'),
    _NavItem(Icons.account_balance_rounded, Icons.account_balance_outlined, 'Formation'),
    _NavItem(Icons.military_tech_rounded, Icons.military_tech_outlined, 'Olympiade'),
    _NavItem(Icons.edit_note_rounded,     Icons.edit_note_outlined,     'Devoirs'),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    _animCtrl.forward(from: 0);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: _navBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0), end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _navBlue.withOpacity(0.12),
            blurRadius: 30, offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _navBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.iconFilled : item.iconOutlined,
                key: ValueKey(isSelected),
                color: isSelected ? _navBlue : Colors.grey.shade400,
                size: isSelected ? 22 : 20,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: _navBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
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
