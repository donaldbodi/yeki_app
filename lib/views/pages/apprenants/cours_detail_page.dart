// lib/views/pages/apprenants/cours_detail_page.dart
//
// Refondu en P11.3 (rituel P5.0) : le glassmorphism fait main et le
// dégradé `YekiGradients.mainBackground` cèdent la place aux tokens `Yk*`.
// Le verrou Premium (`_buildPremiumLock`) avait ses 2 prix figés en dur
// (13000F/1500F, règle 3) — pas de prix fiable disponible ici, le verrou
// affiche donc un message générique plutôt qu'en inventer un. `isPremium`
// (en réalité `estAccessible`, dérivé de `DepartementItem.estAccessible`)
// n'est plus figé à `true` partout depuis P11.4 : certains appelants
// (`formation_detail_page.dart`, `concours_detail_page.dart`) transmettent
// désormais une vraie valeur — ce verrou PEUT donc réellement s'afficher.
// Bouton "Voir les répétiteurs" (P11.3) basculé sur `YkRepetiteurButton`
// (P11.7).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/features/devoirs_cours/presentation/devoirs_cours_page.dart';
import 'package:yeki/features/exercices_cours/presentation/exercices_cours_page.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecons_cours.dart';

class CoursDetailTabs extends StatefulWidget {
  final String coursId;
  final String titre;
  final int coursColor;
  final bool isPremium;
  final int initialTab;
  final int? scrollToQuestionId;
  final int? moduleId;
  final int? leconId;

  const CoursDetailTabs({
    super.key,
    required this.coursId,
    required this.titre,
    required this.coursColor,
    this.isPremium = true,
    this.initialTab = 0,
    this.scrollToQuestionId,
    this.moduleId,
    this.leconId,
  });

  @override
  State<CoursDetailTabs> createState() => _CoursDetailTabsState();
}

class _CoursDetailTabsState extends State<CoursDetailTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _courseColor;

  int? _forumScrollToId;
  String? _forumPreoccupationContenu;
  String? _forumPreoccupationSource;
  int? _forumPreoccupationLeconId;
  String? _forumPreoccupationLeconTitre;
  int? _forumPreoccupationExerciceId;
  String? _forumPreoccupationExerciceTitre;
  int? _forumPreoccupationDevoirId;
  String? _forumPreoccupationDevoirTitre;

  // Filtre de l'onglet Exercices — initialisé depuis les paramètres de
  // route, puis modifiable en place depuis l'onglet Leçons (voir
  // `_naviguerVersExercicesAvecFiltre`, P3.3 §6).
  int? _exercicesModuleIdFiltre;
  int? _exercicesLeconIdFiltre;

  @override
  void initState() {
    super.initState();
    _courseColor = Color(widget.coursColor);
    _exercicesModuleIdFiltre = widget.moduleId;
    _exercicesLeconIdFiltre = widget.leconId;
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void naviguerVersForumAvecQuestion(int questionId) {
    setState(() => _forumScrollToId = questionId);
    _tabController.animateTo(3);
  }

  /// Bascule sur l'onglet Exercices avec le filtre demandé, en place —
  /// jamais une nouvelle navigation (voir `LeconsCoursPage.onNaviguerExercices`,
  /// P3.3 §6).
  void _naviguerVersExercicesAvecFiltre({int? moduleId, int? leconId}) {
    setState(() {
      _exercicesModuleIdFiltre = moduleId;
      _exercicesLeconIdFiltre = leconId;
    });
    _tabController.animateTo(1);
  }

  void setPreoccupationData({
    String? contenu,
    String? source,
    int? leconId,
    String? leconTitre,
    int? exerciceId,
    String? exerciceTitre,
    int? devoirId,
    String? devoirTitre,
  }) {
    setState(() {
      _forumPreoccupationContenu = contenu;
      _forumPreoccupationSource = source;
      _forumPreoccupationLeconId = leconId;
      _forumPreoccupationLeconTitre = leconTitre;
      _forumPreoccupationExerciceId = exerciceId;
      _forumPreoccupationExerciceTitre = exerciceTitre;
      _forumPreoccupationDevoirId = devoirId;
      _forumPreoccupationDevoirTitre = devoirTitre;
    });
    _tabController.animateTo(3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(YkSpacing.xxs, YkSpacing.xxs, YkSpacing.md, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: YkColors.textPrimary(context), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.titre,
                            style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: _courseColor, shape: BoxShape.circle)),
                              SizedBox(width: YkSpacing.xxs),
                              Text(
                                "Espace d'apprentissage",
                                style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    YkRepetiteurButton(compact: true, onPressed: () => context.pushNamed(AppRoute.repetiteurs)),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
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
            ],
          ),
        ),
      ),
      body: _buildTabViews(),
    );
  }

  Widget _buildTabViews() {
    return TabBarView(
      controller: _tabController,
      children: [
        LeconsCoursPage(
          coursId: widget.coursId,
          coursTitre: widget.titre,
          tabController: _tabController,
          onNaviguerForum: naviguerVersForumAvecQuestion,
          onNaviguerExercices: _naviguerVersExercicesAvecFiltre,
          isPremium: widget.isPremium,
          courseColor: _courseColor,
        ),
        widget.isPremium
            ? ExercicesCoursPage(
                coursId: widget.coursId,
                coursTitre: widget.titre,
                onNaviguerForum: naviguerVersForumAvecQuestion,
                courseColor: _courseColor,
                moduleId: _exercicesModuleIdFiltre,
                leconId: _exercicesLeconIdFiltre,
              )
            : _buildPremiumLock(context),
        widget.isPremium
            ? DevoirsCoursPage(
                coursId: widget.coursId,
                coursTitre: widget.titre,
                onNaviguerForum: naviguerVersForumAvecQuestion,
                courseColor: _courseColor,
              )
            : _buildPremiumLock(context),
        widget.isPremium
            ? ForumPage(
                key: ValueKey('$_forumScrollToId$_forumPreoccupationContenu'),
                scrollToQuestionId: _forumScrollToId,
                preoccupationContenu: _forumPreoccupationContenu,
                preoccupationSource: _forumPreoccupationSource,
                preoccupationLeconId: _forumPreoccupationLeconId,
                preoccupationLeconTitre: _forumPreoccupationLeconTitre,
                preoccupationCoursId: int.tryParse(widget.coursId),
                preoccupationCoursTitre: widget.titre,
                preoccupationExerciceId: _forumPreoccupationExerciceId,
                preoccupationExerciceTitre: _forumPreoccupationExerciceTitre,
                preoccupationDevoirId: _forumPreoccupationDevoirId,
                preoccupationDevoirTitre: _forumPreoccupationDevoirTitre,
                coursColor: widget.coursColor,
              )
            : _buildPremiumLock(context),
      ],
    );
  }

  Widget _buildPremiumLock(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(YkSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded, color: YkColors.warning, size: 64),
            SizedBox(height: YkSpacing.md),
            Text(
              'Débloquez tout le potentiel',
              textAlign: TextAlign.center,
              style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            SizedBox(height: YkSpacing.xs),
            Text(
              "Accédez sans limite aux exercices, devoirs et au forum de ce cours en découvrant nos offres.",
              textAlign: TextAlign.center,
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            SizedBox(height: YkSpacing.lg),
            YkButton(
              label: 'Découvrir nos offres',
              icon: Icons.workspace_premium_rounded,
              // Aucun prix réel n'est disponible ici (voir commentaire
              // d'en-tête) — `YkSnack.info` plutôt qu'une navigation vers
              // `AppRoute.paiement` avec un montant inventé à 0.
              onPressed: () => YkSnack.info(context, 'Nos offres seront bientôt disponibles depuis cet écran.'),
            ),
          ],
        ),
      ),
    );
  }
}
