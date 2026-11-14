// lib/views/pages/apprenants/formation_detail_page.dart
//
// Refondu en P11.2 (rituel P5.0, migration mécanique) : bascule vers
// `FormationRepository.detailApprenant()` (endpoint déjà exposé par le
// repository, remplace l'appel `http` brut dupliqué ici) et les tokens/
// composants `Yk*` (plus de `YekiColors`/`YekiButton`/glassmorphism codée
// en dur).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/formation_repository.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';

class FormationDetailPage extends StatefulWidget {
  const FormationDetailPage({super.key, required this.formationId, this.deptPrecharge});

  final int formationId;
  final DepartementItem? deptPrecharge;

  @override
  State<FormationDetailPage> createState() => _FormationDetailPageState();
}

class _FormationDetailPageState extends State<FormationDetailPage> with SingleTickerProviderStateMixin {
  final _repo = FormationRepository();

  bool _loading = true;
  DepartementItem? _dept;
  late final TabController _tabCtrl;

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
    try {
      final dept = await _repo.detailApprenant(widget.formationId);
      if (mounted) setState(() => _dept = dept);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _accentColor(BuildContext context) {
    if (_dept == null) return YkColors.accent(context);
    try {
      return Color(int.parse(_dept!.couleur.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      return _dept!.estFormationMetier ? YkColors.warning : YkColors.accent(context);
    }
  }

  bool get _isMetier => _dept?.estFormationMetier ?? false;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: YkColors.background(context),
        body: Center(child: YkProgress(shape: YkProgressShape.circular)),
      );
    }
    if (_dept == null) {
      return Scaffold(
        backgroundColor: YkColors.background(context),
        body: YkEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Formation introuvable',
          message: "Cette formation n'existe plus ou est temporairement indisponible.",
          actionLabel: 'Retour',
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    final dept = _dept!;
    final accent = _accentColor(context);

    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          _buildSliverAppBar(context, dept, accent),
          SliverToBoxAdapter(child: _buildQuickStats(context, dept, accent)),
          SliverPersistentHeader(
            pinned: true,
            delegate: YkPinnedHeader(
              child: Container(
                color: YkColors.background(context),
                padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.xs),
                child: YkTabs(
                  controller: _tabCtrl,
                  tabs: const [
                    YkTabItem(label: 'À propos'),
                    YkTabItem(label: 'Cours'),
                    YkTabItem(label: 'Programme'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _TabAPropos(dept: dept, accentColor: accent),
            _TabCours(dept: dept, accentColor: accent),
            _TabProgramme(dept: dept, accentColor: accent),
          ],
        ),
      ),
      bottomNavigationBar: dept.nbCours > 0 ? _buildBarreBas(context, dept, accent) : null,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, DepartementItem dept, Color accent) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: accent,
      foregroundColor: YkColors.textOnPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (dept.imageUrl != null)
              Image.network(dept.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fondDegrade(accent))
            else
              _fondDegrade(accent),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  YkBadge(
                    variant: YkBadgeVariant.label,
                    label: _isMetier ? 'Formation métier' : 'Formation classique',
                    color: Colors.white,
                  ),
                  SizedBox(height: YkSpacing.sm),
                  Text(
                    dept.nom,
                    style: YkTypography.h2(context).copyWith(color: Colors.white, height: 1.2),
                    maxLines: 2,
                  ),
                  if (dept.domaine.isNotEmpty)
                    Text(dept.domaine, style: YkTypography.bodySm(context).copyWith(color: Colors.white70)),
                  if (dept.cadre != null)
                    Text(
                      'Cadre : ${dept.cadre!['nom'] ?? ''}',
                      style: YkTypography.caption(context).copyWith(color: Colors.white70),
                    ),
                  if (dept.estCertifiante)
                    Padding(
                      padding: EdgeInsets.only(top: YkSpacing.xs),
                      child: YkBadge(variant: YkBadgeVariant.label, label: 'Formation certifiante', color: Colors.amber),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fondDegrade(Color couleur) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [couleur, couleur.withValues(alpha: 0.7), couleur.withValues(alpha: 0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _isMetier ? Icons.work_outline_rounded : Icons.school_outlined,
          size: 80,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, DepartementItem dept, Color accent) {
    final stats = <(IconData, String, String, Color)>[
      if (dept.dureeFormation.isNotEmpty) (Icons.schedule_rounded, 'Durée', dept.dureeFormation, YkColors.info),
      (Icons.book_rounded, 'Cours', '${dept.nbCours}', accent),
      if (dept.modeFormation.isNotEmpty)
        (Icons.devices_rounded, 'Mode', dept.modeFormationLabel, YkColors.accent(context)),
      (
        Icons.attach_money_rounded,
        'Accès',
        dept.prix == 0 ? 'Gratuit' : '${dept.prix} F',
        dept.prix == 0 ? YkColors.success : YkColors.warning,
      ),
    ];

    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: YkCard(
        variant: YkCardVariant.filled,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final (icon, label, valeur, couleur) in stats)
              Column(
                children: [
                  Icon(icon, color: couleur, size: 22),
                  SizedBox(height: YkSpacing.xxs),
                  Text(
                    valeur,
                    style: YkTypography.label(context).copyWith(color: couleur),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarreBas(BuildContext context, DepartementItem dept, Color accent) {
    return Container(
      padding: EdgeInsets.only(
        left: YkSpacing.md,
        right: YkSpacing.md,
        top: YkSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + YkSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: YkColors.surface(context),
        border: Border(top: BorderSide(color: YkColors.border(context))),
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
                  style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                ),
                SizedBox(height: YkSpacing.xxs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(YkRadius.full),
                  child: LinearProgressIndicator(
                    value: dept.progressionMoyenne / 100,
                    backgroundColor: YkColors.border(context),
                    valueColor: AlwaysStoppedAnimation(accent),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: YkSpacing.md),
          YkButton(
            label: dept.progressionMoyenne > 0 ? 'Continuer' : 'Commencer',
            onPressed: dept.cours.isEmpty
                ? null
                : () => context.pushNamed(
                    AppRoute.coursDetail,
                    pathParameters: {'coursId': dept.cours.first.id.toString()},
                    queryParameters: {
                      'titre': dept.cours.first.title,
                      'coursColor': accent.toARGB32().toString(),
                      'isPremium': dept.estAccessible.toString(),
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


class _TabAPropos extends StatelessWidget {
  const _TabAPropos({required this.dept, required this.accentColor});
  final DepartementItem dept;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dept.description.isNotEmpty) ...[
            _SectionHeader(title: 'À propos de cette formation', icon: Icons.info_outline_rounded, color: accentColor),
            SizedBox(height: YkSpacing.sm),
            YkCard(
              child: Text(
                dept.description,
                style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context), height: 1.6),
              ),
            ),
            SizedBox(height: YkSpacing.lg),
          ],
          if (dept.objectifs.isNotEmpty) ...[
            _SectionHeader(title: 'Objectifs pédagogiques', icon: Icons.flag_rounded, color: accentColor),
            SizedBox(height: YkSpacing.sm),
            _BulletList(text: dept.objectifs, color: accentColor),
            SizedBox(height: YkSpacing.lg),
          ],
          if (dept.prerequis.isNotEmpty) ...[
            _SectionHeader(title: 'Prérequis', icon: Icons.checklist_rounded, color: YkColors.warning),
            SizedBox(height: YkSpacing.sm),
            _BulletList(text: dept.prerequis, color: YkColors.warning),
            SizedBox(height: YkSpacing.lg),
          ],
          _SectionHeader(title: 'Infos pratiques', icon: Icons.info_rounded, color: accentColor),
          SizedBox(height: YkSpacing.sm),
          _PratiqueCard(dept: dept, accentColor: accentColor),
          if (dept.certificatDelivre.isNotEmpty) ...[
            SizedBox(height: YkSpacing.lg),
            _SectionHeader(title: 'Certification', icon: Icons.card_membership_rounded, color: Colors.amber),
            SizedBox(height: YkSpacing.sm),
            YkCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.amber.withValues(alpha: 0.12),
                    child: const Icon(Icons.card_membership_rounded, color: Colors.amber),
                  ),
                  SizedBox(width: YkSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Certificat délivré',
                          style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                        Text(
                          dept.certificatDelivre,
                          style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabCours extends StatelessWidget {
  const _TabCours({required this.dept, required this.accentColor});
  final DepartementItem dept;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (dept.cours.isEmpty) {
      return YkEmptyState(
        icon: Icons.book_outlined,
        title: 'Aucun cours disponible',
        message: 'Les cours de cette formation seront ajoutés prochainement.',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(YkSpacing.md),
      itemCount: dept.cours.length,
      separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
      itemBuilder: (context, i) {
        final c = dept.cours[i];
        Color couleur;
        try {
          couleur = Color(int.parse(c.color.replaceAll('#', 'FF'), radix: 16));
        } catch (_) {
          couleur = accentColor;
        }
        return YkCard(
          accentColor: couleur,
          onTap: () => context.pushNamed(
            AppRoute.coursDetail,
            pathParameters: {'coursId': c.id.toString()},
            queryParameters: {
              'titre': c.title,
              'coursColor': couleur.toARGB32().toString(),
              'isPremium': dept.estAccessible.toString(),
            },
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: couleur.withValues(alpha: 0.12),
                child: Text('${i + 1}', style: TextStyle(color: couleur, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                    ),
                    if (c.enseignantPrincipal != '---')
                      Text(
                        c.enseignantPrincipal,
                        style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                      ),
                    SizedBox(height: YkSpacing.xxs),
                    Row(
                      children: [
                        Icon(Icons.play_lesson_rounded, size: 11, color: YkColors.textSecondary(context)),
                        SizedBox(width: 3),
                        Text(
                          '${c.lessons} leçons',
                          style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                        SizedBox(width: YkSpacing.xs),
                        Icon(Icons.assignment_rounded, size: 11, color: YkColors.textSecondary(context)),
                        SizedBox(width: 3),
                        Text(
                          '${c.assignments}',
                          style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('${c.progression.toStringAsFixed(0)}%', style: TextStyle(color: couleur, fontWeight: FontWeight.bold)),
                  SizedBox(height: YkSpacing.xxs),
                  SizedBox(
                    width: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(YkRadius.full),
                      child: LinearProgressIndicator(
                        value: c.progression / 100,
                        backgroundColor: YkColors.border(context),
                        valueColor: AlwaysStoppedAnimation(couleur),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabProgramme extends StatelessWidget {
  const _TabProgramme({required this.dept, required this.accentColor});
  final DepartementItem dept;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YkCard(
            child: Row(
              children: [
                Expanded(
                  child: _blocStat(context, '${dept.nbCours}', 'Cours', Icons.book_rounded, accentColor),
                ),
                Container(width: 1, height: 50, color: YkColors.border(context)),
                Expanded(
                  child: _blocStat(
                    context,
                    dept.dureeFormation.isEmpty ? 'Flexible' : dept.dureeFormation,
                    'Durée',
                    Icons.timer_rounded,
                    YkColors.info,
                  ),
                ),
                Container(width: 1, height: 50, color: YkColors.border(context)),
                Expanded(
                  child: _blocStat(
                    context,
                    dept.estCertifiante ? 'Oui' : 'Non',
                    'Certifiante',
                    Icons.verified_rounded,
                    dept.estCertifiante ? Colors.amber : YkColors.textTertiary(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: YkSpacing.lg),
          if (dept.cours.isNotEmpty) ...[
            _SectionHeader(title: 'Modules de formation', icon: Icons.list_alt_rounded, color: accentColor),
            SizedBox(height: YkSpacing.sm),
            for (var i = 0; i < dept.cours.length; i++) ...[
              YkCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: accentColor.withValues(alpha: 0.1),
                      child: Text('${i + 1}', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: YkSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dept.cours[i].title,
                            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
                          ),
                          Text(
                            '${dept.cours[i].lessons} leçons · ${dept.cours[i].assignments} devoirs',
                            style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                    if (dept.cours[i].progression == 100)
                      Icon(Icons.check_circle_rounded, color: YkColors.success)
                    else if (dept.cours[i].progression > 0)
                      Icon(Icons.radio_button_checked_rounded, color: accentColor)
                    else
                      Icon(Icons.radio_button_unchecked_rounded, color: YkColors.textTertiary(context)),
                  ],
                ),
              ),
              SizedBox(height: YkSpacing.xs),
            ],
          ],
          if (dept.prerequis.isNotEmpty) ...[
            SizedBox(height: YkSpacing.sm),
            _SectionHeader(title: 'Prérequis', icon: Icons.checklist_rounded, color: YkColors.warning),
            SizedBox(height: YkSpacing.sm),
            YkCard(
              child: Text(
                dept.prerequis,
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context), height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _blocStat(BuildContext context, String valeur, String label, IconData icon, Color couleur) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: couleur, size: 20),
        SizedBox(height: YkSpacing.xxs),
        Text(
          valeur,
          style: YkTypography.label(context).copyWith(color: couleur),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: YkSpacing.xs),
        Text(title, style: YkTypography.label(context).copyWith(color: color)),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lignes = text.split(RegExp(r'\n|•|·')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return YkCard(
      child: Column(
        children: [
          for (final ligne in lignes)
            Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(top: 6, right: YkSpacing.sm),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      ligne,
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PratiqueCard extends StatelessWidget {
  const _PratiqueCard({required this.dept, required this.accentColor});
  final DepartementItem dept;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Color)>[
      if (dept.dureeFormation.isNotEmpty) (Icons.schedule_rounded, 'Durée', dept.dureeFormation, YkColors.info),
      if (dept.modeFormation.isNotEmpty)
        (Icons.devices_rounded, 'Mode', dept.modeFormationLabel, YkColors.accent(context)),
      if (dept.ville.isNotEmpty) (Icons.location_on_rounded, 'Lieu', dept.ville, accentColor),
      if (dept.domaine.isNotEmpty) (Icons.category_rounded, 'Domaine', dept.domaine, YkColors.warning),
      (
        dept.prix == 0 ? Icons.lock_open_rounded : Icons.lock_rounded,
        'Accès',
        dept.prix == 0 ? 'Gratuit' : '${dept.prix} FCFA',
        dept.prix == 0 ? YkColors.success : YkColors.warning,
      ),
    ];

    return YkCard(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: items[i].$4.withValues(alpha: 0.12),
                  child: Icon(items[i].$1, color: items[i].$4, size: 18),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].$2,
                        style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                      ),
                      Text(
                        items[i].$3,
                        style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i < items.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(vertical: YkSpacing.xs),
                child: Divider(height: 1, color: YkColors.border(context)),
              ),
          ],
        ],
      ),
    );
  }
}
