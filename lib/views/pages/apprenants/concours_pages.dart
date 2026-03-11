import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'formations_models.dart';

// ─── Palette ──────────────────────────────────────────────────
const Color _mainTeal = Color(0xFF2884A0);
const Color _tealDark = Color(0xFF1F5F75);
const Color _accent   = Color(0xFFFFB74D);
const Color _bg       = Color(0xFFF4F9FB);

Future<String?> _getToken() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('token');
}

Map<String, String> _headers(String? token) => {
  'Content-Type': 'application/json',
  if (token != null) 'Authorization': 'Token $token',
};

// ═══════════════════════════════════════════════════════════════
// CONCOURS — PAGE LISTE
// ═══════════════════════════════════════════════════════════════
class ConcoursPage extends StatefulWidget {
  const ConcoursPage({super.key});

  @override
  State<ConcoursPage> createState() => _ConcoursPageState();
}

class _ConcoursPageState extends State<ConcoursPage> {
  bool           _loading       = true;
  List<Concours> _tous          = [];
  List<Concours> _affiches      = [];
  String         _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();

    final params = <String, String>{};
    if (_selectedFilter == 'Souscrits')   params['souscrit'] = 'true';
    if (_selectedFilter == 'Disponibles') params['souscrit'] = 'false';

    final uri = Uri.parse('$kBaseUrl/concours/')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    try {
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _tous     = data.map((d) => Concours.fromJson(d)).toList();
        _affiches = List.from(_tous);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                _buildHeader(),
                Positioned(
                  bottom: -25,
                  left: 0,
                  right: 0,
                  child: _buildFilterBar(),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _mainTeal))
            : RefreshIndicator(
                color: _mainTeal,
                onRefresh: _charger,
                child: _affiches.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _affiches.length,
                        itemBuilder: (context, i) =>
                            _buildConcoursCard(_affiches[i]),
                      ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 65),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), _tealDark, _mainTeal],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_user, color: _accent, size: 14),
            const SizedBox(width: 8),
            Text(
              "PROGRAMME ÉLITE",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        const Text(
          'Réussissez vos\nconcours.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Accédez aux meilleures ressources pour intégrer\nles grandes écoles d\'excellence.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
      ]),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['Tous', 'Souscrits', 'Disponibles'];
    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _tealDark.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = f);
                _charger();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _mainTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : _mainTeal.withOpacity(0.6),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConcoursCard(Concours c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetailConcoursPage(concoursId: c.id)),
          ).then((_) => _charger()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image / Banner ─────────────────────────
              Stack(children: [
                // Image réseau ou placeholder gradient
                c.imageUrl.isNotEmpty
                    ? Image.network(
                        c.imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _concoursPlaceholder(c),
                      )
                    : _concoursPlaceholder(c),

                // Overlay gradient
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65)
                      ],
                    ),
                  ),
                ),

                // Badge J-X
                Positioned(
                  top: 12, left: 12,
                  child: _glassBadge(
                    "J-${c.joursRestants}",
                    c.joursRestants <= 14
                        ? Colors.redAccent
                        : _mainTeal,
                  ),
                ),

                // Étoile si souscrit
                if (c.estSouscrit)
                  const Positioned(
                    top: 12, right: 12,
                    child: CircleAvatar(
                      backgroundColor: _accent,
                      radius: 14,
                      child: Icon(Icons.star, color: Colors.white, size: 16),
                    ),
                  ),

                // Titre en bas de l'image
                Positioned(
                  bottom: 10, left: 14,
                  child: Text(
                    c.titre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black54)
                      ],
                    ),
                  ),
                ),
              ]),

              // ── Infos carte ─────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    // Barre de progression
                    _buildProgressionBar(c.joursRestants),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(children: [
                      _infoChip(Icons.school, c.niveau),
                      const SizedBox(width: 8),
                      _infoChip(Icons.menu_book,
                          '${c.nbModules} module${c.nbModules > 1 ? 's' : ''}'),
                      const Spacer(),
                      Text(
                        c.prix == 0
                            ? 'Gratuit'
                            : '${c.prix.toInt()} FCFA',
                        style: const TextStyle(
                          color: _mainTeal,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ]),

                    const SizedBox(height: 12),

                    // Footer : inscrits + taux
                    Row(children: [
                      Icon(Icons.people_outline,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text('${c.nbInscrits} inscrits',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(width: 12),
                      Icon(Icons.verified_outlined,
                          size: 13, color: Colors.green.shade400),
                      const SizedBox(width: 4),
                      Text('${c.tauxReussite}% réussite',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                      const Spacer(),
                      if (c.estSouscrit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _accent),
                          ),
                          child: const Text('Souscrit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _accent,
                              )),
                        ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _concoursPlaceholder(Concours c) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), _tealDark, _mainTeal],
        ),
      ),
      child: Center(
        child: Icon(Icons.emoji_events_rounded,
            size: 60, color: Colors.white.withOpacity(0.2)),
      ),
    );
  }

  Widget _glassBadge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8)),
    child: Text(text,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11)),
  );

  Widget _infoChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: _bg, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(icon, size: 12, color: _mainTeal),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _tealDark)),
    ]),
  );

  Widget _buildProgressionBar(int jours) {
    double progress = ((90 - jours) / 90).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Progression des inscriptions",
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500)),
            Text("${(progress * 100).toInt()}%",
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _mainTeal)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: _mainTeal.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? Colors.redAccent : _mainTeal),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Aucun concours trouvé',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _charger,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// CONCOURS — DÉTAIL
// ═══════════════════════════════════════════════════════════════
class DetailConcoursPage extends StatefulWidget {
  final int concoursId;
  const DetailConcoursPage({super.key, required this.concoursId});

  @override
  State<DetailConcoursPage> createState() => _DetailConcoursPageState();
}

class _DetailConcoursPageState extends State<DetailConcoursPage> {
  bool      _loading    = true;
  bool      _souscribing = false;
  Concours? _concours;

  static const Color _primaryTeal = Color(0xFF008088);
  static const Color _darkBlue    = Color(0xFF1A1C1E);
  static const Color _goldAccent  = Color(0xFFD4AF37);
  static const Color _scaffoldBg  = Color(0xFFF8FAFB);

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$kBaseUrl/concours/${widget.concoursId}/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      setState(() {
        _concours = Concours.fromJson(jsonDecode(res.body));
        _loading  = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _souscrire() async {
    setState(() => _souscribing = true);
    final token = await _getToken();
    final res = await http.post(
      Uri.parse('$kBaseUrl/concours/${widget.concoursId}/souscrire/'),
      headers: _headers(token),
    );
    setState(() => _souscribing = false);

    final msg   = res.statusCode == 201
        ? 'Souscription confirmée ! Bonne préparation.'
        : res.statusCode == 409
            ? 'Vous êtes déjà souscrit.'
            : 'Erreur. Veuillez réessayer.';
    final color = res.statusCode == 201
        ? _primaryTeal
        : res.statusCode == 409
            ? Colors.orange
            : Colors.red;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
      if (res.statusCode == 201) _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: _primaryTeal)));
    }
    final c = _concours!;

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header image ───────────────────────────────
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: _darkBlue,
            leading: _buildBackButton(),
            actions: [
              if (c.estSouscrit)
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(children: [
                    Icon(Icons.star, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Souscrit',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image ou placeholder
                  c.imageUrl.isNotEmpty
                      ? Image.network(c.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _headerPlaceholder())
                      : _headerPlaceholder(),

                  // Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.transparent,
                          _darkBlue.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),

                  // Texte header
                  Positioned(
                    bottom: 40, left: 24, right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: _goldAccent,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text("OFFRE ÉLITE 2026",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                        ),
                        const SizedBox(height: 12),
                        Text(c.titre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            )),
                        if (c.niveau.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.school_outlined,
                                size: 13,
                                color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 5),
                            Text(c.niveau,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenu ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner urgence
                  _buildUrgencyBanner(c),
                  const SizedBox(height: 28),

                  // Stats
                  _buildStatsRow(c),
                  const SizedBox(height: 28),

                  // Description
                  _buildSectionHeader("À propos du concours"),
                  const SizedBox(height: 12),
                  Text(c.description,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                          height: 1.6)),
                  const SizedBox(height: 28),

                  // Modules
                  if (c.modules.isNotEmpty) ...[
                    _buildSectionHeader("Programme de formation"),
                    const SizedBox(height: 16),
                    ...c.modules.map((m) => _buildModuleTile(m, c.estSouscrit)),
                  ],

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(c),
    );
  }

  Widget _headerPlaceholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), _tealDark, _mainTeal],
      ),
    ),
    child: Center(
      child: Icon(Icons.emoji_events_rounded,
          size: 80, color: Colors.white.withOpacity(0.15)),
    ),
  );

  Widget _buildBackButton() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: CircleAvatar(
      backgroundColor: Colors.black.withOpacity(0.3),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
    ),
  );

  Widget _buildUrgencyBanner(Concours c) {
    final urgent = c.joursRestants <= 14;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: (urgent ? Colors.redAccent : _primaryTeal)
                .withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 20)
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (urgent ? Colors.redAccent : _primaryTeal)
                .withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.timer_outlined,
            color: urgent ? Colors.redAccent : _primaryTeal,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Temps restant",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                c.joursRestants == 0
                    ? 'Clôturé'
                    : '${c.joursRestants} jour${c.joursRestants > 1 ? 's' : ''} restant${c.joursRestants > 1 ? 's' : ''}',
                style: TextStyle(
                    color: _darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Text(
                'Date limite : ${c.dateLimite}',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        if (urgent)
          Text("CLÔTURE BIENTÔT",
              style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 10)),
      ]),
    );
  }

  Widget _buildStatsRow(Concours c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statCard(Icons.groups_outlined,
            c.nbInscrits >= 1000
                ? '${(c.nbInscrits / 1000).toStringAsFixed(1)}k'
                : '${c.nbInscrits}',
            'Inscrits'),
        _statCard(Icons.verified_outlined,
            '${c.tauxReussite}%', 'Réussite'),
        _statCard(Icons.menu_book_outlined,
            '${c.nbModules}', 'Modules'),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      width: (MediaQuery.of(context).size.width - 72) / 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(children: [
        Icon(icon, color: _primaryTeal, size: 22),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _darkBlue,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    );
  }

  Widget _buildSectionHeader(String title) => Row(children: [
    Container(
        width: 4, height: 20,
        decoration: BoxDecoration(
            color: _primaryTeal,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 12),
    Text(title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _darkBlue)),
  ]);

  Widget _buildModuleTile(ModuleConcours m, bool estSouscrit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Row(children: [
        Container(
          height: 44, width: 44,
          decoration: BoxDecoration(
            color: _primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.play_arrow_rounded, color: _primaryTeal),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.titre,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: _darkBlue)),
              const SizedBox(height: 3),
              Text(
                m.description.isEmpty
                    ? (estSouscrit
                        ? 'Accès débloqué'
                        : 'Accès premium requis')
                    : m.description,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Icon(
          estSouscrit
              ? Icons.check_circle_outline_rounded
              : Icons.lock_outline_rounded,
          size: 18,
          color: estSouscrit ? Colors.green : Colors.grey.shade400,
        ),
      ]),
    );
  }

  Widget _buildBottomAction(Concours c) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.estSouscrit ? 'Accès actif' : 'Accès complet',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              c.prix == 0 ? 'Gratuit' : '${c.prix.toInt()} FCFA',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: c.estSouscrit ? Colors.green : _primaryTeal),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: c.estSouscrit
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('ACCÈS DÉBLOQUÉ',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: _souscribing ? null : _souscrire,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _souscribing
                          ? _primaryTeal.withOpacity(0.7)
                          : _primaryTeal,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: _primaryTeal.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Center(
                      child: _souscribing
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text("DÉBLOQUER L'ACCÈS",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5)),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}
