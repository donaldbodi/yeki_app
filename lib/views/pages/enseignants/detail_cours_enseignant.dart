import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/exercices_cours.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecons_cours.dart';
import 'package:yeki/views/pages/apprenants/devoirs_cours_page.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

class DetailCoursEnseignantPage extends StatefulWidget {
  final String coursId;
  final String titre;
  final bool estEnseignantPrincipal;
  final RoleEnseignant role;

  const DetailCoursEnseignantPage({
    super.key,
    required this.coursId,
    required this.titre,
    required this.estEnseignantPrincipal,
    required this.role,
  });

  @override
  State<DetailCoursEnseignantPage> createState() => _DetailCoursEnseignantPageState();
}

class _DetailCoursEnseignantPageState extends State<DetailCoursEnseignantPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Couleurs harmonisées
  final Color primaryColor = const Color(0xFF2884A0);
  final Color secondaryColor = const Color(0xFF005F66);
  final Color accentColor = const Color(0xFFFF7F77);

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
      backgroundColor: const Color(0xFFF8FAFB),
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
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
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
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.estEnseignantPrincipal ? "Principal" : "Assistant",
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.titre,
                            style: const TextStyle(
                              color: Colors.white,
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: accentColor,
                      indicatorWeight: 3,
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
          controller: _tabController,
          children: [
            _buildTabContent(LeconsCoursPage(
              coursId: widget.coursId,
              coursTitre: widget.titre,  // ← Ajout du paramètre requis
              role: widget.role,
              tabController: _tabController,
            )),
            _buildTabContent(ExercicesCoursPage(
              coursId: widget.coursId, 
              role: widget.role, 
              coursTitre: widget.titre,
            )),
            _buildTabContent(DevoirsCoursPage(
                coursId: widget.coursId,
                coursTitre: widget.titre,
                isEnseignantPrincipal: widget.estEnseignantPrincipal,
                //estEnseignantPrincipal: widget.estEnseignantPrincipal,
              )),
            _buildForumContent(),
          ],
        ),
      ),
    );
  }

  // Permet de gérer le scroll correctement dans les onglets avec le NestedScrollView
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

  // Contenu spécifique pour le Forum (correction du layout injecteur)
  Widget _buildForumContent() {
    return Builder(
      builder: (context) {
        return Column(
          children: [
            // Récupère la hauteur exacte de l'espace occupé par le SliverAppBar
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 60, 
            ),
            Expanded(
              child: ForumPage(),
            ),
          ],
        );
      },
    );
  }
}