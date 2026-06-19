// lib/views/pages/apprenants/dashboard.dart
// ═══════════════════════════════════════════════════════════════════════════
//  DASHBOARD PRINCIPAL — GLASSMORPHISM EDITION
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/concours_pages.dart';
import 'package:yeki/views/pages/apprenants/devoirs_page.dart';
import 'package:yeki/views/pages/apprenants/formations_pages.dart';
import 'package:yeki/views/pages/apprenants/olympiades_page.dart';
import 'package:yeki/views/pages/apprenants/cursus_page.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';

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
    _NavItem(Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Concours'),
    _NavItem(Icons.layers_rounded, Icons.layers_outlined, 'Formations'),
    _NavItem(Icons.star_rounded, Icons.star_outline_rounded, 'Olympiades'),
    _NavItem(Icons.assignment_rounded, Icons.assignment_outlined, 'Devoirs'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: YekiGradients.mainBackground,
        ),
        child: Stack(
          children: [
            // Sphères décoratives de fond
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.primaryLight.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.accent.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              top: 300,
              right: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.gold.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildGlassBottomBar(),
    );
  }

  Widget _buildGlassBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  YekiColors.white.withValues(alpha: 0.75),
                  YekiColors.white.withValues(alpha: 0.50),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: YekiColors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (idx) => _buildBottomNavItem(idx)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int idx) {
    final item = _navItems[idx];
    final bool isSelected = _currentIndex == idx;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = idx),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? YekiColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(
                        color: YekiColors.primary.withValues(alpha: 0.15),
                        width: 1.0,
                      )
                    : null,
              ),
              child: Icon(
                isSelected ? item.iconFilled : item.iconOutlined,
                color: isSelected ? YekiColors.primaryDark : YekiColors.textMedium,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? YekiColors.primaryDark : YekiColors.textMedium,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
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