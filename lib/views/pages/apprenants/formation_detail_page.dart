// lib/views/pages/apprenants/formation_detail_page.dart
// ════════════════════════════════════════════════════════════════
// DÉTAIL FORMATION (Métier + Classique) — Design Light Harmonisé
// Affiche durée, mode, certificat, objectifs, prérequis, cours…
// ════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/cours_detail_page.dart';
import 'formations_models.dart';

// Palette harmonisée
const Color brandBackground = Color(0xFF135F74);
const Color actionOrange = Color(0xFFFF6B00);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _borderLight = Color(0xFFE0E4E8);
const Color _borderMedium = Color(0xFFD0D4D8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _green = Color(0xFF10B981);
const Color _blue = Color(0xFF2884A0);
const Color _purple = Color(0xFF8B5CF6);
const Color _orange = Color(0xFFF97316);
const Color _gold = Color(0xFFE2A84B);

Future<String?> _getToken() async =>
    (await SharedPreferences.getInstance()).getString('token');
Map<String, String> _headers(String? t) => {
  'Content-Type': 'application/json',
  if (t != null) 'Authorization': 'Token $t',
};

// ══════════════════════════════════════════════════════════════
class FormationDetailPage extends StatefulWidget {
  final int              formationId;
  final DepartementItem? deptPrecharge;

  const FormationDetailPage({
    super.key,
    required this.formationId,
    this.deptPrecharge,
  });

  @override
  State<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  DepartementItem? _dept;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    if (widget.deptPrecharge != null) {
      _dept    = widget.deptPrecharge;
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
        Uri.parse('$kBaseUrl/apprenant/departement/${widget.formationId}/'),
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
    if (_dept == null) return brandBackground;
    try {
      final hex = _dept!.couleur.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _dept!.estFormationMetier ? _orange : brandBackground;
    }
  }

  bool get _isMetier => _dept?.estFormationMetier ?? false;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _bgLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_dept == null) {
      return Scaffold(
        backgroundColor: _bgLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: _textLight),
              const SizedBox(height: 16),
              const Text('Formation introuvable', style: TextStyle(color: _textMedium)),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBackground,
                    foregroundColor: _white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Retour')),
            ],
          ),
        ),
      );
    }

    final dept = _dept!;

    return Scaffold(
      backgroundColor: _bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          _buildSliverAppBar(dept),
          SliverToBoxAdapter(child: _buildQuickStats(dept)),
          SliverToBoxAdapter(child: _buildTabs()),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _TabAPropos(dept: dept, accentColor: _accentColor),
            _TabCours(dept: dept, accentColor: _accentColor),
            _TabProgramme(dept: dept, accentColor: _accentColor),
          ],
        ),
      ),
      bottomNavigationBar: dept.nbCours > 0
          ? _buildBottomBar(dept)
          : null,
    );
  }

  Widget _buildSliverAppBar(DepartementItem dept) {
    final c = _accentColor;
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: c,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          if (dept.imageUrl != null)
            Image.network(dept.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _gradientBg(c))
          else
            _gradientBg(c),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.65),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            left: 20, right: 20, bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isMetier ? _orange : brandBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isMetier ? Icons.work_rounded : Icons.account_balance_rounded,
                        size: 11, color: _white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isMetier ? 'Formation Métier' : 'Formation Classique',
                        style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(dept.nom,
                    style: const TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2),
                    maxLines: 2),
                if (dept.domaine.isNotEmpty)
                  Text(dept.domaine,
                      style: TextStyle(color: _white.withOpacity(0.8), fontSize: 13)),
                if (dept.cadre != null)
                  Text('Cadre : ${dept.cadre!['nom'] ?? ''}',
                      style: TextStyle(color: _white.withOpacity(0.7), fontSize: 12)),
                if (dept.estCertifiante)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 11, color: _white),
                          SizedBox(width: 4),
                          Text('Formation Certifiante',
                              style: TextStyle(color: _white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _gradientBg(Color c) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c, c.withOpacity(0.7), c.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _isMetier ? Icons.work_outline_rounded : Icons.school_outlined,
          size: 80, color: _white.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildQuickStats(DepartementItem dept) {
    final c = _accentColor;
    final stats = <_QuickStat>[];

    if (dept.dureeFormation.isNotEmpty)
      stats.add(_QuickStat(
          icon: Icons.schedule_rounded, label: 'Durée',
          value: dept.dureeFormation, color: _blue));
    stats.add(_QuickStat(
        icon: Icons.book_rounded, label: 'Cours',
        value: '${dept.nbCours}', color: c));
    if (dept.modeFormation.isNotEmpty)
      stats.add(_QuickStat(
          icon: Icons.devices_rounded, label: 'Mode',
          value: dept.modeFormationLabel, color: _purple));
    stats.add(_QuickStat(
        icon: Icons.attach_money_rounded, label: 'Accès',
        value: dept.prix == 0 ? 'Gratuit' : '${dept.prix} F',
        color: dept.prix == 0 ? _green : _gold));

    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      color: _white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats.map((s) => _QuickStatWidget(stat: s)).toList(),
      ),
    );
  }

  Widget _buildTabs() {
    final c = _accentColor;
    return Container(
      color: _white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: c,
        unselectedLabelColor: _textLight,
        indicatorColor: c,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'À propos'),
          Tab(icon: Icon(Icons.book_rounded, size: 18), text: 'Cours'),
          Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'Programme'),
        ],
      ),
    );
  }

  Widget _buildBottomBar(DepartementItem dept) {
    final c = _accentColor;
    return Container(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _borderLight, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dept.progressionMoyenne > 0
                      ? '${dept.progressionMoyenne.toStringAsFixed(0)}% complété'
                      : '${dept.nbCours} cours disponibles',
                  style: const TextStyle(fontSize: 12, color: _textLight),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: dept.progressionMoyenne / 100,
                    backgroundColor: _borderLight,
                    valueColor: AlwaysStoppedAnimation(c),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: dept.cours.isNotEmpty
                ? () => Navigator.push(context,
                      MaterialPageRoute(
                        builder: (_) => CoursDetailTabs(
                            coursId: dept.cours.first.id.toString(),
                            titre: dept.cours.first.title,
                            coursColor: c.value,
                        ),
                      ))
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: c,
              foregroundColor: _white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              dept.progressionMoyenne > 0 ? 'Continuer' : 'Commencer',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB À PROPOS
// ══════════════════════════════════════════════════════════════
class _TabAPropos extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;
  const _TabAPropos({required this.dept, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dept.description.isNotEmpty) ...[
            _SectionHeader(
                title: 'À propos de cette formation',
                icon: Icons.info_outline_rounded,
                color: accentColor),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderLight, width: 1),
              ),
              child: Text(dept.description,
                  style: const TextStyle(fontSize: 14, height: 1.7, color: _textMedium)),
            ),
            const SizedBox(height: 24),
          ],

          if (dept.objectifs.isNotEmpty) ...[
            _SectionHeader(
                title: 'Objectifs pédagogiques',
                icon: Icons.flag_rounded,
                color: accentColor),
            const SizedBox(height: 10),
            _BulletList(text: dept.objectifs, color: accentColor),
            const SizedBox(height: 24),
          ],

          if (dept.prerequis.isNotEmpty) ...[
            _SectionHeader(
                title: 'Prérequis',
                icon: Icons.checklist_rounded,
                color: _orange),
            const SizedBox(height: 10),
            _BulletList(text: dept.prerequis, color: _orange),
            const SizedBox(height: 24),
          ],

          _SectionHeader(
              title: 'Infos pratiques',
              icon: Icons.info_rounded,
              color: accentColor),
          const SizedBox(height: 10),
          _PratiqueCard(dept: dept, accentColor: accentColor),

          if (dept.certificatDelivre.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(
                title: 'Certification',
                icon: Icons.card_membership_rounded,
                color: _gold),
            const SizedBox(height: 10),
            _CertifCard(dept: dept),
          ],
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
            Icon(Icons.book_outlined, size: 60, color: _borderMedium),
            const SizedBox(height: 14),
            Text('Aucun cours disponible',
                style: TextStyle(color: _textLight)),
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
          onTap: () => Navigator.push(ctx,
              MaterialPageRoute(
                  builder: (_) => CoursDetailTabs(
                    coursId: c.id.toString(),
                    titre: c.title,
                    coursColor: cardColor.value,
                  ))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderLight, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardColor.withOpacity(0.2), width: 0.8),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: TextStyle(color: cardColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                      if (c.enseignantPrincipal != '—')
                        Text(c.enseignantPrincipal,
                            style: TextStyle(fontSize: 11, color: _textLight)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.play_lesson_rounded, size: 11, color: _textLight),
                          const SizedBox(width: 3),
                          Text('${c.lessons} leçons',
                              style: TextStyle(fontSize: 11, color: _textLight)),
                          const SizedBox(width: 10),
                          Icon(Icons.assignment_rounded, size: 11, color: _textLight),
                          const SizedBox(width: 3),
                          Text('${c.assignments}',
                              style: TextStyle(fontSize: 11, color: _textLight)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Column(
                    children: [
                      Text('${c.progression.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cardColor)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c.progression / 100,
                          backgroundColor: _borderLight,
                          valueColor: AlwaysStoppedAnimation(cardColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: _textLight),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// TAB PROGRAMME
// ══════════════════════════════════════════════════════════════
class _TabProgramme extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;
  const _TabProgramme({required this.dept, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderLight, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ProgramStatBlock(
                      value: '${dept.nbCours}',
                      label: 'Cours',
                      icon: Icons.book_rounded,
                      color: accentColor),
                ),
                Container(width: 1, height: 50, color: _borderLight),
                Expanded(
                  child: _ProgramStatBlock(
                      value: dept.dureeFormation.isEmpty ? 'Flexible' : dept.dureeFormation,
                      label: 'Durée',
                      icon: Icons.timer_rounded,
                      color: _blue),
                ),
                Container(width: 1, height: 50, color: _borderLight),
                Expanded(
                  child: _ProgramStatBlock(
                      value: dept.estCertifiante ? 'Oui' : 'Non',
                      label: 'Certifiante',
                      icon: Icons.verified_rounded,
                      color: dept.estCertifiante ? _gold : _textLight),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (dept.cours.isNotEmpty) ...[
            _SectionHeader(
                title: 'Modules de formation',
                icon: Icons.list_alt_rounded,
                color: accentColor),
            const SizedBox(height: 12),
            ...List.generate(dept.cours.length, (i) {
              final c = dept.cours[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderLight, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                          Text('${c.lessons} leçons · ${c.assignments} devoirs',
                              style: TextStyle(fontSize: 11, color: _textLight)),
                        ],
                      ),
                    ),
                    if (c.progression == 100)
                      Icon(Icons.check_circle_rounded, size: 20, color: _green)
                    else if (c.progression > 0)
                      Icon(Icons.radio_button_checked_rounded, size: 20, color: accentColor)
                    else
                      Icon(Icons.radio_button_unchecked_rounded, size: 20, color: _textLight),
                  ],
                ),
              );
            }),
          ],

          if (dept.prerequis.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(
                title: 'Prérequis',
                icon: Icons.checklist_rounded,
                color: _orange),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderLight, width: 1),
              ),
              child: Text(dept.prerequis,
                  style: const TextStyle(fontSize: 13, height: 1.6, color: _textMedium)),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// COMPOSANTS
// ══════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Color    color;
  const _SectionHeader(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  final String text;
  final Color  color;
  const _BulletList({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final lignes = text
        .split(RegExp(r'\n|•|·'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: Column(
        children: lignes.map((l) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(l,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: _textMedium)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PratiqueCard extends StatelessWidget {
  final DepartementItem dept;
  final Color accentColor;
  const _PratiqueCard({required this.dept, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final items = <_ItemPratique>[];
    if (dept.dureeFormation.isNotEmpty) {
      items.add(_ItemPratique(
          icon: Icons.schedule_rounded, label: 'Durée',
          value: dept.dureeFormation, color: _blue));
    }
    if (dept.modeFormation.isNotEmpty) {
      items.add(_ItemPratique(
          icon: Icons.devices_rounded, label: 'Mode',
          value: dept.modeFormationLabel, color: _purple));
    }
    if (dept.ville.isNotEmpty)
      items.add(_ItemPratique(
          icon: Icons.location_on_rounded, label: 'Lieu',
          value: dept.ville, color: accentColor));
    if (dept.domaine.isNotEmpty)
      items.add(_ItemPratique(
          icon: Icons.category_rounded, label: 'Domaine',
          value: dept.domaine, color: _orange));
    items.add(_ItemPratique(
        icon: dept.prix == 0 ? Icons.lock_open_rounded : Icons.lock_rounded,
        label: 'Accès',
        value: dept.prix == 0 ? 'Gratuit' : '${dept.prix} FCFA',
        color: dept.prix == 0 ? _green : _gold));

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight, width: 1),
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
                    border: Border.all(color: item.color.withOpacity(0.2), width: 0.8),
                  ),
                  child: Icon(item.icon, color: item.color, size: 18),
                ),
                title: Text(item.label,
                    style: TextStyle(fontSize: 11, color: _textLight)),
                subtitle: Text(item.value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                dense: true,
              ),
              if (i < items.length - 1)
                Divider(height: 1, indent: 68, color: _borderLight),
            ],
          );
        }),
      ),
    );
  }
}

class _ItemPratique {
  final IconData icon;
  final String label, value;
  final Color color;
  const _ItemPratique({required this.icon, required this.label,
    required this.value, required this.color});
}

class _CertifCard extends StatelessWidget {
  final DepartementItem dept;
  const _CertifCard({required this.dept});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _gold.withOpacity(0.2), width: 0.8),
            ),
            child: const Icon(Icons.card_membership_rounded, color: _gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Certificat délivré',
                    style: TextStyle(fontSize: 11, color: _textLight, fontWeight: FontWeight.w500)),
                Text(dept.certificatDelivre,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: _gold, size: 24),
        ],
      ),
    );
  }
}

class _QuickStat {
  final IconData icon;
  final String label, value;
  final Color color;
  const _QuickStat({required this.icon, required this.label,
    required this.value, required this.color});
}

class _QuickStatWidget extends StatelessWidget {
  final _QuickStat stat;
  const _QuickStatWidget({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(stat.icon, color: stat.color, size: 22),
        const SizedBox(height: 6),
        Text(stat.value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: stat.color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(stat.label,
            style: TextStyle(fontSize: 10, color: _textLight)),
      ],
    );
  }
}

class _ProgramStatBlock extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _ProgramStatBlock({required this.value, required this.label,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        Text(label,
            style: TextStyle(fontSize: 10, color: _textLight)),
      ],
    );
  }
}