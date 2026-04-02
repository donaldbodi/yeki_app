// lib/views/pages/apprenants/concours_detail_page.dart
// ════════════════════════════════════════════════════════════════
// DÉTAIL PRÉPA CONCOURS — Design Prestigieux
// Affiche arrêté, date examen, places, frais, débouchés, cours…
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/cours_detail_page.dart';
import 'formations_models.dart';

const Color _navy   = Color(0xFF0D1B2A);
const Color _blue   = Color(0xFF2884A0);
const Color _gold   = Color(0xFFE2A84B);
const Color _green  = Color(0xFF10B981);
const Color _red    = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);
const Color _bg     = Color(0xFFF0F4F8);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');
Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ══════════════════════════════════════════════════════════════
class DetailConcoursPage extends StatefulWidget {
  final int              concoursId;
  final DepartementItem? deptPrecharge;

  const DetailConcoursPage({
    super.key,
    required this.concoursId,
    this.deptPrecharge,
  });

  @override
  State<DetailConcoursPage> createState() => _DetailConcoursPageState();
}

class _DetailConcoursPageState extends State<DetailConcoursPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  DepartementItem? _dept;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    if (widget.deptPrecharge != null) {
      _dept = widget.deptPrecharge;
      _loading = false;
    } else {
      _charger();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/departement/${widget.concoursId}/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _dept    = DepartementItem.fromJson(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _accentColor {
    try {
      final hex = (_dept?.couleur ?? '#2884A0').replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _blue;
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_dept == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Concours introuvable'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final dept = _dept!;

    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(dept),
          SliverToBoxAdapter(child: _buildTabs()),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _TabInfos(dept: dept, accentColor: _accentColor),
            _TabCours(dept: dept, accentColor: _accentColor),
            _TabDebouches(dept: dept, accentColor: _accentColor),
          ],
        ),
      ),
      bottomNavigationBar: dept.nbCours > 0
          ? _buildBottomBar(dept)
          : null,
    );
  }

  Widget _buildSliverAppBar(DepartementItem dept) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: _accentColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          // Image de fond
          if (dept.imageUrl != null)
            Image.network(dept.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildGradientBg(dept))
          else
            _buildGradientBg(dept),
          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Contenu de l'en-tête
          Positioned(
            left: 20, right: 20, bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge type
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Prépa Concours',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dept.nomConcours.isNotEmpty ? dept.nomConcours : dept.nom,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2),
                ),
                if (dept.nom != dept.nomConcours && dept.nom.isNotEmpty)
                  Text(dept.nom,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13)),
                if (dept.cadre != null)
                  Text('Cadre : ${dept.cadre!.nom}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12)),
              ],
            ),
          ),
          // Stats en haut à droite
          Positioned(
            right: 16, top: 56,
            child: Column(
              children: [
                _StatBubble(
                    value: '${dept.nbCours}',
                    label: 'cours',
                    icon: Icons.book_rounded,
                    color: Colors.white),
                const SizedBox(height: 8),
                _StatBubble(
                    value: dept.prix == 0 ? 'Gratuit' : '${dept.prix} F',
                    label: 'accès',
                    icon: dept.prix == 0
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    color: dept.prix == 0 ? _green : _gold),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildGradientBg(DepartementItem dept) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentColor,
            _accentColor.withOpacity(0.7),
            _navy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.emoji_events_rounded,
            size: 80, color: Colors.white.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: _accentColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _accentColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Infos'),
          Tab(icon: Icon(Icons.book_rounded, size: 18), text: 'Cours'),
          Tab(icon: Icon(Icons.trending_up_rounded, size: 18), text: 'Débouchés'),
        ],
      ),
    );
  }

  Widget _buildBottomBar(DepartementItem dept) {
    final progression = dept.progressionMoyenne;
    return Container(
      padding: EdgeInsets.only(
          left: 20, right: 20,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progression > 0
                      ? '${progression.toStringAsFixed(0)}% complété'
                      : '${dept.nbCours} cours disponibles',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progression / 100,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(_accentColor),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: dept.cours.isNotEmpty
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CoursDetailTabs(
                          coursId: dept.cours.single.id.toString(),//dept.cours.first.id.toString()
                          titre: dept.cours.single.title,
                        ),
                      ),
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              progression > 0 ? 'Continuer' : 'Commencer',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB INFOS
// ══════════════════════════════════════════════════════════════
class _TabInfos extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;
  const _TabInfos({required this.dept, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (dept.description.isNotEmpty) ...[
            _SectionTitle(title: 'À propos', icon: Icons.info_outline_rounded, color: accentColor),
            const SizedBox(height: 8),
            Text(dept.description,
                style: const TextStyle(fontSize: 14, height: 1.6,
                    color: Color(0xFF374151))),
            const SizedBox(height: 20),
          ],

          // Dates importantes
          _SectionTitle(title: 'Dates importantes', icon: Icons.calendar_today_rounded, color: accentColor),
          const SizedBox(height: 12),
          _DatesCard(dept: dept),
          const SizedBox(height: 20),

          // Infos du concours
          if (dept.arreteMinisteriel.isNotEmpty ||
              dept.placesDisponibles != null ||
              dept.fraisDossier > 0 ||
              dept.niveauxCibles.isNotEmpty) ...[
            _SectionTitle(title: 'Détails du concours', icon: Icons.gavel_rounded, color: accentColor),
            const SizedBox(height: 12),
            _DetailsCard(dept: dept, accentColor: accentColor),
            const SizedBox(height: 20),
          ],

          // Organisateur
          if (dept.organismeConcours.isNotEmpty) ...[
            _SectionTitle(title: 'Organisateur', icon: Icons.apartment_rounded, color: accentColor),
            const SizedBox(height: 8),
            _OrgCard(dept: dept, accentColor: accentColor),
            const SizedBox(height: 20),
          ],

          // Prix d'accès
          _SectionTitle(title: "Accès à la préparation", icon: Icons.lock_outline_rounded, color: accentColor),
          const SizedBox(height: 8),
          _PrixCard(dept: dept, accentColor: accentColor),
        ],
      ),
    );
  }
}

// ── Carte des dates ───────────────────────────────────────────
class _DatesCard extends StatelessWidget {
  final DepartementItem dept;
  const _DatesCard({required this.dept});

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return 'Non définie';
    try {
      final d = DateTime.parse(iso);
      const months = ['', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
                      'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  bool _isPast(String? iso) {
    if (iso == null) return false;
    try { return DateTime.parse(iso).isBefore(DateTime.now()); } catch (_) { return false; }
  }

  bool _isSoon(String? iso) {
    if (iso == null) return false;
    try {
      final d = DateTime.parse(iso);
      final diff = d.difference(DateTime.now()).inDays;
      return diff >= 0 && diff <= 30;
    } catch (_) { return false; }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_DateRow>[];
    if (dept.dateLimiteInscription != null) {
      final past = _isPast(dept.dateLimiteInscription);
      final soon = _isSoon(dept.dateLimiteInscription);
      rows.add(_DateRow(
        label: "Clôture des inscriptions",
        value: _fmt(dept.dateLimiteInscription),
        icon: Icons.how_to_reg_rounded,
        color: past ? _red : soon ? _gold : _green,
        badge: past ? 'Fermé' : soon ? 'Bientôt' : null,
      ));
    }
    if (dept.dateExamen != null) {
      final past = _isPast(dept.dateExamen);
      rows.add(_DateRow(
        label: "Date de l'examen",
        value: _fmt(dept.dateExamen),
        icon: Icons.event_rounded,
        color: past ? Colors.grey : _red,
        badge: past ? 'Passé' : null,
      ));
    }
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Dates non précisées',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final r = rows[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: r.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(r.icon, color: r.color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                          Text(r.value,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: r.color)),
                        ],
                      ),
                    ),
                    if (r.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: r.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(r.badge!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(height: 1, indent: 72, color: Colors.grey.shade100),
            ],
          );
        }),
      ),
    );
  }
}

class _DateRow {
  final String label, value;
  final IconData icon;
  final Color color;
  final String? badge;
  const _DateRow({required this.label, required this.value,
    required this.icon, required this.color, this.badge});
}

// ── Carte détails ─────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;
  const _DetailsCard({required this.dept, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final items = <_DetailItem>[];
    if (dept.arreteMinisteriel.isNotEmpty)
      items.add(_DetailItem(
          icon: Icons.gavel_rounded, label: 'Arrêté ministériel',
          value: dept.arreteMinisteriel, color: accentColor));
    if (dept.niveauxCibles.isNotEmpty)
      items.add(_DetailItem(
          icon: Icons.school_rounded, label: 'Niveaux ciblés',
          value: dept.niveauxCibles, color: accentColor));
    if (dept.placesDisponibles != null)
      items.add(_DetailItem(
          icon: Icons.people_rounded, label: 'Places disponibles',
          value: '${dept.placesDisponibles}', color: _purple));
    if (dept.fraisDossier > 0)
      items.add(_DetailItem(
          icon: Icons.receipt_long_rounded, label: 'Frais de dossier',
          value: '${dept.fraisDossier} FCFA', color: _gold));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 18),
                ),
                title: Text(item.label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                subtitle: Text(item.value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937))),
                dense: true,
              ),
              if (i < items.length - 1)
                Divider(height: 1, indent: 72, color: Colors.grey.shade100),
            ],
          );
        }),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label, value;
  final Color color;
  const _DetailItem({required this.icon, required this.label,
    required this.value, required this.color});
}

// ── Carte organisateur ────────────────────────────────────────
class _OrgCard extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;
  const _OrgCard({required this.dept, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.apartment_rounded, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dept.organismeConcours,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                if (dept.lienOfficiel.isNotEmpty)
                  Text(dept.lienOfficiel,
                      style: TextStyle(
                          fontSize: 12, color: accentColor,
                          decoration: TextDecoration.underline),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte prix ────────────────────────────────────────────────
class _PrixCard extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;
  const _PrixCard({required this.dept, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isGratuit = dept.prix == 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGratuit
              ? [_green.withOpacity(0.1), _green.withOpacity(0.05)]
              : [_gold.withOpacity(0.1), _gold.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isGratuit ? _green.withOpacity(0.3) : _gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isGratuit ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: isGratuit ? _green : _gold,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGratuit ? 'Accès gratuit' : '${dept.prix} FCFA',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isGratuit ? _green : _gold),
                ),
                Text(
                  isGratuit
                      ? 'Cette préparation est entièrement gratuite'
                      : 'Paiement unique pour accéder à tous les cours',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB COURS
// ══════════════════════════════════════════════════════════════
class _TabCours extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;
  const _TabCours({required this.dept, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    if (dept.cours.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Aucun cours disponible pour l\'instant',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dept.cours.length,
      itemBuilder: (ctx, i) {
        final c = dept.cours[i];
        Color cardColor;
        try {
          final hex = c.color.replaceAll('#', '');
          cardColor = Color(int.parse('FF$hex', radix: 16));
        } catch (_) {
          cardColor = accentColor;
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => 
              CoursDetailTabs(
                          coursId: c.id.toString(),
                          titre: c.title,
                        ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.book_rounded, color: cardColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      if (c.description.isNotEmpty)
                        Text(c.description,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.play_lesson_rounded,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('${c.lessons} leçons',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                          const SizedBox(width: 12),
                          Icon(Icons.assignment_rounded,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('${c.assignments} devoirs',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${c.progression.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cardColor)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c.progression / 100,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(cardColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB DÉBOUCHÉS
// ══════════════════════════════════════════════════════════════
class _TabDebouches extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;
  const _TabDebouches({required this.dept, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    if (dept.debouches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Débouchés non précisés',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    // Parser les débouchés (séparés par \n ou par points)
    final lignes = dept.debouches
        .split(RegExp(r'\n|•|·'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Après ce concours',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: accentColor)),
                ],
              ),
              const SizedBox(height: 14),
              ...lignes.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6, height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 10),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(l,
                              style: const TextStyle(
                                  fontSize: 14, height: 1.5,
                                  color: Color(0xFF374151))),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Color    color;
  const _SectionTitle({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String   value;
  final String   label;
  final IconData icon;
  final Color    color;
  const _StatBubble({
    required this.value, required this.label,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ],
      ),
    );
  }
}
