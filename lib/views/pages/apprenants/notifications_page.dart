// lib/views/pages/apprenants/notifications_page.dart
// ═══════════════════════════════════════════════════════════════
//  PAGE NOTIFICATIONS — Dynamique + prête Firebase
// ═══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _baseN = 'https://yeki.pythonanywhere.com/api';

// Palette
const Color _nBlue  = Color(0xFF2884A0);
const Color _nDark  = Color(0xFF0D1B2A);
const Color _nBg    = Color(0xFFF4F8FC);
const Color _nCard  = Colors.white;
const Color _nMuted = Color(0xFF64748B);

// Catégories notification
const Map<String, _NotifMeta> _notifMeta = {
  'devoir':     _NotifMeta(Icons.assignment_rounded,          Color(0xFFF97316), 'Devoir'),
  'correction': _NotifMeta(Icons.fact_check_rounded,          Color(0xFF10B981), 'Correction'),
  'forum':      _NotifMeta(Icons.chat_bubble_rounded,         Color(0xFF2884A0), 'Forum'),
  'cours':      _NotifMeta(Icons.book_rounded,                Color(0xFF6366F1), 'Cours'),
  'olympiade':  _NotifMeta(Icons.emoji_events_rounded,        Color(0xFFE2A84B), 'Olympiade'),
  'system':     _NotifMeta(Icons.notifications_rounded,       Color(0xFF64748B), 'Système'),
  'note':       _NotifMeta(Icons.star_rounded,                Color(0xFFEC4899), 'Note'),
};

class _NotifMeta {
  final IconData icon;
  final Color color;
  final String label;
  const _NotifMeta(this.icon, this.color, this.label);
}

// Modèle
class _Notif {
  final int     id;
  final String  type;
  final String  titre;
  final String  contenu;
  final String  temps;
  bool          isRead;
  final String? actionRoute;

  _Notif({
    required this.id,
    required this.type,
    required this.titre,
    required this.contenu,
    required this.temps,
    this.isRead = false,
    this.actionRoute,
  });

  factory _Notif.fromJson(Map<String, dynamic> j) => _Notif(
    id:          j['id'] ?? 0,
    type:        j['type'] ?? 'system',
    titre:       j['titre'] ?? '',
    contenu:     j['contenu'] ?? '',
    temps:       j['temps'] ?? '',
    isRead:      j['is_read'] ?? false,
    actionRoute: j['action_route'],
  );
}

// ═══════════════════════════════════════════════════════════════
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  bool         _loading = true;
  List<_Notif> _notifs  = [];
  String       _filtre  = 'Tous';

  late AnimationController _animCtrl;

  static const _filtres = ['Tous', 'Non lues', 'Devoirs', 'Forum', 'Cours'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _charger();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<String?> _token() async =>
      (await SharedPreferences.getInstance()).getString('token');

  Future<void> _charger() async {
    setState(() => _loading = true);
    final tok = await _token();
    try {
      final res = await http.get(
        Uri.parse('$_baseN/notifications/'),
        headers: {
          'Content-Type': 'application/json',
          if (tok != null) 'Authorization': 'Token $tok',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        _notifs = data.map((j) => _Notif.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        // Données démo si l'endpoint n'existe pas encore
        _notifs = _demoNotifs();
      }
    } catch (_) {
      _notifs = _demoNotifs();
    }
    if (mounted) {
      setState(() => _loading = false);
      _animCtrl.forward(from: 0);
    }
  }

  List<_Notif> _demoNotifs() => [
    _Notif(id: 1, type: 'devoir', titre: 'Nouveau devoir disponible',
        contenu: 'Mathématiques — Suites Numériques est à rendre avant demain.',
        temps: '12 min', isRead: false),
    _Notif(id: 2, type: 'forum', titre: 'M. Kamga a répondu',
        contenu: 'N\'oubliez pas de réviser la partie 2 du module de Physique.',
        temps: '1h', isRead: false),
    _Notif(id: 3, type: 'correction', titre: 'Correction disponible',
        contenu: 'Votre exercice d\'Anglais a été noté. Score : 16/20.',
        temps: '3h', isRead: true),
    _Notif(id: 4, type: 'cours', titre: 'Module débloqué',
        contenu: 'Félicitations ! Vous avez accès à Introduction à l\'Algorithmique.',
        temps: 'Hier', isRead: true),
    _Notif(id: 5, type: 'olympiade', titre: 'Olympiade de Physique ouverte',
        contenu: 'Les inscriptions pour l\'olympiade annuelle sont ouvertes.',
        temps: '2j', isRead: true),
    _Notif(id: 6, type: 'note', titre: 'Résultat devoir disponible',
        contenu: 'Votre devoir de SVT a été corrigé. Note : 14/20.',
        temps: '3j', isRead: true),
  ];

  List<_Notif> get _filtered {
    if (_filtre == 'Non lues') return _notifs.where((n) => !n.isRead).toList();
    if (_filtre == 'Devoirs')  return _notifs.where((n) => n.type == 'devoir' || n.type == 'correction' || n.type == 'note').toList();
    if (_filtre == 'Forum')    return _notifs.where((n) => n.type == 'forum').toList();
    if (_filtre == 'Cours')    return _notifs.where((n) => n.type == 'cours').toList();
    return _notifs;
  }

  int get _unreadCount => _notifs.where((n) => !n.isRead).length;

  Future<void> _marquerTousLus() async {
    setState(() { for (final n in _notifs) n.isRead = true; });
    // TODO: appel API PATCH /notifications/mark-all-read/
  }

  Future<void> _marquerLu(int id) async {
    setState(() {
      final n = _notifs.firstWhere((n) => n.id == id, orElse: () => _notifs.first);
      n.isRead = true;
    });
    // TODO: appel API PATCH /notifications/$id/read/
  }

  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _nBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverAppBar()],
        body: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _nBlue))
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _charger,
                          color: _nBlue,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final delay = i * 0.05;
                              return AnimatedBuilder(
                                animation: _animCtrl,
                                builder: (_, child) {
                                  final anim = CurvedAnimation(
                                    parent: _animCtrl,
                                    curve: Interval(delay.clamp(0, 1), 1.0, curve: Curves.easeOutCubic),
                                  );
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.2),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildNotifCard(_filtered[i]),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() => SliverAppBar(
        pinned: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('Notifications',
                style: TextStyle(
                    color: _nDark, fontWeight: FontWeight.w900, fontSize: 20)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _marquerTousLus,
              child: const Text('Tout lire',
                  style: TextStyle(color: _nBlue, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _nDark),
            onPressed: _charger,
          ),
        ],
      );

  Widget _buildFilters() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filtres.map((f) {
              final sel = _filtre == f;
              return GestureDetector(
                onTap: () => setState(() => _filtre = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? _nBlue : _nBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? _nBlue : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : _nMuted)),
                ),
              );
            }).toList(),
          ),
        ),
      );

  Widget _buildNotifCard(_Notif n) {
    final meta = _notifMeta[n.type] ?? _notifMeta['system']!;
    return Dismissible(
      key: Key('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.check_rounded, color: Color(0xFF10B981)),
      ),
      onDismissed: (_) => _marquerLu(n.id),
      child: GestureDetector(
        onTap: () => _marquerLu(n.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.isRead ? _nCard : meta.color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: n.isRead
                  ? const Color(0xFFE8EDF2)
                  : meta.color.withOpacity(0.2),
            ),
            boxShadow: n.isRead
                ? []
                : [BoxShadow(color: meta.color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: meta.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(meta.icon, color: meta.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n.titre,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                                  color: _nDark)),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: meta.color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.contenu,
                        style: TextStyle(fontSize: 12, color: _nMuted, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: meta.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(meta.label,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: meta.color,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Text(n.temps,
                            style: TextStyle(fontSize: 11, color: _nMuted.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _nBlue.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_outlined, size: 52, color: _nBlue.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            const Text('Aucune notification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _nDark)),
            const SizedBox(height: 8),
            Text('Vous êtes à jour !',
                style: TextStyle(fontSize: 13, color: _nMuted)),
          ],
        ),
      );
}
