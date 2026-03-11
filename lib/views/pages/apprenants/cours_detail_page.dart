import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/devoirs_cours_page.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'lecons_cours.dart';
import 'exercices_cours.dart';

class CoursDetailTabs extends StatefulWidget {
  final String coursId;
  final String titre;

  const CoursDetailTabs({
    super.key,
    required this.coursId,
    required this.titre,
  });

  @override
  State<CoursDetailTabs> createState() => _DetailsCoursPageState();
}

class _DetailsCoursPageState extends State<CoursDetailTabs>
    with SingleTickerProviderStateMixin {
  
  // On utilise un seul controller explicite
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF2884A0);
  final Color accentColor = const Color(0xFFFF7F77);

  @override
  void initState() {
    super.initState();
    // Initialisation du controller pour 4 onglets
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
      backgroundColor: const Color(0xFFF8FAFB),
      // SUPPRESSION du DefaultTabController ici pour éviter le conflit
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                elevation: 0,
                backgroundColor: primaryColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, const Color(0xFF005F66)],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(25, 80, 25, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.titre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: 0.65,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "65%",
                                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: TabBar(
                      controller: _tabController, // Utilisation du controller explicite
                      indicatorColor: accentColor,
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey,
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
          controller: _tabController, // Utilisation du même controller
          children: [
            // Page Leçons : on lui passe le controller pour qu'il puisse l'envoyer à LectureLecon
            _buildTabContent(LeconsCoursPage(coursId: widget.coursId, tabController: _tabController,)),
            _buildTabContent(ExercicesCoursPage(coursId: widget.coursId)),
            _buildTabContent(DevoirsCoursPage(coursId: widget.coursId, coursTitre: 'dsss',)),
            
            // Page Forum : Correction de l'affichage
            _buildForumContent(),
          ],
        ),
      ),
    );
  }

  // Contenu standard pour les onglets scrollables (Leçons, Exercices...)
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
              padding: const EdgeInsets.only(bottom: 20),
              sliver: SliverToBoxAdapter(child: page),
            ),
          ],
        );
      },
    );
  }

  // Contenu spécifique pour le Forum (pour éviter les problèmes de clavier et de scroll)
  Widget _buildForumContent() {
    return Builder(
      builder: (context) {
        return Column(
          children: [
            // Cet injecteur est CRUCIAL pour que le contenu ne passe pas sous l'AppBar
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ).specialSliverToBoxAdapter(), 
            
            Expanded(
              child: ForumPage(),
            ),
          ],
        );
      },
    );
  }
}

// Petite extension pour faciliter l'usage de l'injecteur dans une Column
extension on SliverOverlapInjector {
  Widget specialSliverToBoxAdapter() {
    return Builder(
      builder: (context) => SizedBox(
        height: NestedScrollView.sliverOverlapAbsorberHandleFor(context).layoutExtent,
      ),
    );
  }
}