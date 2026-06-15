// lib/views/pages/enseignants/detail_cours_enseignant.dart
// ═══════════════════════════════════════════════════════════════════════════
// DÉTAIL COURS ENSEIGNANT — CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/exercices_cours.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecons_cours.dart';
import 'package:yeki/views/pages/apprenants/devoirs_cours_page.dart';
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
  late TabController _tabController;

  Color get primaryColor => widget.courseColor;
  Color get secondaryColor => widget.courseColor.withValues(alpha: 0.7);
  Color get accentColor => YekiColors.accent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                elevation: 0,
                backgroundColor: primaryColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: YekiColors.black.withValues(alpha: 0.26),
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
                                  color: YekiColors.white.withValues(alpha: 0.2),
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
                      indicatorColor: accentColor,
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
              isPremium: true,
              courseColor: primaryColor,
            )),
            _buildTabContent(ExercicesCoursPage(
              coursId: widget.coursId, 
              role: widget.role, 
              coursTitre: widget.titre,
              courseColor: primaryColor,
            )),
            _buildTabContent(DevoirsCoursPage(
              coursId: widget.coursId,
              coursTitre: widget.titre,
              isEnseignantPrincipal: widget.estEnseignantPrincipal,
              courseColor: primaryColor,
            )),
            _buildForumContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Widget page) {
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              sliver: SliverToBoxAdapter(child: page),
            ),
          ],
        );
      },
    );
  }

  Widget _buildForumContent() {
    return Builder(
      builder: (context) {
        return Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 60, 
            ),
            Expanded(
              child: ForumPage(
                preoccupationCoursId: int.tryParse(widget.coursId),
                preoccupationCoursTitre: widget.titre,
              ),
            ),
          ],
        );
      },
    );
  }
}