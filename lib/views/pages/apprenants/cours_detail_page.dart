import 'package:flutter/material.dart';

import 'lecons_cours.dart';
import 'exercices_cours.dart';
import 'devoirs_cours.dart';
import 'forum.dart';

class CoursDetailTabs extends StatefulWidget {
  const CoursDetailTabs({super.key});

  @override
  State<CoursDetailTabs> createState() => _DetailsCoursPageState();
}

class _DetailsCoursPageState extends State<CoursDetailTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text(
                "Détail du cours",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              backgroundColor: const Color(0xff008088),
              expandedHeight: 80,     // 🔹 très compact 00ced1
              collapsedHeight: 64,    // 🔹 hauteur finale élégante
              pinned: true,
              elevation: innerBoxIsScrolled ? 2 : 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(42),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xffff7f77),
                  indicatorWeight: 2,
                  labelColor: const Color(0xffff7f77),
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: "Leçons"),
                    Tab(text: "Exercices"),
                    Tab(text: "Devoirs"),
                    Tab(text: "Forum"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            LeconsCoursPage(),
            ExercicesCoursPage(),
            DevoirsCoursPage(),
            ForumCoursPage(),
          ],
        ),
      ),
    );
  }
}
