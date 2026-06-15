// lib/views/pages/enseignants/enseignant_admin_dashboard_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// ENSEIGNANT ADMIN DASHBOARD — CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';
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
  List _deptsEnAttente = [];
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
    _tabCtrl = TabController(length: 4, vsync: this);
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
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _stats = (data['stats'] as Map<String, dynamic>?) ?? {};
          _departements = (data['departements'] as List?) ?? [];
          _cadres = (data['cadres'] as List?) ?? [];
          _deptsEnAttente = (data['departements_en_attente'] as List?) ?? [];
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
    } catch (_) {
      setState(() => _loading = false);
      ErrorHandler.showError(context, 'Erreur réseau');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nbEnAttente = _deptsEnAttente.length + _olympiadesEnAttente.length;

    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      floatingActionButton: _nomParcours.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: YekiColors.primaryDark,
              elevation: 4,
              child: const Icon(Icons.add_rounded, color: YekiColors.white, size: 28),
              onPressed: _creerDepartement,
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
                ],
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
                  const Text('En attente'),
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
            ],
          ),
          backgroundColor: YekiColors.white,
        ),
      );

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
        child: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: YekiColors.warning, size: 22),
          SizedBox(width: 12),
          Expanded(child: Text(
            'Aucun parcours ne vous est encore assigné.\nContactez l\'administrateur général.',
            style: TextStyle(color: YekiColors.warning, fontSize: 13),
          )),
        ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: YekiColors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(typeIcon, color: YekiColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mon parcours', style: TextStyle(color: YekiColors.white.withValues(alpha: 0.7), fontSize: 12)),
              Text('Coordonnateur', style: TextStyle(color: YekiColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: YekiColors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text('${_departements.length} dép.',
                style: const TextStyle(color: YekiColors.white, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 14),
        Divider(color: YekiColors.white.withValues(alpha: 0.24), height: 1),
        const SizedBox(height: 14),
        Text(_nomParcours,
            style: const TextStyle(color: YekiColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          _quickStat('${_stats['nb_cours'] ?? 0}', 'cours'),
          const SizedBox(width: 16),
          _quickStat('${_stats['nb_apprenants'] ?? 0}', 'inscrits'),
          const SizedBox(width: 16),
          _quickStat('${_stats['nb_enseignants'] ?? 0}', 'cadres'),
        ]),
      ]),
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
      child: Column(children: [
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
      ]),
    ),
  );

  Widget _buildDeptCard(Map<String, dynamic> dept) {
    final typeDept = dept['type_dept'] as String? ?? 'normal';
    final estValide = dept['est_valide'] == true;
    final prix = dept['prix'] as int? ?? 0;
    final nbCours = dept['nb_cours'] as int? ?? 0;
    final nbIns = dept['nb_inscrits'] as int? ?? 0;
    final cadre = dept['cadre'] as Map?;
    final color = _typeDeptColors[typeDept] ?? YekiColors.primaryDark;
    final icon = _typeDeptIcons[typeDept] ?? Icons.domain_rounded;
    final label = _typeDeptLabels[typeDept] ?? 'Département';
    final statutValidation = dept['statut_validation'] as String? ?? (estValide ? 'valide' : 'attente');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: estValide
            ? Border.all(color: YekiColors.borderLight, width: 1)
            : Border.all(color: YekiColors.warning.withValues(alpha: 0.5), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _voirDetailDepartement(dept),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
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
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dept['nom'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(children: [
                  _miniChip(label, color),
                  const SizedBox(width: 6),
                  if (prix > 0)
                    _miniChip('$prix FCFA', YekiColors.accent)
                  else
                    _miniChip('Gratuit', YekiColors.success),
                ]),
              ])),
              IconButton(
                icon: Icon(cadre == null ? Icons.person_add_outlined : Icons.swap_horiz,
                    color: color),
                tooltip: cadre == null ? 'Nommer un cadre' : 'Changer cadre',
                onPressed: () => _changerCadre(dept),
              ),
            ]),
            const SizedBox(height: 10),
            if (cadre != null)
              Row(children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: YekiColors.purple.withValues(alpha: 0.1),
                  child: Icon(Icons.person, size: 14, color: YekiColors.purple),
                ),
                const SizedBox(width: 8),
                Text('Cadre : ${cadre['nom'] ?? cadre['username'] ?? ''}',
                    style: const TextStyle(fontSize: 12)),
              ])
            else
              _aucunCadreBadge(),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.book_outlined, size: 13),
              const SizedBox(width: 4),
              Text('$nbCours cours', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.people_outlined, size: 13),
              const SizedBox(width: 4),
              Text('$nbIns inscrits', style: const TextStyle(fontSize: 12)),
              const Spacer(),
              if (statutValidation == 'attente')
                _buildBoutonsValidation(dept)
              else if (statutValidation == 'refuse')
                _buildRefuseBadge(dept)
              else
                Row(children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: YekiColors.success),
                  const SizedBox(width: 4),
                  Text('Validé', style: TextStyle(fontSize: 11, color: YekiColors.success, fontWeight: FontWeight.w600)),
                ]),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildBoutonsValidation(Map<String, dynamic> dept) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: YekiColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: YekiColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.hourglass_top_rounded, size: 11, color: YekiColors.warning),
        const SizedBox(width: 4),
        const Text('À valider', style: TextStyle(fontSize: 10, color: YekiColors.warning, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _validerDepartement(dept['id'] as int, dept['nom'] ?? ''),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: YekiColors.success, borderRadius: BorderRadius.circular(8)),
            child: const Text('Valider',
                style: TextStyle(color: YekiColors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _showRefusDialogDepartement(dept['id'] as int, dept['nom'] ?? ''),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: YekiColors.error, borderRadius: BorderRadius.circular(8)),
            child: const Text('Refuser',
                style: TextStyle(color: YekiColors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }

  Widget _buildRefuseBadge(Map<String, dynamic> dept) {
    final motifRefus = dept['motif_refus'] as String? ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: YekiColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: YekiColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cancel_rounded, size: 11, color: YekiColors.error),
            const SizedBox(width: 4),
            const Text('Refusé', style: TextStyle(fontSize: 10, color: YekiColors.error, fontWeight: FontWeight.w700)),
          ]),
        ),
        if (motifRefus.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Motif : $motifRefus',
              style: const TextStyle(fontSize: 10, color: YekiColors.error, fontStyle: FontStyle.italic),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ],
    );
  }

  Widget _tabCadres() {
    if (_cadres.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
      ]));
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
        child: Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: YekiColors.purple.withValues(alpha: 0.1),
            child: Text((cadre['nom'] ?? 'C')[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cadre['nom'] ?? cadre['username'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (dept != null)
              Text(dept['nom'] ?? '',
                  style: const TextStyle(fontSize: 12, color: YekiColors.purple)),
            Text('${cadre['nb_cours'] ?? 0} cours · ${cadre['nb_apprenants'] ?? 0} apprenants',
                style: const TextStyle(fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _tabEnAttente() {
    final total = _deptsEnAttente.length + _olympiadesEnAttente.length;
    if (total == 0) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
        Text('Tout est validé !', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primaryDark,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_deptsEnAttente.isNotEmpty) ...[
            _sectionTitle('Départements à valider', Icons.domain_rounded, YekiColors.warning),
            ..._deptsEnAttente.map((d) => _buildDeptEnAttenteCard(d as Map<String, dynamic>)),
            const SizedBox(height: 16),
          ],
          if (_olympiadesEnAttente.isNotEmpty) ...[
            _sectionTitle('Olympiades à valider', Icons.military_tech_rounded, YekiColors.warning),
            ..._olympiadesEnAttente.map((o) => _buildOlympiadeEnAttenteCard(o as Map<String, dynamic>)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDeptEnAttenteCard(Map<String, dynamic> dept) {
    final typeDept = dept['type_dept'] as String? ?? 'normal';
    final color = _typeDeptColors[typeDept] ?? YekiColors.primaryDark;
    final icon = _typeDeptIcons[typeDept] ?? Icons.domain_rounded;
    final label = _typeDeptLabels[typeDept] ?? 'Département';
    final nom = dept['nom'] ?? '';
    final cadre = dept['cadre'] as Map?;
    final statutValidation = dept['statut_validation'] as String? ?? 'attente';
    final motifRefus = dept['motif_refus'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statutValidation == 'refuse' ? YekiColors.error.withValues(alpha: 0.5) : YekiColors.warning.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statutValidation == 'refuse' ? YekiColors.error.withValues(alpha: 0.1) : YekiColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statutValidation == 'refuse' ? 'Refusé' : 'En attente',
              style: TextStyle(
                color: statutValidation == 'refuse' ? YekiColors.error : YekiColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
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
                  child: Text('Motif : $motifRefus', style: TextStyle(color: YekiColors.error, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
        if (cadre != null) ...[
          const SizedBox(height: 8),
          Text('Cadre : ${cadre['nom'] ?? ''}', style: const TextStyle(fontSize: 12)),
        ],
        if (statutValidation == 'attente') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _validerDepartement(dept['id'] as int, nom),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: YekiColors.success,
                  foregroundColor: YekiColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRefusDialogDepartement(dept['id'] as int, nom),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Refuser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: YekiColors.error,
                  side: const BorderSide(color: YekiColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _buildOlympiadeEnAttenteCard(Map<String, dynamic> olympiade) {
    final nom = olympiade['titre'] ?? '';
    final cadre = olympiade['cadre'] as Map?;
    final statutValidation = olympiade['statut_validation'] as String? ?? 'attente';
    final motifRefus = olympiade['motif_refus'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statutValidation == 'refuse' ? YekiColors.error.withValues(alpha: 0.5) : YekiColors.warning.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: YekiColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.military_tech_rounded, color: YekiColors.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text('Olympiade', style: TextStyle(color: YekiColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statutValidation == 'refuse' ? YekiColors.error.withValues(alpha: 0.1) : YekiColors.warning.withValues(alpha: 0.1),
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
        ]),
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
                  child: Text('Motif : $motifRefus', style: TextStyle(color: YekiColors.error, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
        if (cadre != null) ...[
          const SizedBox(height: 8),
          Text('Cadre : ${cadre['nom'] ?? ''}', style: const TextStyle(fontSize: 12)),
        ],
        if (statutValidation == 'attente') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _validerOlympiade(olympiade['id'] as int, nom, 'valider'),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: YekiColors.success,
                  foregroundColor: YekiColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _tabStats() {
    final items = [
      _SI('Départements', '${_stats['nb_departements'] ?? _departements.length}', Icons.domain, YekiColors.primaryDark),
      _SI('Cours', '${_stats['nb_cours'] ?? 0}', Icons.book, YekiColors.purple),
      _SI('Inscrits', '${_stats['nb_apprenants'] ?? 0}', Icons.people, Colors.teal),
      _SI('Cadres', '${_stats['nb_enseignants'] ?? 0}', Icons.person_outline, YekiColors.warning),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
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
          Row(children: [
            Icon(Icons.leaderboard, color: YekiColors.primaryDark, size: 18),
            const SizedBox(width: 8),
            const Text('Classement des départements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
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
              child: Row(children: [
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
              ]),
            );
          }),
        ],
      ]),
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
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: item.color)),
          Text(item.label, style: const TextStyle(fontSize: 12)),
        ]),
      ],
    ),
  );

  void _creerDepartement() {
    final nomCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: '0');
    String typeDeptSel = _typeDeptOptions.first;
    String? niveauSelectionne;
    List<String> niveauxDisponibles = [];
    bool isLoading = false;
    bool _niveauxCharges = false;

    Future<void> _chargerNiveaux() async {
      if (_niveauxCharges) return;
      final token = await _getToken();
      if (token == null) return;
      try {
        final res = await http.get(
          Uri.parse(ApiConstants.niveaux),
          headers: ApiHeaders.auth(token),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          niveauxDisponibles = List<String>.from(data);
          _niveauxCharges = true;
        }
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        _chargerNiveaux();
        return StatefulBuilder(
          builder: (ctx, setS) => Container(
            decoration: BoxDecoration(
              color: YekiColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  if (_typeParcours == 'formation' || _typeParcours == 'prepa') ...[
                    const Text('Niveau *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                          value: niveauSelectionne,
                          isExpanded: true,
                          hint: Text(
                            _niveauxCharges ? 'Sélectionner un niveau...' : 'Chargement...',
                            style: const TextStyle(fontSize: 14),
                          ),
                          icon: Icon(Icons.keyboard_arrow_down, color: YekiColors.primaryDark),
                          items: niveauxDisponibles.map((niveau) {
                            return DropdownMenuItem<String>(
                              value: niveau,
                              child: Text(niveau, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) => setS(() => niveauSelectionne = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_typeDeptOptions.length > 1) ...[
                    const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _typeDeptOptions.map((t) {
                        final selected = typeDeptSel == t;
                        final c = _typeDeptColors[t] ?? YekiColors.primaryDark;
                        return ChoiceChip(
                          label: Text(_typeDeptLabels[t] ?? t),
                          selected: selected,
                          selectedColor: c.withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: selected ? c : YekiColors.textLight),
                          onSelected: (_) => setS(() => typeDeptSel = t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_typeParcours == 'prepa' || _typeParcours == 'formation') ...[
                    _field(prixCtrl, 'Prix (FCFA)', Icons.attach_money_rounded,
                        '0 = gratuit (validation requise)'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: YekiColors.primaryDark.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.15), width: 1),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: YekiColors.primaryDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Prix = 0 : requiert votre validation avant d\'être visible.\nPrix > 0 : validé automatiquement.',
                            style: TextStyle(fontSize: 11, color: YekiColors.primaryDark),
                          ),
                        ),
                      ]),
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
                      if ((_typeParcours == 'formation' || _typeParcours == 'prepa') && niveauSelectionne == null) {
                        ErrorHandler.showError(context, 'Veuillez sélectionner un niveau');
                        return;
                      }
                      setS(() => isLoading = true);
                      final token = await _getToken();
                      if (token == null) {
                        setS(() => isLoading = false);
                        return;
                      }
                      try {
                        int prix = 0;
                        if (_typeParcours == 'prepa' || _typeParcours == 'formation') {
                          prix = int.tryParse(prixCtrl.text.trim()) ?? 0;
                        }
                        final body = <String, dynamic>{
                          'nom': nomCtrl.text.trim(),
                          'parcours_id': _idParcours,
                          'type_dept': typeDeptSel,
                          'description': descCtrl.text.trim(),
                          'prix': prix,
                        };
                        if (niveauSelectionne != null) {
                          body['niveau'] = niveauSelectionne;
                        }
                        final res = await http.post(
                          Uri.parse(ApiConstants.departementsCreer),
                          headers: ApiHeaders.auth(token),
                          body: jsonEncode(body),
                        );
                        setS(() => isLoading = false);
                        if (res.statusCode == 201) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (prix == 0 && (_typeParcours == 'formation')) {
                            ErrorHandler.showSuccess(context, 'Département créé ! En attente de validation.');
                          } else {
                            ErrorHandler.showSuccess(context, 'Département créé avec succès !');
                          }
                          _charger();
                        } else {
                          final err = jsonDecode(res.body);
                          ErrorHandler.showError(context, err['detail'] ?? 'Erreur ${res.statusCode}');
                        }
                      } catch (_) {
                        setS(() => isLoading = false);
                        ErrorHandler.showError(context, 'Erreur réseau');
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

  Future<void> _validerDepartement(int id, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Valider le département', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Confirmer la validation de "$nom" ?\nIl sera visible pour les apprenants.', style: const TextStyle()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium))),
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
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/departements/$id/valider/'),
      headers: ApiHeaders.auth(token),
    );
    if (res.statusCode == 200) {
      ErrorHandler.showSuccess(context, '✅ Département "$nom" validé !');
      _charger();
    } else {
      ErrorHandler.showError(context, 'Erreur');
    }
  }

  Future<void> _showRefusDialogDepartement(int id, String nom) async {
    final motifCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Refuser le département', style: TextStyle(fontWeight: FontWeight.bold)),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: YekiColors.error, foregroundColor: YekiColors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _refuserDepartement(id, nom, motifCtrl.text.trim());
    }
  }

  Future<void> _refuserDepartement(int id, String nom, String motif) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/departements/$id/refuser/'),
      headers: ApiHeaders.auth(token),
      body: jsonEncode({'motif': motif}),
    );
    if (res.statusCode == 200) {
      ErrorHandler.showSuccess(context, 'Département "$nom" refusé.');
      _charger();
    } else {
      ErrorHandler.showError(context, 'Erreur');
    }
  }

  Future<void> _validerOlympiade(int id, String titre, String action) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/olympiades/$id/valider/'),
      headers: ApiHeaders.auth(token),
      body: jsonEncode({'action': action}),
    );
    if (res.statusCode == 200) {
      ErrorHandler.showSuccess(context, action == 'valider' ? '✅ Olympiade validée !' : 'Olympiade rejetée.');
      _charger();
    } else {
      ErrorHandler.showError(context, 'Erreur');
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
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium))),
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
    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/olympiades/$id/refuser/'),
      headers: ApiHeaders.auth(token),
      body: jsonEncode({'motif': motif}),
    );
    if (res.statusCode == 200) {
      ErrorHandler.showSuccess(context, 'Olympiade "$nom" refusée.');
      _charger();
    } else {
      ErrorHandler.showError(context, 'Erreur');
    }
  }

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
        ErrorHandler.showError(context, 'Impossible de charger les cadres');
        return;
      }
    } catch (_) {
      ErrorHandler.showError(context, 'Erreur réseau');
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                final res = await http.patch(
                  Uri.parse('${ApiConstants.baseUrl}/departements/${dept['id']}/changer-cadre/'),
                  headers: ApiHeaders.auth(t2),
                  body: jsonEncode({'cadre_id': selected}),
                );
                if (res.statusCode == 200) {
                  ErrorHandler.showSuccess(context, 'Cadre modifié !');
                  _charger();
                } else {
                  ErrorHandler.showError(context, 'Erreur');
                }
              },
            ),
          ]),
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
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.warning_outlined, size: 13, color: YekiColors.warning),
      SizedBox(width: 5),
      Text('Aucun cadre nommé', style: TextStyle(fontSize: 11, color: YekiColors.warning)),
    ]),
  );

  Widget _sectionTitle(String title, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    ]),
  );
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
    final estValide = dept['est_valide'] == true;
    final color = _typeDeptColors[typeDept] ?? YekiColors.primaryDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
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
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dept['nom'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(dept['parcours'] ?? '', style: const TextStyle(fontSize: 13)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (prix > 0)
                Text('$prix FCFA', style: const TextStyle(fontWeight: FontWeight.w700))
              else
                Text(estValide ? 'Gratuit ✓' : 'À valider',
                    style: TextStyle(color: estValide ? YekiColors.success : YekiColors.warning, fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ]),
        ),
        const Divider(height: 20, color: YekiColors.borderLight),
        Expanded(
          child: _loading
              ? const Center(child: YekiLoader())
              : DefaultTabController(
                  length: 2,
                  child: Column(children: [
                    TabBar(
                      tabs: const [Tab(text: 'Cours'), Tab(text: 'Inscrits')],
                      labelColor: YekiColors.primaryDark,
                      unselectedLabelColor: YekiColors.textLight,
                      indicatorColor: YekiColors.primaryDark,
                    ),
                    Expanded(
                      child: TabBarView(children: [
                        _cours.isEmpty
                            ? const Center(child: Text('Aucun cours', style: TextStyle()))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _cours.length,
                                itemBuilder: (_, i) {
                                  final c = _cours[i];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: YekiColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: YekiColors.borderLight, width: 1),
                                    ),
                                    child: Row(children: [
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
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c['titre'] ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                                              Text('${c['nb_apprenants'] ?? 0} apprenants',
                                                  style: const TextStyle(fontSize: 12)),
                                            ]),
                                      ),
                                    ]),
                                  );
                                },
                              ),
                        _inscrits.isEmpty
                            ? const Center(child: Text('Aucun inscrit', style: TextStyle()))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _inscrits.length,
                                itemBuilder: (_, i) {
                                  final ins = _inscrits[i];
                                  final statut = ins['statut'] as String? ?? '';
                                  final statusColor = statut == 'accepte'
                                      ? YekiColors.success
                                      : statut == 'en_attente'
                                          ? YekiColors.warning
                                          : YekiColors.error;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: YekiColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: YekiColors.borderLight, width: 1),
                                    ),
                                    child: Row(children: [
                                      CircleAvatar(
                                        backgroundColor: color.withValues(alpha: 0.1),
                                        child: Text(
                                            (ins['nom'] ?? ins['username'] ?? '?')[0].toUpperCase(),
                                            style: TextStyle(color: color)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(ins['nom'] ?? ins['username'] ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                                              Text(ins['inscrit_le']?.toString().substring(0, 10) ?? '',
                                                  style: const TextStyle(fontSize: 12)),
                                            ]),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(statut,
                                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ),
                                    ]),
                                  );
                                },
                              ),
                      ]),
                    ),
                  ]),
                ),
        ),
      ]),
    );
  }
}

class _SI {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SI(this.label, this.value, this.icon, this.color);
}