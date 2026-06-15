// lib/views/pages/apprenants/dashboard.dart
// ═══════════════════════════════════════════════════════════════════════════
//  DASHBOARD PRINCIPAL — CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/concours_pages.dart';
import 'package:yeki/views/pages/apprenants/devoirs_page.dart';
import 'package:yeki/views/pages/apprenants/formations_pages.dart';
import 'package:yeki/views/pages/apprenants/olympiades_page.dart';
import 'package:yeki/views/pages/apprenants/cursus_page.dart';
import 'package:yeki/core/theme/app_theme.dart';

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
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBody: true,
      backgroundColor: YekiColors.backgroundLight,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildFloatingNavBar(screenWidth),
    );
  }

  Widget _buildFloatingNavBar(double screenWidth) {
    final double targetWidth = screenWidth > 600 ? 500 : screenWidth - 32;
    final double bottomMargin = screenWidth > 600 ? 24 : 16;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: bottomMargin),
        width: targetWidth,
        height: 66,
        child: ClipRRect(
          borderRadius: YekiRadius.borderRadiusPill,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: YekiColors.white.withValues(alpha: 0.85),
                borderRadius: YekiRadius.borderRadiusPill,
                border: Border.all(color: YekiColors.borderLight, width: 1.0),
                boxShadow: YekiShadows.floating,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (i) => _buildNavTile(i)),
              ),
            ),
          ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? YekiColors.primaryDark.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: YekiRadius.borderRadiusLg,
              ),
              child: Icon(
                isSelected ? item.iconFilled : item.iconOutlined,
                color: isSelected ? YekiColors.primaryDark : YekiColors.textLight,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? YekiColors.primaryDark : YekiColors.textLight,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: isSelected ? 0.1 : 0,
              ),
              child: Text(item.label),
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