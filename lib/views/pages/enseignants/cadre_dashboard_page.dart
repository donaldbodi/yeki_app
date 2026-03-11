import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

// ─────────────────────────────────────────────────────────────────
// DASHBOARD ENSEIGNANT CADRE
// - Stats complètes du département associé
// - Statistiques de ses cours créés
// - Performances des enseignants principaux
// - Changer un enseignant principal dans un cours
// - Créer un cours
// ─────────────────────────────────────────────────────────────────

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _primary  = Color(0xFF6A1B9A);   // violet pour cadre
const Color _dark     = Color(0xFF0D1B2A);
const Color _bg       = Color(0xFFF8F4FC);

class CadreDashboardPage extends StatefulWidget {
  const CadreDashboardPage({super.key});

  @override
  State<CadreDashboardPage> createState() => _CadreDashboardPageState();
}

class _CadreDashboardPageState extends State<CadreDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _departement = {};
  List _cours = [];
  List _enseignantsPrincipaux = [];
  String _nomEnseignant = '';
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) { setState(() => _loading = false); return; }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignant/cadre/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _stats = data['stats'] ?? {};
          _departement = data['departement'] ?? {};
          _cours = data['cours'] ?? [];
          _enseignantsPrincipaux = data['enseignants_principaux'] ?? [];
          _nomEnseignant = data['nom'] ?? '';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ─── Changer enseignant principal ───────────────────────────────
  void _changerEnseignantPrincipal(Map cours) async {
    final token = await _getToken();
    List enseignants = [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignants/liste/?role=principal'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) enseignants = jsonDecode(res.body);
    } catch (_) {}

    if (!mounted) return;
    int? selected;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Text('Changer l\'enseignant principal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark)),
              Text('Cours : ${cours['titre'] ?? ''}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              if (enseignants.isEmpty)
                const Text('Aucun enseignant principal disponible')
              else
                ...enseignants.map((e) => RadioListTile<int>(
                  value: e['id'] as int,
                  groupValue: selected,
                  activeColor: _primary,
                  title: Text(e['nom'] ?? e['username'] ?? ''),
                  subtitle: Text(e['email'] ?? ''),
                  onChanged: (v) => setS(() => selected = v),
                )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: selected == null ? null : () async {
                    Navigator.pop(ctx);
                    await _applyChangerEnseignant(cours['id'], selected!);
                  },
                  child: const Text('Confirmer', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyChangerEnseignant(int coursId, int enseignantId) async {
    final token = await _getToken();
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/cours/$coursId/changer-enseignant-principal/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'enseignant_principal_id': enseignantId}),
      );
      if (res.statusCode == 200) {
        _showSuccess('Enseignant principal modifié avec succès !');
        _charger();
      } else {
        _showError('Erreur lors du changement');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  // ─── Créer un cours ─────────────────────────────────────────────
  void _creerCours() {
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    Uint8List? imageBytes;
    String? imageName;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                Text('Créer un cours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _dark)),
                Text('Département : ${_departement['nom'] ?? ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 20),
                _modernField(titreCtrl, 'Titre du cours *', Icons.title, 'Ex: Algèbre Linéaire S1'),
                const SizedBox(height: 14),
                _modernField(descCtrl, 'Description', Icons.description_outlined,
                    'Objectifs et contenu du cours', maxLines: 3),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final res = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    if (res != null && res.files.single.bytes != null) {
                      setS(() {
                        imageBytes = res.files.single.bytes;
                        imageName = res.files.single.name;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined, color: _primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            imageName ?? 'Ajouter une image de couverture (optionnel)',
                            style: TextStyle(
                              color: imageName != null ? Colors.black87 : Colors.grey.shade500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (imageName != null) Icon(Icons.check_circle, color: _primary, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isLoading ? null : () async {
                      if (titreCtrl.text.trim().isEmpty) {
                        _showError('Le titre est obligatoire'); return;
                      }
                      setS(() => isLoading = true);
                      final token = await _getToken();
                      try {
                        final uri = Uri.parse('$_baseUrl/cours/creer/');
                        final request = http.MultipartRequest('POST', uri);
                        request.headers['Authorization'] = 'Token $token';
                        request.fields['titre'] = titreCtrl.text.trim();
                        request.fields['description'] = descCtrl.text.trim();
                        request.fields['departement'] = _departement['id'].toString();
                        if (imageBytes != null && imageName != null) {
                          request.files.add(http.MultipartFile.fromBytes(
                            'image', imageBytes!,
                            filename: imageName,
                            contentType: MediaType('image', 'jpeg'),
                          ));
                        }
                        final streamed = await request.send();
                        final res = await http.Response.fromStream(streamed);
                        setS(() => isLoading = false);
                        if (res.statusCode == 201) {
                          Navigator.pop(ctx);
                          _showSuccess('Cours créé avec succès !');
                          _charger();
                        } else {
                          _showError('Erreur ${res.statusCode}');
                        }
                      } catch (_) {
                        setS(() => isLoading = false);
                        _showError('Erreur réseau');
                      }
                    },
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Créer le cours', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau cours', style: TextStyle(color: Colors.white)),
        onPressed: _creerCours,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [_buildAppBar(), _buildTabBar()],
              body: TabBarView(
                controller: _tabCtrl,
                children: [_tabCours(), _tabEnseignants(), _tabStats()],
              ),
            ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: _primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A148C), _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Tableau de bord', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_nomEnseignant.isEmpty ? 'Enseignant Cadre' : _nomEnseignant,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _badge('Enseignant Cadre', Colors.white.withOpacity(0.2)),
                      const SizedBox(width: 8),
                      if (_departement['nom'] != null)
                        _badge(_departement['nom'], Colors.amber.withOpacity(0.25)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text('Dashboard Cadre', style: TextStyle(fontSize: 16, color: Colors.white)),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _charger),
      ],
    );
  }

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: TabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          labelColor: _primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primary,
          tabs: const [
            Tab(text: 'Mes cours'),
            Tab(text: 'Enseignants'),
            Tab(text: 'Statistiques'),
          ],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  // ─── TAB 1 : Cours ───────────────────────────────────────────────
  Widget _tabCours() {
    if (_cours.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Aucun cours créé', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Créer un cours', style: TextStyle(color: Colors.white)),
              onPressed: _creerCours,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cours.length,
        itemBuilder: (_, i) => _buildCoursCard(_cours[i]),
      ),
    );
  }

  Widget _buildCoursCard(Map cours) {
    final taux = (cours['taux_completion'] as num? ?? 0).toDouble();
    final nbApp = cours['nb_apprenants'] ?? 0;
    final ep = cours['enseignant_principal'];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _ouvrirCours(cours),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.book, color: _primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cours['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
                        const SizedBox(height: 2),
                        Text('$nbApp apprenants', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: _primary),
                    tooltip: 'Changer enseignant principal',
                    onPressed: () => _changerEnseignantPrincipal(cours),
                  ),
                ],
              ),
              if (ep != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CircleAvatar(radius: 12, backgroundColor: Color(0xFFE8F4F8),
                        child: Icon(Icons.person, size: 14, color: _primary)),
                    const SizedBox(width: 8),
                    Text('EP : ${ep['nom'] ?? ep['username'] ?? 'Non assigné'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        backgroundColor: Colors.grey.shade100,
                        color: _primary,
                        minHeight: 7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${taux.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TAB 2 : Enseignants Principaux ──────────────────────────────
  Widget _tabEnseignants() {
    if (_enseignantsPrincipaux.isEmpty) {
      return Center(
        child: Text('Aucun enseignant principal assigné',
            style: TextStyle(color: Colors.grey.shade400)),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _enseignantsPrincipaux.length,
        itemBuilder: (_, i) => _buildEnseignantCard(_enseignantsPrincipaux[i]),
      ),
    );
  }

  Widget _buildEnseignantCard(Map ep) {
    final score = (ep['score_moyen'] as num? ?? 0).toDouble();
    final nbCours = ep['nb_cours'] ?? 0;
    final nbApp = ep['nb_apprenants'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _primary.withOpacity(0.1),
              backgroundImage: ep['photo'] != null ? NetworkImage(ep['photo']) : null,
              child: ep['photo'] == null
                  ? Text((ep['nom'] ?? 'E')[0].toUpperCase(),
                      style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ep['nom'] ?? ep['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip('$nbCours cours', Icons.book_outlined, Colors.blue),
                      const SizedBox(width: 8),
                      _chip('$nbApp apprenants', Icons.people_outline, Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text('${score.toStringAsFixed(1)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _primary)),
                const Text('/20', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const Text('moy.', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3 : Statistiques ────────────────────────────────────────
  Widget _tabStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _statsGrid(),
          const SizedBox(height: 20),
          _buildDeptCard(),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final items = [
      _StatInfo('Cours créés', (_stats['nb_cours'] ?? _cours.length).toString(), Icons.book, const Color(0xFF6A1B9A)),
      _StatInfo('Apprenants', (_stats['nb_apprenants'] ?? 0).toString(), Icons.people, const Color(0xFF2884A0)),
      _StatInfo('Enseignants', (_stats['nb_enseignants'] ?? 0).toString(), Icons.person_outline, const Color(0xFF008088)),
      _StatInfo('Taux moyen', '${(_stats['taux_moyen'] ?? 0).toStringAsFixed(0)}%', Icons.bar_chart, const Color(0xFFE65100)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items.map((i) => _buildInfoCard(i)).toList(),
    );
  }

  Widget _buildInfoCard(_StatInfo item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: item.color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: item.color)),
              Text(item.label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeptCard() {
    if (_departement.isEmpty) return const SizedBox();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.8), _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.domain, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Mon Département', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text(_departement['nom'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_departement['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  void _ouvrirCours(Map cours) {
    /*Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterfaceEnseignantPage(
          coursId: cours['id'].toString(),
          role: RoleEnseignant.enseignantCadre,
        ),
      ),
    );*/
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _badge(String text, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
  );

  Widget _chip(String text, IconData icon, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 11, color: color)),
    ],
  );

  Widget _modernField(TextEditingController ctrl, String label, IconData icon, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _primary, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary)),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }
}

// ─────────────────────────────────────────────────────────────────
// Helpers types
// ─────────────────────────────────────────────────────────────────
class _StatInfo {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatInfo(this.label, this.value, this.icon, this.color);
}

class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  const TabBarDelegate(this.tabBar, {this.backgroundColor = Colors.white});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant TabBarDelegate old) => old.tabBar != tabBar;
}
