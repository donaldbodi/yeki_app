// lib/views/pages/enseignants/enseignant_admin_dashboard_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// ENSEIGNANT ADMIN DASHBOARD — CORRIGÉ AVEC IMPORTATION CORRECTE
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';
import 'package:yeki/views/pages/enseignants/detail_cours_enseignant.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart' show RoleEnseignant;
import 'cadre_dashboard_page.dart' show TabBarDelegate;

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
  Map<String, dynamic> _stats = {};
  List _departements = [];
  List _cadres = [];
  List _olympiadesEnAttente = [];
  String _nomEnseignant = '';
  String _nomParcours = '';
  int _idParcours = 0;
  String _typeParcours = 'cursus';

  late TabController _tabCtrl;

  List<String> get _typeDeptOptions {
    switch (_typeParcours) {
      case 'prepa': return ['concours'];
      case 'formation': return ['classique', 'metier'];
      case 'olympiade': return ['normal'];
      default: return ['normal'];
    }
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async =>
      (await SharedPreferences.getInstance()).getString('token');

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.enseignantAdminDashboard),
        headers: ApiHeaders.auth(token),
      );
      if (mounted) {
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          setState(() {
            _stats = (data['stats'] as Map<String, dynamic>?) ?? {};
            _departements = (data['departements'] as List?) ?? [];
            _cadres = (data['cadres'] as List?) ?? [];
            _olympiadesEnAttente = (data['olympiades_en_attente'] as List?) ?? [];
            _nomEnseignant = data['nom'] ?? '';
            _idParcours = data['id_parcours'] ?? 0;
            _nomParcours = data['nom_parcours'] ?? '';
            _typeParcours = data['type_parcours'] ?? 'cursus';
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
          ErrorHandler.showError(context, 'Erreur chargement (${res.statusCode})');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorHandler.showError(context, 'Erreur réseau');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nbEnAttente = _olympiadesEnAttente.length;

    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      floatingActionButton: _nomParcours.isNotEmpty
          ? FloatingActionButton(
              onPressed: _creerDepartement,
              backgroundColor: YekiColors.primaryDark,
              elevation: 4,
              child: const Icon(Icons.add_rounded, color: YekiColors.white, size: 28),
            )
          : null,
      body: _loading
          ? const Center(child: YekiLoader())
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [_buildAppBar(), _buildTabBar(nbEnAttente)],
              body: TabBarView(
                controller: _tabCtrl,
                children: [
                  _tabDepartements(),
                  _tabCadres(),
                  _tabEnAttente(),
                  _tabStats(),
                  _tabTousCours(),
                ],
              ),
            ),
    );
  }

  SliverPersistentHeader _buildTabBar(int nbEnAttente) =>
      SliverPersistentHeader(
        pinned: true,
        delegate: TabBarDelegate(
          TabBar(
            controller: _tabCtrl,
            labelColor: YekiColors.primaryDark,
            unselectedLabelColor: YekiColors.textLight,
            indicatorColor: YekiColors.primaryDark,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              const Tab(text: 'Départements'),
              const Tab(text: 'Cadres'),
              Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Olympiades à valider'),
                  if (nbEnAttente > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: YekiColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$nbEnAttente',
                          style: const TextStyle(color: YekiColors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
              ),
              const Tab(text: 'Statistiques'),
              const Tab(text: 'Tous les cours'),
            ],
          ),
          backgroundColor: YekiColors.white,
        ),
      );

  Widget _tabTousCours() {
    return FutureBuilder<List>(
      future: _chargerTousLesCours(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: YekiLoader());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: YekiColors.error),
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
                    color: YekiColors.primaryDark.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Icon(Icons.book_outlined, size: 48, color: YekiColors.primaryDark),
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
          color: YekiColors.primaryDark,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cours.length,
            itemBuilder: (_, i) => _buildCoursCard(cours[i]),
          ),
        );
      },
    );
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

  Widget _buildCoursCard(Map cours) {
    final colorHex = (cours['color_code'] as String? ?? '#008080').replaceAll('#', '');
    Color coursColor;
    try {
      coursColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      coursColor = YekiColors.primaryDark;
    }
    
    // Récupérer le rôle de l'enseignant pour ce cours
    // Dans le contexte de l'admin enseignant, le rôle est toujours enseignantAdministrateur
    final RoleEnseignant role = RoleEnseignant.enseignantAdministrateur;
    final bool estPrincipal = role == RoleEnseignant.enseignantAdministrateur;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailCoursEnseignantPage(
              coursId: cours['id'].toString(),
              titre: cours['titre'] ?? 'Sans titre',
              estEnseignantPrincipal: estPrincipal,
              role: role,
              courseColor: coursColor,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(fontSize: 12, color: YekiColors.textLight),
                    ),
                    if (cours['departement'] != null)
                      Text(
                        'Département: ${cours['departement']}',
                        style: const TextStyle(fontSize: 11, color: YekiColors.textLight),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: YekiColors.primaryDark, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() => SliverAppBar(
    expandedHeight: 260,
    pinned: true,
    backgroundColor: YekiColors.primaryDark,
    actions: [
      IconButton(icon: const Icon(Icons.refresh, color: YekiColors.white), onPressed: _charger),
    ],
    flexibleSpace: FlexibleSpaceBar(
      collapseMode: CollapseMode.parallax,
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [YekiColors.primaryDark, YekiColors.primaryDark.withValues(alpha: 0.85)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: YekiColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "ADMIN",
                    style: TextStyle(
                      color: YekiColors.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _nomEnseignant.isEmpty ? 'Enseignant Admin' : _nomEnseignant,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: YekiColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Enseignant Administrateur',
                    style: TextStyle(color: YekiColors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 12),
                _parcoursBadge(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _parcoursBadge() {
    if (_nomParcours.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: YekiColors.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: YekiColors.warning, size: 12),
            SizedBox(width: 6),
            Text(
              'Aucun parcours assigné',
              style: TextStyle(color: YekiColors.warning, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
    final typeLabel = {
      'cursus': 'Cursus',
      'prepa': 'Prépa Concours',
      'formation': 'Formations',
      'olympiade': 'Olympiades',
      'autre': 'Parcours',
    }[_typeParcours] ?? _typeParcours;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: YekiColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, color: YekiColors.accent, size: 12),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Coordonnateur · $_nomParcours ($typeLabel)',
              style: const TextStyle(color: YekiColors.white, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabDepartements() => RefreshIndicator(
    onRefresh: _charger,
    color: YekiColors.primaryDark,
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
          borderRadius: BorderRadius.circular(16),
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
          colors: [YekiColors.primaryDark, YekiColors.primaryDark.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(20),
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
              color: YekiColors.primaryDark.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(_typeDeptOptions.isNotEmpty 
                ? Icons.domain_rounded 
                : Icons.school_rounded,
                size: 48, color: YekiColors.primaryDark),
          ),
          const SizedBox(height: 16),
          Text(_typeParcours == 'prepa'
              ? 'Aucun concours créé'
              : _typeParcours == 'formation'
                  ? 'Aucune formation créée'
                  : 'Aucun département créé',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Commencez par créer votre premier élément',
              style: const TextStyle(fontSize: 13)),
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
    final color = _typeDeptColors[typeDept] ?? YekiColors.primaryDark;
    final icon = _typeDeptIcons[typeDept] ?? Icons.domain_rounded;
    final label = _typeDeptLabels[typeDept] ?? 'Département';
    final niveauFormation = dept['niveau_formation'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(12),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                    icon: const Icon(Icons.edit_outlined, color: YekiColors.primaryDark, size: 18),
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
                        style: const TextStyle(fontSize: 12)),
                  ],
                )
              else
                _aucunCadreBadge(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.book_outlined, size: 13),
                  const SizedBox(width: 4),
                  Text('$nbCours cours', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  Icon(Icons.people_outlined, size: 13),
                  const SizedBox(width: 4),
                  Text('$nbIns inscrits', style: const TextStyle(fontSize: 12)),
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

  Widget _tabCadres() {
    if (_cadres.isEmpty) {
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
              child: Icon(Icons.person_outline_rounded, size: 48, color: YekiColors.primaryDark),
            ),
            const SizedBox(height: 16),
            Text('Aucun enseignant cadre',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primaryDark,
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
        borderRadius: BorderRadius.circular(16),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cadre['nom'] ?? cadre['username'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (dept != null)
                    Text(dept['nom'] ?? '',
                        style: const TextStyle(fontSize: 12, color: YekiColors.purple)),
                  Text('${cadre['nb_cours'] ?? 0} cours · ${cadre['nb_apprenants'] ?? 0} apprenants',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabEnAttente() {
    final total = _olympiadesEnAttente.length;
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: YekiColors.success.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: YekiColors.success.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(Icons.check_circle_outline_rounded, size: 48, color: YekiColors.success),
            ),
            const SizedBox(height: 16),
            Text('Toutes les olympiades sont validées !', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primaryDark,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Olympiades à valider', Icons.military_tech_rounded, YekiColors.warning),
          ..._olympiadesEnAttente.map((o) => _buildOlympiadeEnAttenteCard(o as Map<String, dynamic>)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildOlympiadeEnAttenteCard(Map<String, dynamic> olympiade) {
    final nom = olympiade['titre'] ?? '';
    final cadre = olympiade['cadre'] as Map?;
    final statutValidation = olympiade['statut_validation'] as String? ?? 'attente';
    final motifRefus = olympiade['motif_refus'] as String? ?? '';
    final niveauxAccessibles = olympiade['niveaux_accessibles'] as List? ?? [];
    final prixGlobal = olympiade['prix_global'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statutValidation == 'refuse' 
              ? YekiColors.error.withValues(alpha: 0.5) 
              : YekiColors.warning.withValues(alpha: 0.5), 
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: YekiColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.military_tech_rounded, color: YekiColors.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Olympiade gratuite (prix_global: $prixGlobal FCFA)',
                      style: TextStyle(color: YekiColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    if (niveauxAccessibles.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: niveauxAccessibles.map((niveau) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: YekiColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            niveau,
                            style: TextStyle(
                              fontSize: 10,
                              color: YekiColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statutValidation == 'refuse' 
                      ? YekiColors.error.withValues(alpha: 0.1) 
                      : YekiColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statutValidation == 'refuse' ? 'Refusée' : 'En attente',
                  style: TextStyle(
                    color: statutValidation == 'refuse' ? YekiColors.error : YekiColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (statutValidation == 'refuse' && motifRefus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: YekiColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: YekiColors.error, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Motif : $motifRefus',
                      style: TextStyle(color: YekiColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (cadre != null) ...[
            const SizedBox(height: 8),
            Text(
              'Cadre : ${cadre['nom'] ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
          if (statutValidation == 'attente') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _validerOlympiade(olympiade['id'] as int, nom),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: YekiColors.success,
                      foregroundColor: YekiColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRefusDialogOlympiade(olympiade['id'] as int, nom),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: YekiColors.error,
                      side: const BorderSide(color: YekiColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabStats() {
    final items = [
      _SI('Départements', '${_stats['nb_departements'] ?? _departements.length}', Icons.domain, YekiColors.primaryDark),
      _SI('Cours', '${_stats['nb_cours'] ?? 0}', Icons.book, YekiColors.purple),
      _SI('Inscrits', '${_stats['nb_apprenants'] ?? 0}', Icons.people, Colors.teal),
      _SI('Cadres', '${_stats['nb_enseignants'] ?? 0}', Icons.person_outline, YekiColors.warning),
      _SI('Olympiades attente', '${_stats['nb_olympiades_attente'] ?? 0}', Icons.hourglass_top, YekiColors.error),
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
            children: items.map(_buildStatCard).toList(),
          ),
          if (_departements.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.leaderboard, color: YekiColors.primaryDark, size: 18),
                const SizedBox(width: 8),
                const Text('Classement des départements',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: YekiColors.borderLight, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 0 ? YekiColors.accent : i == 1 ? YekiColors.borderMedium : YekiColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: YekiColors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(d['nom'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${taux.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: YekiColors.primaryDark)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(_SI item) => Container(
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
            Text(item.value,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: item.color)),
            Text(item.label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════
  // MODIFICATION D'UN DÉPARTEMENT
  // ═══════════════════════════════════════════════════════════════════════

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
    
    bool isLoading = false;
    List<String> niveauxDisponibles = [];
    bool niveauxCharges = false;

    Future<void> chargerNiveaux() async {
      if (niveauxCharges) return;
      final token = await _getToken();
      if (token == null) return;
      try {
        final res = await http.get(
          Uri.parse(ApiConstants.niveaux),
          headers: ApiHeaders.auth(token),
        );
        if (mounted) {
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            niveauxDisponibles = List<String>.from(data);
            niveauxCharges = true;
          } else {
            niveauxDisponibles = [];
            niveauxCharges = true;
          }
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
        // Charger les niveaux au démarrage
        chargerNiveaux();
        return StatefulBuilder(
          builder: (ctx, setS) => Container(
            decoration: const BoxDecoration(
              color: YekiColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Parcours : $_nomParcours', style: const TextStyle(fontSize: 13)),
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
                    title: const Text('Accès restreint', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Les apprenants doivent demander l\'accès'),
                    activeColor: YekiColors.primaryDark,
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
                    const Text('Type de formation', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      const Text('Niveau de la formation', style: TextStyle(fontWeight: FontWeight.w600)),
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
                            selectedColor: YekiColors.primaryDark.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: sel ? YekiColors.primaryDark : YekiColors.textLight,
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
                    
                    const Text('Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['hybride', 'presentiel', 'distance'].map((m) {
                        final labels = {'hybride': 'Hybride', 'presentiel': 'Présentiel', 'distance': 'À distance'};
                        final sel = mode == m;
                        return ChoiceChip(
                          label: Text(labels[m]!),
                          selected: sel,
                          selectedColor: YekiColors.primaryDark.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: sel ? YekiColors.primaryDark : YekiColors.textLight,
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
                  ],
                  
                  const SizedBox(height: 24),
                  YekiButton(
                    label: 'Mettre à jour',
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
                          if(dateLimiteCtrl.text.trim().isNotEmpty) body['date_limite_inscription'] = dateLimiteCtrl.text.trim();
                          if(dateExamenCtrl.text.trim().isNotEmpty) body['date_examen'] = dateExamenCtrl.text.trim();
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
                        }
                        
                        final res = await http.patch(
                          Uri.parse('${ApiConstants.baseUrl}/admin/departements/${dept['id']}/update/'),
                          headers: ApiHeaders.auth(token),
                          body: jsonEncode(body),
                        );
                        
                        setS(() => isLoading = false);
                        
                        if (mounted && res.statusCode == 200) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) ErrorHandler.showSuccess(context, '✅ Département modifié !');
                          _charger();
                        } else {
                          // Afficher les erreurs détaillées
                          if (mounted) {
                            final err = jsonDecode(res.body);
                            if (err is Map && err.containsKey('detail')) {
                              ErrorHandler.showError(context, err['detail'] as String);
                            } else {
                              ErrorHandler.showError(context, 'Erreur de validation');
                            }
                          }
                        }
                      } catch (e) {
                        setS(() => isLoading = false);
                        if (mounted) ErrorHandler.showError(context, 'Erreur réseau: $e');
                      }
                    },
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        const Text('Niveaux accessibles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: YekiColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YekiColors.borderLight, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: null,
              isExpanded: true,
              hint: charges 
                  ? (disponibles.isNotEmpty 
                      ? const Text('Ajouter un niveau...') 
                      : const Text('Aucun niveau disponible pour l\'instant'))
                  : const Text('Chargement des niveaux...'),
              items: disponibles.where((n) => !selected.contains(n)).map((n) {
                return DropdownMenuItem<String>(
                  value: n,
                  child: Text(n),
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
                color: YekiColors.primaryDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.2), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(n, style: TextStyle(fontSize: 12, color: YekiColors.primaryDark)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setS(() => selected.remove(n)),
                    child: Icon(Icons.close_rounded, size: 14, color: YekiColors.primaryDark),
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

  // ═══════════════════════════════════════════════════════════════════════
  // CRÉATION D'UN DÉPARTEMENT
  // ═══════════════════════════════════════════════════════════════════════

  void _creerDepartement() {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: '0');
    final prixPresentielCtrl = TextEditingController(text: '0');
    List<String> niveauxDisponibles = [];
    List<String> niveauxSelectionnes = [];
    bool isLoading = false;
    bool niveauxCharges = false;
    bool accesRestreint = false;
    String mode = 'hybride';
    bool estFormationMetier = false;
    bool estFormationClassique = false;
    String niveauFormation = 'debutant';
    
    // Contrôleurs pour champs spécifiques
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

    Future<void> chargerNiveaux() async {
      if (niveauxCharges) return;
      final token = await _getToken();
      if (token == null) return;
      try {
        final res = await http.get(
          Uri.parse(ApiConstants.niveaux),
          headers: ApiHeaders.auth(token),
        );
        if (mounted) {
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            niveauxDisponibles = List<String>.from(data);
            niveauxCharges = true;
          } else {
            niveauxDisponibles = [];
            niveauxCharges = true;
          }
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
        // Charger les niveaux au démarrage
        chargerNiveaux();
        return StatefulBuilder(
          builder: (ctx, setS) => Container(
            decoration: const BoxDecoration(
              color: YekiColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Parcours : $_nomParcours', style: const TextStyle(fontSize: 13)),
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
                    title: const Text('Accès restreint', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Les apprenants doivent demander l\'accès'),
                    activeColor: YekiColors.primaryDark,
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
                    const Text('Type de formation', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      const Text('Niveau de la formation', style: TextStyle(fontWeight: FontWeight.w600)),
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
                            selectedColor: YekiColors.primaryDark.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: sel ? YekiColors.primaryDark : YekiColors.textLight,
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
                    
                    const Text('Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['hybride', 'presentiel', 'distance'].map((m) {
                        final labels = {'hybride': 'Hybride', 'presentiel': 'Présentiel', 'distance': 'À distance'};
                        final sel = mode == m;
                        return ChoiceChip(
                          label: Text(labels[m]!),
                          selected: sel,
                          selectedColor: YekiColors.primaryDark.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: sel ? YekiColors.primaryDark : YekiColors.textLight,
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
                      title: const Text('Formation certifiante', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Délivre un certificat reconnu à la fin'),
                      activeColor: YekiColors.accent,
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  YekiButton(
                    label: 'Créer',
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
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VALIDATION OLYMPIADE
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _validerOlympiade(int id, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Valider l\'olympiade', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Confirmer la validation de "$nom" ?\nElle sera visible pour les apprenants.', style: const TextStyle()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: YekiColors.success, foregroundColor: YekiColors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final token = await _getToken();
    if (token == null) return;
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/admin/olympiades/$id/valider/'),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({}),
      );
      if (mounted) {
        if (res.statusCode == 200) {
          ErrorHandler.showSuccess(context, '✅ Olympiade "$nom" validée !');
          _enregistrerHistorique('Validation olympiade', 'Olympiade "$nom" validée avec succès.');
          _charger();
        } else {
          ErrorHandler.showError(context, 'Erreur lors de la validation');
        }
      }
    } catch (_) {
      if (mounted) ErrorHandler.showError(context, 'Erreur réseau');
    }
  }

  Future<void> _showRefusDialogOlympiade(int id, String nom) async {
    final motifCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Refuser l\'olympiade', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Refuser "$nom" ?', style: const TextStyle()),
            const SizedBox(height: 12),
            TextField(
              controller: motifCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Motif du refus (optionnel)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: YekiColors.error, foregroundColor: YekiColors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _refuserOlympiade(id, nom, motifCtrl.text.trim());
    }
  }

  Future<void> _refuserOlympiade(int id, String nom, String motif) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/admin/olympiades/$id/refuser/'),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({'motif': motif}),
      );
      if (mounted) {
        if (res.statusCode == 200) {
          ErrorHandler.showSuccess(context, 'Olympiade "$nom" refusée.');
          _enregistrerHistorique('Refus olympiade', 'Olympiade "$nom" refusée. Motif: $motif');
          _charger();
        } else {
          ErrorHandler.showError(context, 'Erreur lors du refus');
        }
      }
    } catch (_) {
      if (mounted) ErrorHandler.showError(context, 'Erreur réseau');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ENREGISTRER DANS L'HISTORIQUE
  // ═══════════════════════════════════════════════════════════════════════

  void _enregistrerHistorique(String action, String description) {
    // Cette méthode enregistre l'activité dans l'historique
    // Pour l'instant, on affiche un snackbar de confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📝 $action: $description', style: const TextStyle(color: Colors.white)),
          backgroundColor: YekiColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // TODO: Implémenter l'appel à l'API pour enregistrer dans l'historique
    // Exemple: http.post(Uri.parse('${ApiConstants.baseUrl}/historique/'), ...)
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHANGER CADRE
  // ═══════════════════════════════════════════════════════════════════════

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

    if (!mounted) return;
    int? selected = dept['cadre']?['id'] as int?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Département : ${dept['nom'] ?? ''}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: cadresDisp.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Aucun enseignant cadre disponible.',
                              textAlign: TextAlign.center),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: cadresDisp.map<Widget>((e) => RadioListTile<int>(
                          value: e['id'] as int,
                          groupValue: selected,
                          activeColor: YekiColors.primaryDark,
                          title: Text(e['nom'] ?? e['username'] ?? ''),
                          subtitle: Text(e['email'] ?? ''),
                          onChanged: (v) => setS(() => selected = v),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 20),
              YekiButton(
                label: 'Confirmer',
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
                        _enregistrerHistorique('Changement cadre', 'Cadre modifié pour le département ${dept['nom']}');
                        _charger();
                      } else {
                        ErrorHandler.showError(context, 'Erreur lors du changement de cadre');
                      }
                    }
                  } catch (_) {
                    if (mounted) ErrorHandler.showError(context, 'Erreur réseau');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _voirDetailDepartement(Map dept) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailDeptSheet(dept: dept),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(8)),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13),
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, color: YekiColors.primaryDark, size: 20),
        filled: true,
        fillColor: YekiColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: YekiColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: YekiColors.primaryDark, width: 1.5),
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _aucunCadreBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: YekiColors.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
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

  Widget _sectionTitle(String title, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    ),
  );

  Widget _typeChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? YekiColors.primaryDark.withValues(alpha: 0.08) : YekiColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? YekiColors.primaryDark : YekiColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? YekiColors.primaryDark : YekiColors.textLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? YekiColors.primaryDark : YekiColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, Color> _typeDeptColors = {
  'normal': YekiColors.primaryDark,
  'classique': Colors.teal,
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

// ═══════════════════════════════════════════════════════════════════════
// DETAIL DEPARTEMENT (avec cours groupés par niveau)
// ═══════════════════════════════════════════════════════════════════════
class _DetailDeptSheet extends StatefulWidget {
  final Map dept;
  const _DetailDeptSheet({required this.dept});

  @override
  State<_DetailDeptSheet> createState() => _DetailDeptSheetState();
}

class _DetailDeptSheetState extends State<_DetailDeptSheet> {
  List _cours = [];
  List _inscrits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString('token');
    final id = widget.dept['id'];
    try {
      final results = await Future.wait([
        http.get(
          Uri.parse(ApiConstants.departementCours(id)),
          headers: ApiHeaders.auth(token),
        ),
        http.get(
          Uri.parse('${ApiConstants.baseUrl}/departements/$id/inscriptions/'),
          headers: ApiHeaders.auth(token),
        ),
      ]);
      if (mounted) {
        setState(() {
          if (results[0].statusCode == 200) _cours = jsonDecode(results[0].body);
          if (results[1].statusCode == 200) _inscrits = jsonDecode(results[1].body);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dept = widget.dept;
    final typeDept = dept['type_dept'] as String? ?? 'normal';
    final prix = dept['prix'] as int? ?? 0;
    final color = _typeDeptColors[typeDept] ?? YekiColors.primaryDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dept['nom'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(dept['parcours'] ?? '', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (prix > 0)
                      Text('$prix FCFA', style: const TextStyle(fontWeight: FontWeight.w700))
                    else
                      Text('Gratuit', style: TextStyle(color: YekiColors.success, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 20, color: YekiColors.borderLight),
          Expanded(
            child: _loading
                ? const Center(child: YekiLoader())
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: const [Tab(text: 'Cours par niveau'), Tab(text: 'Inscrits')],
                          labelColor: YekiColors.primaryDark,
                          unselectedLabelColor: YekiColors.textLight,
                          indicatorColor: YekiColors.primaryDark,
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _cours.isEmpty
                                  ? const Center(child: Text('Aucun cours', style: TextStyle()))
                                  : _buildCoursParNiveau(),
                              _inscrits.isEmpty
                                  ? const Center(child: Text('Aucun inscrit', style: TextStyle()))
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _inscrits.length,
                                      itemBuilder: (_, i) {
                                        final ins = _inscrits[i];
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: YekiColors.backgroundLight,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: YekiColors.borderLight, width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: color.withValues(alpha: 0.1),
                                                child: Text(
                                                    (ins['nom'] ?? ins['username'] ?? '?')[0].toUpperCase(),
                                                    style: TextStyle(color: color)),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(ins['nom'] ?? ins['username'] ?? '',
                                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                                    Text(ins['inscrit_le']?.toString().substring(0, 10) ?? '',
                                                        style: const TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursParNiveau() {
    // Grouper les cours par niveau
    final Map<String, List> grouped = {};
    for (final c in _cours) {
      final niveau = c['niveau'] ?? 'Non spécifié';
      if (!grouped.containsKey(niveau)) {
        grouped[niveau] = [];
      }
      grouped[niveau]!.add(c);
    }

    // Trier les niveaux
    final sortedNiveaux = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedNiveaux.length,
      itemBuilder: (_, i) {
        final niveau = sortedNiveaux[i];
        final coursNiveau = grouped[niveau]!;
        final typeDept = widget.dept['type_dept'] as String? ?? 'normal';
        final color = _typeDeptColors[typeDept] ?? YekiColors.primaryDark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Niveau: $niveau (${coursNiveau.length} cours)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ),
            ),
            ...coursNiveau.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: YekiColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: YekiColors.borderLight, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.book, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['titre'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${c['nb_apprenants'] ?? 0} apprenants',
                            style: const TextStyle(fontSize: 12)),
                        if (c['nb_lecons'] != null && c['nb_devoirs'] != null)
                          Text('${c['nb_lecons']} leçons · ${c['nb_devoirs']} devoirs',
                              style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _SI {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SI(this.label, this.value, this.icon, this.color);
}