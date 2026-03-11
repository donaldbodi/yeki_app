// ============================================================
//  devoirs_page.dart
//  Page principale — Liste des devoirs (Design Harmonisé)
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'composer_devoir_page.dart';
import 'resultat_devoir_page.dart';
import '../../../../widgets/yeki_app_bar.dart';
import 'package:yeki/views/pages/apprenants/notifications_page.dart';

// ─── Palette de Couleurs Personnalisée ──────────────────────
const Color _mainColor = Color(0xFF2884A0); // Couleur principale demandée
const Color _secondaryColor = Color(0xFF2884A0); // Nuance secondaire
const Color _bg = Color(0xFFF8FAFC);
const Color _dark = Color(0xFF0F172A);
const Color _accent = Color(0xFFFF7F77);
const Color _gold = Color(0xFFE2A84B);
const Color _green = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);
const String _base = 'https://yekiapp.pythonanywhere.com/api';

class DevoirsPage extends StatefulWidget {
  final bool estEnseignantPrincipal;
  const DevoirsPage({super.key, required this.estEnseignantPrincipal});

  @override
  State<DevoirsPage> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<DevoirsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final bool isSubscribed = true;

  // ── État ────────────────────────────────────────────────────
  bool _loading = true;
  List<Map<String, dynamic>> _tous = [];
  List<Map<String, dynamic>> _affiches = [];

  // ── Filtres ─────────────────────────────────────────────────
  String _typeSelectionne = "Tous";
  String? _matiereSelectionnee;
  String? _niveauSelectionne;
  String _statutSelectionne = "Tous";
  String _recherche = "";

  final List<_TypeDevoirTab> _types = [
    _TypeDevoirTab("Tous", Icons.grid_view_rounded, _mainColor),
    _TypeDevoirTab("cursus", Icons.school_rounded, Colors.indigo),
    _TypeDevoirTab("concours", Icons.emoji_events_rounded, _gold),
    _TypeDevoirTab("formation_classique", Icons.account_balance_rounded, Colors.teal),
    _TypeDevoirTab("formation_metier", Icons.work_rounded, Colors.deepOrange),
    _TypeDevoirTab("olympiade", Icons.military_tech_rounded, _accent),
  ];

  final List<String> _matieres = [
    "Mathématiques", "Physique", "Chimie", "SVT", "Informatique",
    "Français", "Anglais", "Histoire-Géo", "Philosophie", "Économie", "Autre",
  ];
  final List<String> _niveaux = [
    "Terminale", "1ère", "2nde", "3ème",
    "Licence 1", "Licence 2", "Licence 3", "Master 1", "Master 2", "Autre",
  ];
  final List<String> _statuts = ["Tous", "non_commence", "en_cours", "soumis", "corrige", "en_retard"];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _types.length, vsync: this);
    _tabCtrl.addListener(() {
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

  // ── API & Logique ───────────────────────────────────────────
  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString("token");
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _token();
    try {
      final res = await http.get(
        Uri.parse('$_base/devoirs/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        _tous = data.cast<Map<String, dynamic>>();
        _appliquerFiltres();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _appliquerFiltres() {
    List<Map<String, dynamic>> temp = List.from(_tous);

    if (_typeSelectionne != "Tous") {
      temp = temp.where((d) => d["type_devoir"] == _typeSelectionne).toList();
    }
    if (_matiereSelectionnee != null) {
      temp = temp.where((d) => d["matiere"] == _matiereSelectionnee).toList();
    }
    if (_niveauSelectionne != null) {
      temp = temp.where((d) => d["niveau"] == _niveauSelectionne).toList();
    }
    if (_statutSelectionne != "Tous") {
      temp = temp.where((d) => d["statut_apprenant"] == _statutSelectionne).toList();
    }
    if (_recherche.isNotEmpty) {
      temp = temp.where((d) =>
          (d["titre"] as String).toLowerCase().contains(_recherche.toLowerCase())).toList();
    }
    setState(() => _affiches = temp);
  }

  // ── Build Principal ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: YekiHeader(
        unreadNotifications: 3,
        isSubscribed: isSubscribed,
        userRole: "Apprenant",
        username: "Donald",
        avatarUrl: null,
        onNotifications: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationsPage(),
            ),
          );
        },
        onSettings: () {},
        onLogout: () {},
      ),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          _buildSliverHeader(),
          _buildSliverTabs(),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _mainColor))
            : RefreshIndicator(
                onRefresh: _charger,
                color: _mainColor,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildFiltresSecondaires()),
                    SliverToBoxAdapter(child: _buildBarreRecherche()),
                    _affiches.isEmpty
                        ? SliverFillRemaining(child: _buildVide())
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _buildCard(_affiches[i]),
                                childCount: _affiches.length,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    final aFaire = _tous.where((d) => d["statut_apprenant"] == "non_commence").length;
    final enRetard = _tous.where((d) => d["statut_apprenant"] == "en_retard").length;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_mainColor, _secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Mes Devoirs",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 4),
                    Text("Suivez vos progrès scolaires",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                _buildHeaderStat(aFaire, "À faire", Icons.edit_calendar_rounded),
                const SizedBox(width: 15),
                _buildHeaderStat(enRetard, "En retard", Icons.error_outline_rounded, isAlert: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(int count, String label, IconData icon, {bool isAlert = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isAlert ? _accent : Colors.white, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            )
          ],
        ),
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
            borderSide: const BorderSide(width: 3, color: _mainColor),
            borderRadius: BorderRadius.circular(3),
          ),
          labelColor: _mainColor,
          unselectedLabelColor: Colors.blueGrey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: _types.map((t) => Tab(
            child: Row(
              children: [
                Icon(t.icon, size: 18),
                const SizedBox(width: 8),
                Text(_labelType(t.code)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildFiltresSecondaires() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 5),
      child: Row(
        children: [
          _dropFilter(value: _matiereSelectionnee, hint: "Matière", items: _matieres, 
            onChanged: (v) => setState(() { _matiereSelectionnee = v; _appliquerFiltres(); })),
          const SizedBox(width: 10),
          _dropFilter(value: _niveauSelectionne, hint: "Niveau", items: _niveaux, 
            onChanged: (v) => setState(() { _niveauSelectionne = v; _appliquerFiltres(); })),
          const SizedBox(width: 10),
          _dropFilter(value: _statutSelectionne == "Tous" ? null : _statutSelectionne, 
            hint: "Statut", items: _statuts.where((s) => s != "Tous").toList(),
            onChanged: (v) => setState(() { _statutSelectionne = v ?? "Tous"; _appliquerFiltres(); }),
            labelBuilder: _labelStatut),
        ],
      ),
    );
  }

  Widget _dropFilter({required String? value, required String hint, required List<String> items, 
      required ValueChanged<String?> onChanged, String Function(String)? labelBuilder}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400)),
          isDense: true,
          items: items.map((s) => DropdownMenuItem(value: s, 
            child: Text(labelBuilder != null ? labelBuilder(s) : s, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBarreRecherche() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        onChanged: (v) => setState(() { _recherche = v; _appliquerFiltres(); }),
        decoration: InputDecoration(
          hintText: "Rechercher un titre...",
          prefixIcon: const Icon(Icons.search_rounded, color: _mainColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  // ── Carte Devoir ───────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> d) {
    final statut = d["statut_apprenant"] ?? "non_commence";
    final estExpire = d["est_expire"] == true;
    final jours = d["temps_restant_jours"] ?? 0;
    final color = _colorForType(d["type_devoir"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _dark.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _badgeSimple(_labelType(d["type_devoir"]), color),
                          _statutBadge(statut),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(d["titre"] ?? "Sans titre",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.layers_outlined, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text("${d['matiere']} • ${d['niveau']}",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _timerInfo(jours, estExpire),
                          _actionBtn(d, statut, estExpire),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeSimple(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statutBadge(String statut) {
    final config = {
      "non_commence": ("À FAIRE", _secondaryColor),
      "en_cours": ("EN COURS", Colors.blue),
      "soumis": ("SOUMIS", _gold),
      "corrige": ("CORRIGÉ", _green),
      "en_retard": ("RETARD", _red),
    }[statut] ?? ("-", Colors.grey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: config.$2.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(config.$1, style: TextStyle(color: config.$2, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  Widget _timerInfo(int jours, bool expire) {
    if (expire) return Text("Clôturé", style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
    Color c = jours < 3 ? _red : (jours < 7 ? _gold : _green);
    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 14, color: c),
        const SizedBox(width: 4),
        Text("$jours j restants", style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionBtn(Map<String, dynamic> d, String statut, bool expire) {
    if (statut == "corrige") {
      return TextButton.icon(
        onPressed: () => _voirResultat(d),
        icon: const Icon(Icons.analytics_outlined, size: 16),
        label: Text("Note: ${d['note_apprenant']}/${d['note_sur']}"),
        style: TextButton.styleFrom(foregroundColor: _green),
      );
    }
    if (expire && statut != "soumis") return const SizedBox();

    return ElevatedButton(
      onPressed: () => _ouvrirDevoir(d),
      style: ElevatedButton.styleFrom(
        backgroundColor: _mainColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(statut == "en_cours" ? "Continuer" : "Commencer", style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Aucun devoir ici", style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
        ],
      ),
    );
  }

  // ── Navigation ──────────────────────────────────────────────
  void _ouvrirDevoir(Map<String, dynamic> d) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ComposerDevoirPage(
      devoirId: d["id"], titre: d["titre"], dureeMin: d["duree_minutes"] ?? 60, noteSur: d["note_sur"] ?? 20,
    ))).then((_) => _charger());
  }

  void _voirResultat(Map<String, dynamic> d) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ResultatDevoirPage(
      devoirId: d["id"], titre: d["titre"],
    )));
  }

  // ── Helpers ─────────────────────────────────────────────────
  String _labelType(String code) => {
    "Tous": "Tous", "cursus": "Cursus", "concours": "Concours",
    "formation_classique": "Formation", "formation_metier": "Métier", "olympiade": "Olympiade",
  }[code] ?? code;

  String _labelStatut(String s) => {
    "non_commence": "À faire", "en_cours": "En cours", "soumis": "Soumis",
    "corrige": "Corrigé", "en_retard": "En retard",
  }[s] ?? s;

  Color _colorForType(String? type) => {
    "cursus": Colors.indigo, "concours": _gold, "formation_classique": Colors.teal,
    "formation_metier": Colors.deepOrange, "olympiade": _accent,
  }[type] ?? _mainColor;
}

// ── Modèles & Helpers UI ──────────────────────────────────────
class _TypeDevoirTab {
  final String code; final IconData icon; final Color color;
  const _TypeDevoirTab(this.code, this.icon, this.color);
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [if (overlapsContent) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: tabBar,
    );
  }
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(_StickyTabBarDelegate old) => false;
}