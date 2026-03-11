import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/formations_classiques_pages.dart';
import 'package:yeki/views/pages/apprenants/formations_metier_pages.dart';
import 'dart:ui';

import 'package:yeki/views/pages/apprenants/notifications_page.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';

class FormationsPage extends StatefulWidget {
  const FormationsPage({super.key});

  @override
  State<FormationsPage> createState() => _FormationsPageState();
}

class _FormationsPageState extends State<FormationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _mainTeal   = Color(0xFF2884A0);
  static const Color _tealDark   = Color(0xFF1F5F75);
  static const Color _accent     = Color(0xFFFFB74D);
  static const Color _bg         = Color(0xFFF4F9FB);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  // ... (imports et début de classe inchangés)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: YekiHeader(
        unreadNotifications: 3,
        isSubscribed: true,
        userRole: "Apprenant",
        username: "Donald",
        onNotifications: () {},
        onSettings: () {},
        onLogout: () {},
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none, // Indispensable pour laisser dépasser la TabBar
                alignment: Alignment.bottomCenter,
                children: [
                  // 1. Le Header
                  _buildHeader(),
                  
                  // 2. La TabBar positionnée à cheval sur le bord bas
                  Positioned(
                    bottom: -25, // La moitié de la hauteur de la TabBar environ
                    left: 0,
                    right: 0,
                    child: _buildTabBar(),
                  ),
                ],
              ),
            ),
            // On ajoute un petit espace vide (Sliver) pour compenser le dépassement 
            // et éviter que le contenu de la TabBarView ne commence trop haut
            const SliverToBoxAdapter(
              child: SizedBox(height: 35), 
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [
            FormationsClassiquesPage(),
            FormationsMetierPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      // On ajoute du padding en bas pour que le texte ne soit pas caché par la TabBar
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 60), 
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), _tealDark, _mainTeal],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FORMATIONS DISPONIBLES',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Construisez\nvotre avenir.',
            style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1),
          ),
          const SizedBox(height: 12),
          Text(
            'Trouvez le parcours qui vous correspond parmi nos écoles.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final int idx = _tabController.index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _tealDark.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _tab(0, 'Classique', Icons.account_balance_rounded, idx),
          const SizedBox(width: 4),
          _tab(1, 'Métiers', Icons.work_rounded, idx),
        ],
      ),
    );
  }

  Widget _tab(int index, String label, IconData icon, int currentIdx) {
    final isSelected = currentIdx == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _mainTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : _mainTeal.withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : _mainTeal.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}