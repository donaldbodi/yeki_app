// lib/views/pages/enseignants/detail_cours_enseignant.dart
// ═══════════════════════════════════════════════════════════════════════════
// DÉTAIL COURS ENSEIGNANT — VERSION CORRIGÉE (DÉFILEMENT OPTIMISÉ)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:yeki/features/exercices_cours/presentation/exercices_cours_page.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecons_cours.dart';
import 'package:yeki/features/devoirs_cours/presentation/devoirs_cours_page.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'package:yeki/core/theme/app_theme.dart';

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

class _DetailCoursEnseignantPageState extends State<DetailCoursEnseignantPage>
    with TickerProviderStateMixin {
  // ✅ CORRECTION : Utiliser un TabController pour les onglets
  late TabController _tabController;

  // Filtre de l'onglet Exercices, modifiable en place depuis l'onglet
  // Leçons (voir `_naviguerVersExercicesAvecFiltre`, P3.3 §6) — jamais une
  // navigation vers l'écran apprenant `CoursDetailTabs`.
  int? _exercicesModuleIdFiltre;
  int? _exercicesLeconIdFiltre;

  Color get primaryColor => widget.courseColor;
  Color get secondaryColor => widget.courseColor.withAlpha(178);

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
      backgroundColor: YekiColors.backgroundLight,
      // ✅ CORRECTION : Utiliser NestedScrollView avec un ScrollController
      // Ne pas passer _tabController à NestedScrollView car il attend un ScrollController
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: primaryColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: YekiColors.black.withAlpha(66),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: YekiColors.white, size: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, secondaryColor],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(25, 80, 25, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: YekiColors.white.withAlpha(51),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.estEnseignantPrincipal ? "Principal" : "Assistant",
                                  style: const TextStyle(color: YekiColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.titre,
                            style: const TextStyle(
                              color: YekiColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    decoration: BoxDecoration(
                      color: YekiColors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: primaryColor,
                      indicatorWeight: 3,
                      labelColor: primaryColor,
                      unselectedLabelColor: YekiColors.textLight,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: "Leçons"),
                        Tab(text: "Exercices"),
                        Tab(text: "Devoirs"),
                        Tab(text: "Forum"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(LeconsCoursPage(
              coursId: widget.coursId,
              coursTitre: widget.titre,
              role: widget.role,
              tabController: _tabController,
              onNaviguerExercices: _naviguerVersExercicesAvecFiltre,
              isPremium: true,
              courseColor: primaryColor,
            )),
            _buildTabContent(ExercicesCoursPage(
              coursId: widget.coursId,
              role: widget.role,
              coursTitre: widget.titre,
              courseColor: primaryColor,
              moduleId: _exercicesModuleIdFiltre,
              leconId: _exercicesLeconIdFiltre,
            )),
            _buildTabContent(DevoirsCoursPage(
              coursId: widget.coursId,
              coursTitre: widget.titre,
              role: widget.role,
              courseColor: primaryColor,
            )),
            _buildTabContent(ForumPage(
              preoccupationCoursId: int.tryParse(widget.coursId),
              preoccupationCoursTitre: widget.titre,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Widget page) {
    // ✅ CORRECTION : Utiliser Builder pour injecter le handle d'overlap
    return Builder(
      builder: (context) {
        final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
        
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverOverlapInjector(
              handle: handle,
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  // Forcer une hauteur suffisante pour le contenu
                  height: MediaQuery.of(context).size.height - kToolbarHeight - 60 - 100,
                  child: page,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}