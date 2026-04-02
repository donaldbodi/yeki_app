// lib/views/pages/apprenants/devoirs_page.dart
// ════════════════════════════════════════════════════════════════
// PAGE DEVOIRS — Épurée (sans header), filtres directs
// ✅ CORRIGÉ : Import correct de kBaseUrl
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Import correct de kBaseUrl depuis formations_models
import 'formations_models.dart';  // kBaseUrl est défini ici
import 'composer_devoir_page.dart';
import 'resultat_devoir_page.dart';

const Color _dMain   = Color(0xFF2884A0);
const Color _dBg     = Color(0xFFF8FAFC);
const Color _dDark   = Color(0xFF0F172A);
const Color _dAccent = Color(0xFFFF7F77);
const Color _dGold   = Color(0xFFE2A84B);
const Color _dGreen  = Color(0xFF10B981);
const Color _dRed    = Color(0xFFEF4444);
// ✅ kBaseUrl est maintenant importé depuis formations_models

class DevoirsPage extends StatefulWidget {
  final bool estEnseignantPrincipal;
  const DevoirsPage({super.key, required this.estEnseignantPrincipal});

  @override
  State<DevoirsPage> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<DevoirsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  bool   _loading   = true;
  List<Map<String, dynamic>> _tous     = [];
  List<Map<String, dynamic>> _affiches = [];

  String  _typeSelectionne   = 'Tous';
  String? _matiereSelectionnee;
  String? _niveauSelectionne;
  String  _statutSelectionne = 'Tous';
  String  _recherche         = '';

  final List<_TypeDevoirTab> _types = [
    _TypeDevoirTab('Tous',              Icons.grid_view_rounded,       _dMain),
    _TypeDevoirTab('cursus',            Icons.school_rounded,          Colors.indigo),
    _TypeDevoirTab('concours',          Icons.emoji_events_rounded,    _dGold),
    _TypeDevoirTab('formation_classique', Icons.account_balance_rounded, Colors.teal),
    _TypeDevoirTab('formation_metier',  Icons.work_rounded,            Colors.deepOrange),
    _TypeDevoirTab('olympiade',         Icons.military_tech_rounded,   _dAccent),
  ];

  final List<String> _matieres = [
    'Mathématiques', 'Physique', 'Chimie', 'SVT', 'Informatique',
    'Français', 'Anglais', 'Histoire-Géo', 'Philosophie', 'Économie', 'Autre',
  ];
  final List<String> _niveaux = [
    'Terminale', '1ère', '2nde', '3ème',
    'Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2', 'Autre',
  ];
  final List<String> _statuts = [
    'Tous', 'non_commence', 'en_cours', 'soumis', 'corrige', 'en_retard',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _types.length, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() {
            _typeSelectionne = _types[_tabCtrl.index].code;
            _appliquerFiltres();
          });
        }
      });
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString('token');

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _token();
    try {
      // ✅ Utilisation correcte de kBaseUrl
      final res = await http.get(
        Uri.parse('$kBaseUrl/devoirs/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (res.statusCode == 200) {
        _tous = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        _appliquerFiltres();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _appliquerFiltres() {
    List<Map<String, dynamic>> temp = List.from(_tous);
    if (_typeSelectionne != 'Tous')
      temp = temp.where((d) => d['type_devoir'] == _typeSelectionne).toList();
    if (_matiereSelectionnee != null)
      temp = temp.where((d) => d['matiere'] == _matiereSelectionnee).toList();
    if (_niveauSelectionne != null)
      temp = temp.where((d) => d['niveau'] == _niveauSelectionne).toList();
    if (_statutSelectionne != 'Tous')
      temp = temp.where((d) => d['statut_apprenant'] == _statutSelectionne).toList();
    if (_recherche.isNotEmpty)
      temp = temp.where((d) =>
          (d['titre'] as String? ?? '').toLowerCase().contains(_recherche.toLowerCase())).toList();
    setState(() => _affiches = temp);
  }

  // ── Stats rapides ────────────────────────────────────────────
  int get _aFaire   => _tous.where((d) => d['statut_apprenant'] == 'non_commence').length;
  int get _enRetard => _tous.where((d) => d['statut_apprenant'] == 'en_retard').length;

  // ════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dBg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          _buildSliverStats(),
          _buildSliverTabs(),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _dMain))
            : RefreshIndicator(
                onRefresh: _charger,
                color: _dMain,
                child: CustomScrollView(slivers: [
                  SliverToBoxAdapter(child: _buildFiltresSecondaires()),
                  SliverToBoxAdapter(child: _buildBarreRecherche()),
                  _affiches.isEmpty
                      ? const SliverFillRemaining(child: _Vide())
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                          sliver: SliverList(delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildCard(_affiches[i]),
                            childCount: _affiches.length,
                          )),
                        ),
                ]),
              ),
      ),
    );
  }

  // ── Stats (mini, pas de gros header) ─────────────────────────
  Widget _buildSliverStats() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        color: Colors.white,
        child: Row(children: [
          Expanded(child: _StatChip(
            count: _tous.length, label: 'Total',
            icon: Icons.assignment_rounded, color: _dMain)),
          const SizedBox(width: 8),
          Expanded(child: _StatChip(
            count: _aFaire, label: 'À faire',
            icon: Icons.edit_calendar_rounded, color: Colors.indigo)),
          const SizedBox(width: 8),
          Expanded(child: _StatChip(
            count: _enRetard, label: 'En retard',
            icon: Icons.error_outline_rounded, color: _dRed)),
        ]),
      ),
    );
  }

  Widget _buildSliverTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(width: 3, color: _dMain),
            borderRadius: BorderRadius.circular(3),
          ),
          labelColor: _dMain,
          unselectedLabelColor: Colors.blueGrey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _types.map((t) => Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t.icon, size: 16),
              const SizedBox(width: 6),
              Text(_labelType(t.code)),
            ]),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildFiltresSecondaires() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        _dropFilter(
          value: _matiereSelectionnee, hint: 'Matière', items: _matieres,
          onChanged: (v) => setState(() { _matiereSelectionnee = v; _appliquerFiltres(); })),
        const SizedBox(width: 8),
        _dropFilter(
          value: _niveauSelectionne, hint: 'Niveau', items: _niveaux,
          onChanged: (v) => setState(() { _niveauSelectionne = v; _appliquerFiltres(); })),
        const SizedBox(width: 8),
        _dropFilter(
          value: _statutSelectionne == 'Tous' ? null : _statutSelectionne,
          hint: 'Statut',
          items: _statuts.where((s) => s != 'Tous').toList(),
          onChanged: (v) => setState(() { _statutSelectionne = v ?? 'Tous'; _appliquerFiltres(); }),
          labelBuilder: _labelStatut),
        if (_matiereSelectionnee != null || _niveauSelectionne != null || _statutSelectionne != 'Tous') ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              _matiereSelectionnee = null;
              _niveauSelectionne   = null;
              _statutSelectionne   = 'Tous';
              _appliquerFiltres();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _dRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _dRed.withOpacity(0.2)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.clear_rounded, size: 14, color: _dRed),
                SizedBox(width: 4),
                Text('Effacer', style: TextStyle(fontSize: 12, color: _dRed, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _dropFilter({
    required String? value, required String hint,
    required List<String> items, required ValueChanged<String?> onChanged,
    String Function(String)? labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400)),
          isDense: true,
          items: items.map((s) => DropdownMenuItem(value: s,
            child: Text(labelBuilder != null ? labelBuilder(s) : s,
                style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBarreRecherche() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() { _recherche = v; _appliquerFiltres(); }),
        decoration: InputDecoration(
          hintText: 'Rechercher un devoir…',
          prefixIcon: const Icon(Icons.search_rounded, color: _dMain, size: 20),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  // ── Carte devoir ─────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> d) {
    final statut   = d['statut_apprenant'] as String? ?? 'non_commence';
    final estExpire = d['est_expire'] == true;
    final jours     = d['temps_restant_jours'] as int? ?? 0;
    final color     = _colorForType(d['type_devoir'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: _dDark.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(children: [
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Badges
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _Badge(label: _labelType(d['type_devoir'] ?? 'cursus'), color: color),
                    _StatutBadge(statut: statut),
                  ]),
                  const SizedBox(height: 10),
                  // Titre
                  Text(d['titre'] as String? ?? 'Sans titre',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: _dDark),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  // Matière + niveau
                  Row(children: [
                    Icon(Icons.layers_outlined, size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text('${d['matiere'] ?? ''} • ${d['niveau'] ?? ''}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ]),
                  const Divider(height: 20),
                  // Timer + action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TimerInfo(jours: jours, expire: estExpire),
                      _ActionBtn(d: d, statut: statut, expire: estExpire,
                          onOuvrir: _ouvrirDevoir, onResultat: _voirResultat),
                    ],
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────
  void _ouvrirDevoir(Map<String, dynamic> d) {
    // ✅ Utilisation correcte de kBaseUrl dans l'import
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ComposerDevoirPage(
        devoirId: d['id'] as int,
        titre:    d['titre'] as String? ?? '',
        dureeMin: d['duree_minutes'] as int? ?? 60,
        noteSur:  d['note_sur'] as int? ?? 20,
      ),
    )).then((_) => _charger());
  }

  void _voirResultat(Map<String, dynamic> d) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ResultatDevoirPage(
        devoirId: d['id'] as int,
        titre:    d['titre'] as String? ?? '',
      ),
    ));
  }

  // ── Helpers ──────────────────────────────────────────────────
  String _labelType(String code) => const {
    'Tous': 'Tous', 'cursus': 'Cursus', 'concours': 'Concours',
    'formation_classique': 'Formation', 'formation_metier': 'Métier', 'olympiade': 'Olympiade',
  }[code] ?? code;

  String _labelStatut(String s) => const {
    'non_commence': 'À faire', 'en_cours': 'En cours', 'soumis': 'Soumis',
    'corrige': 'Corrigé', 'en_retard': 'En retard',
  }[s] ?? s;

  Color _colorForType(String? type) => const {
    'cursus': Colors.indigo, 'concours': _dGold, 'formation_classique': Colors.teal,
    'formation_metier': Colors.deepOrange, 'olympiade': _dAccent,
  }[type] ?? _dMain;
}

// ════════════════════════════════════════════════════════════════
// WIDGETS LOCAUX (inchangés)
// ════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final int count; final String label; final IconData icon; final Color color;
  const _StatChip({required this.count, required this.label,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count', style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(
              color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
}

class _StatutBadge extends StatelessWidget {
  final String statut;
  const _StatutBadge({required this.statut});
  @override
  Widget build(BuildContext context) {
    final (label, color) = const {
      'non_commence': ('À FAIRE', Color(0xFF2884A0)),
      'en_cours':     ('EN COURS', Colors.blue),
      'soumis':       ('SOUMIS', Color(0xFFE2A84B)),
      'corrige':      ('CORRIGÉ', Color(0xFF10B981)),
      'en_retard':    ('RETARD', Color(0xFFEF4444)),
    }[statut] ?? ('-', Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(
          color: color, fontSize: 10, fontWeight: FontWeight.w900)));
  }
}

class _TimerInfo extends StatelessWidget {
  final int jours; final bool expire;
  const _TimerInfo({required this.jours, required this.expire});
  @override
  Widget build(BuildContext context) {
    if (expire) return Text('Clôturé', style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
    final c = jours < 3 ? _dRed : (jours < 7 ? _dGold : _dGreen);
    return Row(children: [
      Icon(Icons.access_time_rounded, size: 13, color: c),
      const SizedBox(width: 4),
      Text('$jours j', style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final Map<String, dynamic> d;
  final String statut; final bool expire;
  final void Function(Map<String,dynamic>) onOuvrir, onResultat;
  const _ActionBtn({required this.d, required this.statut, required this.expire,
    required this.onOuvrir, required this.onResultat});

  @override
  Widget build(BuildContext context) {
    if (statut == 'corrige') {
      return TextButton.icon(
        onPressed: () => onResultat(d),
        icon: const Icon(Icons.analytics_outlined, size: 14),
        label: Text('Note: ${d['note_apprenant']}/${d['note_sur']}'),
        style: TextButton.styleFrom(
            foregroundColor: _dGreen,
            padding: const EdgeInsets.symmetric(horizontal: 8)),
      );
    }
    if (expire && statut != 'soumis') return const SizedBox.shrink();
    return ElevatedButton(
      onPressed: () => onOuvrir(d),
      style: ElevatedButton.styleFrom(
        backgroundColor: _dMain, foregroundColor: Colors.white,
        elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size(0, 34),
      ),
      child: Text(statut == 'en_cours' ? 'Continuer' : 'Commencer',
          style: const TextStyle(fontSize: 12)),
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide();
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.assignment_turned_in_outlined, size: 70, color: Colors.grey.shade300),
    const SizedBox(height: 16),
    const Text('Aucun devoir',
        style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
  ]));
}

class _TypeDevoirTab {
  final String code; final IconData icon; final Color color;
  const _TypeDevoirTab(this.code, this.icon, this.color);
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);
  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) =>
      Container(
        decoration: BoxDecoration(color: Colors.white,
          boxShadow: [if (overlapsContent)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
        child: tabBar);
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(_StickyTabBarDelegate old) => false;
}