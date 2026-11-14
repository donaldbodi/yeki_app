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
//
// Phase 2 (refonte écran 4/N, `docs/ecarts/p2_cours_detail_entete.md`) :
// en-tête restylé sur la maquette (« 09 · Détail cours », qui attribue
// explicitement cet en-tête à ce fichier). Le bouton répétiteur a quitté
// l'en-tête (doublon avec celui déjà posé au bas de l'onglet Leçons,
// P11.7 — seul emplacement de cette action dans la maquette) au profit
// d'un bouton favori local à la session (même précédent déjà écrit dans
// `detail_lecon_page.dart._onFavorite`, aucun favori persistant côté
// backend). Le sous-titre affiche désormais le nombre de leçons et le
// pourcentage complété, calculés depuis `CoursRepository.modules()`
// (mêmes données que `lecons_cours.dart` affiche déjà par leçon).

import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/repositories/paiement_repository.dart';
import 'package:yeki/features/devoirs_cours/presentation/devoirs_cours_page.dart';
import 'package:yeki/features/exercices_cours/presentation/exercices_cours_page.dart';
import 'package:yeki/features/paiement/presentation/ouvrir_abonnement.dart';
import 'package:yeki/repositories/cours_repository.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecon_models.dart';
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
  final _coursRepo = CoursRepository();

  // Favori local à la session — aucun favori persistant côté backend
  // (précédent déjà établi dans `detail_lecon_page.dart._onFavorite`,
  // règle 3 : pas de fonctionnalité persistée qui n'existe pas).
  bool _favori = false;

  // Sous-titre d'en-tête — `null` tant que non chargé, repli sur le
  // texte générique dans ce cas (voir `_sousTitre`).
  int? _totalLecons;
  int? _leconsCompletees;
  String? _niveau;
  String? _enseignantNom;
  String? _enseignantAvatarUrl;

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
    _chargerProgression();
    if (kIsWeb && authState.value.role == 'apprenant') _verifierAbonnementWeb();
  }

  /// Version web : les cours sont réservés aux apprenants abonnés au
  /// département (décision produit — pas de téléchargement possible sur
  /// le web, donc rien à consulter une fois l'abonnement terminé).
  /// `null` tant que non vérifié, ou si la vérification échoue (le serveur
  /// protège de toute façon les contenus Premium).
  bool? _abonneWeb;

  Future<void> _verifierAbonnementWeb() async {
    try {
      final statut = await PaiementRepository().statutAbonnement(int.parse(widget.coursId));
      if (mounted) setState(() => _abonneWeb = statut.actif);
    } catch (_) {
      // Vérification impossible (réseau) : pas de blocage côté interface.
    }
  }

  Future<void> _chargerProgression() async {
    try {
      final coursId = int.parse(widget.coursId);
      final resultats = await Future.wait([_coursRepo.modules(coursId), _coursRepo.detail(coursId)]);
      final modules = resultats[0] as List<ModuleAvecLecons>;
      final detail = resultats[1] as CoursDetailInfo;
      final lecons = modules.expand((m) => m.lecons).toList();
      if (!mounted) return;
      setState(() {
        _totalLecons = lecons.length;
        _leconsCompletees = lecons.where((l) => l.estTerminee).length;
        _niveau = detail.niveau;
        _enseignantNom = detail.enseignantNom;
        _enseignantAvatarUrl = detail.enseignantAvatarUrl;
      });
    } catch (_) {
      // Échec silencieux — repli sur le texte générique (`_sousTitre`),
      // aucune valeur inventée affichée à la place.
    }
  }

  String get _sousTitre {
    final total = _totalLecons;
    final completees = _leconsCompletees;
    if (total == null || total == 0) return "Espace d'apprentissage";
    final pourcentage = (completees! / total * 100).round();
    final niveau = _niveau;
    if (niveau != null && niveau.isNotEmpty) return '$niveau · $total leçons · $pourcentage% complété';
    return '$total leçons · $pourcentage% complété';
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
      // Le corps défile SOUS l'en-tête (nécessaire pour que
      // `BackdropFilter` flOute réellement le contenu qui passe dessous,
      // comme la maquette) — chaque onglet compense avec un padding haut
      // égal à `_headerHeight` (voir plus bas).
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        // En-tête « verre dépoli » — maquette « 09 · Détail cours »
        // (`background: var(--glass); backdrop-filter: blur(20px);
        // border-bottom: 1px solid var(--border)`), jusqu'ici absent
        // (fond opaque uni). Même recette de flou déjà établie par
        // `YkCard(variant: glass)` (sigma 16 → 20 ici pour matcher le
        // blur(20px) exact de la maquette), simplement appliquée à une
        // barre pleine largeur (pas de coins arrondis/bordure complète,
        // seul un liseré bas comme dans la maquette).
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: YkColors.surface(context).withValues(alpha: 0.75),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(YkSpacing.xxs, YkSpacing.xxs, YkSpacing.md, 0),
                      child: Row(
                        children: [
                          YkIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            label: 'Retour',
                            variant: YkIconButtonVariant.outlined,
                            iconSize: 18,
                            onPressed: () => Navigator.pop(context),
                          ),
                          SizedBox(width: YkSpacing.xs),
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
                                    ClipOval(child: Container(width: 7, height: 7, color: _courseColor)),
                                    SizedBox(width: YkSpacing.xxs),
                                    Text(
                                      _sousTitre,
                                      style: YkTypography.caption(
                                        context,
                                      ).copyWith(color: YkColors.textSecondary(context)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: YkSpacing.xs),
                          YkIconButton(
                            icon: _favori ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            label: _favori ? 'Retirer des favoris' : 'Ajouter aux favoris',
                            variant: _favori ? YkIconButtonVariant.tonal : YkIconButtonVariant.outlined,
                            iconSize: 18,
                            onPressed: () => setState(() => _favori = !_favori),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
                      child: YkTabs(
                        controller: _tabController,
                        activeColor: _courseColor,
                        tabs: const [
                          YkTabItem(label: 'Leçons'),
                          YkTabItem(label: 'Exercices'),
                          YkTabItem(label: 'Devoirs'),
                          YkTabItem(label: 'Forum'),
                        ],
                      ),
                    ),
                    Container(height: 1, color: YkColors.border(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: _abonneWeb == false
          ? _buildPremiumLock(
              context,
              titre: 'Abonnement requis',
              message:
                  "Sur le site web, l'accès aux cours est réservé aux abonnés de ce département. "
                  'Abonnez-vous pour continuer.',
            )
          : _buildTabViews(),
    );
  }

  /// Hauteur réelle de l'en-tête « verre dépoli » (96 + l'encoche système)
  /// — le contenu défilable de chaque onglet en a besoin comme padding
  /// haut, `Scaffold(extendBodyBehindAppBar: true)` ne le fait pas pour
  /// eux automatiquement.
  double get _headerHeight => MediaQuery.of(context).padding.top + 96;

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
          enseignantNom: _enseignantNom,
          enseignantAvatarUrl: _enseignantAvatarUrl,
          topPadding: _headerHeight,
        ),
        widget.isPremium
            ? ExercicesCoursPage(
                coursId: widget.coursId,
                coursTitre: widget.titre,
                onNaviguerForum: naviguerVersForumAvecQuestion,
                courseColor: _courseColor,
                moduleId: _exercicesModuleIdFiltre,
                leconId: _exercicesLeconIdFiltre,
                topPadding: _headerHeight,
              )
            : _buildPremiumLock(context),
        widget.isPremium
            ? DevoirsCoursPage(
                coursId: widget.coursId,
                coursTitre: widget.titre,
                onNaviguerForum: naviguerVersForumAvecQuestion,
                courseColor: _courseColor,
                topPadding: _headerHeight,
              )
            : _buildPremiumLock(context),
        widget.isPremium
            ? ForumPage(
                key: ValueKey('$_forumScrollToId$_forumPreoccupationContenu'),
                scrollToQuestionId: _forumScrollToId,
                preoccupationContenu: _forumPreoccupationContenu,
                preoccupationSource: _forumPreoccupationSource,
                preoccupationLeconId: _forumPreoccupationLeconId,
                topPadding: _headerHeight,
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

  Widget _buildPremiumLock(
    BuildContext context, {
    String titre = 'Débloquez tout le potentiel',
    String message = 'Accédez sans limite aux exercices, devoirs et au forum de ce cours en découvrant nos offres.',
  }) {
    return Padding(
      padding: EdgeInsets.only(top: _headerHeight),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(YkSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded, color: YkColors.warning, size: 64),
            SizedBox(height: YkSpacing.md),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            SizedBox(height: YkSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            SizedBox(height: YkSpacing.lg),
            YkButton(
              label: 'Découvrir nos offres',
              icon: Icons.workspace_premium_rounded,
              // Rectification (demande explicite) : `ouvrirAbonnementPremium`
              // est déjà pleinement câblé et fonctionnel ailleurs (Devoirs,
              // Forum, Lecture leçon) — `widget.coursId`/`widget.titre` sont
              // déjà disponibles ici, plus de raison de rester sur un message
              // générique.
              onPressed: () => ouvrirAbonnementPremium(context, coursId: int.parse(widget.coursId), coursNom: widget.titre),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
