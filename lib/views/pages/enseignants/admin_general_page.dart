// lib/views/pages/enseignants/admin_general_page.dart
// ═══════════════════════════════════════════════════════════════════════════
//  ADMIN GÉNÉRAL — Dashboard complet avec design system
//  Version CORRIGÉE avec navigation par niveau
//  Toutes les erreurs Dart résolues
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/theme/yeki_design_extension.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/core/router/route_names.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PAGE DE DÉTAIL PARCOURS — Affiche les départements du parcours
// ═══════════════════════════════════════════════════════════════════════════

class ParcoursDetailPage extends StatefulWidget {
  final int parcoursId;
  final String parcoursNom;
  final String parcoursType;

  const ParcoursDetailPage({
    super.key,
    required this.parcoursId,
    required this.parcoursNom,
    required this.parcoursType,
  });

  @override
  State<ParcoursDetailPage> createState() => _ParcoursDetailPageState();
}

class _ParcoursDetailPageState extends State<ParcoursDetailPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _departements = [];
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
        Uri.parse('${ApiConstants.baseUrl}/parcours/${widget.parcoursId}/departements/'),
        headers: ApiHeaders.auth(token),
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _departements = List<Map<String, dynamic>>.from(data);
          _stats = {
            'nb_departements': _departements.length,
            // CORRECTION: utiliser fold<double> puis convertir en int
            'nb_cours': _departements.fold<double>(0, (sum, d) => sum + ((d['nb_cours'] ?? 0) as num).toDouble()).toInt(),
            'nb_apprenants': _departements.fold<double>(0, (sum, d) => sum + ((d['nb_apprenants'] ?? 0) as num).toDouble()).toInt(),
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _ouvrirDetailDepartement(Map<String, dynamic> dept) {
    context.pushNamed(
      AppRoute.adminDepartementDetail,
      pathParameters: {'departementId': dept['id'].toString()},
      queryParameters: {
        'departementNom': dept['nom']?.toString() ?? '',
        'parcoursNom': widget.parcoursNom,
      },
      extra: dept,
    );
  }

  Color _getDeptColor(Map<String, dynamic> dept) {
    final couleur = dept['couleur'] ?? '#2884A0';
    try {
      return Color(int.parse('FF${couleur.replaceAll('#', '')}', radix: 16));
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
              widget.parcoursNom,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark),
            ),
            Text(
              '${_stats['nb_departements']} départements',
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
              child: _departements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: YekiColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.domain_outlined, size: 48, color: YekiColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun département',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _departements.length,
                      itemBuilder: (_, i) => _buildDepartementCard(_departements[i]),
                    ),
            ),
    );
  }

  Widget _buildDepartementCard(Map<String, dynamic> dept) {
    final color = _getDeptColor(dept);
    final taux = (dept['taux_moyen'] as num?)?.toDouble() ?? 0.0;
    final nbCours = dept['nb_cours'] ?? 0;
    final nbApp = dept['nb_apprenants'] ?? 0;
    final typeDept = dept['type_departement'] ?? 'cursus';

    return GestureDetector(
      onTap: () => _ouvrirDetailDepartement(dept),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YekiColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Icon(
                      _getTypeIcon(typeDept),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept['nom'] ?? 'Département',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: YekiColors.textDark),
                        ),
                        Text(
                          _getTypeLabel(typeDept),
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$nbCours cours',
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dept['description'] != null && dept['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        dept['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: YekiColors.textMedium, height: 1.4),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.people_rounded, '$nbApp apprenants', YekiColors.purple),
                      _infoChip(Icons.book_rounded, '$nbCours cours', YekiColors.primary),
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
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'prepa_concours':
        return Icons.emoji_events_rounded;
      case 'formation_metier':
        return Icons.work_rounded;
      case 'formation_classique':
        return Icons.account_balance_rounded;
      default:
        return Icons.domain_rounded;
    }
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

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE DE DÉTAIL DÉPARTEMENT — Affiche les cours du département
// ═══════════════════════════════════════════════════════════════════════════

class DepartementDetailPage extends StatefulWidget {
  final int departementId;
  final String departementNom;
  final String parcoursNom;
  final Map<String, dynamic>? departementData;

  const DepartementDetailPage({
    super.key,
    required this.departementId,
    required this.departementNom,
    required this.parcoursNom,
    this.departementData,
  });

  @override
  State<DepartementDetailPage> createState() => _DepartementDetailPageState();
}

class _DepartementDetailPageState extends State<DepartementDetailPage> {
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
          // CORRECTION: utiliser fold<double> puis convertir en int
          _stats = {
            'nb_cours': _cours.length,
            'nb_apprenants': _cours.fold<double>(0, (sum, c) => sum + ((c['nb_apprenants'] ?? 0) as num).toDouble()).toInt(),
            // CORRECTION: utiliser isNotEmpty au lieu de length > 0
            'taux_moyen': _cours.isEmpty ? 0.0 : _cours.fold<double>(0, (sum, c) => sum + ((c['taux_completion'] ?? 0) as num).toDouble()) / _cours.length,
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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
    // CORRECTION: variable isMobile supprimée car non utilisée

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
// ADMIN GÉNÉRAL — Dashboard principal
// ═══════════════════════════════════════════════════════════════════════════

class AdminGeneralPage extends StatefulWidget {
  const AdminGeneralPage({super.key});

  @override
  State<AdminGeneralPage> createState() => _AdminGeneralPageState();
}

class _AdminGeneralPageState extends State<AdminGeneralPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _errorDetail = '';
  Map<String, dynamic> _stats = {};
  List _parcours = [];
  List _departements = [];
  List _topEnseignants = [];
  // CORRECTION: champ _nomEnseignant supprimé car non utilisé
  late TabController _tabCtrl;

  // Gestion des enseignants
  List _enseignants = [];
  bool _loadingEnseignants = false;

  // Filtres de recherche
  String _searchQuery = '';
  String _filterUserType = '';
  String _filterStatus = '';
  int? _filterParcours;
  int? _filterDepartement;
  int? _filterCours;

  // État pour éviter les appels setState après dispose
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _tabCtrl = TabController(length: 5, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _mounted = false;
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  // ─── Chargement initial ────────────────────────────────────────────────
  Future<void> _charger() async {
    if (!_mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
      _errorDetail = '';
    });
    
    final token = await _getToken();
    if (token == null) {
      if (_mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Vous devez être connecté pour accéder à cette page.';
        });
      }
      return;
    }
    
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.adminGeneralDashboard),
        headers: ApiHeaders.auth(token),
      );
      
      if (!_mounted) return;
      
      if (res.statusCode == 200) {
        try {
          final data = jsonDecode(res.body);
          setState(() {
            _stats = data['stats'] ?? {};
            _parcours = data['parcours'] ?? [];
            _departements = data['departements'] ?? [];
            _topEnseignants = data['top_enseignants'] ?? [];
            _enseignants = data['enseignants'] ?? [];
            _loading = false;
            _hasError = false;
          });
        } catch (e) {
          setState(() {
            _loading = false;
            _hasError = true;
            _errorMessage = 'Erreur de parsing des données';
            _errorDetail = e.toString();
          });
        }
      } else if (res.statusCode == 403) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Accès refusé. Vous devez être administrateur général pour accéder à cette page.';
        });
      } else if (res.statusCode == 500) {
        String detail = '';
        try {
          final errorData = jsonDecode(res.body);
          detail = errorData['detail'] ?? 'Erreur interne du serveur';
        } catch (_) {
          detail = 'Erreur interne du serveur (500)';
        }
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Erreur serveur';
          _errorDetail = detail;
        });
      } else {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Erreur lors du chargement';
          _errorDetail = 'Code: ${res.statusCode} - ${res.reasonPhrase}';
        });
      }
    } catch (e) {
      if (_mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Erreur réseau';
          _errorDetail = e.toString();
        });
      }
    }
  }

  // ─── Recherche d'enseignants ──────────────────────────────────────────
  Future<void> _rechercherEnseignants() async {
    if (!_mounted) return;
    setState(() => _loadingEnseignants = true);

    final token = await _getToken();
    if (token == null) {
      if (!_mounted) return;
      setState(() => _loadingEnseignants = false);
      _showError('Vous devez être connecté');
      return;
    }

    final params = <String, String>{};
    if (_searchQuery.isNotEmpty) params['q'] = _searchQuery;
    if (_filterUserType.isNotEmpty) params['user_type'] = _filterUserType;
    if (_filterStatus.isNotEmpty) params['is_active'] = _filterStatus;
    if (_filterParcours != null) params['parcours_id'] = _filterParcours.toString();
    if (_filterDepartement != null) params['departement_id'] = _filterDepartement.toString();
    if (_filterCours != null) params['cours_id'] = _filterCours.toString();

    final uri = Uri.parse(ApiConstants.adminGeneralSearchEnseignants)
        .replace(queryParameters: params);

    try {
      final res = await http.get(uri, headers: ApiHeaders.auth(token));
      if (!_mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _enseignants = data['results'] ?? [];
          _loadingEnseignants = false;
        });
      } else {
        setState(() => _loadingEnseignants = false);
        _showError('Erreur lors de la recherche (${res.statusCode})');
      }
    } catch (e) {
      if (_mounted) {
        setState(() => _loadingEnseignants = false);
        _showError('Erreur réseau');
      }
    }
  }

  // ─── Modifier un enseignant ──────────────────────────────────────────
  Future<void> _modifierEnseignant(Map enseignant) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }

    String currentType = enseignant['user_type'] ?? 'enseignant';
    bool currentActive = enseignant['is_active'] ?? false;
    String selectedType = currentType;
    bool selectedActive = currentActive;

    final types = [
      {'code': 'enseignant', 'label': 'Enseignant'},
      {'code': 'enseignant_principal', 'label': 'Enseignant Principal'},
      {'code': 'enseignant_cadre', 'label': 'Enseignant Cadre'},
      {'code': 'enseignant_admin', 'label': 'Enseignant Administrateur'},
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(YekiRadius.lg)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Modifier ${enseignant['nom']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${enseignant['email']}',
                style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
              ),
              const SizedBox(height: 20),
              const Text('Type d\'enseignant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
              const SizedBox(height: 8),
              ...types.map((t) {
                final isSelected = t['code'] == selectedType;
                return RadioListTile<String>(
                  value: t['code'] as String,
                  groupValue: selectedType,
                  onChanged: (value) => setS(() => selectedType = value!),
                  activeColor: YekiColors.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: Text(
                    t['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? YekiColors.primary : YekiColors.textDark,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SwitchListTile(
                value: selectedActive,
                onChanged: (v) => setS(() => selectedActive = v),
                title: const Text('Compte actif', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  selectedActive ? 'L\'enseignant peut se connecter' : 'L\'enseignant ne peut pas se connecter',
                  style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                ),
                activeColor: YekiColors.primary,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: YekiButton(
                  label: 'Enregistrer',
                  onPressed: () {
                    if (selectedType == currentType &&
                        selectedActive == currentActive) {
                      return;
                    }

                    _envoyerModificationEnseignant(
                      enseignant['id'] as int,
                      selectedType,
                      selectedActive,
                    );

                    Navigator.pop(ctx);
                  },
                  color: YekiColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _envoyerModificationEnseignant(int profileId, String newType, bool newActive) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }

    try {
      final res = await http.patch(
        Uri.parse(ApiConstants.adminGeneralModifierEnseignant(profileId)),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({
          'user_type': newType,
          'is_active': newActive,
        }),
      );

      if (_mounted) {
        if (res.statusCode == 200) {
          _showSuccess('Enseignant modifié avec succès !');
          _rechercherEnseignants();
          _charger();
        } else {
          try {
            final err = jsonDecode(res.body);
            _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
          } catch (_) {
            _showError('Erreur ${res.statusCode}');
          }
        }
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  // ─── Créer un parcours ────────────────────────────────────────────────
  void _creerParcours() {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'cursus';

    final List<Map<String, dynamic>> typesParcours = [
      {'code': 'cursus', 'label': 'Cursus scolaire / universitaire', 'icon': Icons.school_rounded, 'color': YekiColors.primary},
      {'code': 'prepa', 'label': 'Prépa Concours', 'icon': Icons.emoji_events_rounded, 'color': YekiColors.gold},
      {'code': 'formation', 'label': 'Formations professionnelles', 'icon': Icons.work_rounded, 'color': YekiColors.accent},
      {'code': 'autre', 'label': 'Autre', 'icon': Icons.category_rounded, 'color': YekiColors.textMedium},
    ];

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
                const Text('Créer un parcours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: YekiColors.textDark)),
                const SizedBox(height: 6),
                const Text(
                  'Un enseignant administrateur pourra être nommé à la tête du parcours.',
                  style: TextStyle(fontSize: 12, color: YekiColors.textMedium),
                ),
                const SizedBox(height: 24),
                _field(nomCtrl, 'Nom du parcours *', Icons.route, 'Ex: Licence Informatique'),
                const SizedBox(height: 16),
                _field(descCtrl, 'Description', Icons.description_outlined,
                    'Objectifs et contenu du parcours', maxLines: 3),
                const SizedBox(height: 20),
                const Text('Type de parcours *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: YekiColors.bgLight,
                    borderRadius: BorderRadius.circular(YekiRadius.md),
                    border: Border.all(color: YekiColors.borderLight, width: 1),
                  ),
                  child: Column(
                    children: typesParcours.map((type) {
                      return RadioListTile<String>(
                        value: type['code'],
                        groupValue: selectedType,
                        onChanged: (value) => setS(() => selectedType = value!),
                        activeColor: type['color'],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (type['color'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(type['icon'], size: 18, color: type['color']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(type['label'],
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: YekiColors.textDark)),
                            ),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: YekiButton(
                    label: 'Créer le parcours',
                    onPressed: () {
                      if (nomCtrl.text.trim().isEmpty) {
                        _showError('Le nom est obligatoire');
                        return;
                      }
                      _creerParcoursAsync(nomCtrl, descCtrl, selectedType, ctx);
                    },
                    color: YekiColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _creerParcoursAsync(TextEditingController nomCtrl, 
      TextEditingController descCtrl, String selectedType, BuildContext ctx) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.parcoursCreer),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({
          'nom': nomCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'type_parcours': selectedType,
        }),
      );
      if (res.statusCode == 201) {
        if (ctx.mounted) Navigator.pop(ctx);
        _showSuccess('Parcours créé avec succès !');
        _charger();
      } else {
        try {
          final err = jsonDecode(res.body);
          _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
        } catch (_) {
          _showError('Erreur ${res.statusCode}');
        }
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  // ─── Modifier un parcours ──────────────────────────────────────────────
  void _modifierParcours(Map parcours) {
    final nomCtrl = TextEditingController(text: parcours['nom'] ?? '');
    final descCtrl = TextEditingController(text: parcours['description'] ?? '');
    String selectedType = parcours['type_parcours'] ?? 'autre';

    final List<Map<String, dynamic>> typesParcours = [
      {'code': 'cursus', 'label': 'Cursus scolaire / universitaire', 'icon': Icons.school_rounded, 'color': YekiColors.primary},
      {'code': 'prepa', 'label': 'Prépa Concours', 'icon': Icons.emoji_events_rounded, 'color': YekiColors.gold},
      {'code': 'formation', 'label': 'Formations professionnelles', 'icon': Icons.work_rounded, 'color': YekiColors.accent},
      {'code': 'autre', 'label': 'Autre', 'icon': Icons.category_rounded, 'color': YekiColors.textMedium},
    ];

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
                Text('Modifier le parcours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: YekiColors.textDark)),
                const SizedBox(height: 6),
                const Text(
                  'Seul le nom, la description et le type peuvent être modifiés.',
                  style: TextStyle(fontSize: 12, color: YekiColors.textMedium),
                ),
                const SizedBox(height: 24),
                _field(nomCtrl, 'Nom du parcours *', Icons.route, 'Ex: Licence Informatique'),
                const SizedBox(height: 16),
                _field(descCtrl, 'Description', Icons.description_outlined,
                    'Objectifs et contenu du parcours', maxLines: 3),
                const SizedBox(height: 20),
                const Text('Type de parcours *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: YekiColors.bgLight,
                    borderRadius: BorderRadius.circular(YekiRadius.md),
                    border: Border.all(color: YekiColors.borderLight, width: 1),
                  ),
                  child: Column(
                    children: typesParcours.map((type) {
                      return RadioListTile<String>(
                        value: type['code'],
                        groupValue: selectedType,
                        onChanged: (value) => setS(() => selectedType = value!),
                        activeColor: type['color'],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (type['color'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(type['icon'], size: 18, color: type['color']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(type['label'],
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: YekiColors.textDark)),
                            ),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: YekiButton(
                    label: 'Enregistrer les modifications',
                    onPressed: () {
                      if (nomCtrl.text.trim().isEmpty) {
                        _showError('Le nom est obligatoire');
                        return;
                      }
                      _modifierParcoursAsync(parcours, nomCtrl, descCtrl, selectedType, ctx);
                    },
                    color: YekiColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _modifierParcoursAsync(Map parcours, TextEditingController nomCtrl,
      TextEditingController descCtrl, String selectedType, BuildContext ctx) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }
    try {
      final res = await http.patch(
        Uri.parse(ApiConstants.parcoursModifier(parcours['id'])),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({
          'nom': nomCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'type_parcours': selectedType,
        }),
      );
      if (res.statusCode == 200) {
        if (ctx.mounted) Navigator.pop(ctx);
        _showSuccess('Parcours modifié avec succès !');
        _charger();
      } else {
        try {
          final err = jsonDecode(res.body);
          _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
        } catch (_) {
          _showError('Erreur ${res.statusCode}');
        }
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  // ─── Changer admin de parcours ────────────────────────────────────────
  void _changerAdmin(Map parcours) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }

    List enseignants = [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/enseignants/liste/?role=admin'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        enseignants = jsonDecode(res.body);
      } else {
        _showError('Impossible de charger les enseignants (${res.statusCode})');
        return;
      }
    } catch (_) {
      _showError('Erreur réseau');
      return;
    }

    if (!_mounted) return;

    int? selected = parcours['enseignant_admin']?['id'] as int?;
    if (selected == null) {
      _showError('Aucun enseignant administrateur sélectionné');
      return;
    }

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
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Text(
                parcours['enseignant_admin'] == null
                    ? 'Nommer un enseignant administrateur'
                    : 'Changer l\'enseignant administrateur',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Parcours : ${parcours['nom'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: YekiColors.textMedium),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: enseignants.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Aucun enseignant administrateur disponible.\n'
                            'Vérifiez qu\'il existe des comptes avec le rôle "enseignant_admin" actifs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: YekiColors.textMedium),
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: enseignants.map<Widget>((e) => RadioListTile<int>(
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
              SizedBox(
                width: double.infinity,
                child: YekiButton(
                  label: 'Confirmer',
                  onPressed: () {
                    if (ctx.mounted) Navigator.pop(ctx);
                    _changerAdminAsync(parcours['id'], selected!);
                  },
                  color: YekiColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changerAdminAsync(int parcoursId, int selected) async {
    final token = await _getToken();
    if (token == null) {
      _showError('Vous devez être connecté');
      return;
    }
    try {
      final res = await http.patch(
        Uri.parse(ApiConstants.parcoursNommerAdmin(parcoursId)),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({'enseignant_admin_id': selected}),
      );
      if (res.statusCode == 200) {
        _showSuccess('Enseignant administrateur mis à jour !');
        _charger();
      } else {
        try {
          final err = jsonDecode(res.body);
          _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
        } catch (_) {
          _showError('Erreur ${res.statusCode}');
        }
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  // ─── Charger tous les cours ──────────────────────────────────────────────
  Future<List> _chargerTousLesCours() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/cours/'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.bgLight,
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const YekiLoader(size: 40),
                  const SizedBox(height: 16),
                  const Text('Chargement du tableau de bord...',
                      style: TextStyle(color: YekiColors.textMedium, fontSize: 14)),
                ],
              ),
            )
          : _hasError
              ? _buildErrorState()
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    _buildSliverTabBar(),
                  ],
                  body: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _tabParcours(),
                      _tabDepartements(),
                      _tabGlobal(),
                      _tabEnseignants(),
                      _tabTousCours(),
                    ],
                  ),
                ),
      floatingActionButton: !_loading && !_hasError ? _buildPremiumFAB() : null,
    );
  }

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
            const SizedBox(height: 12),
            if (_errorDetail.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: YekiColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: YekiColors.borderLight, width: 1),
                ),
                child: Text(
                  _errorDetail,
                  style: const TextStyle(fontSize: 14, color: YekiColors.textMedium),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                YekiButton(
                  label: 'Réessayer',
                  onPressed: _charger,
                  width: 160,
                ),
                const SizedBox(width: 16),
                YekiButton(
                  label: 'Retour',
                  onPressed: () => Navigator.pop(context),
                  color: YekiColors.textMedium,
                  width: 160,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          labelColor: YekiColors.primary,
          unselectedLabelColor: YekiColors.textMedium,
          indicatorColor: YekiColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Parcours'),
            Tab(text: 'Départements'),
            Tab(text: 'Vue globale'),
            Tab(text: 'Enseignants'),
            Tab(text: 'Tous les cours'),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton(
        onPressed: _creerParcours,
        backgroundColor: YekiColors.primary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: YekiColors.white, size: 28),
      ),
    );
  }

  // ─── TAB 1 : Parcours ──────────────────────────────────────────────────
  Widget _tabParcours() {
    if (_parcours.isEmpty) {
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
              child: const Icon(Icons.route_outlined, size: 48, color: YekiColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Aucun parcours créé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
            const SizedBox(height: 8),
            const Text('Commencez par créer votre premier parcours', style: TextStyle(fontSize: 13, color: YekiColors.textMedium)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _parcours.length,
        itemBuilder: (_, i) => _buildParcoursCard(_parcours[i]),
      ),
    );
  }

  Widget _buildParcoursCard(Map p) {
    final nbDepts = p['nb_departements'] ?? 0;
    final nbApp = p['nb_apprenants'] ?? 0;
    final admin = p['enseignant_admin'];
    final taux = (p['taux_moyen'] as num? ?? 0).toDouble();

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          AppRoute.adminParcoursDetail,
          pathParameters: {'parcoursId': p['id'].toString()},
          queryParameters: {
            'parcoursNom': p['nom']?.toString() ?? '',
            'parcoursType': p['type_parcours']?.toString() ?? '',
          },
        );
      },
      child: YekiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: YekiColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(YekiRadius.md),
                    border: Border.all(color: YekiColors.primary.withValues(alpha: 0.2), width: 0.8),
                  ),
                  child: const Icon(Icons.route, color: YekiColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['nom'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: YekiColors.textDark)),
                      const SizedBox(height: 4),
                      Text('$nbDepts départements · $nbApp apprenants',
                          style: const TextStyle(fontSize: 12, color: YekiColors.textMedium)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: YekiColors.primary),
                  tooltip: 'Modifier le parcours',
                  onPressed: () => _modifierParcours(p),
                ),
                IconButton(
                  icon: Icon(
                    admin == null ? Icons.person_add_outlined : Icons.swap_horiz,
                    color: YekiColors.primary,
                  ),
                  tooltip: admin == null ? 'Nommer un admin' : 'Changer l\'admin',
                  onPressed: () => _changerAdmin(p),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (admin != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: YekiColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: YekiColors.primary.withValues(alpha: 0.15), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 14, color: YekiColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Admin : ${admin['nom'] ?? admin['username'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: YekiColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: YekiColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: YekiColors.accent.withValues(alpha: 0.2), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_outlined, size: 14, color: YekiColors.accent),
                    SizedBox(width: 8),
                    Text('Aucun administrateur nommé',
                        style: TextStyle(fontSize: 12, color: YekiColors.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: taux / 100,
                      backgroundColor: YekiColors.borderLight,
                      color: YekiColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${taux.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: YekiColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2 : Départements ──────────────────────────────────────────────
  Widget _tabDepartements() {
    if (_departements.isEmpty) {
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
              child: const Icon(Icons.domain_outlined, size: 48, color: YekiColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Aucun département', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departements.length,
        itemBuilder: (_, i) {
          final d = _departements[i];
          //final taux = (d['taux_moyen'] as num? ?? 0).toDouble();
          final cadre = d['cadre'];
          final parcours = d['parcours'] ?? '';
          final nbCours = d['nb_cours'] ?? 0;
          final nbApprenants = d['nb_apprenants'] ?? 0;
          
          return GestureDetector(
            onTap: () {
              context.pushNamed(
                AppRoute.adminDepartementDetail,
                pathParameters: {'departementId': d['id'].toString()},
                queryParameters: {
                  'departementNom': d['nom']?.toString() ?? '',
                  'parcoursNom': parcours.toString(),
                },
                extra: d,
              );
            },
            child: YekiCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: YekiColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(YekiRadius.sm),
                      border: Border.all(color: YekiColors.primary.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: const Icon(Icons.domain, color: YekiColors.primary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['nom'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: YekiColors.textDark)),
                        Text(
                          '$nbCours cours · $nbApprenants apprenants',
                          style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                        ),
                        if (parcours.isNotEmpty)
                          Text('Parcours: $parcours',
                              style: const TextStyle(fontSize: 11, color: YekiColors.textMedium)),
                        if (cadre != null)
                          Text('Cadre: ${cadre['nom'] ?? ''}',
                              style: const TextStyle(fontSize: 11, color: YekiColors.primary)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: YekiColors.primary, size: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── TAB 3 : Vue globale ──────────────────────────────────────────────
  Widget _tabGlobal() {
    final cards = [
      _GS('Parcours', '${_stats['nb_parcours'] ?? 0}', Icons.route, YekiColors.primary),
      _GS('Départements', '${_stats['nb_departements'] ?? 0}', Icons.domain, YekiColors.primaryDark),
      _GS('Cours', '${_stats['nb_cours'] ?? 0}', Icons.book, YekiColors.purple),
      _GS('Apprenants', '${_stats['nb_apprenants'] ?? 0}', Icons.people, YekiColors.gold),
      _GS('Enseignants', '${_stats['nb_enseignants'] ?? 0}', Icons.person_outline, YekiColors.accent),
      _GS('Leçons', '${_stats['nb_lecons'] ?? 0}', Icons.play_lesson, YekiColors.primaryLight),
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
            children: cards.map((c) => _buildGCard(c)).toList(),
          ),
          if (_topEnseignants.isNotEmpty) ...[
            const SizedBox(height: 24),
            YekiSection(
              title: 'Top enseignants',
              icon: Icons.emoji_events,
              iconColor: YekiColors.gold,
              children: _topEnseignants.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: YekiColors.white,
                    borderRadius: BorderRadius.circular(YekiRadius.md),
                    border: Border.all(color: YekiColors.borderLight, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? YekiColors.gold
                              : i == 1
                                  ? YekiColors.textMedium
                                  : YekiColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: YekiColors.white)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['nom'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                            Text(t['role'] ?? '',
                                style: const TextStyle(fontSize: 11, color: YekiColors.textMedium)),
                          ],
                        ),
                      ),
                      Text('${(t['score'] as num? ?? 0).toStringAsFixed(1)}/20',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: YekiColors.primary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── TAB 4 : Enseignants ──────────────────────────────────────────────
  Widget _tabEnseignants() {
    return Column(
      children: [
        // Barre de recherche et filtres
        Container(
          padding: const EdgeInsets.all(16),
          color: YekiColors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un enseignant...',
                  prefixIcon: const Icon(Icons.search, color: YekiColors.primary),
                  filled: true,
                  fillColor: YekiColors.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(YekiRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(YekiRadius.md),
                    borderSide: BorderSide(color: YekiColors.borderLight, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(YekiRadius.md),
                    borderSide: const BorderSide(color: YekiColors.primary, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: YekiColors.textMedium),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                      _rechercherEnseignants();
                    },
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
                onSubmitted: (_) => _rechercherEnseignants(),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Filtre par type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: YekiColors.bgLight,
                        borderRadius: BorderRadius.circular(YekiRadius.md),
                        border: Border.all(color: YekiColors.borderLight, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterUserType.isEmpty ? null : _filterUserType,
                          hint: const Text('Type', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Tous', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'enseignant', child: Text('Enseignant', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'enseignant_principal', child: Text('Enseignant Principal', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'enseignant_cadre', child: Text('Enseignant Cadre', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'enseignant_admin', child: Text('Enseignant Admin', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (value) {
                            setState(() => _filterUserType = value ?? '');
                            _rechercherEnseignants();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filtre par état
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: YekiColors.bgLight,
                        borderRadius: BorderRadius.circular(YekiRadius.md),
                        border: Border.all(color: YekiColors.borderLight, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterStatus.isEmpty ? null : _filterStatus,
                          hint: const Text('État', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Tous', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'true', child: Text('Autorisé', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'false', child: Text('Non autorisé', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (value) {
                            setState(() => _filterStatus = value ?? '');
                            _rechercherEnseignants();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bouton de recherche
                    YekiButton(
                      label: 'Rechercher',
                      icon: Icons.search,
                      onPressed: _rechercherEnseignants,
                      width: 140,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Liste des enseignants
        Expanded(
          child: _loadingEnseignants
              ? const Center(child: YekiLoader())
              : _enseignants.isEmpty
                  ? Center(
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
                            child: const Icon(Icons.person_outline, size: 48, color: YekiColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text('Aucun enseignant trouvé',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
                          const SizedBox(height: 8),
                          const Text('Essayez d\'ajuster vos filtres de recherche',
                              style: TextStyle(fontSize: 13, color: YekiColors.textMedium)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _enseignants.length,
                      itemBuilder: (_, i) => _buildEnseignantCard(_enseignants[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildEnseignantCard(Map e) {
    final isActive = e['is_active'] ?? false;
    final userType = e['user_type'] ?? 'enseignant';
    final avatarUrl = e['avatar'];
    final dateJoined = e['date_joined'] != null 
        ? DateTime.parse(e['date_joined']).toLocal()
        : null;

    return YekiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              YekiAvatar(
                imageUrl: avatarUrl,
                initials: (e['nom'] ?? e['username'] ?? '?')[0].toUpperCase(),
                backgroundColor: YekiColors.primary.withValues(alpha: 0.1),
                radius: 26,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['nom'] ?? e['username'] ?? 'Inconnu',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: YekiColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e['email'] ?? '',
                      style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        YekiRoleBadge(role: userType),
                        const SizedBox(width: 6),
                        YekiStatusIndicator(
                          label: isActive ? 'Autorisé' : 'Non autorisé',
                          color: isActive ? YekiColors.success : YekiColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: YekiColors.primary),
                tooltip: 'Modifier le profil',
                onPressed: () => _modifierEnseignant(e),
              ),
            ],
          ),
          if (dateJoined != null) ...[
            const SizedBox(height: 8),
            Text(
              'Inscrit le ${DateFormat('dd/MM/yyyy').format(dateJoined)}',
              style: const TextStyle(fontSize: 11, color: YekiColors.textMedium),
            ),
          ],
          if (e['bio'] != null && e['bio'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              e['bio'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
            ),
          ],
          if (e['phone'] != null && e['phone'].toString().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('📞 ${e['phone']}', style: const TextStyle(fontSize: 11, color: YekiColors.textMedium)),
          ],
        ],
      ),
    );
  }

  // ─── TAB 5 : Tous les cours ────────────────────────────────────────────
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
                const Text('Erreur lors du chargement des cours', style: TextStyle(fontSize: 16, color: YekiColors.textDark)),
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
                const Text('Aucun cours créé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark)),
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
            'estEnseignantPrincipal': 'false',
            'courseColor': coursColor.value.toString(),
          },
        );
      },
      child: YekiCard(
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
              child: Icon(Icons.book, color: coursColor, size: 20),
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
    );
  }

  Widget _buildGCard(_GS item) {
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(YekiRadius.lg),
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
              borderRadius: BorderRadius.circular(YekiRadius.md),
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
              Text(item.label,
                  style: const TextStyle(fontSize: 12, color: YekiColors.textMedium)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  Widget _sheetHandle() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: YekiColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: YekiColors.textMedium, fontSize: 13),
        labelStyle: const TextStyle(color: YekiColors.textMedium, fontSize: 13),
        prefixIcon: Icon(icon, color: YekiColors.primary, size: 20),
        filled: true,
        fillColor: YekiColors.bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YekiRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YekiRadius.md),
          borderSide: BorderSide(color: YekiColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(YekiRadius.md),
          borderSide: const BorderSide(color: YekiColors.primary, width: 1.5),
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!_mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: YekiColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YekiRadius.md)),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!_mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: YekiColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YekiRadius.md)),
      ),
    );
  }
}

class _GS {
  final String label, value;
  final IconData icon;
  final Color color;
  const _GS(this.label, this.value, this.icon, this.color);
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: YekiColors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}