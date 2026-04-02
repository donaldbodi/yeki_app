// lib/views/pages/apprenants/olympiades_page.dart
// ════════════════════════════════════════════════════════════════
// PAGE OLYMPIADES — Corrigée et fonctionnelle
// Charge /api/olympiades/pour-moi/ avec filtres phase
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/classement_olympiade.dart';
import 'package:yeki/views/pages/apprenants/composer_devoir_page.dart';
import 'package:yeki/views/pages/apprenants/sheet_inscription.dart';

const String _baseO  = 'https://yeki.pythonanywhere.com/api';
const Color _oPrimary = Color(0xFF2884A0);
const Color _oGold    = Color(0xFFE2A84B);
const Color _oDark    = Color(0xFF0D1B2A);
const Color _oBg      = Color(0xFFF5F7FA);
const Color _oGreen   = Color(0xFF10B981);
const Color _oRed     = Color(0xFFEF4444);
const Color _oPurple  = Color(0xFF8B5CF6);

// ── Modèle ─────────────────────────────────────────────────────
class _OlympiadeItem {
  final int    id, devoirId, dureeMinutes;
  final String titre, matiere, niveau, phase;
  final String reglement, prixDescription, statutApprenant;
  final DateTime datFinInscription, datDebutCompetition, datFinCompetition;
  final bool   estInscrit, afficherClassement;
  final double? note, noteMax;
  final int?   rang;

  const _OlympiadeItem({
    required this.id, required this.devoirId, required this.titre,
    required this.matiere, required this.niveau, required this.phase,
    required this.datFinInscription, required this.datDebutCompetition,
    required this.datFinCompetition, required this.reglement,
    required this.prixDescription, required this.estInscrit,
    required this.statutApprenant, this.note, this.noteMax, this.rang,
    required this.dureeMinutes, required this.afficherClassement,
  });

  factory _OlympiadeItem.fromJson(Map<String, dynamic> j) {
    DateTime _d(String? s) {
      if (s == null || s.isEmpty)
        return DateTime.now().add(const Duration(days: 30));
      try { return DateTime.parse(s).toLocal(); } catch (_) { return DateTime.now(); }
    }
    final statut = j['statut'] as String? ?? 'inscription';
    final phase  = switch (statut) {
      'inscription' => 'inscription',
      'en_cours'    => 'competition',
      'terminee'    => 'terminee',
      _             => 'attente',
    };
    return _OlympiadeItem(
      id:                  j['id'] ?? 0,
      devoirId:            j['devoir_id'] ?? 0,
      titre:               j['titre'] ?? '',
      matiere:             j['matiere'] ?? '',
      niveau:              j['niveau'] ?? '',
      phase:               phase,
      datFinInscription:   _d(j['date_cloture_inscription']),
      datDebutCompetition: _d(j['date_debut_olympiade']),
      datFinCompetition:   _d(j['date_fin_olympiade']),
      reglement:           j['description'] ?? '',
      prixDescription:
          '${j['prix_1er'] ?? ''} / ${j['prix_2eme'] ?? ''} / ${j['prix_3eme'] ?? ''}',
      estInscrit:          j['est_inscrit'] ?? false,
      statutApprenant:
          (j['inscription']?['statut'] as String?) ?? 'non_commence',
      note:                j['inscription']?['note'] != null
          ? (j['inscription']['note'] as num).toDouble() : null,
      noteMax:             (j['note_sur'] as num? ?? 20).toDouble(),
      rang:                j['inscription']?['classement'] as int?,
      dureeMinutes:        j['duree_minutes'] ?? 120,
      afficherClassement:  j['statut'] == 'terminee',
    );
  }
}

// ════════════════════════════════════════════════════════════════
class OlympiadesPage extends StatefulWidget {
  const OlympiadesPage({super.key});
  @override
  State<OlympiadesPage> createState() => _OlympiadesPageState();
}

class _OlympiadesPageState extends State<OlympiadesPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  List<_OlympiadeItem> _tous   = [];
  List<_OlympiadeItem> _affich = [];
  String _niveau      = '';
  String _phaseFiltre = 'tous';
  late AnimationController _animCtrl;

  final List<(String, String, Color)> _phases = [
    ('tous',        'Toutes',       _oPrimary),
    ('inscription', 'Inscriptions', _oGreen),
    ('competition', 'En cours',     _oPurple),
    ('terminee',    'Terminées',    _oGold),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _charger();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = ''; });
    final prefs = await SharedPreferences.getInstance();
    final tok   = prefs.getString('token');
    final headers = {
      'Content-Type': 'application/json',
      if (tok != null) 'Authorization': 'Token $tok',
    };

    // Profil pour niveau
    try {
      final rP = await http.get(
          Uri.parse('$_baseO/profil/me/'), headers: headers);
      if (rP.statusCode == 200) {
        _niveau =
            (jsonDecode(rP.body) as Map)['niveau']?.toString() ?? '';
      }
    } catch (_) {}

    // Olympiades
    try {
      final params = <String, String>{};
      if (_niveau.isNotEmpty) params['niveau'] = _niveau;

      final res = await http.get(
        Uri.parse('$_baseO/olympiades/pour-moi/')
            .replace(queryParameters: params.isNotEmpty ? params : null),
        headers: headers,
      );

      if (res.statusCode == 200 && mounted) {
        final data = (jsonDecode(res.body) as List)
            .map((j) => _OlympiadeItem.fromJson(j as Map<String, dynamic>))
            .toList();
        setState(() { _tous = data; });
        _appliquerFiltre();
        _animCtrl.forward(from: 0);
      } else if (mounted) {
        setState(() => _error = 'Erreur ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur réseau: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _appliquerFiltre() {
    setState(() {
      _affich = _phaseFiltre == 'tous'
          ? _tous
          : _tous.where((o) => o.phase == _phaseFiltre).toList();
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _oBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyD(child: _buildFilters()),
          ),
        ],
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _oPrimary))
            : _error.isNotEmpty
                ? _buildError()
                : RefreshIndicator(
                    color: _oPrimary,
                    onRefresh: _charger,
                    child: _affich.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            itemCount: _affich.length,
                            itemBuilder: (_, i) => _buildCard(_affich[i], i),
                          ),
                  ),
      ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    expandedHeight: 170,
    pinned: true,
    backgroundColor: _oDark,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1A3A4A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_oGold, Color(0xFFD4912E)]),
                      borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.military_tech_rounded,
                        color: Colors.white, size: 22)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Olympiades',
                        style: TextStyle(color: Colors.white,
                            fontSize: 24, fontWeight: FontWeight.w900)),
                    if (_niveau.isNotEmpty)
                      Text('Niveau : $_niveau',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                  ]),
                ]),
              ],
            ),
          ),
        ),
      ),
      title: const Text('Olympiades',
          style: TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
      collapseMode: CollapseMode.parallax,
    ),
  );

  Widget _buildFilters() => Container(
    color: _oBg,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _phases.map((p) {
              final sel = _phaseFiltre == p.$1;
              return GestureDetector(
                onTap: () {
                  setState(() => _phaseFiltre = p.$1);
                  _appliquerFiltre();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? p.$3 : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: sel ? p.$3 : Colors.grey.shade200),
                    boxShadow: sel
                        ? [BoxShadow(
                            color: p.$3.withOpacity(0.25), blurRadius: 8)]
                        : [],
                  ),
                  child: Text(p.$2,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : _oDark)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      Text('${_affich.length}',
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]),
  );

  Widget _buildCard(_OlympiadeItem o, int index) {
    final (phaseLabel, phaseColor) = _phaseInfo(o.phase);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, child) {
        final delay = (index * 0.06).clamp(0.0, 1.0);
        final anim = CurvedAnimation(
          parent: _animCtrl,
          curve: Interval(delay, 1.0, curve: Curves.easeOutCubic));
        return FadeTransition(opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
            child: child));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: _oPrimary.withOpacity(0.08),
              blurRadius: 16, offset: const Offset(0, 6))]),
        child: Column(children: [
          // ── En-tête ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_oDark, phaseColor.withOpacity(0.8)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.military_tech_rounded,
                    color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.titre, style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(o.matiere, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  if (o.niveau.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(o.niveau, style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                  ],
                ]),
              ])),
              _phaseBadge(phaseLabel, phaseColor),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _dateRow(Icons.how_to_reg_rounded, 'Inscriptions jusqu\'au',
                  dateFmt.format(o.datFinInscription), _oGreen),
              const SizedBox(height: 6),
              _dateRow(Icons.play_circle_rounded, 'Début',
                  dateFmt.format(o.datDebutCompetition), _oPrimary),
              const SizedBox(height: 6),
              _dateRow(Icons.stop_circle_rounded, 'Fin',
                  dateFmt.format(o.datFinCompetition), _oRed),

              // Résultat
              if (o.note != null) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _oGold.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _oGold.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.emoji_events_rounded, color: _oGold, size: 20),
                    const SizedBox(width: 10),
                    Text('Note : ${o.note!.toStringAsFixed(1)}/${o.noteMax?.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: _oDark, fontSize: 15)),
                    if (o.rang != null) ...[
                      const Spacer(),
                      Text('Rang #${o.rang}', style: const TextStyle(
                          fontWeight: FontWeight.w700, color: _oGold)),
                    ],
                  ])),
              ],

              const SizedBox(height: 14),
              _buildActions(o),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildActions(_OlympiadeItem o) {
    if (o.phase == 'terminee' && o.afficherClassement) {
      return SizedBox(width: double.infinity,
        child: _btn('Voir le classement', Icons.leaderboard_rounded, _oGold,
            () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ClassementOlympiadePage(
                    olympiadeId: o.id, titre: o.titre)))));
    }
    if (o.phase == 'competition' && o.estInscrit) {
      return SizedBox(width: double.infinity,
        child: _btn('Commencer la compétition', Icons.play_arrow_rounded, _oPurple,
            () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ComposerDevoirPage(
                    devoirId: o.devoirId, titre: o.titre,
                    dureeMin: o.dureeMinutes,
                    noteSur: (o.noteMax ?? 20).toInt())))));
    }
    if (o.phase == 'inscription' && !o.estInscrit) {
      return SizedBox(width: double.infinity,
        child: _btn("S'inscrire", Icons.how_to_reg_rounded, _oGreen,
            () => showModalBottomSheet(
              context: context, isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => InscriptionSheet(
                  olympiadeId: o.id, titre: o.titre, onSuccess: _charger))));
    }
    if (o.phase == 'inscription' && o.estInscrit) {
      return Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _oGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _oGreen.withOpacity(0.3))),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_rounded, color: _oGreen, size: 16),
          SizedBox(width: 8),
          Text('Inscrit — En attente du début',
              style: TextStyle(color: _oGreen, fontWeight: FontWeight.w700, fontSize: 13)),
        ]));
    }
    return const SizedBox.shrink();
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 8),
            Text(label, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
          ])));

  Widget _dateRow(IconData icon, String label, String value, Color color) =>
      Row(children: [
        Container(padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 12, color: color)),
        const SizedBox(width: 8),
        Text('$label : ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _oDark),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]);

  Widget _phaseBadge(String label, Color color) =>
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white30)),
        child: Text(label, style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)));

  (String, Color) _phaseInfo(String phase) => switch (phase) {
    'inscription' => ('Inscriptions', _oGreen),
    'competition' => ('En cours', _oPurple),
    'terminee'    => ('Terminée', _oGold),
    _             => ('En attente', Colors.grey),
  };

  Widget _buildEmpty() => ListView(children: [
    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
    Center(child: Column(children: [
      Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _oGold.withOpacity(0.08), shape: BoxShape.circle),
        child: const Icon(Icons.military_tech_outlined, size: 48, color: _oGold)),
      const SizedBox(height: 16),
      const Text('Aucune olympiade', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: _oDark)),
      const SizedBox(height: 8),
      Text(_niveau.isNotEmpty ? 'Pas d\'olympiade pour le niveau $_niveau'
          : 'Revenez bientôt !',
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
    ])),
  ]);

  Widget _buildError() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
    const SizedBox(height: 12),
    Text(_error, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
    const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: _charger,
      style: ElevatedButton.styleFrom(backgroundColor: _oPrimary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer')),
  ]));
}

class _StickyD extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickyD({required this.child});
  @override double get minExtent => 56;
  @override double get maxExtent => 56;
  @override Widget build(_, __, ___) => child;
  @override bool shouldRebuild(_) => true;
}
