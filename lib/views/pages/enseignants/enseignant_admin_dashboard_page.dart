// lib/views/pages/enseignants/enseignant_admin_dashboard_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// ENSEIGNANT ADMIN DASHBOARD — VERSION COMPLÈTE CORRIGÉE
// Navigation: Département → Cours → DetailCoursEnseignantPage
// Design responsive et fonctionnel
// Toutes les erreurs Dart résolues
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/formation_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PAGE DE DÉTAIL DÉPARTEMENT — Pour enseignant admin
// ═══════════════════════════════════════════════════════════════════════════

class AdminDepartementDetailPage extends StatefulWidget {
  final int departementId;
  final String departementNom;
  final String parcoursNom;
  final Map<String, dynamic>? departementData;

  const AdminDepartementDetailPage({
    super.key,
    required this.departementId,
    required this.departementNom,
    required this.parcoursNom,
    this.departementData,
  });

  @override
  State<AdminDepartementDetailPage> createState() => _AdminDepartementDetailPageState();
}

class _AdminDepartementDetailPageState extends State<AdminDepartementDetailPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _cours = [];
  Map<String, dynamic> _stats = {};

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    final token = await _getToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/departements/${widget.departementId}/cours/'),
        headers: ApiHeaders.auth(token),
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _cours = List<Map<String, dynamic>>.from(data);
          _stats = {
            'nb_cours': _cours.length,
            'nb_apprenants': _cours.fold<double>(0, (sum, c) => sum + ((c['nb_apprenants'] ?? 0) as num).toDouble()).toInt(),
            'taux_moyen': _cours.isEmpty ? 0.0 : _cours.fold<double>(0, (sum, c) => sum + ((c['taux_completion'] ?? 0.0) as num).toDouble()) / _cours.length,
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      ErrorHandler.showError(context, 'Erreur de chargement: $e');
    }
  }

  void _ouvrirDetailCours(Map<String, dynamic> cours) {
    final colorHex = (cours['color_code'] as String? ?? '#008080').replaceAll('#', '');
    Color coursColor;
    try {
      coursColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      coursColor = YekiColors.primary;
    }

    context.pushNamed(
      AppRoute.coursDetailEnseignant,
      pathParameters: {'coursId': cours['id'].toString()},
      queryParameters: {
        'titre': (cours['titre'] ?? 'Sans titre') as String,
        'estEnseignantPrincipal': 'false',
        'courseColor': coursColor.value.toString(),
      },
    );
  }

  Color _getCoursColor(Map<String, dynamic> cours) {
    final hex = (cours['color_code'] as String? ?? '#008080').replaceAll('#', '');
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return YekiColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.bgLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.departementNom,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark),
            ),
            Text(
              '${widget.parcoursNom} · ${_stats['nb_cours']} cours',
              style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
            ),
          ],
        ),
        backgroundColor: YekiColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: YekiColors.primary),
            onPressed: _charger,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: YekiLoader())
          : RefreshIndicator(
              onRefresh: _charger,
              color: YekiColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Statistiques
                    _buildStatsCard(),
                    const SizedBox(height: 16),

                    // Liste des cours
                    if (_cours.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: YekiColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: YekiColors.primary.withValues(alpha: 0.2), width: 1),
                                ),
                                child: const Icon(Icons.book_outlined, size: 48, color: YekiColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Aucun cours dans ce département',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._cours.map((c) => _buildCoursCard(c)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    final tauxMoyen = _stats['taux_moyen'] ?? 0.0;
    final nbCours = _stats['nb_cours'] ?? 0;
    final nbApprenants = _stats['nb_apprenants'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [YekiColors.primary, YekiColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques du département',
            style: TextStyle(color: YekiColors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statItem('$nbCours', 'Cours', Icons.book_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _statItem('$nbApprenants', 'Apprenants', Icons.people_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _statItem('${tauxMoyen.toStringAsFixed(0)}%', 'Taux', Icons.bar_chart_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: YekiColors.white.withValues(alpha: 0.7), size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(color: YekiColors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(color: YekiColors.white.withValues(alpha: 0.7), fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCoursCard(Map<String, dynamic> cours) {
    final color = _getCoursColor(cours);
    final taux = (cours['taux_completion'] as num?)?.toDouble() ?? 0.0;
    final nbApp = cours['nb_apprenants'] ?? 0;
    final nbLecons = cours['nb_lecons'] ?? 0;
    final nbDevoirs = cours['nb_devoirs'] ?? 0;

    return GestureDetector(
      onTap: () => _ouvrirDetailCours(cours),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YekiColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Icon(Icons.book, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cours['titre'] ?? 'Sans titre',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: YekiColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${cours['niveau'] ?? 'Niveau non spécifié'}',
                          style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 14),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _chip(Icons.people_rounded, '$nbApp apprenants', YekiColors.success),
                  _chip(Icons.article_rounded, '$nbLecons leçons', YekiColors.info),
                  _chip(Icons.assignment_rounded, '$nbDevoirs devoirs', YekiColors.warning),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        backgroundColor: YekiColors.borderLight,
                        color: color,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${taux.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
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
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENSEIGNANT ADMIN DASHBOARD — PAGE PRINCIPALE
// ═══════════════════════════════════════════════════════════════════════════

class EnseignantAdminDashboardPage extends StatefulWidget {
  const EnseignantAdminDashboardPage({super.key});

  @override
  State<EnseignantAdminDashboardPage> createState() =>
      _EnseignantAdminDashboardPageState();
}

class _EnseignantAdminDashboardPageState
    extends State<EnseignantAdminDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _stats = {};
  List _departements = [];
  List _cadres = [];
  String _nomParcours = '';
  int _idParcours = 0;
  String _typeParcours = 'cursus';

  late TabController _tabCtrl;
  bool _mounted = true;

  List<String> get _typeDeptOptions {
    switch (_typeParcours) {
      case 'prepa': return ['concours'];
      case 'formation': return ['classique', 'metier'];
      case 'olympiade': return ['normal'];
      default: return ['normal'];
    }
  }

  // ─── INITIALISATION ──────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _mounted = true;
    _tabCtrl = TabController(length: 4, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _mounted = false;
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── CHARGEMENT DES DONNÉES ──────────────────────────────────────────────
  Future<String?> _getToken() async =>
      (await SharedPreferences.getInstance()).getString('token');

  Future<void> _charger() async {
    if (!_mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
    });

    final token = await _getToken();
    if (token == null) {
      if (!_mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'Vous devez être connecté.';
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(ApiConstants.enseignantAdminDashboard),
        headers: ApiHeaders.auth(token),
      );

      if (!_mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _stats = (data['stats'] as Map<String, dynamic>?) ?? {};
          _departements = (data['departements'] as List?) ?? [];
          _cadres = (data['cadres'] as List?) ?? [];
          _idParcours = data['id_parcours'] ?? 0;
          _nomParcours = data['nom_parcours'] ?? '';
          _typeParcours = data['type_parcours'] ?? 'cursus';
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Erreur chargement (${res.statusCode})';
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Erreur réseau: $e';
        });
      }
    }
  }

  Future<List> _chargerTousLesCours() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/cours/'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final cours = data as List;
        final parcoursId = _idParcours;
        return cours.where((c) => c['parcours_id'] == parcoursId).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.bgLight,
      floatingActionButton: _nomParcours.isNotEmpty
          ? FloatingActionButton(
              onPressed: _creerDepartement,
              backgroundColor: YekiColors.primary,
              elevation: 4,
              child: const Icon(Icons.add_rounded, color: YekiColors.white, size: 28),
            )
          : null,
      body: _loading
          ? const Center(child: YekiLoader(size: 40))
          : _hasError
              ? _buildErrorState()
              : NestedScrollView(
                  headerSliverBuilder: (_, _) => [ _buildTabBar()],
                  body: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _tabDepartements(),
                      _tabCadres(),
                      _tabStats(),
                      _tabTousCours(),
                    ],
                  ),
                ),
    );
  }

  // ─── ÉTAT D'ERREUR ──────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 72, color: YekiColors.accent),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: YekiColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _charger,
              style: ElevatedButton.styleFrom(
                backgroundColor: YekiColors.primary,
                foregroundColor: YekiColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(YekiRadius.md),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB BAR ─────────────────────────────────────────────────────────────
  SliverPersistentHeader _buildTabBar() =>
      SliverPersistentHeader(
        pinned: true,
        delegate: _StickyTabBarDelegate(
          TabBar(
            controller: _tabCtrl,
            labelColor: YekiColors.primary,
            unselectedLabelColor: YekiColors.textMedium,
            indicatorColor: YekiColors.primary,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              const Tab(text: 'Départements'),
              const Tab(text: 'Cadres'),
              const Tab(text: 'Statistiques'),
              const Tab(text: 'Tous les cours'),
            ],
          ),
          backgroundColor: YekiColors.white,
        ),
      );

  // ─── TAB 1 : DÉPARTEMENTS ──────────────────────────────────────────────
  Widget _tabDepartements() => RefreshIndicator(
    onRefresh: _charger,
    color: YekiColors.primary,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildParcoursCard(),
        const SizedBox(height: 16),
        if (_departements.isEmpty)
          _buildVideDepartement()
        else
          ..._departements.map((d) => _buildDeptCard(d as Map<String, dynamic>)),
        const SizedBox(height: 80),
      ],
    ),
  );

  Widget _buildParcoursCard() {
    if (_nomParcours.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: YekiColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(YekiRadius.sm),
          border: Border.all(color: YekiColors.warning.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: YekiColors.warning, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucun parcours ne vous est encore assigné.\nContactez l\'administrateur général.',
                style: TextStyle(color: YekiColors.warning, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final typeIcon = {
      'cursus': Icons.school_rounded,
      'prepa': Icons.emoji_events_rounded,
      'formation': Icons.work_rounded,
      'olympiade': Icons.military_tech_rounded,
    }[_typeParcours] ?? Icons.domain_rounded;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [YekiColors.primary, YekiColors.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(YekiRadius.sm),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: YekiColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(YekiRadius.sm),
                ),
                child: Icon(typeIcon, color: YekiColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mon parcours', style: TextStyle(color: YekiColors.white.withValues(alpha: 0.7), fontSize: 12)),
                    Text('Coordonnateur', style: TextStyle(color: YekiColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: YekiColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(YekiRadius.lg),
                ),
                child: Text('${_departements.length} dép.',
                    style: const TextStyle(color: YekiColors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: YekiColors.white.withValues(alpha: 0.24), height: 1),
          const SizedBox(height: 14),
          Text(_nomParcours,
              style: const TextStyle(color: YekiColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _quickStat('${_stats['nb_cours'] ?? 0}', 'cours'),
              const SizedBox(width: 16),
              _quickStat('${_stats['nb_apprenants'] ?? 0}', 'inscrits'),
              const SizedBox(width: 16),
              _quickStat('${_stats['nb_enseignants'] ?? 0}', 'cadres'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickStat(String val, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(val, style: const TextStyle(color: YekiColors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      Text(label, style: TextStyle(color: YekiColors.white.withValues(alpha: 0.7), fontSize: 10)),
    ],
  );

  Widget _buildVideDepartement() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: YekiColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: YekiColors.primary.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(_typeDeptOptions.isNotEmpty
                ? Icons.domain_rounded
                : Icons.school_rounded,
                size: 48, color: YekiColors.primary),
          ),
          const SizedBox(height: 16),
          Text(_typeParcours == 'prepa'
              ? 'Aucun concours créé'
              : _typeParcours == 'formation'
                  ? 'Aucune formation créée'
                  : 'Aucun département créé',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
          const SizedBox(height: 8),
          Text('Commencez par créer votre premier élément',
              style: const TextStyle(fontSize: 13, color: YekiColors.textMedium)),
        ],
      ),
    ),
  );

  Widget _buildDeptCard(Map<String, dynamic> dept) {
    final typeDept = dept['type_dept'] as String? ?? 'normal';
    final prix = dept['prix'] as int? ?? 0;
    final nbCours = dept['nb_cours'] as int? ?? 0;
    final nbIns = dept['nb_inscrits'] as int? ?? 0;
    final cadre = dept['cadre'] as Map?;
    final color = _typeDeptColors[typeDept] ?? YekiColors.primary;
    final icon = _typeDeptIcons[typeDept] ?? Icons.domain_rounded;
    final label = _typeDeptLabels[typeDept] ?? 'Département';
    final niveauFormation = dept['niveau_formation'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(YekiRadius.sm),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(YekiRadius.sm),
        onTap: () => _voirDetailDepartement(dept),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(YekiRadius.sm),
                      border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dept['nom'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: YekiColors.textDark)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _miniChip(label, color),
                            const SizedBox(width: 6),
                            if (prix > 0)
                              _miniChip('$prix FCFA', YekiColors.accent)
                            else
                              _miniChip('Gratuit', YekiColors.success),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(cadre == null ? Icons.person_add_outlined : Icons.swap_horiz,
                        color: color),
                    tooltip: cadre == null ? 'Nommer un cadre' : 'Changer cadre',
                    onPressed: () => _changerCadre(dept),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: YekiColors.primary, size: 18),
                    tooltip: 'Modifier le département',
                    onPressed: () => _modifierDepartement(dept),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (cadre != null)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: YekiColors.purple.withValues(alpha: 0.1),
                      child: Icon(Icons.person, size: 14, color: YekiColors.purple),
                    ),
                    const SizedBox(width: 8),
                    Text('Cadre : ${cadre['nom'] ?? cadre['username'] ?? ''}',
                        style: const TextStyle(fontSize: 12, color: YekiColors.textDark)),
                  ],
                )
              else
                _aucunCadreBadge(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.book_outlined, size: 13, color: YekiColors.textMedium),
                  const SizedBox(width: 4),
                  Text('$nbCours cours', style: const TextStyle(fontSize: 12, color: YekiColors.textMedium)),
                  const SizedBox(width: 12),
                  Icon(Icons.people_outlined, size: 13, color: YekiColors.textMedium),
                  const SizedBox(width: 4),
                  Text('$nbIns inscrits', style: const TextStyle(fontSize: 12, color: YekiColors.textMedium)),
                  const Spacer(),
                  if (typeDept == 'metier' && niveauFormation != null)
                    _miniChip('Niv. $niveauFormation', YekiColors.warning),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(YekiRadius.sm),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _aucunCadreBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: YekiColors.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(YekiRadius.sm),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_outlined, size: 13, color: YekiColors.warning),
        SizedBox(width: 5),
        Text('Aucun cadre nommé', style: TextStyle(fontSize: 11, color: YekiColors.warning)),
      ],
    ),
  );

  // ─── TAB 2 : CADRES ──────────────────────────────────────────────────────
  Widget _tabCadres() {
    if (_cadres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: YekiColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: YekiColors.primary.withValues(alpha: 0.2), width: 1),
              ),
              child: const Icon(Icons.person_outline_rounded, size: 48, color: YekiColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Aucun enseignant cadre',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cadres.length,
        itemBuilder: (_, i) => _buildCadreCard(_cadres[i] as Map),
      ),
    );
  }

  Widget _buildCadreCard(Map cadre) {
    final dept = cadre['departement'] as Map?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(YekiRadius.sm),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: YekiColors.purple.withValues(alpha: 0.1),
              child: Text((cadre['nom'] ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: YekiColors.purple)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cadre['nom'] ?? cadre['username'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: YekiColors.textDark)),
                  if (dept != null)
                    Text(dept['nom'] ?? '',
                        style: const TextStyle(fontSize: 12, color: YekiColors.purple)),
                  Text('${cadre['nb_cours'] ?? 0} cours · ${cadre['nb_apprenants'] ?? 0} apprenants',
                      style: const TextStyle(fontSize: 12, color: YekiColors.textMedium)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 4 : STATISTIQUES ──────────────────────────────────────────────
  Widget _tabStats() {
    final items = [
      _SI('Départements', '${_stats['nb_departements'] ?? _departements.length}', Icons.domain, YekiColors.primary),
      _SI('Cours', '${_stats['nb_cours'] ?? 0}', Icons.book, YekiColors.purple),
      _SI('Inscrits', '${_stats['nb_apprenants'] ?? 0}', Icons.people, YekiColors.primaryDark),
      _SI('Cadres', '${_stats['nb_enseignants'] ?? 0}', Icons.person_outline, YekiColors.warning),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: items.map((item) => Container(
              decoration: BoxDecoration(
                color: YekiColors.white,
                borderRadius: BorderRadius.circular(YekiRadius.sm),
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
                      borderRadius: BorderRadius.circular(YekiRadius.sm),
                      border: Border.all(color: item.color.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.value,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: item.color)),
                      Text(item.label, style: const TextStyle(fontSize: 12, color: YekiColors.textMedium)),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ),
          if (_departements.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.leaderboard, color: YekiColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text('Classement des départements',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: YekiColors.textDark)),
              ],
            ),
            const SizedBox(height: 12),
            ..._departements.asMap().entries.map((e) {
              final i = e.key;
              final d = e.value;
              final taux = (d['taux_moyen'] as num? ?? 0).toDouble();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: YekiColors.white,
                  borderRadius: BorderRadius.circular(YekiRadius.sm),
                  border: Border.all(color: YekiColors.borderLight, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 0 ? YekiColors.accent : i == 1 ? YekiColors.textMedium : YekiColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: YekiColors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(d['nom'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark))),
                    Text('${taux.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: YekiColors.primary)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── TAB 5 : TOUS LES COURS ─────────────────────────────────────────────
  Widget _tabTousCours() {
    return FutureBuilder<List>(
      future: _chargerTousLesCours(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: YekiLoader(size: 40));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: YekiColors.accent),
                const SizedBox(height: 16),
                const Text('Erreur lors du chargement des cours',
                    style: TextStyle(fontSize: 16, color: YekiColors.textDark)),
              ],
            ),
          );
        }
        final cours = snapshot.data ?? [];
        if (cours.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: YekiColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: YekiColors.primary.withValues(alpha: 0.2), width: 1),
                  ),
                  child: const Icon(Icons.book_outlined, size: 48, color: YekiColors.primary),
                ),
                const SizedBox(height: 16),
                const Text('Aucun cours créé dans ce parcours',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _charger,
          color: YekiColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cours.length,
            itemBuilder: (_, i) => _buildCoursCard(cours[i]),
          ),
        );
      },
    );
  }

  Widget _buildCoursCard(Map cours) {
    final colorHex = (cours['color_code'] as String? ?? '#008080').replaceAll('#', '');
    Color coursColor;
    try {
      coursColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      coursColor = YekiColors.primary;
    }

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          AppRoute.coursDetailEnseignant,
          pathParameters: {'coursId': cours['id'].toString()},
          queryParameters: {
            'titre': (cours['titre'] ?? 'Sans titre') as String,
            'estEnseignantPrincipal': 'true',
            'courseColor': coursColor.value.toString(),
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(YekiRadius.sm),
          border: Border.all(color: YekiColors.borderLight, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: coursColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(YekiRadius.sm),
                  border: Border.all(color: coursColor.withValues(alpha: 0.2), width: 0.8),
                ),
                child: Icon(Icons.book, color: coursColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cours['titre'] ?? 'Sans titre',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: YekiColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cours['niveau'] ?? 'Niveau non spécifié'} · ${cours['nb_apprenants'] ?? 0} apprenants',
                      style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                    ),
                    if (cours['departement'] != null)
                      Text(
                        'Département: ${cours['departement']}',
                        style: const TextStyle(fontSize: 11, color: YekiColors.textMedium),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: YekiColors.primary, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MÉTHODES DE NAVIGATION ET ACTIONS ──────────────────────────────────

  void _voirDetailDepartement(Map dept) {
    context.pushNamed(
      AppRoute.coordinationDepartementDetail,
      pathParameters: {'departementId': dept['id'].toString()},
      queryParameters: {
        'departementNom': dept['nom']?.toString() ?? '',
        'parcoursNom': _nomParcours,
      },
      extra: dept,
    );
  }

  // ─── MODIFICATION D'UN DÉPARTEMENT ──────────────────────────────────────
  void _modifierDepartement(Map<String, dynamic> dept) {
    final nomCtrl = TextEditingController(text: dept['nom'] ?? '');
    final descCtrl = TextEditingController(text: dept['description'] ?? '');
    final prixCtrl = TextEditingController(text: (dept['prix'] ?? 0).toString());
    final prixPresentielCtrl = TextEditingController(text: (dept['prix_presentiel'] ?? 0).toString());

    List<String> niveauxSelectionnes = [];
    if (dept['niveaux_accessibles'] != null) {
      final niveaux = dept['niveaux_accessibles'];
      if (niveaux is List) {
        niveauxSelectionnes = List<String>.from(niveaux);
      } else if (niveaux is String) {
        niveauxSelectionnes = niveaux.split(',').map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
      }
    }

    bool estFormationMetier = dept['est_formation_metier'] ?? false;
    bool estFormationClassique = dept['est_formation_classique'] ?? false;
    bool accesRestreint = dept['acces_restreint'] ?? false;
    String mode = dept['mode'] ?? 'hybride';
    String niveauFormation = dept['niveau_formation'] ?? 'debutant';

    final nomConcoursCtrl = TextEditingController(text: dept['nom_concours'] ?? '');
    final organismeCtrl = TextEditingController(text: dept['organisme_concours'] ?? '');
    final dateLimiteCtrl = TextEditingController(text: dept['date_limite_inscription']?.toString() ?? '');
    final dateExamenCtrl = TextEditingController(text: dept['date_examen']?.toString() ?? '');
    final arreteCtrl = TextEditingController(text: dept['arrete_ministeriel'] ?? '');
    final placesCtrl = TextEditingController(text: (dept['places_disponibles'] ?? '').toString());
    final debouchesCtrl = TextEditingController(text: dept['debouches'] ?? '');

    final dureeCtrl = TextEditingController(text: dept['duree_formation'] ?? '');
    final certificatCtrl = TextEditingController(text: dept['certificat_delivre'] ?? '');
    final prerequisCtrl = TextEditingController(text: dept['prerequis'] ?? '');
    final objectifsCtrl = TextEditingController(text: dept['objectifs'] ?? '');
    final domaineCtrl = TextEditingController(text: dept['domaine'] ?? '');
    final villeCtrl = TextEditingController(text: dept['ville'] ?? '');
    bool estCertifiante = dept['est_certifiante'] ?? false;

    List<String> niveauxDisponibles = [];
    bool niveauxCharges = false;

    Future<void> chargerNiveaux() async {
      if (niveauxCharges) return;
      // FormationRepository (fonction canonique unique, P5.4) — gère
      // l'authentification via l'intercepteur Dio, plus de token/headers
      // manuels ici, voir docs/ecarts/register.md.
      try {
        final niveaux = await FormationRepository().niveaux();
        if (mounted) {
          niveauxDisponibles = niveaux;
          niveauxCharges = true;
        }
      } catch (_) {
        if (mounted) {
          niveauxDisponibles = [];
          niveauxCharges = true;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        chargerNiveaux();
        return StatefulBuilder(
          builder: (ctx, setS) {
            // CORRECTION: déclarer isLoading ici, à l'intérieur du StatefulBuilder
            bool isLoading = false;

            return Container(
              decoration: const BoxDecoration(
                color: YekiColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(YekiRadius.lg)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHandle(),
                    const SizedBox(height: 20),
                    Text(
                      'Modifier le département',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text('Parcours : $_nomParcours',
                        style: const TextStyle(fontSize: 13, color: YekiColors.textMedium)),
                    const SizedBox(height: 24),
                    _field(nomCtrl, 'Nom *', Icons.label_rounded, 'Ex: Département Sciences'),
                    const SizedBox(height: 16),
                    _field(descCtrl, 'Description', Icons.description_outlined, 'Objectifs, programme…', maxLines: 3),
                    const SizedBox(height: 16),
                    _field(prixCtrl, 'Prix (FCFA)', Icons.attach_money_rounded, '0 = gratuit'),
                    const SizedBox(height: 16),
                    _field(prixPresentielCtrl, 'Prix présentiel (FCFA)', Icons.attach_money_rounded, '0 = absent'),
                    const SizedBox(height: 16),
                    _buildNiveauxSelector(ctx, setS, niveauxSelectionnes, niveauxDisponibles, niveauxCharges),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: accesRestreint,
                      onChanged: (v) => setS(() => accesRestreint = v),
                      title: const Text('Accès restreint', style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                      subtitle: const Text('Les apprenants doivent demander l\'accès'),
                      activeColor: YekiColors.primary,
                    ),
                    const SizedBox(height: 16),
                    if (_typeParcours == 'prepa') ...[
                      _field(nomConcoursCtrl, 'Nom du concours', Icons.emoji_events_rounded, 'Ex: ENS, Polytechnique…'),
                      const SizedBox(height: 16),
                      _field(organismeCtrl, 'Organisme', Icons.apartment_rounded, 'Ex: MINESUP, ENS…'),
                      const SizedBox(height: 16),
                      _field(dateLimiteCtrl, 'Date limite inscription', Icons.calendar_today_rounded, 'YYYY-MM-DD'),
                      const SizedBox(height: 16),
                      _field(dateExamenCtrl, 'Date de l\'examen', Icons.event_rounded, 'YYYY-MM-DD'),
                      const SizedBox(height: 16),
                      _field(arreteCtrl, 'Arrêté ministériel', Icons.gavel_rounded, 'Référence'),
                      const SizedBox(height: 16),
                      _field(placesCtrl, 'Places disponibles', Icons.people_rounded, '0 = illimité'),
                      const SizedBox(height: 16),
                      _field(debouchesCtrl, 'Débouchés', Icons.trending_up_rounded, 'Décrivez les débouchés'),
                    ],
                    if (_typeParcours == 'formation') ...[
                      const Text('Type de formation',
                          style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _typeChip(
                              'Métier',
                              Icons.work_rounded,
                              estFormationMetier,
                              () => setS(() => estFormationMetier = !estFormationMetier),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _typeChip(
                              'Classique',
                              Icons.account_balance_rounded,
                              estFormationClassique,
                              () => setS(() => estFormationClassique = !estFormationClassique),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (estFormationMetier) ...[
                        const Text('Niveau de la formation',
                            style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['debutant', 'intermediaire', 'avance'].map((n) {
                            final labels = {
                              'debutant': 'Débutant',
                              'intermediaire': 'Intermédiaire',
                              'avance': 'Avancé',
                            };
                            final sel = niveauFormation == n;
                            return ChoiceChip(
                              label: Text(labels[n]!),
                              selected: sel,
                              selectedColor: YekiColors.primary.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: sel ? YekiColors.primary : YekiColors.textMedium,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => setS(() => niveauFormation = n),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _field(dureeCtrl, 'Durée', Icons.schedule_rounded, 'Ex: 6 mois, 200 heures…'),
                      const SizedBox(height: 16),
                      _field(domaineCtrl, 'Domaine', Icons.category_rounded, 'Ex: Informatique, Finance…'),
                      const SizedBox(height: 16),
                      _field(villeCtrl, 'Ville', Icons.location_on_rounded, 'Ex: Yaoundé, Douala…'),
                      const SizedBox(height: 16),
                      const Text('Mode', style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['hybride', 'presentiel', 'distance'].map((m) {
                          final labels = {'hybride': 'Hybride', 'presentiel': 'Présentiel', 'distance': 'À distance'};
                          final sel = mode == m;
                          return ChoiceChip(
                            label: Text(labels[m]!),
                            selected: sel,
                            selectedColor: YekiColors.primary.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: sel ? YekiColors.primary : YekiColors.textMedium,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) => setS(() => mode = m),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _field(certificatCtrl, 'Certificat délivré', Icons.card_membership_rounded, 'Ex: Certificat Python…'),
                      const SizedBox(height: 16),
                      _field(objectifsCtrl, 'Objectifs pédagogiques', Icons.flag_rounded, 'Un objectif par ligne…', maxLines: 3),
                      const SizedBox(height: 16),
                      _field(prerequisCtrl, 'Prérequis', Icons.checklist_rounded, 'Ex: Niveau Bac…', maxLines: 2),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: estCertifiante,
                        onChanged: (v) => setS(() => estCertifiante = v),
                        title: const Text('Formation certifiante',
                            style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                        subtitle: const Text('Délivre un certificat reconnu à la fin'),
                        activeColor: YekiColors.accent,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      // ignore: dead_code
                      onPressed: isLoading ? null : () {
                        if (nomCtrl.text.trim().isEmpty) {
                          ErrorHandler.showError(context, 'Le nom est obligatoire');
                          return;
                        }
                        setS(() => isLoading = true);
                        final token = _getToken();
                        _modifierDepartementAsync(
                          token, dept['id'],
                          nomCtrl, descCtrl, prixCtrl, prixPresentielCtrl,
                          niveauxSelectionnes, accesRestreint, mode,
                          estFormationMetier, estFormationClassique, niveauFormation,
                          estCertifiante,
                          nomConcoursCtrl, organismeCtrl, dateLimiteCtrl, dateExamenCtrl,
                          arreteCtrl, placesCtrl, debouchesCtrl,
                          dureeCtrl, certificatCtrl, prerequisCtrl, objectifsCtrl,
                          domaineCtrl, villeCtrl,
                          ctx, setS, isLoading
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: YekiColors.primary,
                        foregroundColor: YekiColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(YekiRadius.md),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: YekiColors.white, strokeWidth: 2),
                            )
                          : const Text('Mettre à jour'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── MÉTHODES ASYNCHRONES POUR MODIFICATION ────────────────────────────

  void _modifierDepartementAsync(
    Future<String?> tokenFuture,
    int deptId,
    TextEditingController nomCtrl,
    TextEditingController descCtrl,
    TextEditingController prixCtrl,
    TextEditingController prixPresentielCtrl,
    List<String> niveauxSelectionnes,
    bool accesRestreint,
    String mode,
    bool estFormationMetier,
    bool estFormationClassique,
    String niveauFormation,
    bool estCertifiante,
    TextEditingController nomConcoursCtrl,
    TextEditingController organismeCtrl,
    TextEditingController dateLimiteCtrl,
    TextEditingController dateExamenCtrl,
    TextEditingController arreteCtrl,
    TextEditingController placesCtrl,
    TextEditingController debouchesCtrl,
    TextEditingController dureeCtrl,
    TextEditingController certificatCtrl,
    TextEditingController prerequisCtrl,
    TextEditingController objectifsCtrl,
    TextEditingController domaineCtrl,
    TextEditingController villeCtrl,
    BuildContext ctx,
    StateSetter setS,
    bool isLoading, // CORRECTION: passer isLoading comme paramètre
  ) async {
    final token = await tokenFuture;
    if (token == null) {
      setS(() => isLoading = false);
      ErrorHandler.showError(context, 'Vous devez être connecté');
      return;
    }

    try {
      final body = <String, dynamic>{
        'nom': nomCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'prix': int.tryParse(prixCtrl.text.trim()) ?? 0,
        'prix_presentiel': int.tryParse(prixPresentielCtrl.text.trim()) ?? 0,
        'niveaux_accessibles': niveauxSelectionnes,
        'acces_restreint': accesRestreint,
        'mode': mode,
      };

      if (_typeParcours == 'prepa') {
        body['nom_concours'] = nomConcoursCtrl.text.trim();
        body['organisme_concours'] = organismeCtrl.text.trim();
        if (dateLimiteCtrl.text.trim().isNotEmpty) {
          body['date_limite_inscription'] = dateLimiteCtrl.text.trim();
        }
        if (dateExamenCtrl.text.trim().isNotEmpty) {
          body['date_examen'] = dateExamenCtrl.text.trim();
        }
        body['arrete_ministeriel'] = arreteCtrl.text.trim();
        body['places_disponibles'] = int.tryParse(placesCtrl.text.trim()) ?? 0;
        body['debouches'] = debouchesCtrl.text.trim();
      }

      if (_typeParcours == 'formation') {
        body['est_formation_metier'] = estFormationMetier;
        body['est_formation_classique'] = estFormationClassique;
        if (estFormationMetier) {
          body['niveau_formation'] = niveauFormation;
        }
        body['duree_formation'] = dureeCtrl.text.trim();
        body['mode'] = mode;
        body['domaine'] = domaineCtrl.text.trim();
        body['ville'] = villeCtrl.text.trim();
        body['certificat_delivre'] = certificatCtrl.text.trim();
        body['objectifs'] = objectifsCtrl.text.trim();
        body['prerequis'] = prerequisCtrl.text.trim();
        body['est_certifiante'] = estCertifiante;
      }

      final res = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/admin/departements/$deptId/update/'),
        headers: ApiHeaders.auth(token),
        body: jsonEncode(body),
      );

      if (mounted && res.statusCode == 200) {
        if (ctx.mounted) Navigator.pop(ctx);
        if (mounted) ErrorHandler.showSuccess(context, '✅ Département modifié !');
        _charger();
      } else {
        if (mounted) {
          try {
            final err = jsonDecode(res.body);
            if (err is Map && err.containsKey('detail')) {
              ErrorHandler.showError(context, err['detail'] as String);
            } else {
              ErrorHandler.showError(context, 'Erreur lors de la modification');
            }
          } catch (_) {
            ErrorHandler.showError(context, 'Erreur ${res.statusCode}');
          }
        }
      }
    } catch (e) {
      setS(() => isLoading = false);
      if (mounted) ErrorHandler.showError(context, 'Erreur réseau: $e');
    }
  }

  // ─── CRÉATION D'UN DÉPARTEMENT ──────────────────────────────────────────
  void _creerDepartement() {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: '0');
    final prixPresentielCtrl = TextEditingController(text: '0');
    List<String> niveauxDisponibles = [];
    List<String> niveauxSelectionnes = [];
    bool accesRestreint = false;
    String mode = 'hybride';
    bool estFormationMetier = false;
    bool estFormationClassique = false;
    String niveauFormation = 'debutant';

    final nomConcoursCtrl = TextEditingController();
    final organismeCtrl = TextEditingController();
    final dateLimiteCtrl = TextEditingController();
    final dateExamenCtrl = TextEditingController();
    final arreteCtrl = TextEditingController();
    final placesCtrl = TextEditingController();
    final debouchesCtrl = TextEditingController();

    final dureeCtrl = TextEditingController();
    final certificatCtrl = TextEditingController();
    final prerequisCtrl = TextEditingController();
    final objectifsCtrl = TextEditingController();
    final domaineCtrl = TextEditingController();
    final villeCtrl = TextEditingController();
    bool estCertifiante = false;

    bool niveauxCharges = false;

    Future<void> chargerNiveaux() async {
      if (niveauxCharges) return;
      // FormationRepository (fonction canonique unique, P5.4) — gère
      // l'authentification via l'intercepteur Dio, plus de token/headers
      // manuels ici, voir docs/ecarts/register.md.
      try {
        final niveaux = await FormationRepository().niveaux();
        if (mounted) {
          niveauxDisponibles = niveaux;
          niveauxCharges = true;
        }
      } catch (_) {
        if (mounted) {
          niveauxDisponibles = [];
          niveauxCharges = true;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        chargerNiveaux();
        return StatefulBuilder(
          builder: (ctx, setS) {
            // CORRECTION: déclarer isLoading ici, à l'intérieur du StatefulBuilder
            bool isLoading = false;

            return Container(
              decoration: const BoxDecoration(
                color: YekiColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(YekiRadius.lg)),
              ),
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sheetHandle(),
                    const SizedBox(height: 20),
                    Text(
                      _typeParcours == 'prepa'
                          ? 'Créer un concours'
                          : _typeParcours == 'formation'
                              ? 'Créer une formation'
                              : 'Créer un département',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text('Parcours : $_nomParcours', style: const TextStyle(fontSize: 13, color: YekiColors.textMedium)),
                    const SizedBox(height: 24),
                    _field(nomCtrl, 'Nom *', Icons.label_rounded,
                        _typeParcours == 'prepa' ? 'Ex: Concours ENS' : 'Ex: Formation Développement Web'),
                    const SizedBox(height: 16),
                    _field(descCtrl, 'Description', Icons.description_outlined,
                        'Objectifs, programme…', maxLines: 3),
                    const SizedBox(height: 16),
                    _field(prixCtrl, 'Prix (FCFA)', Icons.attach_money_rounded, '0 = gratuit'),
                    const SizedBox(height: 16),
                    _field(prixPresentielCtrl, 'Prix présentiel (FCFA)', Icons.attach_money_rounded, '0 = absent'),
                    const SizedBox(height: 16),
                    _buildNiveauxSelector(ctx, setS, niveauxSelectionnes, niveauxDisponibles, niveauxCharges),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: accesRestreint,
                      onChanged: (v) => setS(() => accesRestreint = v),
                      title: const Text('Accès restreint', style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                      subtitle: const Text('Les apprenants doivent demander l\'accès'),
                      activeColor: YekiColors.primary,
                    ),
                    const SizedBox(height: 16),
                    if (_typeParcours == 'prepa') ...[
                      _field(nomConcoursCtrl, 'Nom du concours', Icons.emoji_events_rounded, 'Ex: ENS, Polytechnique…'),
                      const SizedBox(height: 16),
                      _field(organismeCtrl, 'Organisme', Icons.apartment_rounded, 'Ex: MINESUP, ENS…'),
                      const SizedBox(height: 16),
                      _field(dateLimiteCtrl, 'Date limite inscription', Icons.calendar_today_rounded, 'YYYY-MM-DD'),
                      const SizedBox(height: 16),
                      _field(dateExamenCtrl, 'Date de l\'examen', Icons.event_rounded, 'YYYY-MM-DD'),
                      const SizedBox(height: 16),
                      _field(arreteCtrl, 'Arrêté ministériel', Icons.gavel_rounded, 'Référence'),
                      const SizedBox(height: 16),
                      _field(placesCtrl, 'Places disponibles', Icons.people_rounded, '0 = illimité'),
                      const SizedBox(height: 16),
                      _field(debouchesCtrl, 'Débouchés', Icons.trending_up_rounded, 'Décrivez les débouchés'),
                    ],
                    if (_typeParcours == 'formation') ...[
                      const Text('Type de formation',
                          style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _typeChip(
                              'Métier',
                              Icons.work_rounded,
                              estFormationMetier,
                              () => setS(() => estFormationMetier = !estFormationMetier),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _typeChip(
                              'Classique',
                              Icons.account_balance_rounded,
                              estFormationClassique,
                              () => setS(() => estFormationClassique = !estFormationClassique),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (estFormationMetier) ...[
                        const Text('Niveau de la formation',
                            style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['debutant', 'intermediaire', 'avance'].map((n) {
                            final labels = {
                              'debutant': 'Débutant',
                              'intermediaire': 'Intermédiaire',
                              'avance': 'Avancé',
                            };
                            final sel = niveauFormation == n;
                            return ChoiceChip(
                              label: Text(labels[n]!),
                              selected: sel,
                              selectedColor: YekiColors.primary.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: sel ? YekiColors.primary : YekiColors.textMedium,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => setS(() => niveauFormation = n),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _field(dureeCtrl, 'Durée', Icons.schedule_rounded, 'Ex: 6 mois, 200 heures…'),
                      const SizedBox(height: 16),
                      _field(domaineCtrl, 'Domaine', Icons.category_rounded, 'Ex: Informatique, Finance…'),
                      const SizedBox(height: 16),
                      _field(villeCtrl, 'Ville', Icons.location_on_rounded, 'Ex: Yaoundé, Douala…'),
                      const SizedBox(height: 16),
                      const Text('Mode', style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['hybride', 'presentiel', 'distance'].map((m) {
                          final labels = {'hybride': 'Hybride', 'presentiel': 'Présentiel', 'distance': 'À distance'};
                          final sel = mode == m;
                          return ChoiceChip(
                            label: Text(labels[m]!),
                            selected: sel,
                            selectedColor: YekiColors.primary.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: sel ? YekiColors.primary : YekiColors.textMedium,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) => setS(() => mode = m),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _field(certificatCtrl, 'Certificat délivré', Icons.card_membership_rounded, 'Ex: Certificat Python…'),
                      const SizedBox(height: 16),
                      _field(objectifsCtrl, 'Objectifs pédagogiques', Icons.flag_rounded, 'Un objectif par ligne…', maxLines: 3),
                      const SizedBox(height: 16),
                      _field(prerequisCtrl, 'Prérequis', Icons.checklist_rounded, 'Ex: Niveau Bac…', maxLines: 2),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: estCertifiante,
                        onChanged: (v) => setS(() => estCertifiante = v),
                        title: const Text('Formation certifiante',
                            style: TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                        subtitle: const Text('Délivre un certificat reconnu à la fin'),
                        activeColor: YekiColors.accent,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      // ignore: dead_code
                      onPressed: isLoading ? null : () async {
                        if (nomCtrl.text.trim().isEmpty) {
                          ErrorHandler.showError(context, 'Le nom est obligatoire');
                          return;
                        }
                        setS(() => isLoading = true);
                        final token = await _getToken();
                        if (token == null) {
                          setS(() => isLoading = false);
                          return;
                        }
                        try {
                          int prix = int.tryParse(prixCtrl.text.trim()) ?? 0;
                          int prixPresentiel = int.tryParse(prixPresentielCtrl.text.trim()) ?? 0;

                          final body = <String, dynamic>{
                            'nom': nomCtrl.text.trim(),
                            'parcours_id': _idParcours,
                            'description': descCtrl.text.trim(),
                            'prix': prix,
                            'prix_presentiel': prixPresentiel,
                            'niveaux_accessibles': niveauxSelectionnes,
                            'acces_restreint': accesRestreint,
                            'mode': mode,
                          };

                          if (_typeParcours == 'prepa') {
                            body['est_prepa_concours'] = true;
                            body['nom_concours'] = nomConcoursCtrl.text.trim();
                            body['organisme_concours'] = organismeCtrl.text.trim();
                            body['date_limite_inscription'] = dateLimiteCtrl.text.trim().isNotEmpty ? dateLimiteCtrl.text.trim() : null;
                            body['date_examen'] = dateExamenCtrl.text.trim().isNotEmpty ? dateExamenCtrl.text.trim() : null;
                            body['arrete_ministeriel'] = arreteCtrl.text.trim();
                            body['places_disponibles'] = int.tryParse(placesCtrl.text.trim()) ?? 0;
                            body['debouches'] = debouchesCtrl.text.trim();
                          }

                          if (_typeParcours == 'formation') {
                            body['est_formation_metier'] = estFormationMetier;
                            body['est_formation_classique'] = estFormationClassique;
                            if (estFormationMetier) {
                              body['niveau_formation'] = niveauFormation;
                            }
                            body['duree_formation'] = dureeCtrl.text.trim();
                            body['mode'] = mode;
                            body['domaine'] = domaineCtrl.text.trim();
                            body['ville'] = villeCtrl.text.trim();
                            body['certificat_delivre'] = certificatCtrl.text.trim();
                            body['objectifs'] = objectifsCtrl.text.trim();
                            body['prerequis'] = prerequisCtrl.text.trim();
                            body['est_certifiante'] = estCertifiante;
                          }

                          final res = await http.post(
                            Uri.parse(ApiConstants.departementsCreer),
                            headers: ApiHeaders.auth(token),
                            body: jsonEncode(body),
                          );
                          setS(() => isLoading = false);
                          if (mounted) {
                            if (res.statusCode == 201) {
                              if (ctx.mounted) Navigator.pop(ctx);
                              ErrorHandler.showSuccess(context, '✅ Département créé avec succès !');
                              _charger();
                            } else {
                              final err = jsonDecode(res.body);
                              if (err is Map && err.containsKey('detail')) {
                                ErrorHandler.showError(context, err['detail'] as String);
                              } else {
                                ErrorHandler.showError(context, 'Erreur ${res.statusCode}');
                              }
                            }
                          }
                        } catch (_) {
                          setS(() => isLoading = false);
                          if (mounted) ErrorHandler.showError(context, 'Erreur réseau');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: YekiColors.primary,
                        foregroundColor: YekiColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(YekiRadius.md),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: YekiColors.white, strokeWidth: 2),
                            )
                          : const Text('Créer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── CHANGER CADRE ──────────────────────────────────────────────────────
  void _changerCadre(Map dept) async {
    final token = await _getToken();
    if (token == null) return;
    List cadresDisp = [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/enseignants/liste/?role=cadre'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        cadresDisp = jsonDecode(res.body);
      } else {
        if (mounted) ErrorHandler.showError(context, 'Impossible de charger les cadres');
        return;
      }
    } catch (_) {
      if (mounted) ErrorHandler.showError(context, 'Erreur réseau');
      return;
    }

    if (!_mounted) return;
    int? selected = dept['cadre']?['id'] as int?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(YekiRadius.lg)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Text(dept['cadre'] == null ? 'Nommer un cadre' : 'Changer le cadre',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark)),
              const SizedBox(height: 6),
              Text('Département : ${dept['nom'] ?? ''}',
                  style: const TextStyle(fontSize: 13, color: YekiColors.textMedium)),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: cadresDisp.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Aucun enseignant cadre disponible.',
                              textAlign: TextAlign.center, style: TextStyle(color: YekiColors.textMedium)),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: cadresDisp.map<Widget>((e) => RadioListTile<int>(
                          value: e['id'] as int,
                          groupValue: selected,
                          activeColor: YekiColors.primary,
                          title: Text(e['nom'] ?? e['username'] ?? '',
                              style: const TextStyle(color: YekiColors.textDark)),
                          subtitle: Text(e['email'] ?? '',
                              style: const TextStyle(color: YekiColors.textMedium)),
                          onChanged: (v) => setS(() => selected = v),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: selected == null ? null : () async {
                  if (ctx.mounted) Navigator.pop(ctx);
                  final t2 = await _getToken();
                  if (t2 == null) return;
                  try {
                    final res = await http.patch(
                      Uri.parse('${ApiConstants.baseUrl}/departements/${dept['id']}/changer-cadre/'),
                      headers: ApiHeaders.auth(t2),
                      body: jsonEncode({'cadre_id': selected}),
                    );
                    if (mounted) {
                      if (res.statusCode == 200) {
                        ErrorHandler.showSuccess(context, 'Cadre modifié !');
                        _charger();
                      } else {
                        ErrorHandler.showError(context, 'Erreur lors du changement de cadre');
                      }
                    }
                  } catch (_) {
                    if (mounted) ErrorHandler.showError(context, 'Erreur réseau');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: YekiColors.primary,
                  foregroundColor: YekiColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(YekiRadius.md),
                  ),
                ),
                child: const Text('Confirmer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────
  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(YekiRadius.sm)),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: YekiColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: YekiColors.textMedium),
        labelStyle: const TextStyle(fontSize: 13, color: YekiColors.textMedium),
        prefixIcon: Icon(icon, color: YekiColors.primary, size: 20),
        filled: true,
        fillColor: YekiColors.bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YekiRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YekiRadius.sm),
          borderSide: BorderSide(color: YekiColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YekiRadius.sm),
          borderSide: const BorderSide(color: YekiColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildNiveauxSelector(
    BuildContext context,
    StateSetter setS,
    List<String> selected,
    List<String> disponibles,
    bool charges,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Niveaux accessibles',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: YekiColors.textDark)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: YekiColors.bgLight,
            borderRadius: BorderRadius.circular(YekiRadius.sm),
            border: Border.all(color: YekiColors.borderLight, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: null,
              isExpanded: true,
              hint: charges
                  ? (disponibles.isNotEmpty
                      ? const Text('Ajouter un niveau...', style: TextStyle(color: YekiColors.textMedium))
                      : const Text('Aucun niveau disponible pour l\'instant', style: TextStyle(color: YekiColors.textMedium)))
                  : const Text('Chargement des niveaux...', style: TextStyle(color: YekiColors.textMedium)),
              items: disponibles.where((n) => !selected.contains(n)).map((n) {
                return DropdownMenuItem<String>(
                  value: n,
                  child: Text(n, style: const TextStyle(color: YekiColors.textDark)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && !selected.contains(value)) {
                  setS(() => selected.add(value));
                }
              },
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected.map((n) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: YekiColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(YekiRadius.sm),
                border: Border.all(color: YekiColors.primary.withValues(alpha: 0.2), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(n, style: TextStyle(fontSize: 12, color: YekiColors.primary)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setS(() => selected.remove(n)),
                    child: Icon(Icons.close_rounded, size: 14, color: YekiColors.primary),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
        if (selected.isEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Aucun niveau sélectionné → accessible à tous les niveaux',
            style: TextStyle(fontSize: 11, color: YekiColors.textMedium, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  Widget _typeChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? YekiColors.primary.withValues(alpha: 0.08) : YekiColors.bgLight,
          borderRadius: BorderRadius.circular(YekiRadius.sm),
          border: Border.all(
            color: selected ? YekiColors.primary : YekiColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? YekiColors.primary : YekiColors.textMedium),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? YekiColors.primary : YekiColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONSTANTES DE MAPPING
// ═══════════════════════════════════════════════════════════════════════════

const Map<String, Color> _typeDeptColors = {
  'normal': YekiColors.primary,
  'classique': YekiColors.primaryDark,
  'metier': YekiColors.accent,
  'concours': YekiColors.purple,
};

const Map<String, IconData> _typeDeptIcons = {
  'normal': Icons.domain_rounded,
  'classique': Icons.account_balance_rounded,
  'metier': Icons.work_rounded,
  'concours': Icons.emoji_events_rounded,
};

const Map<String, String> _typeDeptLabels = {
  'normal': 'Département',
  'classique': 'Formation Classique',
  'metier': 'Formation Métier',
  'concours': 'Prépa Concours',
};

class _SI {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SI(this.label, this.value, this.icon, this.color);
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  const _StickyTabBarDelegate(
    this.tabBar, {
    this.backgroundColor = YekiColors.white,
  });

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}