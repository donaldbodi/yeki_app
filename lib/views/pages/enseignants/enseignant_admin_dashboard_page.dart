// lib/views/pages/enseignants/enseignant_admin_dashboard_page.dart
// ✅ Gère tous les types de parcours (cursus, prepa, formation, olympiade)
// ✅ Création département enrichie : type_dept, prix, image, description
// ✅ Section "En attente de validation" pour départements et olympiades prix=0
// ✅ Validation / rejet depuis le dashboard
// ✅ 4 onglets : Départements · Cadres · En attente · Stats

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cadre_dashboard_page.dart' show TabBarDelegate;

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _primary  = Color(0xFF1565C0);
const Color _dark     = Color(0xFF0D1B2A);
const Color _bg       = Color(0xFFF4F7FB);
const Color _green    = Color(0xFF10B981);
const Color _gold     = Color(0xFFE2A84B);
const Color _teal     = Color(0xFF2884A0);
const Color _red      = Color(0xFFEF4444);

class EnseignantAdminDashboardPage extends StatefulWidget {
  const EnseignantAdminDashboardPage({super.key});

  @override
  State<EnseignantAdminDashboardPage> createState() =>
      _EnseignantAdminDashboardPageState();
}

class _EnseignantAdminDashboardPageState
    extends State<EnseignantAdminDashboardPage>
    with SingleTickerProviderStateMixin {
  bool   _loading = true;
  Map<String, dynamic> _stats         = {};
  List   _departements                = [];
  List   _cadres                      = [];
  List   _deptsEnAttente              = [];
  List   _olympiadesEnAttente         = [];
  String _nomEnseignant               = '';
  String _nomParcours                 = '';
  int    _idParcours                  = 0;
  String _typeParcours                = 'cursus';
  List   _parcoursList                = [];

  late TabController _tabCtrl;

  // ── Mapping types ─────────────────────────────────────────────
  static const _typeDeptLabels = {
    'normal':    'Département',
    'classique': 'Formation Classique',
    'metier':    'Formation Métier',
    'concours':  'Prépa Concours',
  };
  static const _typeDeptIcons = {
    'normal':    Icons.domain_rounded,
    'classique': Icons.account_balance_rounded,
    'metier':    Icons.work_rounded,
    'concours':  Icons.emoji_events_rounded,
  };
  static const _typeDeptColors = {
    'normal':    _primary,
    'classique': _teal,
    'metier':    _gold,
    'concours':  Color(0xFF8B5CF6),
  };

  // Options de type_dept selon le type de parcours
  List<String> get _typeDeptOptions {
    switch (_typeParcours) {
      case 'prepa':     return ['concours'];
      case 'formation': return ['classique', 'metier'];
      case 'olympiade': return ['normal'];
      default:          return ['normal'];
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

  // ── Chargement ────────────────────────────────────────────────
  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) { setState(() => _loading = false); return; }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignant/admin/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _stats               = (data['stats'] as Map<String, dynamic>?) ?? {};
          _departements        = (data['departements'] as List?) ?? [];
          _cadres              = (data['cadres'] as List?) ?? [];
          _deptsEnAttente      = (data['departements_en_attente'] as List?) ?? [];
          _olympiadesEnAttente = (data['olympiades_en_attente'] as List?) ?? [];
          _nomEnseignant       = data['nom'] ?? '';
          _idParcours          = data['id_parcours'] ?? 0;
          _nomParcours         = data['nom_parcours'] ?? '';
          _typeParcours        = data['type_parcours'] ?? 'cursus';
          _parcoursList        = (data['parcours_list'] as List?) ?? [];
          _loading             = false;
        });
      } else {
        setState(() => _loading = false);
        _showMsg('Erreur chargement (${res.statusCode})', error: true);
      }
    } catch (_) {
      setState(() => _loading = false);
      _showMsg('Erreur réseau', error: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final nbEnAttente = _deptsEnAttente.length + _olympiadesEnAttente.length;

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: _nomParcours.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: _primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                _typeParcours == 'prepa'
                    ? 'Nouveau concours'
                    : _typeParcours == 'formation'
                        ? 'Nouvelle formation'
                        : 'Nouveau département',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: _creerDepartement,
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
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

  // ── AppBar ────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() => SliverAppBar(
    expandedHeight: 230,
    pinned: true,
    backgroundColor: _primary,
    actions: [
      IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _charger),
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), _primary],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Tableau de bord',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(_nomEnseignant.isEmpty ? 'Enseignant Admin' : _nomEnseignant,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _roleBadge(),
                const SizedBox(height: 8),
                _parcoursBadge(),
              ],
            ),
          ),
        ),
      ),
      title: const Text('Dashboard Admin',
          style: TextStyle(fontSize: 16, color: Colors.white)),
      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      collapseMode: CollapseMode.parallax,
    ),
  );

  Widget _roleBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
    child: const Text('Enseignant Administrateur',
        style: TextStyle(color: Colors.white, fontSize: 12)),
  );

  Widget _parcoursBadge() {
    if (_nomParcours.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.25), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 14),
          SizedBox(width: 6),
          Text('Aucun parcours assigné', style: TextStyle(color: Colors.orange, fontSize: 12)),
        ]),
      );
    }
    final typeLabel = {
      'cursus': 'Cursus', 'prepa': 'Prépa Concours',
      'formation': 'Formations', 'olympiade': 'Olympiades', 'autre': 'Parcours',
    }[_typeParcours] ?? _typeParcours;

    return Row(children: [
      const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          'Coordonnateur · $_nomParcours ($typeLabel)',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }

  // ── TabBar ────────────────────────────────────────────────────
  SliverPersistentHeader _buildTabBar(int nbEnAttente) =>
      SliverPersistentHeader(
        pinned: true,
        delegate: TabBarDelegate(
          TabBar(
            controller: _tabCtrl,
            labelColor: _primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _primary,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
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
                        color: _red, borderRadius: BorderRadius.circular(10)),
                      child: Text('$nbEnAttente',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
              ),
              const Tab(text: 'Statistiques'),
            ],
          ),
          backgroundColor: Colors.white,
        ),
      );

  // ═══════════════════════════════════════════════════════════════
  //  TAB 1 : Départements
  // ═══════════════════════════════════════════════════════════════
  Widget _tabDepartements() => RefreshIndicator(
    onRefresh: _charger, color: _primary,
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
          color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
          SizedBox(width: 12),
          Expanded(child: Text(
            'Aucun parcours ne vous est encore assigné.\nContactez l\'administrateur général.',
            style: TextStyle(color: Colors.orange, fontSize: 13),
          )),
        ]),
      );
    }

    final typeIcon = {
      'cursus': Icons.school_rounded, 'prepa': Icons.emoji_events_rounded,
      'formation': Icons.work_rounded, 'olympiade': Icons.military_tech_rounded,
    }[_typeParcours] ?? Icons.domain_rounded;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(typeIcon, color: Colors.amber, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mon parcours', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Coordonnateur', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text('${_departements.length} dép.',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 14),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 14),
        Text(_nomParcours, style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        // Stats rapides
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
      Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ],
  );

  Widget _buildVideDepartement() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        Icon(Icons.domain_outlined, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(_typeParcours == 'prepa'
            ? 'Aucun concours créé'
            : _typeParcours == 'formation'
                ? 'Aucune formation créée'
                : 'Aucun département créé',
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: _primary),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Créer', style: TextStyle(color: Colors.white)),
          onPressed: _creerDepartement,
        ),
      ]),
    ),
  );

  Widget _buildDeptCard(Map<String, dynamic> dept) {
    final typeDept  = dept['type_dept'] as String? ?? 'normal';
    final estValide = dept['est_valide'] == true;
    final prix      = dept['prix'] as int? ?? 0;
    final nbCours   = dept['nb_cours'] as int? ?? 0;
    final nbIns     = dept['nb_inscrits'] as int? ?? 0;
    final cadre     = dept['cadre'] as Map?;
    final color     = _typeDeptColors[typeDept] ?? _primary;
    final icon      = _typeDeptIcons[typeDept] ?? Icons.domain_rounded;
    final label     = _typeDeptLabels[typeDept] ?? 'Département';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: estValide ? null : Border.all(color: Colors.orange.shade200, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _voirDetailDepartement(dept),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dept['nom'] ?? '', style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
                const SizedBox(height: 2),
                Row(children: [
                  _miniChip(label, color),
                  const SizedBox(width: 6),
                  if (prix > 0)
                    _miniChip('$prix FCFA', _gold)
                  else
                    _miniChip('Gratuit', _green),
                ]),
              ])),
              // Actions rapides
              IconButton(
                icon: Icon(cadre == null ? Icons.person_add_outlined : Icons.swap_horiz, color: color),
                tooltip: cadre == null ? 'Nommer un cadre' : 'Changer cadre',
                onPressed: () => _changerCadre(dept),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onPressed: () => _voirDetailDepartement(dept),
              ),
            ]),
            const SizedBox(height: 10),
            // Cadre info
            if (cadre != null)
              Row(children: [
                const CircleAvatar(radius: 11,
                  backgroundColor: Color(0xFFEDE7F6),
                  child: Icon(Icons.person, size: 14, color: Color(0xFF6A1B9A))),
                const SizedBox(width: 8),
                Text('Cadre : ${cadre['nom'] ?? cadre['username'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ])
            else
              _aucunCadreBadge(),
            const SizedBox(height: 10),
            // Stats
            Row(children: [
              Icon(Icons.book_outlined, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('$nbCours cours', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.people_outlined, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('$nbIns inscrits', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const Spacer(),
              // Badge validation
              if (!estValide)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.hourglass_top_rounded, size: 11, color: Colors.orange),
                    const SizedBox(width: 4),
                    const Text('À valider', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    // Bouton valider rapide
                    GestureDetector(
                      onTap: () => _validerDepartement(dept['id'] as int, dept['nom'] ?? ''),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _green, borderRadius: BorderRadius.circular(6)),
                        child: const Text('Valider', style: TextStyle(
                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                )
              else
                Row(children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: _green),
                  const SizedBox(width: 4),
                  Text('Validé', style: TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
                ]),
            ]),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 2 : Cadres
  // ═══════════════════════════════════════════════════════════════
  Widget _tabCadres() {
    if (_cadres.isEmpty) {
      return Center(child: Text('Aucun enseignant cadre',
          style: TextStyle(color: Colors.grey.shade400)));
    }
    return RefreshIndicator(
      onRefresh: _charger, color: _primary,
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
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(
            radius: 26, backgroundColor: const Color(0xFFEDE7F6),
            child: Text((cadre['nom'] ?? 'C')[0].toUpperCase(),
                style: const TextStyle(color: Color(0xFF6A1B9A), fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cadre['nom'] ?? cadre['username'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
            if (dept != null)
              Text(dept['nom'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6A1B9A))),
            Text('${cadre['nb_cours'] ?? 0} cours · ${cadre['nb_apprenants'] ?? 0} apprenants',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 3 : En attente de validation
  // ═══════════════════════════════════════════════════════════════
  Widget _tabEnAttente() {
    final total = _deptsEnAttente.length + _olympiadesEnAttente.length;
    if (total == 0) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Tout est validé !', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _charger, color: _primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Départements/formations en attente
          if (_deptsEnAttente.isNotEmpty) ...[
            _sectionTitle('Départements à valider', Icons.domain_rounded, Colors.orange),
            ..._deptsEnAttente.map((d) => _buildEnAttenteCard(
              id: d['id'] as int,
              nom: d['nom'] ?? '',
              typeDept: d['type_dept'] ?? 'normal',
              createdAt: d['created_at'] ?? '',
              cadre: d['cadre'] as Map?,
              isOlympiade: false,
            )),
            const SizedBox(height: 16),
          ],
          // Olympiades en attente
          if (_olympiadesEnAttente.isNotEmpty) ...[
            _sectionTitle('Olympiades à valider', Icons.military_tech_rounded, Colors.orange),
            ..._olympiadesEnAttente.map((o) => _buildEnAttenteCard(
              id: o['id'] as int,
              nom: o['titre'] ?? '',
              typeDept: 'olympiade',
              createdAt: '',
              cadre: null,
              isOlympiade: true,
            )),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEnAttenteCard({
    required int id, required String nom, required String typeDept,
    required String createdAt, Map? cadre, required bool isOlympiade,
  }) {
    final label = isOlympiade ? 'Olympiade' : (_typeDeptLabels[typeDept] ?? 'Département');
    final color = isOlympiade ? _gold : (_typeDeptColors[typeDept] ?? _primary);
    final icon  = isOlympiade ? Icons.military_tech_rounded : (_typeDeptIcons[typeDept] ?? Icons.domain_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _dark),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
          // Badge orange "En attente"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text('En attente', style: TextStyle(
                color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (cadre != null) ...[
          const SizedBox(height: 8),
          Text('Cadre : ${cadre['nom'] ?? ''}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        // Boutons Valider / Rejeter
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => isOlympiade
                  ? _validerOlympiade(id, nom, 'valider')
                  : _validerDepartement(id, nom),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Valider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green, foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => isOlympiade
                  ? _validerOlympiade(id, nom, 'rejeter')
                  : _rejeterDepartement(id, nom),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Rejeter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: BorderSide(color: _red),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  TAB 4 : Statistiques
  // ═══════════════════════════════════════════════════════════════
  Widget _tabStats() {
    final items = [
      _SI('Départements', '${_stats['nb_departements'] ?? _departements.length}', Icons.domain, _primary),
      _SI('Cours', '${_stats['nb_cours'] ?? 0}', Icons.book, const Color(0xFF6A1B9A)),
      _SI('Inscrits', '${_stats['nb_apprenants'] ?? 0}', Icons.people, _teal),
      _SI('Cadres', '${_stats['nb_enseignants'] ?? 0}', Icons.person_outline, const Color(0xFFE65100)),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          children: items.map(_buildStatCard).toList(),
        ),
        if (_departements.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.leaderboard, color: _primary, size: 18),
            const SizedBox(width: 8),
            const Text('Classement des départements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
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
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Row(children: [
                Container(
                  width: 28, height: 28, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == 0 ? Colors.amber : i == 1 ? Colors.grey.shade300 : Colors.brown.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(d['nom'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('${taux.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _primary)),
              ]),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildStatCard(_SI item) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: item.color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(item.icon, color: item.color, size: 20),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: item.color)),
          Text(item.label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════════

  // ── Créer un département ─────────────────────────────────────
  void _creerDepartement() {
    final nomCtrl  = TextEditingController();
    final descCtrl = TextEditingController();
    final prixCtrl = TextEditingController(text: '0');
    String typeDeptSel = _typeDeptOptions.first;
    bool   accesSelectSel = false;
    bool   isLoading = false;
    File?  imageFile;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                const SizedBox(height: 16),
                Text(
                  _typeParcours == 'prepa'
                      ? 'Créer un concours'
                      : _typeParcours == 'formation'
                          ? 'Créer une formation'
                          : 'Créer un département',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _dark),
                ),
                const SizedBox(height: 4),
                Text('Parcours : $_nomParcours',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 20),

                // Nom
                _field(nomCtrl, 'Nom *', Icons.label_rounded,
                    _typeParcours == 'prepa' ? 'Ex: Concours ENS' : 'Ex: Formation ENSEA'),
                const SizedBox(height: 12),

                // Description
                _field(descCtrl, 'Description', Icons.description_outlined,
                    'Objectifs, programme…', maxLines: 3),
                const SizedBox(height: 12),

                // Type de département (si plusieurs options)
                if (_typeDeptOptions.length > 1) ...[
                  const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _typeDeptOptions.map((t) {
                      final selected = typeDeptSel == t;
                      final c = _typeDeptColors[t] ?? _primary;
                      return ChoiceChip(
                        label: Text(_typeDeptLabels[t] ?? t),
                        selected: selected,
                        selectedColor: c.withOpacity(0.15),
                        labelStyle: TextStyle(color: selected ? c : Colors.grey.shade600),
                        onSelected: (_) => setS(() => typeDeptSel = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Prix
                _field(prixCtrl, 'Prix (FCFA)', Icons.attach_money_rounded,
                    '0 = gratuit (validation requise)'),
                const SizedBox(height: 8),
                // Info prix
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prix = 0 : requiert votre validation avant d\'être visible.\nPrix > 0 : validé automatiquement, commission Yéki 15%.',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // Accès sélectionné
                SwitchListTile(
                  value: accesSelectSel,
                  onChanged: (v) => setS(() => accesSelectSel = v),
                  title: const Text('Accès sélectionné', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Le cadre sélectionne manuellement les apprenants',
                      style: TextStyle(fontSize: 11)),
                  activeColor: _primary,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),

                // Image
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (picked != null) setS(() => imageFile = File(picked.path));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)),
                    child: Row(children: [
                      Icon(Icons.image_rounded, color: _primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        imageFile != null ? imageFile!.path.split('/').last : 'Choisir une image (optionnel)',
                        style: TextStyle(color: imageFile != null ? _dark : Colors.grey, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      )),
                      if (imageFile != null)
                        GestureDetector(
                          onTap: () => setS(() => imageFile = null),
                          child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                        ),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isLoading ? null : () async {
                      if (nomCtrl.text.trim().isEmpty) { _showMsg('Le nom est obligatoire', error: true); return; }
                      setS(() => isLoading = true);
                      final token = await _getToken();
                      if (token == null) { setS(() => isLoading = false); return; }
                      try {
                        int prix = 0;
                        try { prix = int.parse(prixCtrl.text.trim()); } catch (_) {}

                        // Simple JSON POST (Departement n'a pas de champ image)
                        final body = <String, dynamic>{
                          'nom':         nomCtrl.text.trim(),
                          'parcours_id': _idParcours,
                        };
                        final res = await http.post(
                          Uri.parse('$_baseUrl/departements/creer/'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Token $token',
                          },
                          body: jsonEncode(body),
                        );
                        setS(() => isLoading = false);

                        if (res.statusCode == 201) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          final json = jsonDecode(res.body);
                          _showMsg(json['detail'] ?? 'Département créé !', success: true);
                          _charger();
                        } else {
                          final err = jsonDecode(res.body);
                          _showMsg(err['detail'] ?? 'Erreur ${res.statusCode}', error: true);
                        }
                      } catch (_) {
                        setS(() => isLoading = false);
                        _showMsg('Erreur réseau', error: true);
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Créer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Valider un département ────────────────────────────────────
  Future<void> _validerDepartement(int id, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider le département'),
        content: Text('Confirmer la validation de "$nom" ?\nIl sera visible pour les apprenants.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final token = await _getToken();
    final res = await http.patch(
      Uri.parse('$_baseUrl/departements/$id/valider/'),
      headers: {'Authorization': 'Token $token!', 'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'valider'}),
    );
    if (res.statusCode == 200) {
      _showMsg('✅ Département "$nom" validé !', success: true);
      _charger();
    } else {
      _showMsg(jsonDecode(res.body)['error'] ?? 'Erreur', error: true);
    }
  }

  Future<void> _rejeterDepartement(int id, String nom) async {
    final token = await _getToken();
    final res = await http.patch(
      Uri.parse('$_baseUrl/departements/$id/valider/'),
      headers: {'Authorization': 'Token $token!', 'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'rejeter'}),
    );
    if (res.statusCode == 200) {
      _showMsg('Département "$nom" rejeté.', success: false);
      _charger();
    } else {
      _showMsg('Erreur', error: true);
    }
  }

  Future<void> _validerOlympiade(int id, String titre, String action) async {
    final token = await _getToken();
    final res = await http.patch(
      Uri.parse('$_baseUrl/olympiades/$id/valider/'),
      headers: {'Authorization': 'Token $token!', 'Content-Type': 'application/json'},
      body: jsonEncode({'action': action}),
    );
    if (res.statusCode == 200) {
      _showMsg(action == 'valider' ? '✅ Olympiade validée !' : 'Olympiade rejetée.', success: action == 'valider');
      _charger();
    } else {
      _showMsg('Erreur', error: true);
    }
  }

  // ── Nommer / changer le cadre ─────────────────────────────────
  void _changerCadre(Map dept) async {
    final token = await _getToken();
    if (token == null) return;
    List cadresDisp = [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignants/liste/?role=cadre'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) cadresDisp = jsonDecode(res.body);
      else { _showMsg('Impossible de charger les cadres', error: true); return; }
    } catch (_) { _showMsg('Erreur réseau', error: true); return; }

    if (!mounted) return;
    int? selected = dept['cadre']?['id'] as int?;

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(), const SizedBox(height: 16),
            Text(dept['cadre'] == null ? 'Nommer un cadre' : 'Changer le cadre',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
            Text('Département : ${dept['nom'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
              child: cadresDisp.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(20),
                      child: Text('Aucun enseignant cadre disponible.', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey))))
                  : ListView(shrinkWrap: true, children: cadresDisp.map<Widget>((e) =>
                      RadioListTile<int>(
                        value: e['id'] as int, groupValue: selected,
                        activeColor: _primary,
                        title: Text(e['nom'] ?? e['username'] ?? ''),
                        subtitle: Text(e['email'] ?? ''),
                        onChanged: (v) => setS(() => selected = v),
                      )).toList()),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: selected == null ? null : () async {
                  if (ctx.mounted) Navigator.pop(ctx);
                  final t2 = await _getToken();
                  if (t2 == null) return;
                  final res = await http.patch(
                    Uri.parse('$_baseUrl/departements/${dept['id']}/changer-cadre/'),
                    headers: {'Authorization': 'Token $t2', 'Content-Type': 'application/json'},
                    body: jsonEncode({'cadre_id': selected}),
                  );
                  if (res.statusCode == 200) { _showMsg('Cadre modifié !', success: true); _charger(); }
                  else { _showMsg(jsonDecode(res.body)['detail'] ?? 'Erreur', error: true); }
                },
                child: const Text('Confirmer', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Détail département ────────────────────────────────────────
  void _voirDetailDepartement(Map dept) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _DetailDeptSheet(dept: dept),
    );
  }

  // ── Helpers UI ────────────────────────────────────────────────
  Widget _sheetHandle() => Center(
    child: Container(width: 40, height: 4,
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint,
      {int maxLines = 1}) => TextField(
    controller: ctrl, maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary)),
    ),
  );

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _aucunCadreBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.warning_outlined, size: 13, color: Colors.orange),
      SizedBox(width: 5),
      Text('Aucun cadre nommé', style: TextStyle(fontSize: 11, color: Colors.orange)),
    ]),
  );

  Widget _sectionTitle(String title, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
    ]),
  );

  void _showMsg(String msg, {bool success = false, bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _red : success ? _green : _primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ── Sheet détail département ──────────────────────────────────
class _DetailDeptSheet extends StatefulWidget {
  final Map dept;
  const _DetailDeptSheet({required this.dept});
  @override
  State<_DetailDeptSheet> createState() => _DetailDeptSheetState();
}

class _DetailDeptSheetState extends State<_DetailDeptSheet> {
  List _cours   = [];
  List _inscrits = [];
  bool _loading  = true;

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
        http.get(Uri.parse('$_baseUrl/departements/$id/cours/'),
            headers: {'Authorization': 'Token $token'}),
        http.get(Uri.parse('$_baseUrl/departements/$id/inscriptions/'),
            headers: {'Authorization': 'Token $token'}),
      ]);
      if (mounted) {
        setState(() {
          if (results[0].statusCode == 200) _cours    = jsonDecode(results[0].body);
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
    final dept     = widget.dept;
    final typeDept = dept['type_dept'] as String? ?? 'normal';
    final prix     = dept['prix'] as int? ?? 0;
    final estValide = dept['est_valide'] == true;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dept['nom'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _dark)),
              Text(dept['parcours'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (prix > 0)
                Text('$prix FCFA', style: const TextStyle(color: _gold, fontWeight: FontWeight.w700))
              else
                Text(estValide ? 'Gratuit ✓' : 'À valider', style: TextStyle(
                  color: estValide ? _green : Colors.orange, fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ]),
        ),
        const Divider(height: 20),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : DefaultTabController(
                  length: 2,
                  child: Column(children: [
                    const TabBar(
                      tabs: [Tab(text: 'Cours'), Tab(text: 'Inscrits')],
                      labelColor: _primary, unselectedLabelColor: Colors.grey, indicatorColor: _primary,
                    ),
                    Expanded(child: TabBarView(children: [
                      // Tab Cours
                      _cours.isEmpty
                          ? const Center(child: Text('Aucun cours'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _cours.length,
                              itemBuilder: (_, i) {
                                final c = _cours[i];
                                return ListTile(
                                  leading: Container(padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.book, color: _primary, size: 20)),
                                  title: Text(c['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text('${c['nb_apprenants'] ?? 0} apprenants'),
                                );
                              }),
                      // Tab Inscrits
                      _inscrits.isEmpty
                          ? const Center(child: Text('Aucun inscrit'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _inscrits.length,
                              itemBuilder: (_, i) {
                                final ins = _inscrits[i];
                                final statut = ins['statut'] as String? ?? '';
                                final statusColor = statut == 'accepte' ? _green
                                    : statut == 'en_attente' ? Colors.orange : _red;
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text((ins['nom'] ?? ins['username'] ?? '?')[0].toUpperCase())),
                                  title: Text(ins['nom'] ?? ins['username'] ?? ''),
                                  subtitle: Text(ins['inscrit_le']?.toString().substring(0, 10) ?? ''),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(statut, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                );
                              }),
                    ])),
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
