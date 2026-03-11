import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/cours_detail_page.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';


class FormationMetierDetailPage extends StatefulWidget {
  final FormationMetier formation;
  const FormationMetierDetailPage({super.key, required this.formation});

  @override
  State<FormationMetierDetailPage> createState() =>
      _FormationMetierDetailPageState();
}

class _FormationMetierDetailPageState extends State<FormationMetierDetailPage>
    with SingleTickerProviderStateMixin {
  static const Color _gold = Color(0xFFE2A84B);
  static const Color _dark = Color(0xFF0D1B2A);
  static const Color _teal = Color(0xFF008088);

  late TabController _tabCtrl;
  bool _isInscrit = false;

  final List<Map<String, dynamic>> _classement = [
    {'rang': 1, 'nom': 'Alicia Fouda', 'score': 98},
    {'rang': 2, 'nom': 'Boris Kamga',  'score': 94},
    {'rang': 3, 'nom': 'Chantal Ngo',  'score': 91},
    {'rang': 4, 'nom': 'David Mbarga', 'score': 87},
    {'rang': 5, 'nom': 'Emma Talla',   'score': 85},
    {'rang': 12, 'nom': 'Vous', 'score': 72, 'isMe': true},
  ];

  final List<Map<String, dynamic>> _cours = [
    {'id': '1','titre': 'Introduction & Setup',   'duree': '1h30', 'statut': 'fait',          'locked': false},
    {'id': '2','titre': 'Fondamentaux Avancés',   'duree': '2h15', 'statut': 'en_cours',      'locked': false},
    {'id': '3','titre': 'Projet Pratique #1',     'duree': '3h',   'statut': 'non_commence',  'locked': false},
    {'id': '4','titre': 'Module Expert',          'duree': '2h45', 'statut': 'non_commence',  'locked': true},
    {'id': '5','titre': 'Certification Finale',   'duree': '1h',   'statut': 'non_commence',  'locked': true},
  ];

  int    get _coursTermines => _cours.where((c) => c['statut'] == 'fait').length;
  double get _progression   => _cours.isEmpty ? 0 : _coursTermines / _cours.length;
  int    get _monRang       => 12;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String _formatPrix(double prix) {
    if (prix >= 1000) return '${(prix / 1000).toStringAsFixed(0)} 000';
    return prix.toStringAsFixed(0);
  }

  Color _domaineColor(String d) {
    switch (d) {
      case 'Tech':     return const Color(0xFF008088);
      case 'Business': return const Color(0xFF5B4FCF);
      case 'Design':   return const Color(0xFFE2455A);
      default:         return const Color(0xFF008088);
    }
  }

  String _niveauLabel(String n) {
    switch (n) {
      case 'debutant':      return 'Débutant';
      case 'intermediaire': return 'Intermédiaire';
      case 'avance':        return 'Avancé';
      default:              return n;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final f = widget.formation;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(f),
          if (_isInscrit)
            SliverToBoxAdapter(child: _buildProgressBar()),
          SliverToBoxAdapter(child: _buildMyRangBar()),
          // FIX: ColoredBox au lieu de Container(color:...)
          SliverToBoxAdapter(
            child: ColoredBox(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: _gold,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: _gold,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Programme'),
                  Tab(text: 'Classement'),
                  Tab(text: 'A propos'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildProgrammeTab(),
            _buildClassementTab(),
            _buildAProposTab(f),
          ],
        ),
      ),
      bottomNavigationBar: _isInscrit ? null : _buildBottomCTA(f),
    );
  }

  // ── SliverAppBar ─────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(FormationMetier f) {
    final domColor = _domaineColor(f.domaine);
    return SliverAppBar(
      expandedHeight: 230,
      pinned: true,
      backgroundColor: domColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.share_outlined,         color: Colors.white), onPressed: () {}),
        IconButton(icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white), onPressed: () {}),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [domColor, domColor.withOpacity(0.5), _dark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // FIX: badge avec couleur opaque (pas withOpacity sur color de BoxDecoration)
                  Wrap(spacing: 6, children: [
                    _heroBadge(f.domaine, Colors.black38),
                    if (f.incubateur)
                      _heroBadge('Incubateur', _gold),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    f.nom,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w900, height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    SizedBox(
                      width: 26.0 + (f.fondateurs.take(2).length - 1) * 18.0,
                      height: 26,
                      child: Stack(
                        children: [
                          ...f.fondateurs.take(2).toList().asMap().entries.map((entry) {
                            final idx = entry.key;
                            final fond = entry.value;
                            return Positioned(
                              left: idx * 18.0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  color: domColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    fond['nom']!.substring(0, 1),
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Par ${f.fondateurs.map((e) => e['nom']!.split(' ').last).join(' & ')}',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded, color: _gold, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      f.noteMoyenne.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // FIX: couleur opaque uniquement dans _heroBadge
  Widget _heroBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── Barre de progression ─────────────────────────────────────────────────────
  // FIX: decoration: BoxDecoration(color:) au lieu de color: direct
  Widget _buildProgressBar() {
    final pct = (_progression * 100).toInt();
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Ma progression',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$_coursTermines / ${_cours.length} cours',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(width: 6),
            Text('$pct%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _teal)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progression,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(_teal),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de rang ────────────────────────────────────────────────────────────
  Widget _buildMyRangBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1A3A4A)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.leaderboard_rounded, color: _gold, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Votre rang actuel',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          Text(
            _isInscrit
                ? '#$_monRang sur ${widget.formation.nbInscrits}'
                : 'Inscrivez-vous pour participer',
            style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
            ),
          ),
        ]),
        const Spacer(),
        if (_isInscrit)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Top 10%',
                style: TextStyle(color: _gold, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  // ── Onglet Programme ─────────────────────────────────────────────────────────
  Widget _buildProgrammeTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _cours.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildCoursTile(_cours[i], i + 1),
    );
  }

  Widget _buildCoursTile(Map<String, dynamic> cours, int num) {
  final bool locked = cours['locked'] == true && !_isInscrit;

  final Color statusColor = cours['statut'] == 'fait'
      ? Colors.green
      : cours['statut'] == 'en_cours'
          ? _gold
          : Colors.grey.shade300;

  return GestureDetector(
    onTap: locked
        ? null
        : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CoursDetailTabs(
                  coursId: cours['id'],
                  titre: cours['titre'],
                ),
              ),
            );
          },

    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: cours['statut'] == 'en_cours'
            ? Border.all(color: _gold.withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          )
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: cours['statut'] == 'fait'
                  ? const Icon(Icons.check_rounded,
                      color: Colors.green, size: 18)
                  : locked
                      ? Icon(Icons.lock_outline_rounded,
                          color: Colors.grey.shade400, size: 18)
                      : Text(
                          '$num',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cours['titre'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: locked ? Colors.grey.shade400 : _dark,
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),

                    Text(
                      cours['duree'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),

                    if (cours['statut'] == 'en_cours') ...[
                      const SizedBox(width: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'En cours',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: _gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (!locked)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.grey.shade300,
            ),
        ],
      ),
    ),
  );
}

  // ── Onglet Classement ────────────────────────────────────────────────────────
  Widget _buildClassementTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildPodium(),
        const SizedBox(height: 16),
        ..._classement.skip(3).map((entry) => _buildRangTile(entry)),
      ],
    );
  }

  Widget _buildPodium() {
    final top3 = _classement.take(3).toList();
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
      child: Column(
        children: [
          const Text(
            'Classement des Meilleurs',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
          ),
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
        ],
      ),
    );
  }

  Widget _podiumItem(Map<String, dynamic> entry, double height, Color color) {
    final rang = entry['rang'] as int;
    final medal = rang == 1 ? '1er' : rang == 2 ? '2e' : '3e';

    return Column(children: [
      Text(medal, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      CircleAvatar(
        radius: 20,
        backgroundColor: color.withOpacity(0.3),
        child: Text(
          (entry['nom'] as String).substring(0, 1),
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        (entry['nom'] as String).split(' ').first,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      Text(
        '${entry['score']}pts',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Container(
        width: 60, height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(
            '#$rang',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ),
    ]);
  }

  Widget _buildRangTile(Map<String, dynamic> entry) {
    final bool isMe = entry['isMe'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? _gold.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isMe ? Border.all(color: _gold.withOpacity(0.4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Text('#${entry['rang']}',
              style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13,
                color: isMe ? _gold : Colors.grey.shade400,
              )),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 16,
          backgroundColor: isMe ? _gold.withOpacity(0.2) : Colors.grey.shade100,
          child: Text(
            (entry['nom'] as String).substring(0, 1),
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800,
              color: isMe ? _gold : Colors.grey.shade500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(entry['nom'],
              style: TextStyle(
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isMe ? _dark : Colors.grey.shade700,
              )),
        ),
        if (isMe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Vous',
                style: TextStyle(fontSize: 10, color: _gold, fontWeight: FontWeight.w800)),
          ),
        const SizedBox(width: 8),
        Text('${entry['score']} pts',
            style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 12,
              color: isMe ? _gold : Colors.grey.shade500,
            )),
      ]),
    );
  }

  // ── Onglet À propos ──────────────────────────────────────────────────────────
  Widget _buildAProposTab(FormationMetier f) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _section('Objectif', Icons.flag_outlined, [
          Text(f.objectif,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
        ]),
        const SizedBox(height: 12),
        _section('Description', Icons.info_outline_rounded, [
          Text(f.description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
        ]),
        const SizedBox(height: 12),
        _section('Competences acquises', Icons.psychology_outlined, [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: f.competences.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withOpacity(0.25)),
                  ),
                  child: Text(c,
                      style: const TextStyle(
                        fontSize: 12, color: Color(0xFFB8860B), fontWeight: FontWeight.w600,
                      )),
                )).toList(),
          ),
        ]),
        const SizedBox(height: 12),
        _section('Vos formateurs', Icons.people_outline_rounded, [
          ...f.fondateurs.map((fond) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _domaineColor(f.domaine).withOpacity(0.15),
                    child: Text(
                      fond['nom']!.substring(0, 1),
                      style: TextStyle(
                        color: _domaineColor(f.domaine),
                        fontWeight: FontWeight.w800, fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(fond['nom']!,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(fond['profession']!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                ]),
              )),
        ]),
        const SizedBox(height: 12),
        _section('Infos pratiques', Icons.tune_rounded, [
          _infoRow(Icons.schedule_outlined,        'Duree',    '${f.dureeJours} jours'),
          _infoRow(Icons.people_outline,            'Inscrits', '${f.nbInscrits} apprenants'),
          _infoRow(Icons.book_outlined,             'Cours',    '${f.nbCours} modules'),
          _infoRow(Icons.signal_cellular_alt_rounded,'Niveau',  _niveauLabel(f.niveau)),
          if (f.incubateur)
            _infoRow(Icons.rocket_launch_rounded, 'Debouches',
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: _gold),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _dark)),
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
        Text('$label : ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        Flexible(
          child: Text(value,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color ?? _dark,
              )),
        ),
      ]),
    );
  }

  // ── CTA Inscription ──────────────────────────────────────────────────────────
  Widget _buildBottomCTA(FormationMetier f) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Prix de la formation',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            f.prix == 0 ? 'Gratuit' : '${_formatPrix(f.prix)} FCFA',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _dark),
          ),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: () {
            setState(() => _isInscrit = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Inscription reussie ! Bonne formation.'),
                backgroundColor: _gold,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE2A84B), Color(0xFFC8871A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _gold.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              "S'inscrire maintenant",
              style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
