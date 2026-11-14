// lib/views/pages/enseignants/detail_cours_enseignant.dart
//
// Refondu en P11.3 (rituel P5.0) : `YekiColors`/`TextStyle` en dur
// remplacés par les tokens/composants `Yk*`. Séparation stricte déjà en
// place (confirmé par grep exhaustif avant refonte : aucune référence à
// `CoursDetailTabs`/`cours_detail_page.dart`, l'écran apprenant) —
// vérifiée à nouveau après réécriture.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/features/devoirs_cours/presentation/devoirs_cours_page.dart';
import 'package:yeki/features/exercices_cours/presentation/exercices_cours_page.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecons_cours.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

class DetailCoursEnseignantPage extends StatefulWidget {
  final String coursId;
  final String titre;
  final bool estEnseignantPrincipal;
  final RoleEnseignant role;
  final Color courseColor;

  const DetailCoursEnseignantPage({
    super.key,
    required this.coursId,
    required this.titre,
    required this.estEnseignantPrincipal,
    required this.role,
    required this.courseColor,
  });

  @override
  State<DetailCoursEnseignantPage> createState() => _DetailCoursEnseignantPageState();
}

class _DetailCoursEnseignantPageState extends State<DetailCoursEnseignantPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Filtre de l'onglet Exercices, modifiable en place depuis l'onglet
  // Leçons (voir `_naviguerVersExercicesAvecFiltre`, P3.3 §6) — jamais une
  // navigation vers l'écran apprenant `CoursDetailTabs`.
  int? _exercicesModuleIdFiltre;
  int? _exercicesLeconIdFiltre;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _naviguerVersExercicesAvecFiltre({int? moduleId, int? leconId}) {
    setState(() {
      _exercicesModuleIdFiltre = moduleId;
      _exercicesLeconIdFiltre = leconId;
    });
    _tabController.animateTo(1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: widget.courseColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: YkGradientBackground(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.courseColor, widget.courseColor.withValues(alpha: 0.7)],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(YkSpacing.lg, YkSpacing.xl, YkSpacing.lg, YkSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        YkBadge(
                          variant: YkBadgeVariant.label,
                          label: widget.estEnseignantPrincipal ? 'Principal' : 'Assistant',
                          color: Colors.white,
                        ),
                        SizedBox(height: YkSpacing.sm),
                        Text(
                          widget.titre,
                          style: YkTypography.h2(context).copyWith(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: YkPinnedHeader(
              child: Container(
                color: YkColors.background(context),
                padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.xs),
                child: YkTabs(
                  controller: _tabController,
                  tabs: const [
                    YkTabItem(label: 'Leçons'),
                    YkTabItem(label: 'Exercices'),
                    YkTabItem(label: 'Devoirs'),
                    YkTabItem(label: 'Forum'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            LeconsCoursPage(
              coursId: widget.coursId,
              coursTitre: widget.titre,
              role: widget.role,
              tabController: _tabController,
              onNaviguerExercices: _naviguerVersExercicesAvecFiltre,
              isPremium: true,
              courseColor: widget.courseColor,
            ),
            ExercicesCoursPage(
              coursId: widget.coursId,
              role: widget.role,
              coursTitre: widget.titre,
              courseColor: widget.courseColor,
              moduleId: _exercicesModuleIdFiltre,
              leconId: _exercicesLeconIdFiltre,
            ),
            DevoirsCoursPage(
              coursId: widget.coursId,
              coursTitre: widget.titre,
              role: widget.role,
              courseColor: widget.courseColor,
            ),
            ForumPage(
              preoccupationCoursId: int.tryParse(widget.coursId),
              preoccupationCoursTitre: widget.titre,
            ),
          ],
        ),
      ),
    );
  }
}

