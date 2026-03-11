import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../widgets/yeki_app_bar.dart';
import 'package:yeki/views/pages/apprenants/notifications_page.dart';

// Vos imports
import 'package:yeki/views/pages/apprenants/classement_olympiade.dart';
import 'package:yeki/views/pages/apprenants/composer_devoir_page.dart';
import 'package:yeki/views/pages/apprenants/sheet_inscription.dart';

const String _baseO = 'https://yekiapp.pythonanywhere.com/api';

// ─── Palette de Couleurs Harmonisée ─────────────────────────────
const Color _primary = Color(0xFF2884A0); 
const Color _gold    = Color(0xFFE2A84B);
const Color _dark    = Color(0xFF1A1C1E);
const Color _bg      = Color(0xFFF5F7FA);

// ─── Délégué pour le filtre collant (Sticky) ───────────────────
class _StickyFiltersDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyFiltersDelegate({required this.child});

  @override
  double get minExtent => 70.0;
  @override
  double get maxExtent => 70.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _bg,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyFiltersDelegate oldDelegate) => false;
}

// ─── Modèle ─────────────────────────────────────────────────────
class _OlympiadeItem {
  final int      id; 
  final int      devoirId;
  final String   titre;
  final String   matiere;
  final String   niveau;
  final String   phase;        // inscription|attente|competition|terminee
  final DateTime datFinInscription;
  final DateTime datDebutCompetition;
  final DateTime datFinCompetition;
  final String   reglement;
  final String   prixDescription;
  final bool     estInscrit;
  final String   statutApprenant; // non_commence|en_cours|soumis|corrige
  final double?  note;
  final double?  noteMax;
  final int?     rang;
  final int      dureeMinutes;
  final bool     afficherClassement;

  const _OlympiadeItem({
    required this.id,
    required this.devoirId,
    required this.titre,
    required this.matiere,
    required this.niveau,
    required this.phase,
    required this.datFinInscription,
    required this.datDebutCompetition,
    required this.datFinCompetition,
    required this.reglement,
    required this.prixDescription,
    required this.estInscrit,
    required this.statutApprenant,
    this.note,
    this.noteMax,
    this.rang,
    required this.dureeMinutes,
    required this.afficherClassement,
  });

  factory _OlympiadeItem.fromJson(Map<String, dynamic> j) {
    final o = j['olympiade'] as Map<String, dynamic>? ?? {};
    return _OlympiadeItem(
      id:                 o['id'] ?? 0,
      devoirId:           j['id'] ?? 0,
      titre:              j['titre'] ?? '',
      matiere:            j['matiere'] ?? '',
      niveau:             j['niveau'] ?? '',
      phase:              o['phase_actuelle'] ?? 'inscription',
      datFinInscription:  DateTime.parse(
          o['date_fin_inscription'] ?? DateTime.now().toIso8601String()),
      datDebutCompetition: DateTime.parse(
          o['date_debut_competition'] ?? DateTime.now().toIso8601String()),
      datFinCompetition:  DateTime.parse(
          o['date_fin_competition'] ?? DateTime.now().toIso8601String()),
      reglement:          o['reglement'] ?? '',
      prixDescription:    o['prix_description'] ?? '',
      estInscrit:           j['est_inscrit'] == true,
      statutApprenant:      j['statut_apprenant'] ?? 'non_commence',
      note:                 (j['note_apprenant'] as num?)?.toDouble(),
      noteMax:              (j['note_sur'] as num?)?.toDouble(),
      rang:                 j['rang'] as int?,
      dureeMinutes:         j['duree_minutes'] ?? 0,
      afficherClassement:   o['afficher_classement'] == true,
    );
  }
}

class OlympiadesPage extends StatefulWidget {
  const OlympiadesPage({super.key});

  @override
  State<OlympiadesPage> createState() => _OlympiadesPageState();
}

class _OlympiadesPageState extends State<OlympiadesPage>
    with SingleTickerProviderStateMixin {

  bool _loading = true;
  final bool isSubscribed = true;
  List<_OlympiadeItem> _all      = [];
  List<_OlympiadeItem> _affiches = [];
  String _phaseFiltre = 'Toutes';

  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _charger();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _token();
    try {
      final res = await http.get(
        Uri.parse('$_baseO/devoirs/?type=olympiade'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _all = data
            .map((d) => _OlympiadeItem.fromJson(d))
            .toList();
        _filtrer();
        _anim.forward(from: 0);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _filtrer() {
    setState(() {
      _affiches = _phaseFiltre == 'Toutes'
          ? List.from(_all)
          : _all.where((o) => o.phase == _phaseFiltre).toList();
    });
  }

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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _charger,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverHeader(),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyFiltersDelegate(
                      child: _buildFiltrePhases(),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildCompteur()),
                  _affiches.isEmpty
                      ? SliverFillRemaining(child: _buildVide())
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _buildCard(_affiches[i], i),
                              childCount: _affiches.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverHeader() {
    final ouvertes = _all.where((o) => o.phase == 'inscription').length;
    final actives  = _all.where((o) => o.phase == 'competition').length;

    return SliverAppBar(
      expandedHeight: 170,
      pinned: false,
      floating: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: _primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF144555), _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.military_tech_rounded,
                        color: _gold, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Olympiades', style: TextStyle(
                        color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.w900,
                      )),
                      Text('Compétitions académiques',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _statPill('$ouvertes', 'Ouvertes', Colors.greenAccent.shade400),
                  const SizedBox(width: 10),
                  _statPill('$actives', 'En cours', const Color(0xFFFF7F77)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statPill(String val, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(val, style: TextStyle(
            color: color, fontWeight: FontWeight.w900, fontSize: 14)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildFiltrePhases() {
    final phases = [
      ('Toutes', 'Toutes'),
      ('inscription', 'Inscriptions'),
      ('attente', 'En attente'),
      ('competition', 'Compétition'),
      ('terminee', 'Terminées'),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: phases.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final (val, label) = phases[i];
        final sel = _phaseFiltre == val;
        return GestureDetector(
          onTap: () {
            setState(() => _phaseFiltre = val);
            _filtrer();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: sel 
                ? [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: sel ? Colors.white : Colors.grey.shade600,
                  fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompteur() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Text(
        '${_affiches.length} olympiade${_affiches.length > 1 ? 's' : ''}',
        style: TextStyle(color: Colors.grey.shade400,
            fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCard(_OlympiadeItem o, int idx) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _anim,
        curve: Interval((idx * 0.05).clamp(0.0, 0.5), 1.0, curve: Curves.easeOutCubic),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary.withOpacity(0.1), width: 1),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )],
        ),
        child: Column(children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _phaseBadge(o.phase),
                  const SizedBox(width: 8),
                  if (o.matiere.isNotEmpty)
                    _pill(o.matiere, Colors.grey.shade100, Colors.grey.shade600),
                  const Spacer(),
                  if (o.estInscrit)
                    _pill('Inscrit', const Color(0xFFE8F5E9), Colors.green.shade700),
                ]),
                const SizedBox(height: 12),
                Text(o.titre, style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: _dark,
                )),
                if (o.niveau.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Niveau : ${o.niveau}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
                const SizedBox(height: 14),
                _buildTimeline(o),
                const SizedBox(height: 14),
                if (o.rang != null || o.note != null) _buildScoreRow(o),
                if (o.phase == 'inscription' || o.phase == 'competition')
                  _buildAntiTricheInfo(),
                const SizedBox(height: 14),
                _buildAction(o),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTimeline(_OlympiadeItem o) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        _timelineRow('Inscriptions', o.datFinInscription, now.isBefore(o.datFinInscription), o.phase == 'inscription'),
        _timelineRow('Compétition', o.datDebutCompetition, now.isBefore(o.datDebutCompetition), o.phase == 'competition'),
        _timelineRow('Clôture', o.datFinCompetition, now.isBefore(o.datFinCompetition), o.phase == 'terminee', isLast: true),
      ]),
    );
  }

  Widget _timelineRow(String label, DateTime date, bool futur, bool actif, {bool isLast = false}) {
    final fmt = DateFormat('dd/MM · HH:mm');
    return Row(children: [
      Column(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: actif ? _primary : (futur ? Colors.grey.shade300 : Colors.green.shade400),
            shape: BoxShape.circle,
          ),
        ),
        if (!isLast) Container(width: 1.5, height: 18, color: Colors.grey.shade200),
      ]),
      const SizedBox(width: 10),
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: Row(children: [
            Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: actif ? _primary : Colors.grey.shade600,
            )),
            const Spacer(),
            Text(fmt.format(date), style: TextStyle(
              fontSize: 11, color: actif ? _primary : Colors.grey.shade500,
            )),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildScoreRow(_OlympiadeItem o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: Row(children: [
        if (o.rang != null) ...[
          const Icon(Icons.emoji_events_rounded, color: _gold, size: 20),
          const SizedBox(width: 8),
          Text('Rang #${o.rang}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFC8871A))),
          const SizedBox(width: 16),
        ],
        if (o.note != null && o.noteMax != null) ...[
          const Icon(Icons.star_rounded, color: _gold, size: 18),
          const SizedBox(width: 6),
          Text('${((o.note! / o.noteMax!) * 20).toStringAsFixed(1)}/20',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFC8871A))),
        ],
        const Spacer(),
        if (o.afficherClassement)
          GestureDetector(
            onTap: () => _voirClassement(o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
              child: const Text('Classement', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }

  Widget _buildAntiTricheInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.security_rounded, color: Colors.orange, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Anti-triche actif — minuteur strict, questions mélangées, sorties détectées',
            style: TextStyle(fontSize: 11, color: Colors.orange.shade800, height: 1.4),
          ),
        ),
      ]),
    );
  }

  Widget _buildAction(_OlympiadeItem o) {
    switch (o.phase) {
      case 'inscription':
        if (o.estInscrit) {
          return _btn('Déjà inscrit — le ${DateFormat('dd/MM').format(o.datDebutCompetition)}',
              Colors.grey.shade100, Colors.grey.shade400, null);
        }
        return _btn('S\'inscrire à l\'olympiade', _primary, Colors.white, () => _ouvrirInscription(o));
      case 'competition':
        if (!o.estInscrit) return _btn('Non inscrit', Colors.grey.shade100, Colors.grey.shade400, null);
        if (o.statutApprenant == 'soumis' || o.statutApprenant == 'corrige') {
          return _btn('Devoir soumis', Colors.grey.shade100, Colors.grey.shade400, null);
        }
        return _btn(o.statutApprenant == 'en_cours' ? 'Continuer' : 'Participer', _primary, Colors.white, () => _ouvrirDevoir(o));
      case 'terminee':
        if (o.afficherClassement) return _btn('Voir le classement', _primary, Colors.white, () => _voirClassement(o));
        return _btn('Terminée', Colors.grey.shade100, Colors.grey.shade400, null);
      default:
        return const SizedBox.shrink();
    }
  }

  void _ouvrirInscription(_OlympiadeItem o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InscriptionSheet(
        olympiadeId: o.id,
        titre: o.titre,
        reglement: o.reglement,
        prixDesc: o.prixDescription,
        datDebut: o.datDebutCompetition,
        datFin: o.datFinCompetition,
        onSuccess: _charger,
      ),
    );
  }

  void _ouvrirDevoir(_OlympiadeItem o) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposerDevoirPage(
          devoirId: o.devoirId,
          titre: o.titre,
          dureeMin: o.dureeMinutes,
          noteSur: (o.noteMax ?? 20).toInt(),
        ),
      ),
    ).then((_) => _charger());
  }

  void _voirClassement(_OlympiadeItem o) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClassementPage(olympiadeId: o.id, titre: o.titre)),
    );
  }

  Widget _phaseBadge(String phase) {
    final cfg = <String, (String, Color)>{
      'inscription': ('Inscriptions', Colors.green),
      'attente':     ('En attente',   Colors.orange),
      'competition': ('Compétition',   _primary),
      'terminee':    ('Terminée',     Colors.grey),
    };
    final (label, color) = cfg[phase] ?? ('?', Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _pill(String t, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(t, style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _btn(String label, Color bg, Color fg, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? bg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap != null ? [BoxShadow(color: bg.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: onTap != null ? fg : Colors.grey.shade400, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }

  Widget _buildVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.military_tech_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text('Aucune olympiade disponible',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}