import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'formations_models.dart';

// ─── Palette ─────────────────────────────────────────────────
const Color _teal = Color(0xFF008088);
const Color _dark = Color(0xFF0D1B2A);

// ═══════════════════════════════════════════════════════════════
// SERVICE
// ═══════════════════════════════════════════════════════════════
Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Token $token',
};

// ═══════════════════════════════════════════════════════════════
// FORMATIONS CLASSIQUES — PAGE LISTE
// ═══════════════════════════════════════════════════════════════
class FormationsClassiquesPage extends StatefulWidget {
  const FormationsClassiquesPage({super.key});

  @override
  State<FormationsClassiquesPage> createState() =>
      _FormationsClassiquesPageState();
}

class _FormationsClassiquesPageState
    extends State<FormationsClassiquesPage> {
  bool _loading = true;
  List<FormationClassique> _all      = [];
  List<FormationClassique> _affiches = [];

  final _searchCtrl = TextEditingController();
  String _searchQuery     = '';
  String _selectedType    = 'Tous';
  bool   _publicSeulement = false;

  final List<String> _types = [
    'Tous', 'Grande École', 'Université', 'Lycée', 'Centre'
  ];
  final Map<String, String> _typeKeys = {
    'Tous':         '',
    'Grande École': 'grande_ecole',
    'Université':   'universite',
    'Lycée':        'lycee',
    'Centre':       'centre_formation',
  };

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();

    final params = <String, String>{};
    final typeKey = _typeKeys[_selectedType] ?? '';
    if (typeKey.isNotEmpty) params['type'] = typeKey;
    if (_publicSeulement)   params['publique'] = 'true';
    if (_searchQuery.isNotEmpty) params['q'] = _searchQuery;

    final uri = Uri.parse('$kBaseUrl/formations/classiques/')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    try {
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _all = data.map((d) => FormationClassique.fromJson(d)).toList();
        _appliquerFiltresLocaux();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _appliquerFiltresLocaux() {
    final q = _searchQuery.toLowerCase();
    setState(() {
      _affiches = _all.where((f) {
        final match = q.isEmpty ||
            f.ecole.toLowerCase().contains(q)   ||
            f.parcours.toLowerCase().contains(q) ||
            f.ville.toLowerCase().contains(q);
        return match;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: _teal))
        : RefreshIndicator(
            color: _teal,
            onRefresh: _charger,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildSearchBar(),
                  ),
                ),
                SliverToBoxAdapter(child: _buildTypeFilters()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Row(children: [
                      Text(
                        '${_affiches.length} formation${_affiches.length > 1 ? 's' : ''}',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      _togglePublic(),
                    ]),
                  ),
                ),
                _affiches.isEmpty
                    ? SliverFillRemaining(child: _buildEmpty())
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildCard(_affiches[i]),
                            childCount: _affiches.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          _searchQuery = v;
          _appliquerFiltresLocaux();
        },
        decoration: InputDecoration(
          hintText: 'Rechercher école, parcours, ville...',
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey.shade400, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                    _appliquerFiltresLocaux();
                  })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t        = _types[i];
          final isSelected = _selectedType == t;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = t);
              _charger();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? _teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? _teal : Colors.grey.shade200),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: _teal.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Text(t,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _togglePublic() {
    return GestureDetector(
      onTap: () {
        setState(() => _publicSeulement = !_publicSeulement);
        _charger();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _publicSeulement ? _teal.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: _publicSeulement ? _teal : Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(Icons.account_balance_outlined,
              size: 14,
              color: _publicSeulement ? _teal : Colors.grey.shade400),
          const SizedBox(width: 5),
          Text('Publiques',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _publicSeulement ? _teal : Colors.grey.shade400)),
        ]),
      ),
    );
  }

  Widget _buildCard(FormationClassique f) {
    final typeColor = _typeColor(f.type);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FormationClassiqueDetailPage(id: f.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(children: [
              Container(
                height: 130, width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      typeColor.withOpacity(0.85),
                      typeColor.withOpacity(0.5),
                      _dark,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(_typeIcon(f.type),
                      size: 52,
                      color: Colors.white.withOpacity(0.22)),
                ),
              ),
              Positioned(
                top: 12, right: 12,
                child: _badge(
                  f.estPublique ? 'Public' : 'Privé',
                  f.estPublique
                      ? Colors.green.withOpacity(0.85)
                      : Colors.orange.withOpacity(0.85),
                ),
              ),
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(_typeLabel(f.type),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              Positioned(
                bottom: 12, left: 14,
                child: Text(f.ecole,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                    )),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.parcours,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _dark)),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text('${f.ville}, ${f.pays}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ]),
                const SizedBox(height: 10),
                Text(f.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4)),
                const SizedBox(height: 12),
                Row(children: [
                  _statChip(Icons.book_outlined,
                      '${f.nbCours} cours', _teal),
                  const SizedBox(width: 8),
                  _statChip(Icons.people_outline,
                      '${f.nbEtudiants}', Colors.indigo),
                  const Spacer(),
                  ...f.niveaux.take(2).map((n) => Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(n,
                            style: const TextStyle(
                                fontSize: 10,
                                color: _teal,
                                fontWeight: FontWeight.w600)),
                      )),
                  if (f.niveaux.length > 2)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('+${f.niveaux.length - 2}',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600)),
                    ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded,
            size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Aucune formation trouvée',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Modifiez vos critères',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _statChip(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Color  _typeColor(String t) => const {
    'lycee':          Color(0xFF2884A0),
    'universite':     Color(0xFF5B4FCF),
    'grande_ecole':   Color(0xFF008088),
    'centre_formation': Color(0xFFE2A84B),
  }[t] ?? const Color(0xFF008088);

  String _typeLabel(String t) => const {
    'lycee':          'Lycée',
    'universite':     'Université',
    'grande_ecole':   'Grande École',
    'centre_formation': 'Centre',
  }[t] ?? 'Formation';

  IconData _typeIcon(String t) => const {
    'lycee':          Icons.school_rounded,
    'universite':     Icons.account_balance_rounded,
    'grande_ecole':   Icons.emoji_events_rounded,
    'centre_formation': Icons.hub_rounded,
  }[t] ?? Icons.school_rounded;
}


// ═══════════════════════════════════════════════════════════════
// FORMATION CLASSIQUE — DÉTAIL
// ═══════════════════════════════════════════════════════════════
class FormationClassiqueDetailPage extends StatefulWidget {
  final int id;
  const FormationClassiqueDetailPage({super.key, required this.id});

  @override
  State<FormationClassiqueDetailPage> createState() =>
      _FormationClassiqueDetailPageState();
}

class _FormationClassiqueDetailPageState
    extends State<FormationClassiqueDetailPage>
    with SingleTickerProviderStateMixin {
  bool               _loading = true;
  FormationClassique? _formation;
  late TabController  _tabCtrl;

  String _searchQuery    = '';
  String _selectedNiveau = 'Tous';
  String _selectedMat    = 'Toutes';
  final  _searchCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$kBaseUrl/formations/classiques/${widget.id}/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      setState(() {
        _formation = FormationClassique.fromJson(jsonDecode(res.body));
        _loading   = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  List<CoursClassique> get _coursFiltres {
    final f = _formation;
    if (f == null) return [];
    final q = _searchQuery.toLowerCase();
    return f.cours.where((c) {
      final mq = q.isEmpty ||
          c.titre.toLowerCase().contains(q) ||
          c.enseignant.toLowerCase().contains(q);
      final mn = _selectedNiveau == 'Tous' || c.niveau == _selectedNiveau;
      final mm = _selectedMat == 'Toutes'  || c.matiere == _selectedMat;
      return mq && mn && mm;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _teal)));
    }
    final f = _formation!;
    final typeColor = _tc(f.type);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(f, typeColor),
          SliverToBoxAdapter(child: _buildInfoBar(f)),
          SliverToBoxAdapter(
            child: ColoredBox(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: _teal,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: _teal,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [Tab(text: 'Cours'), Tab(text: 'Informations')],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildCoursTab(f),
            _buildInfoTab(f),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(FormationClassique f, Color typeColor) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: typeColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                typeColor, typeColor.withOpacity(0.6), _dark
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f.ecole,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Text(f.parcours,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w900, height: 1.2,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBar(FormationClassique f) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoBarItem(Icons.book_outlined, '${f.nbCours}', 'Cours', _teal),
          _divider(),
          _infoBarItem(Icons.people_outline, '${f.nbEtudiants}', 'Étudiants', Colors.indigo),
          _divider(),
          _infoBarItem(Icons.layers_outlined, '${f.niveaux.length}', 'Niveaux', Colors.orange),
          _divider(),
          _infoBarItem(
            f.estPublique
                ? Icons.account_balance_outlined
                : Icons.business_outlined,
            f.estPublique ? 'Public' : 'Privé',
            'Statut',
            f.estPublique ? Colors.green : Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _infoBarItem(
      IconData icon, String val, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(val,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800, color: _dark)),
      Text(label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
    ]);
  }

  Widget _divider() => Container(
      width: 1, height: 35, color: Colors.grey.shade100);

  // ── Onglet Cours ─────────────────────────────────────────────
  Widget _buildCoursTab(FormationClassique f) {
    final cours = _coursFiltres;
    final niveaux  = ['Tous', ...f.niveaux];
    final matieres = ['Toutes', ...f.matieres];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildCoursSearch(),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildHorizontalFilter(
            niveaux,
            _selectedNiveau,
            (v) => setState(() => _selectedNiveau = v),
            _teal,
          ),
        ),
        SliverToBoxAdapter(
          child: _buildHorizontalFilter(
            matieres,
            _selectedMat,
            (v) => setState(() => _selectedMat = v),
            Colors.indigo,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              '${cours.length} cours trouvé${cours.length > 1 ? 's' : ''}',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
        cours.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Text('Aucun cours',
                      style: TextStyle(color: Colors.grey.shade400)),
                ))
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildCoursTile(cours[i]),
                    childCount: cours.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildCoursSearch() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Rechercher un cours, un enseignant...',
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 19),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey.shade400, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHorizontalFilter(
    List<String> items,
    String selected,
    ValueChanged<String> onTap,
    Color color,
  ) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final item       = items[i];
          final isSelected = selected == item;
          return GestureDetector(
            onTap: () => onTap(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200),
              ),
              child: Text(item,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoursTile(CoursClassique c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.play_circle_outline_rounded,
              color: _teal, size: 22),
        ),
        title: Text(c.titre,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(c.enseignant,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 5),
            Row(children: [
              _miniChip(c.matiere, Colors.indigo),
              const SizedBox(width: 5),
              _miniChip(c.niveau, _teal),
              const SizedBox(width: 5),
              _miniChip('${c.nbLecons} leçons', Colors.orange),
            ]),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Colors.grey.shade300),
            const SizedBox(height: 4),
            Text(c.duree,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(
            fontSize: 9.5, color: color, fontWeight: FontWeight.w700)),
  );

  // ── Onglet Informations ─────────────────────────────────────
  Widget _buildInfoTab(FormationClassique f) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _infoSection('À propos', Icons.info_outline_rounded, [
          Text(f.description,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
        ]),
        const SizedBox(height: 16),
        _infoSection('Niveaux disponibles', Icons.layers_outlined, [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: f.niveaux
                .map((n) => _tagChip(n, _teal))
                .toList(),
          ),
        ]),
        const SizedBox(height: 16),
        _infoSection('Matières enseignées', Icons.subject_rounded, [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: f.matieres
                .map((m) => _tagChip(m, Colors.indigo))
                .toList(),
          ),
        ]),
        const SizedBox(height: 16),
        _infoSection('Localisation', Icons.location_on_outlined, [
          Row(children: [
            Icon(Icons.location_city_rounded,
                size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text('${f.ville}, ${f.pays}',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade700)),
          ]),
        ]),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _infoSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: _teal),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _dark)),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _tagChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  );

  Color _tc(String t) => const {
    'lycee':            Color(0xFF2884A0),
    'universite':       Color(0xFF5B4FCF),
    'grande_ecole':     Color(0xFF008088),
    'centre_formation': Color(0xFFE2A84B),
  }[t] ?? const Color(0xFF008088);
}
