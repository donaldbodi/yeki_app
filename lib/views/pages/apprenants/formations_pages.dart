// lib/views/pages/apprenants/formations_pages.dart
// ════════════════════════════════════════════════════════════════
// PAGE FORMATIONS — Design Premium Unifié
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';
import 'package:yeki/views/pages/apprenants/formation_detail_page.dart';

const Color _dark = Color(0xFF0D1B2A);
const Color _teal = Color(0xFF008088);
const Color _blue = Color(0xFF2884A0);
const Color _gold = Color(0xFFE2A84B);
const Color _green = Color(0xFF10B981);
const Color _purple = Color(0xFF8B5CF6);
const Color _orange = Color(0xFFF97316);
const Color _bg = Color(0xFFF5F8FA);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ══════════════════════════════════════════════════════════════
// PAGE FORMATIONS
// ══════════════════════════════════════════════════════════════
class FormationsPage extends StatefulWidget {
  const FormationsPage({super.key});

  @override
  State<FormationsPage> createState() => _FormationsPageState();
}

class _FormationsPageState extends State<FormationsPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  List<DepartementItem> _tous = [];
  List<DepartementItem> _affiches = [];
  late TabController _tabCtrl;
  String _niveauApprenant = '';

  String _searchQ = '';
  String _filtreProg = 'Toutes';
  final _searchCtrl = TextEditingController();

  static const _types = ['Tout', 'Métier', 'Classique'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _types.length, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    _loadNiveau();
    _charger();
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging) _appliquerFiltres();
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNiveau() async {
    final niveau = await NiveauService.getNiveau();
    if (niveau != null) {
      setState(() => _niveauApprenant = niveau);
    }
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = ''; });
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/apprenant/formations/?type=all'),
        headers: _headers(token),
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _tous = data.map((d) => DepartementItem.fromJson(d as Map<String, dynamic>)).toList();
          _appliquerFiltres();
        });
      } else if (mounted) {
        setState(() => _error = 'Erreur ${res.statusCode}');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Erreur réseau');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _appliquerFiltres() {
    final q = _searchQ.toLowerCase();
    final tab = _tabCtrl.index;

    setState(() {
      _affiches = _tous.where((d) {
        final matchType = switch (tab) {
          1 => d.estFormationMetier,
          2 => d.estFormationClassique,
          _ => true,
        };

        // Filtrage par niveau: niveau formation <= niveau apprenant
        bool matchNiveau = true;
        if (_niveauApprenant.isNotEmpty && d.niveauxCibles.isNotEmpty) {
          matchNiveau = NiveauService.estAccessible(_niveauApprenant, d.niveauxCibles);
        }

        final matchProg = switch (_filtreProg) {
          'En cours' => d.progression > 0 && d.progression < 100,
          'Nouvelles' => d.progression == 0,
          'Terminées' => d.progression >= 100,
          _ => true,
        };

        final matchSearch = q.isEmpty ||
            d.nom.toLowerCase().contains(q) ||
            d.domaine.toLowerCase().contains(q) ||
            d.ville.toLowerCase().contains(q) ||
            d.dureeFormation.toLowerCase().contains(q);

        return matchType && matchProg && matchSearch && matchNiveau;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchAndFilter()),
          SliverToBoxAdapter(child: _buildTabs()),
        ],
        body: _loading
            ? const _SkeletonList()
            : _error.isNotEmpty
                ? _ErrorView(msg: _error, onRetry: _charger)
                : _affiches.isEmpty
                    ? const _EmptyView()
                    : _buildList(),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      backgroundColor: _dark,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        titlePadding: const EdgeInsets.only(left: 20, bottom: 56),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Formations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 0.5)),
            Text('Développez vos compétences',
                style: TextStyle(fontSize: 11, color: Color(0xFFB0C4D8))),
          ],
        ),
        background: Stack(fit: StackFit.expand, children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B2A), Color(0xFF1A3A5C), Color(0xFF008088)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: 20, bottom: 40,
            child: Opacity(
              opacity: 0.12,
              child: Icon(Icons.workspace_premium_rounded, size: 90, color: _gold),
            ),
          ),
        ]),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _charger,
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: _dark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher une formation…',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withOpacity(0.6), size: 20),
                suffixIcon: _searchQ.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white54, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQ = '');
                          _appliquerFiltres();
                        })
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) {
                setState(() => _searchQ = v);
                _appliquerFiltres();
              },
            ),
          ),
          const SizedBox(width: 10),
          _FilterPopup(
            selected: _filtreProg,
            onChanged: (v) {
              setState(() => _filtreProg = v);
              _appliquerFiltres();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final counts = [
      _tous.length,
      _tous.where((d) => d.estFormationMetier).length,
      _tous.where((d) => d.estFormationClassique).length,
    ];
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: _teal,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _teal,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: List.generate(_types.length, (i) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_types[i]),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _tabCtrl.index == i
                        ? _teal.withOpacity(0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${counts[i]}',
                    style: TextStyle(
                        fontSize: 10,
                        color: _tabCtrl.index == i ? _teal : Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildList() {
    return TabBarView(
      controller: _tabCtrl,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(_types.length, (_) {
        if (_affiches.isEmpty) return const _EmptyView();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _affiches.length,
          itemBuilder: (ctx, i) => _FormationCard(
            dept: _affiches[i],
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => FormationDetailPage(
                  formationId: _affiches[i].id,
                  deptPrecharge: _affiches[i],
                ),
              ),
            ).then((_) => _charger()),
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CARTE FORMATION
// ══════════════════════════════════════════════════════════════
class _FormationCard extends StatelessWidget {
  final DepartementItem dept;
  final VoidCallback onTap;

  const _FormationCard({required this.dept, required this.onTap});

  Color get _color {
    try {
      final hex = dept.couleur.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return dept.estFormationMetier ? _orange : _teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    final typeLabel = dept.estFormationMetier ? 'Formation Métier' : 'Formation Classique';
    final typeIcon = dept.estFormationMetier ? Icons.work_rounded : Icons.account_balance_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: c.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [c, c.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: dept.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(dept.imageUrl!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(c.withOpacity(0.5), BlendMode.darken),
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (dept.imageUrl == null)
                    Center(
                      child: Icon(typeIcon, size: 46, color: Colors.white.withOpacity(0.25)),
                    ),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(typeLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: _StatusBadge(statut: dept.statut),
                  ),
                  if (dept.estCertifiante)
                    Positioned(
                      bottom: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text('Certifiante',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dept.nom,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (dept.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(dept.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: [
                      if (dept.dureeFormation.isNotEmpty)
                        _MiniChip(icon: Icons.schedule_rounded, label: dept.dureeFormation, color: _blue),
                      if (dept.ville.isNotEmpty)
                        _MiniChip(icon: Icons.location_on_rounded, label: dept.ville, color: c),
                      if (dept.modeFormation.isNotEmpty)
                        _MiniChip(
                            icon: dept.modeFormation == 'presentiel'
                                ? Icons.location_city_rounded
                                : dept.modeFormation == 'distance'
                                    ? Icons.wifi_rounded
                                    : Icons.devices_rounded,
                            label: dept.modeFormationLabel,
                            color: _purple),
                      if (dept.domaine.isNotEmpty)
                        _MiniChip(icon: Icons.category_rounded, label: dept.domaine, color: _orange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (dept.nbCours > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${dept.nbCours} cours',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        Text('${dept.progressionMoyenne.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: dept.progressionMoyenne / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation(c),
                        minHeight: 5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            dept.progression > 0 ? 'Continuer' : 'Voir la formation',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: dept.prix == 0 ? _green.withOpacity(0.1) : _gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: dept.prix == 0 ? _green.withOpacity(0.3) : _gold.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          dept.prix == 0 ? 'Gratuit' : '${dept.prix} F',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: dept.prix == 0 ? _green : _gold),
                        ),
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
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String statut;
  const _StatusBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (statut) {
      'TERMINÉ' => (Colors.green.shade600, 'Terminé'),
      'EN COURS' => (_teal, 'En cours'),
      _ => (Colors.grey.shade500, 'Nouveau'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

class _FilterPopup extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterPopup({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => ['Toutes', 'En cours', 'Nouvelles', 'Terminées']
          .map((s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    if (s == selected) const Icon(Icons.check_rounded, size: 14, color: _teal),
                    if (s == selected) const SizedBox(width: 6),
                    Text(s, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 250,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Aucune formation disponible pour votre niveau',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        ],
      ),
    );
  }
}