import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cadre_dashboard_page.dart' show TabBarDelegate;

// ─────────────────────────────────────────────────────────────────
// DASHBOARD ADMIN GÉNÉRAL
// - Vue globale de toutes les statistiques
// - Créer des parcours
// - Nommer un unique enseignant administrateur par parcours
// - Changer l'enseignant administrateur d'un parcours
// ─────────────────────────────────────────────────────────────────

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _primary  = Color(0xFF00897B);
const Color _dark     = Color(0xFF0D1B2A);
const Color _bg       = Color(0xFFF0FAF9);

class AdminGeneralPage extends StatefulWidget {
  const AdminGeneralPage({super.key});

  @override
  State<AdminGeneralPage> createState() => _AdminGeneralPageState();
}

class _AdminGeneralPageState extends State<AdminGeneralPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List _parcours = [];
  List _departements = [];
  List _topEnseignants = [];
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

  // ─── Chargement dashboard ────────────────────────────────────────
  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) { setState(() => _loading = false); return; }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin-general/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _stats          = data['stats'] ?? {};
          _parcours       = data['parcours'] ?? [];
          _departements   = data['departements'] ?? [];
          _topEnseignants = data['top_enseignants'] ?? [];
          _nomEnseignant  = data['nom'] ?? '';
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

  // ─── Créer un parcours ───────────────────────────────────────────
  void _creerParcours() {
    final nomCtrl  = TextEditingController();
    final descCtrl = TextEditingController();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              const Text('Créer un parcours',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _dark)),
              const SizedBox(height: 4),
              const Text(
                'Un enseignant administrateur pourra être nommé à la tête du parcours.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _field(nomCtrl, 'Nom du parcours *', Icons.route, 'Ex: Licence Informatique'),
              const SizedBox(height: 14),
              _field(descCtrl, 'Description', Icons.description_outlined,
                  'Objectifs et contenu du parcours', maxLines: 3),
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
                    if (nomCtrl.text.trim().isEmpty) {
                      _showError('Le nom est obligatoire');
                      return;
                    }
                    setS(() => isLoading = true);
                    final token = await _getToken();
                    try {
                      final res = await http.post(
                        Uri.parse('$_baseUrl/parcours/creer/'),
                        headers: {
                          'Authorization': 'Token $token',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({
                          'nom': nomCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                        }),
                      );
                      setS(() => isLoading = false);
                      if (res.statusCode == 201) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showSuccess('Parcours créé avec succès !');
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Créer',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Nommer / Changer l'enseignant admin d'un parcours ──────────
  void _changerAdmin(Map parcours) async {
    final token = await _getToken();
    if (token == null) return;

    // Charger la liste des enseignants admin disponibles
    List enseignants = [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignants/liste/?role=admin'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        enseignants = jsonDecode(res.body);
      } else {
        _showError('Impossible de charger les enseignants (${res.statusCode})');
        return;
      }
    } catch (_) {
      _showError('Erreur réseau');
      return;
    }

    if (!mounted) return;

    int? selected = parcours['enseignant_admin']?['id'] as int?;

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
                parcours['enseignant_admin'] == null
                    ? 'Nommer un enseignant administrateur'
                    : 'Changer l\'enseignant administrateur',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
              ),
              const SizedBox(height: 4),
              Text(
                'Parcours : ${parcours['nom'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.4),
                child: enseignants.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Aucun enseignant administrateur disponible.\n'
                            'Vérifiez qu\'il existe des comptes avec le rôle "enseignant_admin" actifs.',
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: selected == null ? null : () async {
                    if (ctx.mounted) Navigator.pop(ctx);
                    final token2 = await _getToken();
                    if (token2 == null) return;
                    try {
                      final res = await http.patch(
                        Uri.parse('$_baseUrl/parcours/${parcours['id']}/nommer-admin/'),
                        headers: {
                          'Authorization': 'Token $token2',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode({'enseignant_admin_id': selected}),
                      );
                      if (res.statusCode == 200) {
                        _showSuccess('Enseignant administrateur mis à jour !');
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
        label: const Text('Nouveau parcours', style: TextStyle(color: Colors.white)),
        onPressed: _creerParcours,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [_buildAppBar(), _buildTabBar()],
              body: TabBarView(
                controller: _tabCtrl,
                children: [_tabParcours(), _tabDepartements(), _tabGlobal()],
              ),
            ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00695C), _primary],
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
                  const Text('Tableau de bord global',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _nomEnseignant.isEmpty ? 'Admin Général' : _nomEnseignant,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _badge('Admin Général', Colors.white.withOpacity(0.2)),
                      const SizedBox(width: 8),
                      _badge('Vue complète', Colors.amber.withOpacity(0.3)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _miniStatBadge('${_stats['nb_parcours'] ?? 0}', 'Parcours'),
                      const SizedBox(width: 16),
                      _miniStatBadge('${_stats['nb_departements'] ?? 0}', 'Depts'),
                      const SizedBox(width: 16),
                      _miniStatBadge('${_stats['nb_apprenants'] ?? 0}', 'Apprenants'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text('Admin Général', style: TextStyle(fontSize: 16, color: Colors.white)),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _charger),
      ],
    );
  }

  Widget _miniStatBadge(String val, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(val, style: const TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );

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
            Tab(text: 'Parcours'),
            Tab(text: 'Départements'),
            Tab(text: 'Vue globale'),
          ],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  // ─── TAB 1 : Parcours ────────────────────────────────────────────
  Widget _tabParcours() {
    if (_parcours.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Aucun parcours créé', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Créer un parcours', style: TextStyle(color: Colors.white)),
              onPressed: _creerParcours,
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
        itemCount: _parcours.length,
        itemBuilder: (_, i) => _buildParcoursCard(_parcours[i]),
      ),
    );
  }

  Widget _buildParcoursCard(Map p) {
    final nbDepts = p['nb_departements'] ?? 0;
    final nbApp   = p['nb_apprenants'] ?? 0;
    final admin   = p['enseignant_admin'];
    final taux    = (p['taux_moyen'] as num? ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
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
                  child: const Icon(Icons.route, color: _primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['nom'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: _dark)),
                      const SizedBox(height: 2),
                      Text('$nbDepts départements · $nbApp apprenants',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    admin == null ? Icons.person_add_outlined : Icons.swap_horiz,
                    color: _primary,
                  ),
                  tooltip: admin == null ? 'Nommer un admin' : 'Changer l\'admin',
                  onPressed: () => _changerAdmin(p),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (admin != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 14, color: _primary),
                    const SizedBox(width: 6),
                    Text(
                      'Admin : ${admin['nom'] ?? admin['username'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 12, color: _primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_outlined, size: 14, color: Colors.orange),
                    SizedBox(width: 6),
                    Text('Aucun administrateur nommé',
                        style: TextStyle(fontSize: 12, color: Colors.orange)),
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
                const SizedBox(width: 10),
                Text('${taux.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2 : Départements ────────────────────────────────────────
  Widget _tabDepartements() {
    if (_departements.isEmpty) {
      return Center(
        child: Text('Aucun département', style: TextStyle(color: Colors.grey.shade400)),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departements.length,
        itemBuilder: (_, i) {
          final d    = _departements[i];
          final taux = (d['taux_moyen'] as num? ?? 0).toDouble();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.domain, color: _primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['nom'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        '${d['nb_cours'] ?? 0} cours · ${d['nb_apprenants'] ?? 0} apprenants',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text('${taux.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _primary, fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── TAB 3 : Vue globale ─────────────────────────────────────────
  Widget _tabGlobal() {
    final cards = [
      _GS('Parcours',    '${_stats['nb_parcours'] ?? 0}',    Icons.route,          const Color(0xFF00897B)),
      _GS('Départements','${_stats['nb_departements'] ?? 0}',Icons.domain,          const Color(0xFF1565C0)),
      _GS('Cours',       '${_stats['nb_cours'] ?? 0}',       Icons.book,            const Color(0xFF6A1B9A)),
      _GS('Apprenants',  '${_stats['nb_apprenants'] ?? 0}',  Icons.people,          const Color(0xFF2884A0)),
      _GS('Enseignants', '${_stats['nb_enseignants'] ?? 0}', Icons.person_outline,  const Color(0xFFE65100)),
      _GS('Leçons',      '${_stats['nb_lecons'] ?? 0}',      Icons.play_lesson,     const Color(0xFF008088)),
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
            children: cards.map((c) => _buildGCard(c)).toList(),
          ),
          if (_topEnseignants.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('Top enseignants',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
              ],
            ),
            const SizedBox(height: 12),
            ..._topEnseignants.asMap().entries.map((e) {
              final i = e.key; final t = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['nom'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(t['role'] ?? '',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text('${(t['score'] as num? ?? 0).toStringAsFixed(1)}/20',
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

  Widget _buildGCard(_GS item) {
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

  Widget _badge(String text, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
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

class _GS {
  final String label, value;
  final IconData icon;
  final Color color;
  const _GS(this.label, this.value, this.icon, this.color);
}
