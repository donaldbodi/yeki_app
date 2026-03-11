import 'package:flutter/material.dart';
import 'package:yeki/views/pages/apprenants/cours_detail_page.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';


class FormationClassiqueDetailPage extends StatefulWidget {
  final FormationClassique formation;
  const FormationClassiqueDetailPage({super.key, required this.formation});

  @override
  State<FormationClassiqueDetailPage> createState() =>
      _FormationClassiqueDetailPageState();
}

class _FormationClassiqueDetailPageState
    extends State<FormationClassiqueDetailPage>
    with SingleTickerProviderStateMixin {
  static const Color _teal = Color(0xFF008088);
  static const Color _dark = Color(0xFF0D1B2A);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedNiveau = 'Tous';
  String _selectedMatiere = 'Toutes';
  late TabController _tabCtrl;

  // Mock cours
  final List<Map<String, dynamic>> _cours = [
    {'id': '1','titre': 'Algèbre Linéaire', 'matiere': 'Mathématiques', 'niveau': 'Licence 1', 'nbLecons': 12, 'duree': '8h', 'enseignant': 'Dr. Mbarga'},
    {'id': '2','titre': 'Mécanique Newtonienne', 'matiere': 'Physique', 'niveau': 'Licence 1', 'nbLecons': 10, 'duree': '7h', 'enseignant': 'Prof. Fouda'},
    {'id': '3','titre': 'Analyse Mathématique', 'matiere': 'Mathématiques', 'niveau': 'Licence 2', 'nbLecons': 14, 'duree': '10h', 'enseignant': 'Dr. Nkomo'},
    {'id': '4','titre': 'Thermodynamique', 'matiere': 'Physique', 'niveau': 'Licence 2', 'nbLecons': 11, 'duree': '8h', 'enseignant': 'Prof. Abanda'},
    {'id': '5','titre': 'Algorithmique & Python', 'matiere': 'Informatique', 'niveau': 'Licence 1', 'nbLecons': 16, 'duree': '12h', 'enseignant': 'Dr. Kamga'},
    {'id': '6','titre': 'Chimie Organique', 'matiere': 'Chimie', 'niveau': 'Licence 2', 'nbLecons': 9, 'duree': '6h', 'enseignant': 'Prof. Bello'},
    {'id': '7','titre': 'Electromagnétisme', 'matiere': 'Physique', 'niveau': 'Licence 3', 'nbLecons': 13, 'duree': '9h', 'enseignant': 'Dr. Essoh'},
    {'id': '8','titre': 'Probabilités & Statistiques', 'matiere': 'Mathématiques', 'niveau': 'Licence 3', 'nbLecons': 10, 'duree': '7h', 'enseignant': 'Prof. Talla'},
  ];

  List<Map<String, dynamic>> get _filtered {
    return _cours.where((c) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          (c['titre'] as String).toLowerCase().contains(q) ||
          (c['enseignant'] as String).toLowerCase().contains(q);
      final matchNiveau = _selectedNiveau == 'Tous' || c['niveau'] == _selectedNiveau;
      final matchMatiere = _selectedMatiere == 'Toutes' || c['matiere'] == _selectedMatiere;
      return matchSearch && matchNiveau && matchMatiere;
    }).toList();
  }

  List<String> get _niveaux => ['Tous', ...widget.formation.niveaux];
  List<String> get _matieres => ['Toutes', ...widget.formation.matieres];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.formation;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(f),
          SliverToBoxAdapter(child: _buildInfoBar(f)),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabCtrl,
              labelColor: _teal,
              unselectedLabelColor: Colors.grey.shade400,
              indicatorColor: _teal,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: 'Cours'),
                Tab(text: 'Informations'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildCoursTab(),
            _buildInfoTab(f),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(FormationClassique f) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _teal,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _typeColor(f.type),
                _typeColor(f.type).withOpacity(0.6),
                const Color(0xFF0D1B2A),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      f.ecole,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    f.parcours,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBar(FormationClassique f) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoBarItem(Icons.book_outlined, '${f.nbCours}', 'Cours', _teal),
          _divider(),
          _infoBarItem(Icons.people_outline, '${f.nbEtudiants}', 'Étudiants', Colors.indigo),
          _divider(),
          _infoBarItem(Icons.layers_outlined, '${f.niveaux.length}', 'Niveaux', Colors.orange),
          _divider(),
          _infoBarItem(
            f.estPublique ? Icons.account_balance_outlined : Icons.business_outlined,
            f.estPublique ? 'Public' : 'Privé',
            'Statut',
            f.estPublique ? Colors.green : Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _infoBarItem(IconData icon, String val, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _dark)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1, height: 35,
        color: Colors.grey.shade100,
      );

  // ── Onglet Cours ─────────────────────────────────────────────────────────────
  Widget _buildCoursTab() {
    final cours = _filtered;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildSearchBar(),
          ),
        ),
        SliverToBoxAdapter(child: _buildNiveauFilter()),
        SliverToBoxAdapter(child: _buildMatiereFilter()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              '${cours.length} cours trouvé${cours.length > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        cours.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Text('Aucun cours trouvé',
                      style: TextStyle(color: Colors.grey.shade400)),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildCoursTile(cours[i]),
                    childCount: cours.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Rechercher un cours, un enseignant...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 19),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 16),
                  onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildNiveauFilter() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: _niveaux.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final n = _niveaux[i];
          final isSelected = _selectedNiveau == n;
          return GestureDetector(
            onTap: () => setState(() => _selectedNiveau = n),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? _teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _teal : Colors.grey.shade200),
              ),
              child: Text(
                n,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatiereFilter() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: _matieres.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final m = _matieres[i];
          final isSelected = _selectedMatiere == m;
          return GestureDetector(
            onTap: () => setState(() => _selectedMatiere = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.indigo : Colors.grey.shade200,
                ),
              ),
              child: Text(
                m,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isSelected ? Colors.indigo : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoursTile(Map<String, dynamic> cours) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
        )
      ],
    ),
    child: ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoursDetailTabs(
              coursId: cours['id'], // tu peux remplacer par cours['id'] quand ton backend sera prêt
              titre: cours['titre'],
            ),
          ),
        );
      },

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: _teal,
          size: 22,
        ),
      ),

      title: Text(
        cours['titre'],
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _dark,
        ),
      ),

      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(
            cours['enseignant'],
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              _miniChip(cours['matiere'], Colors.indigo),
              const SizedBox(width: 5),
              _miniChip(cours['niveau'], _teal),
              const SizedBox(width: 5),
              _miniChip('${cours['nbLecons']} leçons', Colors.orange),
            ],
          ),
        ],
      ),

      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 4),
          Text(
            cours['duree'],
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── Onglet Informations ───────────────────────────────────────────────────────
  Widget _buildInfoTab(FormationClassique f) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _infoSection('À propos', Icons.info_outline_rounded, [
          Text(f.description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
        ]),
        const SizedBox(height: 16),
        _infoSection('Niveaux disponibles', Icons.layers_outlined, [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: f.niveaux.map((n) => _tagChip(n, _teal)).toList(),
          ),
        ]),
        const SizedBox(height: 16),
        _infoSection('Matières enseignées', Icons.subject_rounded, [
          Wrap(
            spacing: 8, runSpacing: 8,
            children: f.matieres.map((m) => _tagChip(m, Colors.indigo)).toList(),
          ),
        ]),
        const SizedBox(height: 16),
        _infoSection('Localisation', Icons.location_on_outlined, [
          Row(children: [
            Icon(Icons.location_city_rounded, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text('${f.ville}, ${f.pays}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ]),
        ]),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _infoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: _teal),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _tagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'lycee':        return const Color(0xFF2884A0);
      case 'universite':   return const Color(0xFF5B4FCF);
      case 'grande_ecole': return const Color(0xFF008088);
      default:             return const Color(0xFF008088);
    }
  }
}
