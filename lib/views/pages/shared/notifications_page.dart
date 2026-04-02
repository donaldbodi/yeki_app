// lib/views/pages/shared/notifications_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _baseN = 'https://yeki.pythonanywhere.com/api';

const Color _nBlue   = Color(0xFF2884A0);
const Color _nDark   = Color(0xFF0D1B2A);
const Color _nBg     = Color(0xFFF8FAFC);
const Color _nGold   = Color(0xFFE2A84B);
const Color _nGreen  = Color(0xFF10B981);
const Color _nPurple = Color(0xFF8B5CF6);
const Color _nRed    = Color(0xFFEF4444);
const Color _nOrange = Color(0xFFF97316);

// Mapping type → couleur + icône
const Map<String, Color> _typeColor = {
  'devoir':      _nOrange,
  'correction':  _nGreen,
  'forum':       _nBlue,
  'cours':       _nPurple,
  'olympiade':   _nGold,
  'note':        _nGreen,
  'systeme':     _nBlue,
};
const Map<String, IconData> _typeIcon = {
  'devoir':      Icons.assignment_rounded,
  'correction':  Icons.fact_check_rounded,
  'forum':       Icons.forum_rounded,
  'cours':       Icons.auto_stories_rounded,
  'olympiade':   Icons.military_tech_rounded,
  'note':        Icons.grade_rounded,
  'systeme':     Icons.notifications_rounded,
};

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  bool _loading  = true;
  List<Map<String, dynamic>> _notifs  = [];
  List<Map<String, dynamic>> _filtres = [];
  String _filtre = 'tous';

  late AnimationController _animCtrl;

  final List<_FiltrTab> _filtres_ = [
    _FiltrTab('tous',      'Toutes',     null),
    _FiltrTab('devoir',    'Devoirs',    _nOrange),
    _FiltrTab('correction','Corrections', _nGreen),
    _FiltrTab('forum',     'Forum',      _nBlue),
    _FiltrTab('cours',     'Cours',      _nPurple),
    _FiltrTab('olympiade', 'Olympiades', _nGold),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _charger();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<Map<String, String>> _headers() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('token');
    return {'Content-Type': 'application/json', if (t != null) 'Authorization': 'Token $t'};
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final h = await _headers();
      final res = await http.get(
        Uri.parse('$_baseN/notifications/'),
        headers: h,
      );
      if (res.statusCode == 200 && mounted) {
        final data = (jsonDecode(res.body) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() { _notifs = data; });
        _appliquerFiltre();
        _animCtrl.forward(from: 0);
      }
    } catch (_) {
      // Données de démo si API indisponible
      _chargerDemo();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _chargerDemo() {
    _notifs = [
      {
        'id': 1, 'type': 'devoir', 'titre': 'Nouveau devoir disponible',
        'contenu': 'Un devoir de Mathématiques a été publié.',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
        'lu': false,
      },
      {
        'id': 2, 'type': 'correction', 'titre': 'Devoir corrigé',
        'contenu': 'Votre devoir de Physique a été noté : 16/20.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'lu': false,
      },
      {
        'id': 3, 'type': 'forum', 'titre': 'Réponse à votre question',
        'contenu': 'Un enseignant a répondu à votre préoccupation.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'lu': true,
      },
      {
        'id': 4, 'type': 'cours', 'titre': 'Nouveau module disponible',
        'contenu': 'Le module 3 d\'Algorithmique est maintenant accessible.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'lu': true,
      },
      {
        'id': 5, 'type': 'olympiade', 'titre': 'Olympiade de Mathématiques',
        'contenu': 'Les inscriptions sont ouvertes jusqu\'au 30 janvier.',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'lu': true,
      },
    ];
    _appliquerFiltre();
  }

  void _appliquerFiltre() {
    setState(() {
      if (_filtre == 'tous') {
        _filtres = _notifs;
      } else {
        _filtres = _notifs.where((n) => n['type'] == _filtre).toList();
      }
    });
  }

  Future<void> _marquerLu(int id) async {
    try {
      final h = await _headers();
      await http.patch(
        Uri.parse('$_baseN/notifications/$id/lire/'),
        headers: h,
      );
    } catch (_) {}
    setState(() {
      final idx = _notifs.indexWhere((n) => n['id'] == id);
      if (idx >= 0) _notifs[idx]['lu'] = true;
      _appliquerFiltre();
    });
  }

  Future<void> _marquerTousLus() async {
    try {
      final h = await _headers();
      await http.post(Uri.parse('$_baseN/notifications/lire-tout/'), headers: h);
    } catch (_) {}
    setState(() {
      for (final n in _notifs) n['lu'] = true;
      _appliquerFiltre();
    });
  }

  int get _nbNonLus => _notifs.where((n) => n['lu'] == false).length;

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _nBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _nDark,
            actions: [
              if (_nbNonLus > 0)
                TextButton.icon(
                  onPressed: _marquerTousLus,
                  icon: const Icon(Icons.done_all_rounded, color: Colors.white70, size: 16),
                  label: const Text('Tout lire',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _charger,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D1B2A), Color(0xFF1E3A4A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Notifications', style: TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                          _nbNonLus > 0 ? '$_nbNonLus non lue${_nbNonLus > 1 ? 's' : ''}' : 'Tout est à jour',
                          style: TextStyle(
                            color: _nbNonLus > 0 ? _nOrange : Colors.white54,
                            fontSize: 13, fontWeight: FontWeight.w600,
                          )),
                      ],
                    ),
                  ),
                ),
              ),
              title: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Notifications', style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                if (_nbNonLus > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _nOrange, borderRadius: BorderRadius.circular(100)),
                    child: Text('$_nbNonLus', style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
            ),
          ),

          // ── Filtres ─────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FiltreDelegate(
              child: Container(
                color: _nBg,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _filtres_.map((f) {
                      final sel = _filtre == f.key;
                      final col = f.color ?? _nBlue;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _filtre = f.key);
                          _appliquerFiltre();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? col : Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: sel ? col : Colors.grey.shade200),
                            boxShadow: sel ? [BoxShadow(color: col.withOpacity(0.25), blurRadius: 8)] : [],
                          ),
                          child: Text(f.label, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : _nDark,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // ── Liste ──────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _nBlue)))
          else if (_filtres.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildCard(_filtres[i], i),
                  childCount: _filtres.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> n, int index) {
    final type   = n['type']?.toString() ?? 'systeme';
    final color  = _typeColor[type] ?? _nBlue;
    final icon   = _typeIcon[type] ?? Icons.notifications_rounded;
    final lu     = n['lu'] == true;
    final id     = n['id'] as int? ?? 0;

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, child) {
        final delay = index * 0.05;
        final anim = CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(delay.clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _marquerLu(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: lu ? Colors.white : color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: lu ? Colors.grey.shade100 : color.withOpacity(0.25),
              width: lu ? 1 : 1.5,
            ),
            boxShadow: lu
                ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]
                : [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                // Contenu
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(n['titre']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 14, fontWeight: lu ? FontWeight.w600 : FontWeight.w800,
                          color: lu ? _nDark : _nDark,
                        ))),
                      if (!lu)
                        Container(width: 8, height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ]),
                    const SizedBox(height: 4),
                    Text(n['contenu']?.toString() ?? '',
                      style: TextStyle(fontSize: 12, color: lu ? Colors.grey.shade500 : _nDark.withOpacity(0.7), height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(_capitalise(type), style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ),
                      const Spacer(),
                      Text(_formatTime(n['timestamp']?.toString()),
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ]),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalise(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _nBlue.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.notifications_off_outlined, size: 48, color: _nBlue),
      ),
      const SizedBox(height: 16),
      const Text('Aucune notification', style: TextStyle(
        color: _nDark, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      const Text('Vous êtes à jour !', style: TextStyle(color: Colors.grey, fontSize: 13)),
    ]),
  );
}

class _FiltrTab { final String key, label; final Color? color;
  const _FiltrTab(this.key, this.label, this.color); }

class _FiltreDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _FiltreDelegate({required this.child});
  @override double get minExtent => 52;
  @override double get maxExtent => 52;
  @override Widget build(_, __, ___) => child;
  @override bool shouldRebuild(_) => true;
}
