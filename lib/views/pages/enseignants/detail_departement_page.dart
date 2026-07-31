// lib/views/pages/enseignants/detail_departement_page.dart
//
// Refondu en P11.3 (rituel P5.0) : bascule vers `FormationRepository.
// detailEnseignantCadre()` (remplace l'appel `http` brut + token manuel
// lu depuis `SharedPreferences`) et les tokens/composants `Yk*` (plus de
// `YekiColors`/glassmorphism fait main).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/formation_repository.dart';
import 'package:yeki/views/pages/enseignants/departement_models.dart';
import 'package:yeki/widgets/creer_cours_sheet.dart';

class DetailDepartementPage extends StatefulWidget {
  const DetailDepartementPage({
    super.key,
    required this.departementId,
    required this.departementNom,
  });

  final int departementId;
  final String departementNom;

  @override
  State<DetailDepartementPage> createState() => _DetailDepartementPageState();
}

class _DetailDepartementPageState extends State<DetailDepartementPage> with SingleTickerProviderStateMixin {
  final _repo = FormationRepository();
  late final TabController _tabCtrl;

  bool _loading = true;
  DepartementCadreDetail? _dept;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final dept = await _repo.detailEnseignantCadre(widget.departementId);
      if (mounted) setState(() => _dept = dept);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _accentColor {
    try {
      return Color(int.parse((_dept?.colorHex ?? '#135F74').replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      return YkColors.accent(context);
    }
  }

  void _creerCours() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreerCoursSheet(
        departementId: widget.departementId,
        departementNom: widget.departementNom,
        onSuccess: _charger,
      ),
    );
  }

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
          title: 'Département introuvable',
          message: "Ce département n'existe plus ou est temporairement indisponible.",
          actionLabel: 'Retour',
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    final dept = _dept!;
    final accent = _accentColor;

    return Scaffold(
      backgroundColor: YkColors.background(context),
      floatingActionButton: YkFab(icon: Icons.add_rounded, label: 'Créer un cours', onPressed: _creerCours, backgroundColor: accent),
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          _buildSliverAppBar(context, dept, accent),
          SliverToBoxAdapter(child: _buildInfoBar(context, dept, accent)),
          SliverPersistentHeader(
            pinned: true,
            delegate: YkPinnedHeader(
              child: Container(
                color: YkColors.background(context),
                padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.xs),
                child: YkTabs(
                  controller: _tabCtrl,
                  tabs: const [YkTabItem(label: 'Cours'), YkTabItem(label: 'Statistiques')],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [_tabCours(context, dept, accent), _tabStats(context, dept, accent)],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, DepartementCadreDetail dept, Color accent) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _charger)],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  YkBadge(variant: YkBadgeVariant.label, label: _typeLabel(dept.typeDepartement), color: Colors.white),
                  SizedBox(height: YkSpacing.sm),
                  Text(
                    dept.nom.isEmpty ? widget.departementNom : dept.nom,
                    style: YkTypography.h2(context).copyWith(color: Colors.white),
                  ),
                  SizedBox(height: YkSpacing.xs),
                  Row(
                    children: [
                      _statBadge('${dept.cours.length} cours', Icons.book_rounded),
                      SizedBox(width: YkSpacing.sm),
                      _statBadge('${dept.nbApprenants} apprenants', Icons.people_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBadge(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xxs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(YkRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          SizedBox(width: YkSpacing.xxs),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildInfoBar(BuildContext context, DepartementCadreDetail dept, Color accent) {
    return Container(
      color: YkColors.surface(context),
      padding: EdgeInsets.symmetric(vertical: YkSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoBarItem(context, Icons.route_rounded, dept.parcours.isNotEmpty ? dept.parcours : 'Non défini', 'Parcours', accent),
          _infoBarItem(
            context,
            dept.prix == 0 ? Icons.lock_open_rounded : Icons.lock_rounded,
            dept.prix == 0 ? 'Gratuit' : '${dept.prix} FCFA',
            'Accès',
            accent,
          ),
          if (dept.ville.isNotEmpty) _infoBarItem(context, Icons.location_on_rounded, dept.ville, 'Localisation', accent),
        ],
      ),
    );
  }

  Widget _infoBarItem(BuildContext context, IconData icon, String value, String label, Color accent) {
    return Column(
      children: [
        Icon(icon, size: 18, color: accent),
        SizedBox(height: YkSpacing.xxs),
        Text(value, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
        Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
      ],
    );
  }

  Widget _tabCours(BuildContext context, DepartementCadreDetail dept, Color accent) {
    if (dept.cours.isEmpty) {
      return YkEmptyState(
        icon: Icons.book_outlined,
        title: 'Aucun cours',
        message: 'Créez votre premier cours dans ce département.',
        actionLabel: 'Créer un cours',
        onAction: _creerCours,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(YkSpacing.md),
      itemCount: dept.cours.length,
      separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
      itemBuilder: (context, i) => _coursCard(context, dept.cours[i], accent),
    );
  }

  Widget _coursCard(BuildContext context, CoursCadreItem cours, Color accent) {
    Color couleur;
    try {
      couleur = Color(int.parse(cours.colorHex.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      couleur = accent;
    }

    return YkCard(
      accentColor: couleur,
      onTap: () => context.pushNamed(
        AppRoute.coursDetailEnseignant,
        pathParameters: {'coursId': cours.id.toString()},
        queryParameters: {
          'titre': cours.titre,
          'estEnseignantPrincipal': 'true',
          'courseColor': couleur.toARGB32().toString(),
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(YkSpacing.xs),
                decoration: BoxDecoration(color: couleur.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(YkRadius.md)),
                child: Icon(Icons.book_rounded, color: couleur, size: 22),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cours.titre,
                      style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(cours.niveau, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                  ],
                ),
              ),
              if (cours.enseignantPrincipalNom != null)
                YkBadge(variant: YkBadgeVariant.label, label: cours.enseignantPrincipalNom!, color: YkColors.success),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              _miniStat(context, Icons.people_rounded, '${cours.nbApprenants}', 'apprenants'),
              SizedBox(width: YkSpacing.md),
              _miniStat(context, Icons.play_lesson_rounded, '${cours.nbLecons}', 'leçons'),
              SizedBox(width: YkSpacing.md),
              _miniStat(context, Icons.assignment_rounded, '${cours.nbDevoirs}', 'devoirs'),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Expanded(
                child: YkProgress(shape: YkProgressShape.linear, value: cours.tauxCompletion / 100, color: couleur),
              ),
              SizedBox(width: YkSpacing.sm),
              Text(
                '${cours.tauxCompletion.toStringAsFixed(0)}%',
                style: YkTypography.label(context).copyWith(color: couleur),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: YkColors.textSecondary(context)),
        SizedBox(width: YkSpacing.xxs),
        Text(value, style: YkTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: YkColors.textPrimary(context))),
        SizedBox(width: 2),
        Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
      ],
    );
  }

  Widget _tabStats(BuildContext context, DepartementCadreDetail dept, Color accent) {
    var totalLecons = 0;
    var totalDevoirs = 0;
    for (final c in dept.cours) {
      totalLecons += c.nbLecons;
      totalDevoirs += c.nbDevoirs;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        children: [
          YkCard(
            variant: YkCardVariant.filled,
            accentColor: accent,
            child: Column(
              children: [
                Text(
                  'Taux de complétion moyen',
                  style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                ),
                SizedBox(height: YkSpacing.xs),
                Text(
                  '${dept.tauxMoyen.toStringAsFixed(0)}%',
                  style: YkTypography.h1(context).copyWith(color: accent),
                ),
                SizedBox(height: YkSpacing.sm),
                YkProgress(shape: YkProgressShape.linear, value: dept.tauxMoyen / 100, color: accent),
              ],
            ),
          ),
          SizedBox(height: YkSpacing.md),
          Row(
            children: [
              Expanded(child: _statCard(context, 'Cours', '${dept.cours.length}', Icons.book_rounded, accent)),
              SizedBox(width: YkSpacing.sm),
              Expanded(child: _statCard(context, 'Leçons', '$totalLecons', Icons.play_lesson_rounded, accent)),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Expanded(child: _statCard(context, 'Devoirs', '$totalDevoirs', Icons.assignment_rounded, accent)),
              SizedBox(width: YkSpacing.sm),
              Expanded(child: _statCard(context, 'Apprenants', '${dept.nbApprenants}', Icons.people_rounded, accent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color accent) {
    return YkCard(
      child: Column(
        children: [
          Icon(icon, size: 24, color: accent),
          SizedBox(height: YkSpacing.xs),
          Text(value, style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
          Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'prepa_concours':
        return 'Prépa Concours';
      case 'formation_metier':
        return 'Formation Métier';
      case 'formation_classique':
        return 'Formation Classique';
      default:
        return 'Département';
    }
  }
}

