// lib/views/pages/apprenants/cours_detail_page.dart

import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/devoirs_cours_page.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecons_cours.dart';
import 'package:yeki/views/pages/apprenants/exercices_cours.dart';

class CoursDetailTabs extends StatefulWidget {
  final String coursId;
  final String titre;
  final bool isPremium;
  final int initialTab;
  final int? scrollToQuestionId;

  const CoursDetailTabs({
    super.key,
    required this.coursId,
    required this.titre,
    this.isPremium = true,
    this.initialTab = 0,
    this.scrollToQuestionId,
  });

  @override
  State<CoursDetailTabs> createState() => _CoursDetailTabsState();
}

class _CoursDetailTabsState extends State<CoursDetailTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _primary = Color(0xFF2884A0);
  static const Color _gold = Color(0xFFFFD700);

  int? _forumScrollToId;
  String? _forumPreoccupationContenu;
  String? _forumPreoccupationSource;
  int? _forumPreoccupationLeconId;
  String? _forumPreoccupationLeconTitre;
  int? _forumPreoccupationExerciceId;
  String? _forumPreoccupationExerciceTitre;
  int? _forumPreoccupationDevoirId;
  String? _forumPreoccupationDevoirTitre;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
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
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildTabViews()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, Color(0xFF005F66)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 20, 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.titre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: _gold, size: 14),
                      const SizedBox(width: 4),
                      const Text('Gratuit',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: _primary,
        indicatorWeight: 3,
        labelColor: _primary,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: [
          const Tab(icon: Icon(Icons.play_lesson_rounded, size: 18), text: 'Leçons'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_note_rounded, size: 16),
                const SizedBox(width: 4),
                const Text('Exercices'),
                if (!widget.isPremium) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.lock_rounded, size: 10, color: _gold),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assignment_rounded, size: 16),
                const SizedBox(width: 4),
                const Text('Devoirs'),
                if (!widget.isPremium) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.lock_rounded, size: 10, color: _gold),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.forum_rounded, size: 16),
                const SizedBox(width: 4),
                const Text('Forum'),
                if (!widget.isPremium) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.lock_rounded, size: 10, color: _gold),
                ],
              ],
            ),
          ),
        ],
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
          isPremium: widget.isPremium,
        ),
        widget.isPremium
            ? ExercicesCoursPage(
                coursId: widget.coursId,
                coursTitre: widget.titre,
                onNaviguerForum: naviguerVersForumAvecQuestion,
              )
            : _buildPremiumLock('exercices'),
        widget.isPremium
            ? DevoirsCoursPage(
                coursId: widget.coursId,
                coursTitre: widget.titre,
                onNaviguerForum: naviguerVersForumAvecQuestion,
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
              )
            : _buildPremiumLock('forum'),
      ],
    );
  }

  Widget _buildPremiumLock(String feature) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: _gold.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.workspace_premium_rounded, color: _gold, size: 52),
            ),
            const SizedBox(height: 20),
            const Text('Accès Premium requis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
            const SizedBox(height: 10),
            Text(
              'Abonnez-vous à Yéki Premium pour accéder aux $feature.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('1 500 FCFA / mois',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: BorderSide(color: _primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('13 000 FCFA / an',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('Économisez 26% !',
                        style: TextStyle(fontSize: 10, color: Color(0xFFFFD700))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}