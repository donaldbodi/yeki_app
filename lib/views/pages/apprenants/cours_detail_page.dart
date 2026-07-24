// lib/views/pages/apprenants/cours_detail_page.dart
// ════════════════════════════════════════════════════════════════════════
// DÉTAILS DU COURS — GLASSMORPHISM LIGHT EDITION
// ════════════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yeki/features/devoirs_cours/presentation/devoirs_cours_page.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecons_cours.dart';
import 'package:yeki/features/exercices_cours/presentation/exercices_cours_page.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';

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

class _CoursDetailTabsState extends State<CoursDetailTabs>
    with SingleTickerProviderStateMixin {
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
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
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
      backgroundColor: YekiColors.bgLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: YekiGradients.mainBackground,
        ),
        child: Stack(
          children: [
            // Sphères décoratives
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _courseColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.accent.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.gold.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Le contenu des onglets
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 130),
                child: _buildTabViews(),
              ),
            ),
            
            // Header flouté (Glassmorphism) + TabBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          YekiColors.white.withValues(alpha: 0.80),
                          YekiColors.white.withValues(alpha: 0.60),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: YekiColors.white.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        _buildTabBarCapsule(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: YekiColors.textDark, size: 20),
              onPressed: () {
                _triggerHaptic();
                Navigator.pop(context);
              },
              splashRadius: 22,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titre,
                    style: const TextStyle(
                      color: YekiColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: _courseColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Espace d'apprentissage",
                        style: TextStyle(color: YekiColors.textMedium, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarCapsule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: YekiColors.white.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: TabBar(
          controller: _tabController,
          onTap: (_) => _triggerHaptic(),
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          indicator: BoxDecoration(
            gradient: LinearGradient(
              colors: [_courseColor, _courseColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _courseColor.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          labelColor: YekiColors.white,
          unselectedLabelColor: YekiColors.textMedium,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 11.5, 
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 11,
          ),
          tabs: const [
            Tab(child: Center(child: Text('Leçons'))),
            Tab(child: Center(child: Text('Exercices'))),
            Tab(child: Center(child: Text('Devoirs'))),
            Tab(child: Center(child: Text('Forum'))),
          ],
        ),
      ),
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
            : _buildPremiumLock('exercices'),
        widget.isPremium
            ? DevoirsCoursPage(
                coursId: widget.coursId,
                coursTitre: widget.titre,
                onNaviguerForum: naviguerVersForumAvecQuestion,
                courseColor: _courseColor,
              )
            : _buildPremiumLock('devoirs'),
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
            : _buildPremiumLock('forum'),
      ],
    );
  }

  Widget _buildPremiumLock(String feature) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Visuel d'impact : Badge Couronne Lumineux
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [YekiColors.gold.withValues(alpha: 0.15), YekiColors.gold.withValues(alpha: 0.0)],
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(55),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: YekiColors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: YekiColors.white.withValues(alpha: 0.8),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: YekiColors.gold.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: YekiColors.gold, size: 42),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Débloquez tout le potentiel',
                  style: YekiTextStyles.h2(context).copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Rejoignez la communauté Premium pour accéder sans limite aux $feature, fiches de révision et corrections d\'experts.',
                    textAlign: TextAlign.center,
                    style: YekiTextStyles.body(context).copyWith(fontSize: 13.5, height: 1.45),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Formule Annuelle
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            YekiColors.white.withValues(alpha: 0.7),
                            YekiColors.white.withValues(alpha: 0.4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: YekiColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Badge Économie
                          Positioned(
                            top: -12,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [YekiColors.accent, YekiColors.accent.withValues(alpha: 0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '-26% ÉCONOMIE',
                                style: TextStyle(color: YekiColors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _triggerHaptic(),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: YekiColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.flash_on_rounded, color: YekiColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Formule Annuelle',
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: YekiColors.textDark),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Accès total pendant 12 mois',
                                          style: TextStyle(color: YekiColors.textMedium, fontSize: 11, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Text(
                                    '13 000 F',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: YekiColors.primary, letterSpacing: -0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Formule Mensuelle
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            YekiColors.white.withValues(alpha: 0.5),
                            YekiColors.white.withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: YekiColors.white.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _triggerHaptic(),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: YekiColors.textMedium.withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.calendar_today_rounded, color: YekiColors.textMedium, size: 18),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Abonnement Mensuel',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: YekiColors.textDark),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Liberté totale, sans engagement',
                                      style: TextStyle(color: YekiColors.textMedium, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                '1 500 F',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: YekiColors.textDark, letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                
                // Rassurance
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_rounded, color: YekiColors.textMedium.withValues(alpha: 0.5), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Paiement Mobile Sécurisé • Annulable à tout moment',
                      style: TextStyle(color: YekiColors.textMedium.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}