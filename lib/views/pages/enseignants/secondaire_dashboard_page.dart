// lib/views/pages/enseignants/secondaire_dashboard_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// ENSEIGNANT SECONDAIRE DASHBOARD — VERSION COMPLÈTE CORRIGÉE
// Navigation: Cours → DetailCoursEnseignantPage
// Design responsive et fonctionnel
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MODÈLE DE COURS POUR ENSEIGNANT SECONDAIRE
// ═══════════════════════════════════════════════════════════════════════════

class SecondaireCours {
  final int id;
  final String titre;
  final String niveau;
  final String? description;
  final String colorCode;
  final String iconName;
  final int nbLecons;
  final int nbDevoirs;
  final int nbApprenants;
  final double tauxCompletion;
  final String? departementNom;
  final Map<String, dynamic>? enseignantPrincipal;

  SecondaireCours({
    required this.id,
    required this.titre,
    required this.niveau,
    this.description,
    this.colorCode = '#2884A0',
    this.iconName = 'school',
    this.nbLecons = 0,
    this.nbDevoirs = 0,
    this.nbApprenants = 0,
    this.tauxCompletion = 0.0,
    this.departementNom,
    this.enseignantPrincipal,
  });

  factory SecondaireCours.fromJson(Map<String, dynamic> json) {
    return SecondaireCours(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      niveau: json['niveau'] as String? ?? '',
      description: json['description_brief'] as String?,
      colorCode: json['color_code'] as String? ?? '#2884A0',
      iconName: json['icon_name'] as String? ?? 'school',
      nbLecons: json['nb_lecons'] as int? ?? 0,
      nbDevoirs: json['nb_devoirs'] as int? ?? 0,
      nbApprenants: json['nb_apprenants'] as int? ?? 0,
      tauxCompletion: (json['taux_completion'] as num? ?? 0).toDouble(),
      departementNom: json['departement'] != null && json['departement'] is Map
          ? json['departement']['nom'] as String?
          : json['departement_nom'] as String?,
      enseignantPrincipal: json['enseignant_principal'] as Map<String, dynamic>?,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ═══════════════════════════════════════════════════════════════════════════

class SecondaireDashboardPage extends StatefulWidget {
  const SecondaireDashboardPage({super.key});

  @override
  State<SecondaireDashboardPage> createState() => _SecondaireDashboardPageState();
}

class _SecondaireDashboardPageState extends State<SecondaireDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<SecondaireCours> _cours = [];
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── AUTHENTIFICATION ────────────────────────────────────────────────
  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  // ─── CHARGEMENT ──────────────────────────────────────────────────────
  Future<void> _charger() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      ErrorHandler.showError(context, 'Veuillez vous reconnecter');
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(ApiConstants.enseignantDashboard),
        headers: ApiHeaders.auth(token),
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _stats = data['stats'] != null 
              ? Map<String, dynamic>.from(data['stats']) 
              : {};
          
          final coursData = data['cours'] != null ? List.from(data['cours']) : [];
          _cours = coursData.map((c) => SecondaireCours.fromJson(c)).toList();
          _loading = false;
        });
      } else if (res.statusCode == 403 && mounted) {
        setState(() => _loading = false);
        ErrorHandler.showError(context, 'Accès non autorisé');
      } else {
        if (mounted) {
          setState(() => _loading = false);
          ErrorHandler.showError(context, 'Erreur chargement (${res.statusCode})');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorHandler.showError(context, 'Erreur réseau: $e');
      }
    }
  }

  // ─── NAVIGATION ──────────────────────────────────────────────────────
  void _ouvrirDetailCours(SecondaireCours cours) {
    final Color courseColor = _hexColor(cours.colorCode);
    
    context.pushNamed(
      AppRoute.coursDetailEnseignant,
      pathParameters: {'coursId': cours.id.toString()},
      queryParameters: {
        'titre': cours.titre,
        'estEnseignantPrincipal': 'false',
        'courseColor': courseColor.value.toString(),
      },
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────
  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return YekiColors.primaryDark;
    }
  }

  IconData _getIconForCours(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'school':
        return Icons.school_rounded;
      case 'book':
        return Icons.book_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'history':
        return Icons.history_rounded;
      case 'math':
        return Icons.calculate_rounded;
      case 'language':
        return Icons.translate_rounded;
      case 'computer':
        return Icons.computer_rounded;
      case 'art':
        return Icons.art_track_rounded;
      case 'music':
        return Icons.music_note_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.bgLight,
      body: _loading
          ? const Center(child: YekiLoader())
          : NestedScrollView(
              headerSliverBuilder: (_, _) => [
                _buildTabBar(),
              ],
              body: TabBarView(
                controller: _tabCtrl,
                children: [
                  _tabCours(),
                  _tabStats(),
                ],
              ),
            ),
    );
  }

  // ─── TAB BAR ──────────────────────────────────────────────────────────
  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          labelColor: YekiColors.primaryDark,
          unselectedLabelColor: YekiColors.textLight,
          indicatorColor: YekiColors.primaryDark,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Mes Cours'),
            Tab(text: 'Statistiques'),
          ],
        ),
        backgroundColor: YekiColors.white,
      ),
    );
  }

  // ─── TAB 1 : COURS ────────────────────────────────────────────────────
  Widget _tabCours() {
    if (_cours.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: YekiColors.primaryDark.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(Icons.school_outlined, size: 48, color: YekiColors.primaryDark),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun cours assigné',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les cours vous seront attribués par votre cadre',
              style: TextStyle(fontSize: 13, color: YekiColors.textMedium),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primaryDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cours.length,
        itemBuilder: (_, index) => _buildCoursCard(_cours[index]),
      ),
    );
  }

  Widget _buildCoursCard(SecondaireCours cours) {
    final Color courseColor = _hexColor(cours.colorCode);
    final bool hasProgress = cours.tauxCompletion > 0;

    return GestureDetector(
      onTap: () => _ouvrirDetailCours(cours),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YekiColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              decoration: BoxDecoration(
                color: courseColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: courseColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: courseColor.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Icon(
                      _getIconForCours(cours.iconName),
                      color: courseColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cours.titre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: YekiColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          cours.niveau,
                          style: const TextStyle(
                            fontSize: 12,
                            color: YekiColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge "Associé"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: YekiColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Assistant',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: YekiColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Statistiques
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statChip(Icons.article_rounded, '${cours.nbLecons} leçons', YekiColors.info),
                      const SizedBox(width: 8),
                      _statChip(Icons.assignment_rounded, '${cours.nbDevoirs} devoirs', YekiColors.warning),
                      const SizedBox(width: 8),
                      _statChip(Icons.people_rounded, '${cours.nbApprenants} apprenants', YekiColors.success),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: courseColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.touch_app, size: 12, color: YekiColors.textLight),
                            const SizedBox(width: 4),
                            const Text(
                              'Détails',
                              style: TextStyle(
                                fontSize: 10,
                                color: YekiColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Progression
                  if (hasProgress) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: cours.tauxCompletion / 100,
                              backgroundColor: YekiColors.borderLight,
                              color: courseColor,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${cours.tauxCompletion.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: courseColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Taux de complétion',
                      style: TextStyle(fontSize: 11, color: YekiColors.textLight),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),

            // Département
            if (cours.departementNom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.domain_rounded, size: 12, color: YekiColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      'Département: ${cours.departementNom}',
                      style: const TextStyle(fontSize: 11, color: YekiColors.textLight),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );

  // ─── TAB 2 : STATISTIQUES ─────────────────────────────────────────────
  Widget _tabStats() {
    final nbCours = _stats['nb_cours'] ?? _cours.length;
    final nbApprenants = _stats['nb_apprenants'] ?? 0;
    final nbLecons = _stats['nb_lecons'] ?? 0;
    final nbDevoirs = _stats['nb_devoirs'] ?? 0;

    final items = [
      _StatItem('Cours assignés', nbCours.toString(), Icons.book_outlined, YekiColors.primaryDark),
      _StatItem('Apprenants', nbApprenants.toString(), Icons.people_outline, YekiColors.success),
      _StatItem('Leçons', nbLecons.toString(), Icons.article_outlined, YekiColors.info),
      _StatItem('Devoirs', nbDevoirs.toString(), Icons.assignment_outlined, YekiColors.warning),
    ];

    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primaryDark,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: items.map((i) => _buildStatCard(i)).toList(),
            ),
            const SizedBox(height: 24),
            _buildCoursListStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.color.withValues(alpha: 0.2), width: 0.8),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoursListStats() {
    if (_cours.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YekiColors.borderLight, width: 1),
        ),
        child: const Center(
          child: Text(
            'Aucun cours assigné',
            style: TextStyle(color: YekiColors.textMedium),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détail des cours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: YekiColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._cours.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: YekiColors.bgLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: YekiColors.borderLight, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _hexColor(c.colorCode),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.titre,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: YekiColors.textDark,
                        ),
                      ),
                      Text(
                        '${c.nbLecons} leçons · ${c.nbDevoirs} devoirs · ${c.nbApprenants} apprenants',
                        style: const TextStyle(
                          fontSize: 11,
                          color: YekiColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _ouvrirDetailCours(c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: YekiColors.primaryDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Voir',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: YekiColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLASSES AUXILIAIRES
// ═══════════════════════════════════════════════════════════════════════════

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  const _TabBarDelegate(this.tabBar, {this.backgroundColor = YekiColors.white});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) =>
      Container(color: backgroundColor, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => old.tabBar != tabBar;
}