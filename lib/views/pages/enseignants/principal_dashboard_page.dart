// lib/views/pages/enseignants/dashboard_principal_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _primary = Color(0xFF2884A0);
const Color _dark    = Color(0xFF1E293B);
const Color _bg      = Color(0xFFF1F5F9);

class DashboardPrincipalPage extends StatefulWidget {
  final String nomEnseignant;
  final String roleEnseignant;
  final List<dynamic>? extraInfo; // ← cours passés depuis la page parente

  const DashboardPrincipalPage({
    super.key,
    required this.nomEnseignant,
    required this.roleEnseignant,
    this.extraInfo,
  });

  @override
  State<DashboardPrincipalPage> createState() => _DashboardPrincipalPageState();
}

class _DashboardPrincipalPageState extends State<DashboardPrincipalPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;

  // ✅ Même logique que l'ancien : on travaille sur une copie locale
  //    de extraInfo, exactement comme _localExtraInfo dans l'ancien code.
  late List<dynamic> _localExtraInfo;
  List<Map<String, dynamic>> _enseignantsSecondaires = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl       = TabController(length: 3, vsync: this);
    // ✅ Copie défensive — même pattern que l'ancien
    _localExtraInfo = List<dynamic>.from(widget.extraInfo ?? const []);
    _fetchEnseignantsSecondaires();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Auth ──────────────────────────────────────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // ✅ Même helper que l'ancien _asListOfMap
  List<Map<String, dynamic>> _asListOfMap(List<dynamic>? raw) {
    if (raw == null) return [];
    return raw
        .where((e) => e is Map)
        .map<Map<String, dynamic>>(
          (e) => Map<String, dynamic>.from(
            (e as Map).map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList();
  }

  // ── Stats calculées sur _localExtraInfo ──────────────────────────
  Map<String, dynamic> get _stats {
    final cours = _asListOfMap(_localExtraInfo);
    return {
      'nb_cours':      cours.length,
      'nb_lecons':     cours.fold<int>(0, (s, c) => s + _toInt(c['nb_lecons'])),
      'nb_devoirs':    cours.fold<int>(0, (s, c) => s + _toInt(c['nb_devoirs'])),
      'nb_apprenants': cours.fold<int>(0, (s, c) => s + _toInt(c['nb_apprenants'])),
    };
  }

  int _toInt(dynamic v) => (v as num? ?? 0).toInt();

  // ── Chargement enseignants secondaires disponibles ────────────────
  Future<void> _fetchEnseignantsSecondaires() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignants_secondaires/'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          // robuste : accepte List directe ou objet enveloppant
          if (body is List) {
            _enseignantsSecondaires = _asListOfMap(body);
          } else if (body is Map) {
            for (final key in ['results', 'data', 'enseignants']) {
              if (body[key] is List) {
                _enseignantsSecondaires = _asListOfMap(body[key] as List);
                break;
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════
  //  AJOUT enseignant secondaire (multi-select, même logique ancien)
  // ══════════════════════════════════════════════════════════════════
  Future<void> _ajouterEnseignantSecondaire(int coursId) async {
    List<int> selectedIds = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final coursList = _asListOfMap(_localExtraInfo);
          final cours = coursList.firstWhere(
            (c) => c['id'] == coursId,
            orElse: () => {},
          );
          final existants = _asListOfMap(
            (cours['enseignants'] as List?) ?? [],
          ).map((e) => e['id']).toSet();
          final candidats = _enseignantsSecondaires
              .where((e) => !existants.contains(e['id']))
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.72,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Text('Assigner des assistants',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _dark)),
              Text('${candidats.length} enseignant(s) disponible(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              Expanded(
                child: candidats.isEmpty
                    ? const Center(
                        child: Text('Tous les enseignants sont déjà assignés.'))
                    : ListView.builder(
                        itemCount: candidats.length,
                        itemBuilder: (_, i) {
                          final ens       = candidats[i];
                          final isSelected = selectedIds.contains(ens['id']);
                          final username  =
                              ens['user']?['username'] ?? ens['username'] ?? '';
                          final email =
                              ens['user']?['email'] ?? ens['email'] ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primary.withOpacity(0.07)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? _primary.withOpacity(0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: CheckboxListTile(
                              activeColor: _primary,
                              checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              title: Text(username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              subtitle: Text(email,
                                  style: const TextStyle(fontSize: 12)),
                              value: isSelected,
                              onChanged: (v) => setS(() {
                                if (v == true) {
                                  selectedIds.add(ens['id'] as int);
                                } else {
                                  selectedIds.remove(ens['id']);
                                }
                              }),
                            ),
                          );
                        },
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: selectedIds.isEmpty || _isLoading
                      ? null
                      : () async {
                          setS(() => _isLoading = true);
                          final headers = await _authHeaders();
                          bool success = true;

                          for (final id in selectedIds) {
                            try {
                              final res = await http.post(
                                Uri.parse(
                                    '$_baseUrl/cours/$coursId/add-enseignant/'),
                                headers: headers,
                                body: jsonEncode({'enseignant_id': id}),
                              );
                              if (res.statusCode != 200 &&
                                  res.statusCode != 201) {
                                success = false;
                              }
                            } catch (_) {
                              success = false;
                            }
                          }

                          // ✅ Mise à jour locale immédiate (même logique ancien)
                          if (success) {
                            setState(() {
                              for (var c in _localExtraInfo) {
                                if ((c as Map)['id'] == coursId) {
                                  final List sec = List.from(
                                      c['enseignants'] as List? ?? []);
                                  for (final id in selectedIds) {
                                    final added = _enseignantsSecondaires
                                        .firstWhere((e) => e['id'] == id,
                                            orElse: () => {});
                                    if (added.isNotEmpty) sec.add(added);
                                  }
                                  c['enseignants'] = sec;
                                }
                              }
                            });
                            _showSuccess('Enseignant(s) ajouté(s) avec succès !');
                          } else {
                            _showError('Certains ajouts ont échoué.');
                          }

                          setS(() => _isLoading = false);
                          if (mounted) Navigator.pop(ctx);
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Ajouter ${selectedIds.length} sélection(s)',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  RETRAIT enseignant secondaire
  // ══════════════════════════════════════════════════════════════════
  Future<void> _retirerEnseignant(
      int coursId, int enseignantId, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Retirer l'assistant"),
        content: Text('Voulez-vous retirer "$nom" de ce cours ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final headers = await _authHeaders();
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/cours/$coursId/remove-enseignant/'),
        headers: headers,
        body: jsonEncode({'enseignant_id': enseignantId}),
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        // ✅ Mise à jour locale immédiate
        setState(() {
          for (var c in _localExtraInfo) {
            if ((c as Map)['id'] == coursId) {
              final List sec = List.from(c['enseignants'] as List? ?? []);
              sec.removeWhere((e) =>
                  (e is Map ? e['id'] : e) == enseignantId);
              c['enseignants'] = sec;
            }
          }
        });
        _showSuccess('Enseignant retiré avec succès.');
      } else {
        final err = jsonDecode(res.body);
        _showError(err['detail'] ?? 'Erreur lors du retrait.');
      }
    } catch (_) {
      _showError('Erreur réseau.');
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildAppBar(),
          _buildTabBar(),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [_tabCours(), _tabSuivi(), _tabStats()],
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    final stats = _stats;
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A5276), _primary],
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
                  const Text('Tableau de bord',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    widget.nomEnseignant.isEmpty
                        ? 'Enseignant Principal'
                        : widget.nomEnseignant,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _roleBadge('Enseignant Principal'),
                  const SizedBox(height: 10),
                  Row(children: [
                    _miniStatBadge(
                        '${stats['nb_cours']}', 'cours', Icons.book),
                    const SizedBox(width: 12),
                    _miniStatBadge(
                        '${stats['nb_apprenants']}', 'apprenants', Icons.people),
                    const SizedBox(width: 12),
                    _miniStatBadge(
                        '${stats['nb_lecons']}', 'leçons', Icons.article),
                  ]),
                ],
              ),
            ),
          ),
        ),
        title: const Text('Dashboard Principal',
            style: TextStyle(fontSize: 16, color: Colors.white)),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _fetchEnseignantsSecondaires,
        ),
      ],
    );
  }

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          labelColor: _primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primary,
          tabs: const [
            Tab(text: 'Mes Cours'),
            Tab(text: 'Suivi'),
            Tab(text: 'Statistiques'),
          ],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  // ── TAB 1 : Cours ────────────────────────────────────────────────
  Widget _tabCours() {
    final cours = _asListOfMap(_localExtraInfo);
    if (cours.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.book_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Aucun cours assigné',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: cours.map(_buildCoursCard).toList(),
    );
  }

  Widget _buildCoursCard(Map<String, dynamic> c) {
    final assistants = _asListOfMap(c['enseignants'] as List?);
    final int lecons     = _toInt(c['nb_lecons']);
    final int devoirs    = _toInt(c['nb_devoirs']);
    final int apprenants = _toInt(c['nb_apprenants']);
    final Color cardColor =
        _hexColor(c['color_code'] as String? ?? '#2884A0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(children: [
        // ── Header coloré ──────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.12),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.book, color: cardColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['titre'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _dark)),
                    Text(c['niveau'] ?? '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ]),
            ),
          ]),
        ),
        // ── Badges stats ───────────────────────────────────────
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            _badge2(Icons.article,    '$lecons Leçons',    Colors.blue),
            const SizedBox(width: 8),
            _badge2(Icons.assignment, '$devoirs Devoirs',  Colors.orange),
            const SizedBox(width: 8),
            _badge2(Icons.people,     '$apprenants Élèves', Colors.teal),
          ]),
        ),
        // ── Équipe (expansible) ────────────────────────────────
        Theme(
          data:
              Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              'Équipe (${assistants.length} assistant(s))',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
            leading:
                Icon(Icons.people_outline, color: cardColor, size: 20),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (assistants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aucun assistant assigné.',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ),
              ...assistants.map((e) {
                final username =
                    e['user']?['username'] ?? e['username'] ?? 'Assistant';
                final email =
                    e['user']?['email'] ?? e['email'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _primary.withOpacity(0.1),
                      child: Text(
                        username.isNotEmpty
                            ? username[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            if (email.isNotEmpty)
                              Text(email,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey)),
                          ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red, size: 20),
                      tooltip: 'Retirer',
                      onPressed: () => _retirerEnseignant(
                          c['id'] as int,
                          e['id'] as int,
                          username),
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _ajouterEnseignantSecondaire(c['id'] as int),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter un assistant'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: BorderSide(color: _primary.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── TAB 2 : Suivi ────────────────────────────────────────────────
  Widget _tabSuivi() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Suivi des Devoirs & Rendus'),
        const SizedBox(height: 12),
        _buildHomeworkAnalytics(),
        const SizedBox(height: 24),
        _sectionTitle('Élèves à surveiller'),
        const SizedBox(height: 12),
        _buildAtRiskStudents(),
        const SizedBox(height: 24),
        _sectionTitle('Taux de rendu global'),
        const SizedBox(height: 12),
        _buildKPIRow(),
      ],
    );
  }

  Widget _buildKPIRow() {
    return Row(children: [
      _kpiCard('Rendu',   '88%',  Icons.assignment_turned_in, Colors.green),
      const SizedBox(width: 12),
      _kpiCard('Moyenne', '14.2', Icons.analytics,            _primary),
      const SizedBox(width: 12),
      _kpiCard('Retards', '05',   Icons.timer_outlined,       Colors.orange),
    ]);
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
      );

  Widget _buildHomeworkAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _homeworkRow('Mathématiques : Matrices', 0.75, '22/30 élèves'),
        const Divider(height: 28),
        _homeworkRow('Physique : Dynamique', 0.40, '12/30 élèves'),
      ]),
    );
  }

  Widget _homeworkRow(String title, double progress, String detail) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        Text(detail,
            style: TextStyle(
                fontSize: 12,
                color: _primary,
                fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: _bg,
          color: progress > 0.5 ? _primary : Colors.orange,
        ),
      ),
    ]);
  }

  Widget _buildAtRiskStudents() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _riskTile('Awa Diop', '3 retards consécutifs', Colors.red),
        _riskTile('Kevin N.', 'Moyenne en baisse',      Colors.orange),
      ]),
    );
  }

  Widget _riskTile(String name, String reason, Color color) => ListTile(
    leading: CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Text(name[0],
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold)),
    ),
    title: Text(name,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600)),
    subtitle:
        Text(reason, style: const TextStyle(fontSize: 12)),
    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
  );

  // ── TAB 3 : Statistiques ─────────────────────────────────────────
  Widget _tabStats() {
    final stats = _stats;
    final items = [
      _StatInfo('Cours',      '${stats['nb_cours']}',      Icons.book,                const Color(0xFF2884A0)),
      _StatInfo('Apprenants', '${stats['nb_apprenants']}', Icons.people,              const Color(0xFF6A1B9A)),
      _StatInfo('Leçons',     '${stats['nb_lecons']}',     Icons.article,             const Color(0xFF00897B)),
      _StatInfo('Devoirs',    '${stats['nb_devoirs']}',    Icons.assignment_outlined, const Color(0xFFE65100)),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: items.map(_buildStatCard).toList(),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Performance globale'),
        const SizedBox(height: 12),
        _buildPerformanceCard(),
      ]),
    );
  }

  Widget _buildStatCard(_StatInfo item) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
            color: item.color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4)),
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
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: item.color)),
          Text(item.label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ],
    ),
  );

  Widget _buildPerformanceCard() {
    final stats = _stats;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.85), _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.bar_chart, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Résumé de vos cours',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _perfItem('${stats['nb_cours']}',   'Cours actifs')),
          Expanded(
              child: _perfItem('${stats['nb_lecons']}',  'Leçons publiées')),
          Expanded(
              child: _perfItem('${stats['nb_devoirs']}', 'Devoirs créés')),
        ]),
      ]),
    );
  }

  Widget _perfItem(String value, String label) => Column(children: [
    Text(value,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold)),
    Text(label,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
        textAlign: TextAlign.center),
  ]);

  // ── Helpers ──────────────────────────────────────────────────────
  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _primary;
    }
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _roleBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20)),
    child: Text(text,
        style: const TextStyle(color: Colors.white, fontSize: 12)),
  );

  Widget _miniStatBadge(String value, String label, IconData icon) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 5),
          Text('$value $label',
              style: const TextStyle(
                  color: Colors.white, fontSize: 11)),
        ]),
      );

  Widget _badge2(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: _dark));

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

// ─────────────────────────────────────────────────────────────────
// Helpers classes
// ─────────────────────────────────────────────────────────────────
class _StatInfo {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatInfo(this.label, this.value, this.icon, this.color);
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  const _TabBarDelegate(this.tabBar, {this.backgroundColor = Colors.white});

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) =>
      Container(color: backgroundColor, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => old.tabBar != tabBar;
}
