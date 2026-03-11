import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cadre_dashboard_page.dart' show TabBarDelegate;

// ─────────────────────────────────────────────────────────────────
// DASHBOARD ENSEIGNANT ADMINISTRATEUR
// - Vue sur tous ses départements (parcours assigné)
// - Créer un département (sur son parcours seulement)
// - Nommer / changer l'enseignant cadre d'un département
// ─────────────────────────────────────────────────────────────────

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _primary  = Color(0xFF1565C0);
const Color _dark     = Color(0xFF0D1B2A);
const Color _bg       = Color(0xFFF4F7FB);

class AdminEnseignantDashboardPage extends StatefulWidget {
  const AdminEnseignantDashboardPage({super.key});

  @override
  State<AdminEnseignantDashboardPage> createState() =>
      _AdminEnseignantDashboardPageState();
}

class _AdminEnseignantDashboardPageState
    extends State<AdminEnseignantDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List _departements = [];
  List _cadres = [];
  String _nomEnseignant = '';
  // Pour la sélection du parcours lors de la création d'un département
  List _parcours = [];
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

  // ─── Chargement dashboard ────────────────────────────────────────
  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) { setState(() => _loading = false); return; }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignant/admin/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Extraire la liste des parcours uniques depuis les départements
        final depts = (data['departements'] as List? ?? []);
        final parcoursMap = <int, Map>{};
        for (final d in depts) {
          final pid = d['parcours_id'] as int?;
          if (pid != null && !parcoursMap.containsKey(pid)) {
            parcoursMap[pid] = {'id': pid, 'nom': d['parcours']};
          }
        }
        setState(() {
          _stats          = data['stats'] ?? {};
          _departements   = depts;
          _cadres         = data['cadres'] ?? [];
          _nomEnseignant  = data['nom'] ?? '';
          _parcours       = parcoursMap.values.toList();
          _loading        = false;
        });
      } else {
        setState(() => _loading = false);
        _showError('Erreur chargement (${res.statusCode})');
      }
    } catch (_) {
      setState(() => _loading = false);
      _showError('Erreur réseau');
    }
  }

  // ─── Créer un département ────────────────────────────────────────
  void _creerDepartement() {
    final nomCtrl  = TextEditingController();
    final descCtrl = TextEditingController();
    bool isLoading = false;
    // Sélection du parcours si plusieurs
    Map? selectedParcours = _parcours.length == 1 ? _parcours.first as Map : null;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              const Text('Créer un département',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: _dark)),
              const SizedBox(height: 20),
              // Sélecteur de parcours si plusieurs parcours assignés
              if (_parcours.length > 1) ...[
                DropdownButtonFormField<Map>(
                  value: selectedParcours,
                  decoration: InputDecoration(
                    labelText: 'Parcours *',
                    prefixIcon: const Icon(Icons.route, color: _primary, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _primary)),
                  ),
                  items: _parcours
                      .map((p) => DropdownMenuItem<Map>(
                            value: p as Map,
                            child: Text(p['nom'] ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setS(() => selectedParcours = v),
                ),
                const SizedBox(height: 14),
              ] else if (_parcours.length == 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route, color: _primary, size: 16),
                      const SizedBox(width: 8),
                      Text('Parcours : ${_parcours.first['nom']}',
                          style: const TextStyle(color: _primary, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _field(nomCtrl, 'Nom du département *', Icons.domain, 'Ex: Mathématiques'),
              const SizedBox(height: 14),
              _field(descCtrl, 'Description', Icons.description_outlined,
                  'Domaine et objectifs', maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: isLoading ? null : () async {
                    if (nomCtrl.text.trim().isEmpty) {
                      _showError('Le nom est obligatoire');
                      return;
                    }
                    if (_parcours.length > 1 && selectedParcours == null) {
                      _showError('Veuillez sélectionner un parcours');
                      return;
                    }
                    setS(() => isLoading = true);
                    final token = await _getToken();
                    if (token == null) { setS(() => isLoading = false); return; }
                    try {
                      final body = <String, dynamic>{
                        'nom': nomCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                      };
                      // Ajouter parcours_id si plusieurs parcours
                      if (selectedParcours != null) {
                        body['parcours_id'] = selectedParcours!['id'];
                      }
                      final res = await http.post(
                        Uri.parse('$_baseUrl/departements/creer/'),
                        headers: {
                          'Authorization': 'Token $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(body),
                      );
                      setS(() => isLoading = false);
                      if (res.statusCode == 201) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showSuccess('Département créé avec succès !');
                        _charger();
                      } else {
                        final err = jsonDecode(res.body);
                        _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
                      }
                    } catch (_) {
                      setS(() => isLoading = false);
                      _showError('Erreur réseau');
                    }
                  },
                  child: isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Créer',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Nommer / Changer le cadre d'un département ──────────────────
  void _changerCadre(Map dept) async {
    final token = await _getToken();
    if (token == null) return;

    List enseignants = [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignants/liste/?role=cadre'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        enseignants = jsonDecode(res.body);
      } else {
        _showError('Impossible de charger les cadres (${res.statusCode})');
        return;
      }
    } catch (_) {
      _showError('Erreur réseau');
      return;
    }

    if (!mounted) return;

    // Présélectionner le cadre actuel si existant
    int? selected = dept['cadre']?['id'] as int?;

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
              Text(
                dept['cadre'] == null
                    ? 'Nommer un enseignant cadre'
                    : 'Changer l\'enseignant cadre',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
              ),
              const SizedBox(height: 4),
              Text('Département : ${dept['nom'] ?? ''}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: enseignants.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Aucun enseignant cadre disponible.\n'
                            'Vérifiez qu\'il existe des comptes avec le rôle "enseignant_cadre" actifs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: enseignants.map<Widget>((e) => RadioListTile<int>(
                          value: e['id'] as int,
                          groupValue: selected,
                          activeColor: _primary,
                          title: Text(e['nom'] ?? e['username'] ?? ''),
                          subtitle: Text(e['email'] ?? ''),
                          onChanged: (v) => setS(() => selected = v),
                        )).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: selected == null ? null : () async {
                    if (ctx.mounted) Navigator.pop(ctx);
                    final token2 = await _getToken();
                    if (token2 == null) return;
                    try {
                      final res = await http.patch(
                        Uri.parse(
                            '$_baseUrl/departements/${dept['id']}/changer-cadre/'),
                        headers: {
                          'Authorization': 'Token $token2',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({'cadre_id': selected}),
                      );
                      if (res.statusCode == 200) {
                        _showSuccess('Cadre modifié avec succès !');
                        _charger();
                      } else {
                        final err = jsonDecode(res.body);
                        _showError(err['detail'] ?? 'Erreur ${res.statusCode}');
                      }
                    } catch (_) {
                      _showError('Erreur réseau');
                    }
                  },
                  child: const Text('Confirmer',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau département', style: TextStyle(color: Colors.white)),
        onPressed: _creerDepartement,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [_buildAppBar(), _buildTabBar()],
              body: TabBarView(
                controller: _tabCtrl,
                children: [_tabDepartements(), _tabCadres(), _tabStats()],
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
              colors: [Color(0xFF0D47A1), _primary],
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
                  const Text('Tableau de bord administrateur',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _nomEnseignant.isEmpty
                        ? 'Enseignant Administrateur'
                        : _nomEnseignant,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Enseignant Administrateur',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  // Parcours assignés
                  if (_parcours.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _parcours.map((p) => p['nom']).join(', '),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        title: const Text('Dashboard Admin',
            style: TextStyle(fontSize: 16, color: Colors.white)),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _charger),
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
            Tab(text: 'Départements'),
            Tab(text: 'Cadres'),
            Tab(text: 'Vue globale'),
          ],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  // ─── TAB 1 : Départements ────────────────────────────────────────
  Widget _tabDepartements() {
    if (_departements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.domain_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Aucun département créé',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Créer un département',
                  style: TextStyle(color: Colors.white)),
              onPressed: _creerDepartement,
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
        itemCount: _departements.length,
        itemBuilder: (_, i) => _buildDeptCard(_departements[i] as Map),
      ),
    );
  }

  Widget _buildDeptCard(Map dept) {
    final nbCours = dept['nb_cours'] ?? 0;
    final nbApp   = dept['nb_apprenants'] ?? 0;
    final cadre   = dept['cadre'];
    final taux    = (dept['taux_moyen'] as num? ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _voirDetailDepartement(dept),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.domain, color: _primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dept['nom'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _dark)),
                        const SizedBox(height: 2),
                        Text('$nbCours cours · $nbApp apprenants',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      cadre == null ? Icons.person_add_outlined : Icons.swap_horiz,
                      color: _primary,
                    ),
                    tooltip: cadre == null ? 'Nommer un cadre' : 'Changer cadre',
                    onPressed: () => _changerCadre(dept),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              if (cadre != null)
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 11,
                      backgroundColor: Color(0xFFEDE7F6),
                      child: Icon(Icons.person, size: 14, color: Color(0xFF6A1B9A)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cadre : ${cadre['nom'] ?? cadre['username'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_outlined, size: 13, color: Colors.orange),
                      SizedBox(width: 5),
                      Text('Aucun cadre nommé',
                          style: TextStyle(fontSize: 11, color: Colors.orange)),
                    ],
                  ),
                ),
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
                  const SizedBox(width: 8),
                  Text('${taux.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _voirDetailDepartement(Map dept) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DetailDeptSheet(dept: dept),
    );
  }

  // ─── TAB 2 : Cadres ──────────────────────────────────────────────
  Widget _tabCadres() {
    if (_cadres.isEmpty) {
      return Center(
        child: Text('Aucun enseignant cadre',
            style: TextStyle(color: Colors.grey.shade400)),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cadres.length,
        itemBuilder: (_, i) => _buildCadreCard(_cadres[i] as Map),
      ),
    );
  }

  Widget _buildCadreCard(Map cadre) {
    final nbCours = cadre['nb_cours'] ?? 0;
    final nbApp   = cadre['nb_apprenants'] ?? 0;
    final taux    = (cadre['taux_moyen'] as num? ?? 0).toDouble();
    final dept    = cadre['departement'];

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
              backgroundColor: const Color(0xFFEDE7F6),
              backgroundImage: cadre['photo'] != null
                  ? NetworkImage(cadre['photo'])
                  : null,
              child: cadre['photo'] == null
                  ? Text(
                      (cadre['nom'] ?? 'C')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF6A1B9A),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cadre['nom'] ?? cadre['username'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15, color: _dark),
                  ),
                  const SizedBox(height: 3),
                  if (dept != null)
                    Text(dept['nom'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6A1B9A))),
                  const SizedBox(height: 4),
                  Text('$nbCours cours · $nbApp apprenants',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              children: [
                Text('${taux.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primary)),
                const Text('taux',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3 : Vue globale ─────────────────────────────────────────
  Widget _tabStats() {
    final items = [
      _SI('Départements', '${_stats['nb_departements'] ?? _departements.length}',
          Icons.domain,        const Color(0xFF1565C0)),
      _SI('Cours totaux',  '${_stats['nb_cours'] ?? 0}',
          Icons.book,          const Color(0xFF6A1B9A)),
      _SI('Apprenants',    '${_stats['nb_apprenants'] ?? 0}',
          Icons.people,        const Color(0xFF008088)),
      _SI('Enseignants',   '${_stats['nb_enseignants'] ?? 0}',
          Icons.person_outline, const Color(0xFFE65100)),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: items.map((i) => _buildStatCard(i)).toList(),
          ),
          const SizedBox(height: 20),
          if (_departements.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.leaderboard, color: _primary, size: 18),
                SizedBox(width: 8),
                Text('Classement des départements',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
              ],
            ),
            const SizedBox(height: 12),
            ..._departements.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final taux = (d['taux_moyen'] as num? ?? 0).toDouble();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? Colors.amber
                            : i == 1
                                ? Colors.grey.shade300
                                : Colors.brown.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(d['nom'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text('${taux.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: _primary)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(_SI item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: item.color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: item.color)),
              Text(item.label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  Widget _sheetHandle() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(
          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint,
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary)),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }
}

// ─── Sheet détail département ─────────────────────────────────────
class _DetailDeptSheet extends StatefulWidget {
  final Map dept;
  const _DetailDeptSheet({required this.dept});

  @override
  State<_DetailDeptSheet> createState() => _DetailDeptSheetState();
}

class _DetailDeptSheetState extends State<_DetailDeptSheet> {
  List _cours = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerCours();
  }

  Future<void> _chargerCours() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString('token');
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/departements/${widget.dept['id']}/cours/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _cours   = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.dept['nom'] ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: _dark)),
                if (widget.dept['cadre'] != null)
                  Text(
                    'Cadre : ${widget.dept['cadre']['nom'] ?? ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary))
                : _cours.isEmpty
                    ? const Center(
                        child: Text('Aucun cours dans ce département'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _cours.length,
                        itemBuilder: (_, i) {
                          final c    = _cours[i];
                          final taux = (c['taux_completion'] as num? ?? 0).toDouble();
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.book,
                                  color: _primary, size: 20),
                            ),
                            title: Text(c['titre'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${c['nb_apprenants'] ?? 0} apprenants '
                              '· ${taux.toStringAsFixed(0)}% complétion',
                            ),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.grey),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SI {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SI(this.label, this.value, this.icon, this.color);
}
