import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/devoirs_cours_page.dart';
import 'package:yeki/views/pages/apprenants/forum_page.dart';
import 'package:yeki/views/pages/apprenants/lecons_cours.dart';
import 'package:yeki/views/pages/apprenants/exercices_cours.dart';

// Palette harmonisée
const Color brandBackground = Color(0xFF135F74);
const Color actionOrange = Color(0xFFFF6B00);
const Color _white = Color(0xFFFFFFFF);
const Color _white80 = Color(0xCCFFFFFF);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _bgLight = Color(0xFFF8FAFC);

class CoursDetailTabs extends StatefulWidget {
  final String coursId;
  final String titre;
  final int coursColor;
  final bool isPremium;
  final int initialTab;
  final int? scrollToQuestionId;

  const CoursDetailTabs({
    super.key,
    required this.coursId,
    required this.titre,
    required this.coursColor,
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

  int? _forumScrollToId;
  String? _forumPreoccupationContenu;
  String? _forumPreoccupationSource;
  int? _forumPreoccupationLeconId;
  String? _forumPreoccupationLeconTitre;
  int? _forumPreoccupationExerciceId;
  String? _forumPreoccupationExerciceTitre;
  int? _forumPreoccupationDevoirId;
  String? _forumPreoccupationDevoirTitre;

  late Color _courseColor;

  @override
  void initState() {
    super.initState();
    _courseColor = Color(widget.coursColor);
    _tabController = TabController(
      length: 4, 
      vsync: this, 
      initialIndex: widget.initialTab,
    );
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
      backgroundColor: _bgLight,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_courseColor, _courseColor.withOpacity(0.7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 20, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: _white, size: 18),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.titre,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: actionOrange.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: actionOrange, size: 12),
                      const SizedBox(width: 4),
                      const Text('Gratuit',
                          style: TextStyle(color: _white80, fontSize: 10, fontWeight: FontWeight.w600)),
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
      color: _white,
      child: SizedBox(
        height: 44,
        child: TabBar(
          controller: _tabController,
          indicatorColor: _courseColor,
          indicatorWeight: 2.5,
          labelColor: _courseColor,
          unselectedLabelColor: _textMedium,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.play_lesson_rounded, size: 16), text: 'Leçons'),
            Tab(icon: Icon(Icons.edit_note_rounded, size: 16), text: 'Exos'),
            Tab(icon: Icon(Icons.assignment_rounded, size: 16), text: 'Devoirs'),
            Tab(icon: Icon(Icons.forum_rounded, size: 16), text: 'Forum'),
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
          isPremium: widget.isPremium,
          courseColor: _courseColor,
        ),
        widget.isPremium
            ? ExercicesCoursPage(
                coursId: widget.coursId,
                coursTitre: widget.titre,
                onNaviguerForum: naviguerVersForumAvecQuestion,
                courseColor: _courseColor,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: actionOrange.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: actionOrange.withOpacity(0.2), width: 1),
              ),
              child: Icon(Icons.workspace_premium_rounded, color: actionOrange, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Accès Premium requis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Abonnez-vous à Yéki Premium pour accéder aux $feature.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMedium, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionOrange,
                  foregroundColor: _white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('1 500 FCFA / mois',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandBackground,
                  side: const BorderSide(color: brandBackground),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('13 000 FCFA / an',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('Économisez 26% !',
                        style: TextStyle(fontSize: 9, color: actionOrange)),
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