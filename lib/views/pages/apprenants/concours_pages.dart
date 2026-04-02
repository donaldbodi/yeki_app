// lib/views/pages/apprenants/concours_pages.dart
// ════════════════════════════════════════════════════════════════
// PAGE PRÉPA CONCOURS — Design Prestigieux
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';
import 'package:yeki/views/pages/apprenants/concours_detail_page.dart';

const Color _navy = Color(0xFF0D1B2A);
const Color _blue = Color(0xFF2884A0);
const Color _gold = Color(0xFFE2A84B);
const Color _green = Color(0xFF10B981);
const Color _red = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);
const Color _bg = Color(0xFFF0F4F8);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');

Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ══════════════════════════════════════════════════════════════
// PAGE LISTE — PRÉPA CONCOURS
// ══════════════════════════════════════════════════════════════
class ConcoursPage extends StatefulWidget {
  const ConcoursPage({super.key});

  @override
  State<ConcoursPage> createState() => _ConcoursPageState();
}

class _ConcoursPageState extends State<ConcoursPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  List<DepartementItem> _tous = [];
  List<DepartementItem> _affiches = [];
  String _filtre = 'Tous';
  String _searchQ = '';
  String _niveauApprenant = '';
  final _searchCtrl = TextEditingController();
  late AnimationController _animCtrl;

  static const _filtres = ['Tous', 'Gratuit', 'Payant', 'En cours'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadNiveau();
    _charger();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
        Uri.parse('$kBaseUrl/apprenant/prepa-concours/'),
        headers: _headers(token),
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _tous = data.map((d) => DepartementItem.fromJson(d as Map<String, dynamic>)).toList();
          _appliquerFiltre();
        });
        _animCtrl.forward(from: 0);
      } else if (mounted) {
        setState(() => _error = 'Erreur ${res.statusCode}');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Erreur réseau');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _appliquerFiltre() {
    final q = _searchQ.toLowerCase();
    setState(() {
      _affiches = _tous.where((d) {
        final matchSearch = q.isEmpty ||
            d.nom.toLowerCase().contains(q) ||
            d.nomConcours.toLowerCase().contains(q) ||
            d.niveauxCibles.toLowerCase().contains(q);

        final matchFiltre = switch (_filtre) {
          'Gratuit' => d.prix == 0,
          'Payant' => d.prix > 0,
          'En cours' => d.progression > 0 && d.progression < 100,
          _ => true,
        };

        // Filtrage par niveau: niveau concours <= niveau apprenant
        bool matchNiveau = true;
        if (_niveauApprenant.isNotEmpty && d.niveauxCibles.isNotEmpty) {
          matchNiveau = NiveauService.estAccessible(_niveauApprenant, d.niveauxCibles);
        }

        return matchSearch && matchFiltre && matchNiveau;
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
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterDelegate(
              filtres: _filtres,
              selected: _filtre,
              onSelect: (f) { _filtre = f; _appliquerFiltre(); },
            ),
          ),
        ],
        body: _loading
            ? const _LoadingView()
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
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: _navy,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        titlePadding: const EdgeInsets.only(left: 20, bottom: 56),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Prépa Concours',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 0.5)),
            Text('Préparez votre réussite',
                style: TextStyle(fontSize: 11, color: Color(0xFFADD8E6))),
          ],
        ),
        background: Stack(fit: StackFit.expand, children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B2A), Color(0xFF1A3A5C), Color(0xFF2884A0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _StarPatternPainter()),
          ),
          Positioned(
            right: 24, bottom: 48,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.emoji_events_rounded, size: 100, color: _gold),
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

  Widget _buildSearchBar() {
    return Container(
      color: _navy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher un concours…',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7), size: 20),
          suffixIcon: _searchQ.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQ = '');
                    _appliquerFiltre();
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
          _appliquerFiltre();
        },
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _affiches.length,
      itemBuilder: (_, i) {
        final anim = CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(
            (i / _affiches.length).clamp(0.0, 1.0),
            ((i + 1) / _affiches.length).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        );
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim),
            child: _ConcoursCard(
              dept: _affiches[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailConcoursPage(
                    concoursId: _affiches[i].id,
                    deptPrecharge: _affiches[i],
                  ),
                ),
              ).then((_) => _charger()),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CARTE CONCOURS
// ══════════════════════════════════════════════════════════════
class _ConcoursCard extends StatelessWidget {
  final DepartementItem dept;
  final VoidCallback onTap;

  const _ConcoursCard({required this.dept, required this.onTap});

  Color _parseColor() {
    try {
      final hex = dept.couleur.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: dept.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(dept.imageUrl!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(color.withOpacity(0.4), BlendMode.darken),
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (dept.imageUrl == null)
                    Center(
                      child: Icon(Icons.emoji_events_rounded, size: 52, color: Colors.white.withOpacity(0.3)),
                    ),
                  Positioned(
                    top: 12, right: 12,
                    child: _StatusBadge(statut: dept.statut),
                  ),
                  Positioned(
                    top: 12, left: 12,
                    child: _PrixBadge(prix: dept.prix),
                  ),
                  Positioned(
                    bottom: 12, left: 14, right: 60,
                    child: Text(
                      dept.nomConcours.isNotEmpty ? dept.nomConcours : dept.nom,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w800, shadows: [
                        Shadow(blurRadius: 4, color: Colors.black54),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  if (dept.nom != dept.nomConcours && dept.nom.isNotEmpty)
                    Text(dept.nom,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                  if (dept.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(dept.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  _InfoGrid(dept: dept, accentColor: color),
                  const SizedBox(height: 12),
                  if (dept.nbCours > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${dept.nbCours} cours',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        Text('${dept.progressionMoyenne.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: dept.progressionMoyenne / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            dept.progression > 0 ? 'Continuer la préparation' : 'Commencer la préparation',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
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

// ══════════════════════════════════════════════════════════════
// GRILLE D'INFOS
// ══════════════════════════════════════════════════════════════
class _InfoGrid extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;

  const _InfoGrid({required this.dept, required this.accentColor});

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (dept.dateExamen != null) {
      items.add(_InfoChip(
        icon: Icons.event_rounded,
        label: 'Examen: ${_formatDate(dept.dateExamen)}',
        color: _red,
      ));
    }
    if (dept.dateLimiteInscription != null) {
      items.add(_InfoChip(
        icon: Icons.timer_rounded,
        label: 'Clôture: ${_formatDate(dept.dateLimiteInscription)}',
        color: _gold,
      ));
    }
    if (dept.niveauxCibles.isNotEmpty) {
      items.add(_InfoChip(
        icon: Icons.school_rounded,
        label: 'Niveaux: ${dept.niveauxCibles}',
        color: accentColor,
      ));
    }
    if (dept.placesDisponibles != null) {
      items.add(_InfoChip(
        icon: Icons.people_rounded,
        label: 'Places: ${dept.placesDisponibles}',
        color: _purple,
      ));
    }
    if (dept.fraisDossier > 0) {
      items.add(_InfoChip(
        icon: Icons.receipt_long_rounded,
        label: 'Frais: ${dept.fraisDossier} FCFA',
        color: _green,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
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
      'EN COURS' => (_blue, 'En cours'),
      _ => (Colors.grey.shade600, 'Nouveau'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _PrixBadge extends StatelessWidget {
  final int prix;
  const _PrixBadge({required this.prix});

  @override
  Widget build(BuildContext context) {
    if (prix == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(20)),
        child: const Text('GRATUIT',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(20)),
      child: Text('$prix FCFA',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _FilterDelegate extends SliverPersistentHeaderDelegate {
  final List<String> filtres;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterDelegate({
    required this.filtres,
    required this.selected,
    required this.onSelect,
  });

  @override double get minExtent => 52;
  @override double get maxExtent => 52;
  @override bool shouldRebuild(_FilterDelegate o) => o.selected != selected;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filtres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filtres[i];
          final sel = f == selected;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _navy : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(f,
                  style: TextStyle(
                      fontSize: 13,
                      color: sel ? Colors.white : Colors.grey.shade600,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 280,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
          const SizedBox(height: 16),
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
          Icon(Icons.emoji_events_outlined, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Aucun concours disponible pour votre niveau',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          const SizedBox(height: 8),
          Text('Des concours seront disponibles quand vous aurez le niveau requis',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StarPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    const positions = [
      Offset(0.1, 0.2), Offset(0.3, 0.7), Offset(0.5, 0.3),
      Offset(0.7, 0.8), Offset(0.85, 0.15),
    ];
    for (final p in positions) {
      canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), 3, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}