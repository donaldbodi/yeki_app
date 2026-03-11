import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'formations_models.dart';

const Color _gold   = Color(0xFFE2A84B);
const Color _dark   = Color(0xFF0D1B2A);
const Color _tealM  = Color(0xFF2884A0);

Future<String?> _tok() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _hdrs(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ═══════════════════════════════════════════════════════════════
// FORMATIONS MÉTIER — LISTE
// ═══════════════════════════════════════════════════════════════
class FormationsMetierPage extends StatefulWidget {
  const FormationsMetierPage({super.key});

  @override
  State<FormationsMetierPage> createState() => _FormationsMetierPageState();
}

class _FormationsMetierPageState extends State<FormationsMetierPage> {
  bool _loading = true;
  List<FormationMetier> _all      = [];
  List<FormationMetier> _affiches = [];

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _domaine     = 'Tous';
  String _niveau      = 'Tous';
  bool   _incubateur  = false;

  static const _domaines      = ['Tous', 'Tech', 'Business', 'Design', 'Sante'];
  static const _domainesLabel = ['Tous', 'Tech', 'Business', 'Design', 'Santé'];
  static const _niveaux       = ['Tous', 'Débutant', 'Intermédiaire', 'Avancé'];
  static const _niveauKeys    = {
    'Tous': '', 'Débutant': 'debutant',
    'Intermédiaire': 'intermediaire', 'Avancé': 'avance',
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
    final token = await _tok();

    final params = <String, String>{};
    if (_domaine != 'Tous') params['domaine'] = _domaine;
    final nKey = _niveauKeys[_niveau] ?? '';
    if (nKey.isNotEmpty) params['niveau'] = nKey;
    if (_incubateur) params['incubateur'] = 'true';
    if (_searchQuery.isNotEmpty) params['q'] = _searchQuery;

    final uri = Uri.parse('$kBaseUrl/formations/metier/')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    try {
      final res = await http.get(uri, headers: _hdrs(token));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _all      = data.map((d) => FormationMetier.fromJson(d)).toList();
        _affiches = List.from(_all);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _gold));
    }

    return RefreshIndicator(
      color: _gold,
      onRefresh: _charger,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _buildIncubateurBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildSearchBar(),
          ),
          _buildDomaineFilters(),
          _buildSecondaryFilters(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              '${_affiches.length} formation${_affiches.length > 1 ? 's' : ''} disponibles',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
          if (_affiches.isEmpty) _buildEmpty(),
          ..._affiches.map((f) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: _buildMetierCard(f),
              )),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Banner incubateur ───────────────────────────────────────
  Widget _buildIncubateurBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF00555A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: _tealM.withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFDF3E3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.rocket_launch_rounded,
              color: _gold, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Incubateur Yéki',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 3),
              Text(
                'Les meilleurs apprenants accèdent à notre réseau emploi partenaire.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 11.5,
                    height: 1.4),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded,
            color: _gold, size: 14),
      ]),
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
          _charger();
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une formation métier...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.grey.shade400, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _searchQuery = '';
                    _charger();
                  })
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildDomaineFilters() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
        itemCount: _domaines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d          = _domaines[i];
          final label      = _domainesLabel[i];
          final isSelected = _domaine == d;
          return GestureDetector(
            onTap: () {
              setState(() => _domaine = d);
              _charger();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _gold : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? _gold : Colors.grey.shade200),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: _gold.withOpacity(0.35),
                        blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Text(label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecondaryFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _niveaux.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final n          = _niveaux[i];
                final isSelected = _niveau == n;
                return GestureDetector(
                  onTap: () {
                    setState(() => _niveau = n);
                    _charger();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE0F4F4)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected ? _tealM : Colors.grey.shade200),
                    ),
                    child: Text(n,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? _tealM : Colors.grey.shade400,
                        )),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            setState(() => _incubateur = !_incubateur);
            _charger();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color:
                  _incubateur ? const Color(0xFFFDF3E3) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _incubateur ? _gold : Colors.grey.shade200),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.rocket_launch_rounded,
                  size: 14,
                  color: _incubateur ? _gold : Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('Incubateur',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _incubateur ? _gold : Colors.grey.shade400,
                  )),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildMetierCard(FormationMetier f) {
    final dc = _domaineColor(f.domaine);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FormationMetierDetailPage(id: f.id)),
      ).then((_) => _charger()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
            child: Stack(children: [
              Container(
                height: 140, width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      dc.withOpacity(0.9), dc.withOpacity(0.4), _dark
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(_domaineIcon(f.domaine),
                      size: 60, color: Colors.white.withOpacity(0.15)),
                ),
              ),
              // Niveau + Incubateur
              Positioned(
                top: 12, left: 12,
                child: Wrap(spacing: 6, children: [
                  _bannerBadge(_niveauLabel(f.niveau), Colors.black38),
                  if (f.incubateur)
                    _bannerBadge('Incubateur', const Color(0xFFC8871A)),
                ]),
              ),
              // Prix
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8)],
                  ),
                  child: Text(
                    f.prix == 0
                        ? 'Gratuit'
                        : '${_formatPrix(f.prix)} FCFA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: f.prix == 0 ? Colors.green : _dark,
                    ),
                  ),
                ),
              ),
              // Fondateurs
              Positioned(
                bottom: 10, left: 14,
                child: _fondateursRow(f, dc),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(f.nom,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _dark)),
                  ),
                  const SizedBox(width: 8),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: _gold),
                    const SizedBox(width: 3),
                    Text(f.noteMoyenne.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                  ]),
                ]),
                const SizedBox(height: 6),
                Text(f.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    ...f.competences.take(4).map((c) => _skillChip(c)),
                    if (f.competences.length > 4)
                      _skillChip('+${f.competences.length - 4}',
                          isMore: true),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _statMini(Icons.book_outlined, '${f.nbCours} cours'),
                  const SizedBox(width: 12),
                  _statMini(Icons.people_outline, '${f.nbInscrits}'),
                  const SizedBox(width: 12),
                  _statMini(Icons.schedule_outlined, '${f.dureeJours}j'),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF3E3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2A84B)),
                    ),
                    child: const Text('Voir',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _gold)),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _fondateursRow(FormationMetier f, Color dc) {
    return Row(children: [
      SizedBox(
        width: 28.0 + (f.fondateurs.take(2).length - 1) * 20.0,
        height: 28,
        child: Stack(
          children: f.fondateurs.take(2).toList().asMap().entries.map((e) {
            return Positioned(
              left: e.key * 20.0,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: dc,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    e.value['nom']!.substring(0, 1),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        f.fondateurs.map((e) => e['nom']!.split(' ').last).join(' & '),
        style: const TextStyle(
          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600,
          shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
        ),
      ),
    ]);
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.work_off_outlined,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Aucune formation trouvée',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Modifiez vos filtres',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _bannerBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _skillChip(String label, {bool isMore = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: isMore ? Colors.grey.shade100 : const Color(0xFFFEF9F0),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
          color: isMore
              ? Colors.grey.shade200
              : const Color(0xFFE2A84B)),
    ),
    child: Text(label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: isMore ? Colors.grey.shade400 : const Color(0xFFB8860B),
        )),
  );

  Widget _statMini(IconData icon, String label) => Row(children: [
    Icon(icon, size: 12, color: Colors.grey.shade400),
    const SizedBox(width: 3),
    Text(label,
        style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500)),
  ]);

  Color    _domaineColor(String d) => const {
    'Tech':     Color(0xFF008088), 'Business': Color(0xFF5B4FCF),
    'Design':   Color(0xFFE2455A), 'Sante':    Color(0xFF2EA84B),
  }[d] ?? const Color(0xFF008088);

  IconData _domaineIcon(String d) => const {
    'Tech':     Icons.code_rounded, 'Business': Icons.trending_up_rounded,
    'Design':   Icons.palette_rounded, 'Sante': Icons.medical_services_rounded,
  }[d] ?? Icons.work_rounded;

  String _niveauLabel(String n) => const {
    'debutant': 'Débutant', 'intermediaire': 'Intermédiaire', 'avance': 'Avancé',
  }[n] ?? n;

  String _formatPrix(double prix) =>
      prix >= 1000 ? '${(prix / 1000).toStringAsFixed(0)} 000' : prix.toStringAsFixed(0);
}


// ═══════════════════════════════════════════════════════════════
// FORMATION MÉTIER — DÉTAIL
// ═══════════════════════════════════════════════════════════════
class FormationMetierDetailPage extends StatefulWidget {
  final int id;
  const FormationMetierDetailPage({super.key, required this.id});

  @override
  State<FormationMetierDetailPage> createState() =>
      _FormationMetierDetailPageState();
}

class _FormationMetierDetailPageState
    extends State<FormationMetierDetailPage>
    with SingleTickerProviderStateMixin {
  bool             _loading    = true;
  bool             _inscribing = false;
  FormationMetier? _formation;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final token = await _tok();
    final res = await http.get(
      Uri.parse('$kBaseUrl/formations/metier/${widget.id}/'),
      headers: _hdrs(token),
    );
    if (res.statusCode == 200) {
      setState(() {
        _formation = FormationMetier.fromJson(jsonDecode(res.body));
        _loading   = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _inscrire() async {
    setState(() => _inscribing = true);
    final token = await _tok();
    final res = await http.post(
      Uri.parse('$kBaseUrl/formations/metier/${widget.id}/inscrire/'),
      headers: _hdrs(token),
    );
    setState(() => _inscribing = false);

    final msg = res.statusCode == 201
        ? 'Inscription réussie ! Bonne formation.'
        : res.statusCode == 409
            ? 'Déjà inscrit.'
            : 'Erreur lors de l\'inscription.';
    final color = res.statusCode == 201
        ? _gold
        : res.statusCode == 409
            ? Colors.orange
            : Colors.red;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      if (res.statusCode == 201) _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: _gold)));
    }
    final f        = _formation!;
    final domColor = _domaineColor(f.domaine);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(f, domColor),
          if (f.estInscrit)
            SliverToBoxAdapter(child: _buildProgressBar(f)),
          SliverToBoxAdapter(child: _buildRangBar(f)),
          SliverToBoxAdapter(
            child: ColoredBox(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: _gold,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: _gold,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Programme'),
                  Tab(text: 'Classement'),
                  Tab(text: 'À propos'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildProgrammeTab(f),
            _buildClassementTab(f),
            _buildAProposTab(f),
          ],
        ),
      ),
      bottomNavigationBar: f.estInscrit ? null : _buildCTA(f),
    );
  }

  Widget _buildSliverAppBar(FormationMetier f, Color dc) {
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: dc,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
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
              colors: [dc, dc.withOpacity(0.5), _dark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Wrap(spacing: 6, children: [
                    _heroBadge(f.domaine, Colors.black38),
                    if (f.incubateur) _heroBadge('Incubateur', _gold),
                  ]),
                  const SizedBox(height: 10),
                  Text(f.nom,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w900, height: 1.2,
                      )),
                  const SizedBox(height: 8),
                  Row(children: [
                    _fondateursRowHero(f, dc),
                    const Spacer(),
                    const Icon(Icons.star_rounded, color: _gold, size: 14),
                    const SizedBox(width: 3),
                    Text(f.noteMoyenne.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  Widget _fondateursRowHero(FormationMetier f, Color dc) {
    return Row(children: [
      SizedBox(
        width: 26.0 + (f.fondateurs.take(2).length - 1) * 18.0,
        height: 26,
        child: Stack(
          children: f.fondateurs.take(2).toList().asMap().entries.map((e) {
            return Positioned(
              left: e.key * 18.0,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: dc, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(e.value['nom']!.substring(0, 1),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'Par ${f.fondateurs.map((e) => e['nom']!.split(' ').last).join(' & ')}',
        style: TextStyle(
            color: Colors.white.withOpacity(0.8), fontSize: 12),
      ),
    ]);
  }

  Widget _buildProgressBar(FormationMetier f) {
    final done  = f.cours.where((c) => c.statut == 'fait').length;
    final total = f.cours.length;
    final pct   = total > 0 ? done / total : 0.0;

    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Ma progression',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$done / $total cours',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(width: 6),
          Text('${(pct * 100).toInt()}%',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF008088))),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF008088)),
            minHeight: 8,
          ),
        ),
      ]),
    );
  }

  Widget _buildRangBar(FormationMetier f) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1A3A4A)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.leaderboard_rounded,
              color: _gold, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Votre rang actuel',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          Text(
            f.estInscrit && f.monRang != null
                ? '#${f.monRang} sur ${f.nbInscrits}'
                : 'Inscrivez-vous pour participer',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14),
          ),
        ]),
        const Spacer(),
        if (f.estInscrit && f.monRang != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Top 10%',
                style: TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  // ── Onglet Programme ────────────────────────────────────────
  Widget _buildProgrammeTab(FormationMetier f) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: f.cours.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCoursTile(f.cours[i], i + 1),
    );
  }

  Widget _buildCoursTile(ModuleMetier m, int num) {
    final locked = m.locked && !(_formation?.estInscrit ?? false);
    final statusColor = m.statut == 'fait'
        ? Colors.green
        : m.statut == 'en_cours'
            ? _gold
            : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: m.statut == 'en_cours'
            ? Border.all(color: _gold.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: m.statut == 'fait'
                ? const Icon(Icons.check_rounded,
                    color: Colors.green, size: 18)
                : locked
                    ? Icon(Icons.lock_outline_rounded,
                        color: Colors.grey.shade400, size: 18)
                    : Text('$num',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade500,
                            fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.titre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: locked ? Colors.grey.shade400 : _dark,
                  )),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.schedule_outlined,
                    size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(m.duree,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400)),
                if (m.statut == 'en_cours') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('En cours',
                        style: TextStyle(
                            fontSize: 9.5,
                            color: _gold,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            ],
          ),
        ),
        if (!locked)
          Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: Colors.grey.shade300),
      ]),
    );
  }

  // ── Onglet Classement ───────────────────────────────────────
  Widget _buildClassementTab(FormationMetier f) {
    final cl = f.classement;
    if (cl.isEmpty) {
      return Center(
        child: Text('Classement non disponible',
            style: TextStyle(color: Colors.grey.shade400)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildPodium(cl.take(3).toList()),
        const SizedBox(height: 16),
        ...cl.skip(3).map((e) => _buildRangTile(e)),
      ],
    );
  }

  Widget _buildPodium(List<EntreeClassement> top3) {
    if (top3.length < 3) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF00404A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        const Text('Classement des Meilleurs',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _podiumItem(top3[1], 80,  const Color(0xFFC0C0C0)),
            _podiumItem(top3[0], 110, _gold),
            _podiumItem(top3[2], 65,  const Color(0xFFCD7F32)),
          ],
        ),
      ]),
    );
  }

  Widget _podiumItem(EntreeClassement e, double height, Color color) {
    final medal = e.rang == 1 ? '1er' : e.rang == 2 ? '2e' : '3e';
    return Column(children: [
      Text(medal,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      CircleAvatar(
        radius: 20,
        backgroundColor: color.withOpacity(0.3),
        child: Text(e.nom.isNotEmpty ? e.nom.substring(0, 1) : '?',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
      const SizedBox(height: 6),
      Text(e.nom.split(' ').first,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      Text('${e.score}pts',
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Container(
        width: 60, height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(
          child: Text('#${e.rang}',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
        ),
      ),
    ]);
  }

  Widget _buildRangTile(EntreeClassement e) {
    final isMe = false; // TODO: comparer avec le username connecté
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // ignore: dead_code
        color: isMe ? _gold.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        // ignore: dead_code
        border: isMe ? Border.all(color: _gold.withOpacity(0.4)) : null,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Text('#${e.rang}',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Colors.grey.shade400)),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey.shade100,
          child: Text(e.nom.isNotEmpty ? e.nom.substring(0, 1) : '?',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade500)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(e.nom,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade700)),
        ),
        Text('${e.score} pts',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.grey.shade500)),
      ]),
    );
  }

  // ── Onglet À propos ─────────────────────────────────────────
  Widget _buildAProposTab(FormationMetier f) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _section('Objectif', Icons.flag_outlined, [
          Text(f.objectif,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
        ]),
        const SizedBox(height: 12),
        _section('Description', Icons.info_outline_rounded, [
          Text(f.description,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
        ]),
        const SizedBox(height: 12),
        _section('Compétences acquises', Icons.psychology_outlined, [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: f.competences
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _gold.withOpacity(0.25)),
                      ),
                      child: Text(c,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB8860B),
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ]),
        const SizedBox(height: 12),
        _section('Vos formateurs', Icons.people_outline_rounded, [
          ...f.fondateurs.map((fond) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        _domaineColor(f.domaine).withOpacity(0.15),
                    child: Text(fond['nom']!.substring(0, 1),
                        style: TextStyle(
                            color: _domaineColor(f.domaine),
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(fond['nom']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(fond['profession'] ?? '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                ]),
              )),
        ]),
        const SizedBox(height: 12),
        _section('Infos pratiques', Icons.tune_rounded, [
          _infoRow(Icons.schedule_outlined, 'Durée', '${f.dureeJours} jours'),
          _infoRow(Icons.people_outline, 'Inscrits', '${f.nbInscrits} apprenants'),
          _infoRow(Icons.book_outlined, 'Cours', '${f.nbCours} modules'),
          _infoRow(Icons.signal_cellular_alt_rounded, 'Niveau', _niveauLabel(f.niveau)),
          if (f.incubateur)
            _infoRow(Icons.rocket_launch_rounded, 'Débouchés',
                'Emploi via incubateur Yeki', color: _gold),
        ]),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
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
          Icon(icon, size: 16, color: _gold),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _dark)),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade400),
        const SizedBox(width: 10),
        Text('$label : ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        Flexible(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color ?? _dark)),
        ),
      ]),
    );
  }

  // ── CTA Inscription ─────────────────────────────────────────
  Widget _buildCTA(FormationMetier f) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Prix de la formation',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            f.prix == 0 ? 'Gratuit' : '${_formatPrix(f.prix)} FCFA',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: _dark),
          ),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: _inscribing ? null : _inscrire,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFE2A84B), Color(0xFFC8871A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: _gold.withOpacity(0.4),
                  blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: _inscribing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text("S'inscrire maintenant",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  Color    _domaineColor(String d) => const {
    'Tech': Color(0xFF008088), 'Business': Color(0xFF5B4FCF),
    'Design': Color(0xFFE2455A), 'Sante': Color(0xFF2EA84B),
  }[d] ?? const Color(0xFF008088);

  String   _niveauLabel(String n) => const {
    'debutant': 'Débutant', 'intermediaire': 'Intermédiaire', 'avance': 'Avancé',
  }[n] ?? n;

  String _formatPrix(double prix) =>
      prix >= 1000 ? '${(prix / 1000).toStringAsFixed(0)} 000' : prix.toStringAsFixed(0);
}
