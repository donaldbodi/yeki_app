// lib/views/pages/enseignants/detail_departement_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// DÉTAIL DÉPARTEMENT — CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/creer_cours_sheet.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

class DetailDepartementPage extends StatefulWidget {
  final int departementId;
  final String departementNom;
  final Map<String, dynamic>? departement;

  const DetailDepartementPage({
    super.key,
    required this.departementId,
    required this.departementNom,
    this.departement,
  });

  @override
  State<DetailDepartementPage> createState() => _DetailDepartementPageState();
}

class _DetailDepartementPageState extends State<DetailDepartementPage>
    with SingleTickerProviderStateMixin {
  
  bool _loading = true;
  Map<String, dynamic> _departement = {};
  List<Map<String, dynamic>> _cours = [];
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    
    if (widget.departement != null) {
      _departement = widget.departement!;
      _cours = List<Map<String, dynamic>>.from(_departement['cours'] ?? []);
      _loading = false;
    } else {
      _charger();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    
    final token = await _getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.enseignantCadreDepartement(widget.departementId)),
        headers: ApiHeaders.auth(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _departement = data;
          _cours = List<Map<String, dynamic>>.from(data['cours'] ?? []);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ErrorHandler.showError(context, 'Erreur ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loading = false);
      ErrorHandler.showError(context, 'Erreur réseau');
    }
  }

  void _creerCours() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreerCoursSheet(
        departementId: widget.departementId,
        departementNom: widget.departementNom,
        onSuccess: _charger,
      ),
    );
  }

  Color get _accentColor {
    final couleur = _departement['couleur'] ?? '#135F74';
    try {
      return Color(int.parse('FF${couleur.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF135F74);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        elevation: 4,
        onPressed: _creerCours,
        child: const Icon(Icons.add_rounded, color: YekiColors.white, size: 28),
      ),
      body: _loading
          ? const Center(child: YekiLoader())
          : NestedScrollView(
              headerSliverBuilder: (_, _) => [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildInfoBar()),
                SliverToBoxAdapter(child: _buildTabs()),
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

  SliverAppBar _buildSliverAppBar() {
    final nbCours = _cours.length;
    final nbApprenants = _departement['nb_apprenants'] ?? 0;
    final typeDept = _departement['type_departement'] ?? 'cursus';

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _accentColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: YekiColors.black.withValues(alpha: 0.26),
            borderRadius: YekiRadius.borderRadiusSm,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: YekiColors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentColor, _accentColor.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: YekiColors.accent.withValues(alpha: 0.2),
                      borderRadius: YekiRadius.borderRadiusXl,
                    ),
                    child: Text(
                      _getTypeLabel(typeDept).toUpperCase(),
                      style: const TextStyle(color: YekiColors.accent, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _departement['nom'] ?? widget.departementNom,
                    style: const TextStyle(color: YekiColors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statBadge('$nbCours cours', Icons.book_rounded),
                      const SizedBox(width: 12),
                      _statBadge('$nbApprenants apprenants', Icons.people_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: YekiColors.white),
          onPressed: _charger,
        ),
      ],
    );
  }

  Widget _statBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.15),
        borderRadius: YekiRadius.borderRadiusXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: YekiColors.white, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: YekiColors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    final prix = _departement['prix'] ?? 0;
    final parcours = _departement['parcours'] ?? '';
    final ville = _departement['ville'] ?? '';
    
    return Container(
      color: YekiColors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoBarItem(Icons.route_rounded, parcours.isNotEmpty ? parcours : 'Non défini', 'Parcours'),
          _infoBarItem(
            prix == 0 ? Icons.lock_open_rounded : Icons.lock_rounded,
            prix == 0 ? 'Gratuit' : '$prix FCFA',
            'Accès',
          ),
          if (ville.isNotEmpty)
            _infoBarItem(Icons.location_on_rounded, ville, 'Localisation'),
        ],
      ),
    );
  }

  Widget _infoBarItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: _accentColor),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      color: YekiColors.white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: _accentColor,
        unselectedLabelColor: YekiColors.textLight,
        indicatorColor: _accentColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.book_rounded, size: 18), text: 'Cours'),
          Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: 'Statistiques'),
        ],
      ),
    );
  }

  Widget _tabCours() {
    if (_cours.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.book_outlined, size: 48, color: _accentColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun cours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre premier cours dans ce département',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _creerCours,
              icon: const Icon(Icons.add),
              label: const Text('Créer un cours'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: YekiColors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cours.length,
      itemBuilder: (context, index) => _buildCoursCard(_cours[index]),
    );
  }

  Widget _buildCoursCard(Map<String, dynamic> cours) {
    final taux = (cours['taux_completion'] as num?)?.toDouble() ?? 0.0;
    final nbApprenants = cours['nb_apprenants'] ?? 0;
    final nbLecons = cours['nb_lecons'] ?? 0;
    final nbDevoirs = cours['nb_devoirs'] ?? 0;
    final ep = cours['enseignant_principal'];
    
    Color coursColor;
    try {
      final hex = (cours['color_code'] ?? '#135F74').replaceAll('#', '');
      coursColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      coursColor = _accentColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusLg,
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: InkWell(
        borderRadius: YekiRadius.borderRadiusLg,
        onTap: () {
          context.pushNamed(
            AppRoute.coursDetailEnseignant,
            pathParameters: {'coursId': cours['id'].toString()},
            queryParameters: {
              'titre': (cours['titre'] ?? '') as String,
              'estEnseignantPrincipal': 'true',
              'courseColor': coursColor.value.toString(),
            },
          );
        },
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
                      color: coursColor.withValues(alpha: 0.1),
                      borderRadius: YekiRadius.borderRadiusMd,
                    ),
                    child: Icon(Icons.book_rounded, color: coursColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cours['titre'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cours['niveau'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (ep != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: YekiColors.success.withValues(alpha: 0.1),
                        borderRadius: YekiRadius.borderRadiusSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 10, color: YekiColors.success),
                          const SizedBox(width: 4),
                          Text(
                            ep['nom'] ?? '',
                            style: const TextStyle(fontSize: 10, color: YekiColors.success),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _miniStat(Icons.people_rounded, '$nbApprenants', 'apprenants'),
                  const SizedBox(width: 16),
                  _miniStat(Icons.play_lesson_rounded, '$nbLecons', 'leçons'),
                  const SizedBox(width: 16),
                  _miniStat(Icons.assignment_rounded, '$nbDevoirs', 'devoirs'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: YekiRadius.borderRadiusSm,
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        backgroundColor: YekiColors.borderLight,
                        color: coursColor,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${taux.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: coursColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: YekiColors.textLight),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _tabStats() {
    final nbCours = _cours.length;
    final nbApprenants = _departement['nb_apprenants'] ?? 0;
    final tauxMoyen = (_departement['taux_moyen'] as num?)?.toDouble() ?? 0.0;
    
    int totalLecons = 0;
    int totalDevoirs = 0;
    for (final cours in _cours) {
      totalLecons += (cours['nb_lecons'] as num?)?.toInt() ?? 0;
      totalDevoirs += (cours['nb_devoirs'] as num?)?.toInt() ?? 0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor, _accentColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: YekiRadius.borderRadiusXl,
            ),
            child: Column(
              children: [
                Text(
                  'Taux de complétion moyen',
                  style: TextStyle(color: YekiColors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '${tauxMoyen.toStringAsFixed(0)}%',
                  style: const TextStyle(color: YekiColors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: YekiRadius.borderRadiusSm,
                  child: LinearProgressIndicator(
                    value: tauxMoyen / 100,
                    backgroundColor: YekiColors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(YekiColors.accent),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard('Cours', '$nbCours', Icons.book_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Leçons', '$totalLecons', Icons.play_lesson_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard('Devoirs', '$totalDevoirs', Icons.assignment_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Apprenants', '$nbApprenants', Icons.people_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusLg,
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: _accentColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'prepa_concours':
        return 'Prépa Concours';
      case 'formation_metier':
        return 'Formation Métier';
      case 'formation_classique':
        return 'Formation Classique';
      default:
        return 'Département';
    }
  }
}