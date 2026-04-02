import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────
// PAGE HISTORIQUE  — Enseignants
// Connectée à GET /api/historique/  et  GET /api/historique/stats/
// ─────────────────────────────────────────────────────────────────

const String _hBaseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _hPrimary = Color(0xFF2884A0);
const Color _hBg = Color(0xFFF1F5F9);
const Color _hDark = Color(0xFF1E293B);

// ── Mapping action → icône / couleur / label ──────────────────────
const Map<String, Map<String, dynamic>> _actionMeta = {
  'course_created':    {'icon': Icons.add_circle_outline,    'color': Color(0xFF2E7D32), 'cat': 'cours'},
  'course_modified':   {'icon': Icons.edit_outlined,          'color': Color(0xFF1565C0), 'cat': 'cours'},
  'course_deleted':    {'icon': Icons.delete_outline,         'color': Color(0xFFC62828), 'cat': 'cours'},
  'teacher_assigned':  {'icon': Icons.person_add_outlined,    'color': Color(0xFFE65100), 'cat': 'enseignants'},
  'teacher_changed':   {'icon': Icons.swap_horiz,             'color': Color(0xFFE65100), 'cat': 'enseignants'},
  'secondary_added':   {'icon': Icons.group_add_outlined,     'color': Color(0xFF00838F), 'cat': 'enseignants'},
  'secondary_removed': {'icon': Icons.group_remove_outlined,  'color': Color(0xFFAD1457), 'cat': 'enseignants'},
  'module_created':    {'icon': Icons.folder_outlined,        'color': Color(0xFF6A1B9A), 'cat': 'modules'},
  'module_modified':   {'icon': Icons.folder_open_outlined,   'color': Color(0xFF4527A0), 'cat': 'modules'},
  'module_deleted':    {'icon': Icons.folder_delete_outlined, 'color': Color(0xFFC62828), 'cat': 'modules'},
  'lesson_created':    {'icon': Icons.article_outlined,       'color': Color(0xFF00695C), 'cat': 'lecons'},
  'lesson_modified':   {'icon': Icons.edit_note_outlined,     'color': Color(0xFF00695C), 'cat': 'lecons'},
  'lesson_deleted':    {'icon': Icons.delete_sweep_outlined,  'color': Color(0xFFC62828), 'cat': 'lecons'},
  'homework_created':  {'icon': Icons.assignment_outlined,    'color': Color(0xFF558B2F), 'cat': 'devoirs'},
  'homework_modified': {'icon': Icons.assignment_late_outlined,'color': Color(0xFF558B2F), 'cat': 'devoirs'},
  'homework_graded':   {'icon': Icons.grading_outlined,       'color': Color(0xFF558B2F), 'cat': 'devoirs'},
  'exercise_created':  {'icon': Icons.quiz_outlined,          'color': Color(0xFF283593), 'cat': 'exercices'},
  'question_added':    {'icon': Icons.help_outline,           'color': Color(0xFF283593), 'cat': 'exercices'},
  'olympiad_created':  {'icon': Icons.emoji_events_outlined,  'color': Color(0xFFBF360C), 'cat': 'olympiades'},
  'olympiad_closed':   {'icon': Icons.event_busy_outlined,    'color': Color(0xFFBF360C), 'cat': 'olympiades'},
  'ranking_computed':  {'icon': Icons.leaderboard_outlined,   'color': Color(0xFFBF360C), 'cat': 'olympiades'},
  'department_created':{'icon': Icons.domain_add_outlined,    'color': Color(0xFF00695C), 'cat': 'departements'},
  'cadre_assigned':    {'icon': Icons.supervisor_account_outlined, 'color': Color(0xFF006064), 'cat': 'departements'},
  'submission_graded': {'icon': Icons.done_all,               'color': Color(0xFF2E7D32), 'cat': 'corrections'},
};

Map<String, dynamic> _getMeta(String action) =>
    _actionMeta[action] ??
    {'icon': Icons.history, 'color': Colors.grey.shade500, 'cat': 'autre'};

// ── Catégories pour le filtre ─────────────────────────────────────
const List<_HFilter> _filters = [
  _HFilter(key: '',             label: 'Tout',         icon: Icons.apps),
  _HFilter(key: 'cours',        label: 'Cours',        icon: Icons.book_outlined),
  _HFilter(key: 'modules',      label: 'Modules',      icon: Icons.folder_outlined),
  _HFilter(key: 'lecons',       label: 'Leçons',       icon: Icons.article_outlined),
  _HFilter(key: 'devoirs',      label: 'Devoirs',      icon: Icons.assignment_outlined),
  _HFilter(key: 'exercices',    label: 'Exercices',    icon: Icons.quiz_outlined),
  _HFilter(key: 'olympiades',   label: 'Olympiades',   icon: Icons.emoji_events_outlined),
  _HFilter(key: 'enseignants',  label: 'Enseignants',  icon: Icons.people_outlined),
  _HFilter(key: 'departements', label: 'Départements', icon: Icons.domain_outlined),
  _HFilter(key: 'corrections',  label: 'Corrections',  icon: Icons.grading_outlined),
];

class _HFilter {
  final String key;
  final String label;
  final IconData icon;
  const _HFilter({required this.key, required this.label, required this.icon});
}

// ═══════════════════════════════════════════════════════════════════
//  PAGE PRINCIPALE
// ═══════════════════════════════════════════════════════════════════
class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _loadingStats = true;
  String _error = '';

  List<Map<String, dynamic>> _activites = [];
  Map<String, dynamic> _stats = {};

  String _selectedCategory = '';
  String _selectedPeriode = '';   // '', 'semaine', 'mois'

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _chargerTout();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // ── Chargement ───────────────────────────────────────────────────
  Future<void> _chargerTout() async {
    await Future.wait([_chargerActivites(), _chargerStats()]);
  }

  Future<void> _chargerActivites() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final headers = await _authHeaders();

      final params = <String, String>{};
      if (_selectedCategory.isNotEmpty) params['category'] = _selectedCategory;

      if (_selectedPeriode == 'semaine') {
        final depuis = DateTime.now().subtract(const Duration(days: 7));
        params['depuis'] = DateFormat('yyyy-MM-dd').format(depuis);
      } else if (_selectedPeriode == 'mois') {
        final depuis = DateTime(DateTime.now().year, DateTime.now().month, 1);
        params['depuis'] = DateFormat('yyyy-MM-dd').format(depuis);
      }

      params['limit'] = '150';

      final uri = Uri.parse('$_hBaseUrl/historique/').replace(queryParameters: params);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _activites = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
        _animCtrl.reset();
        _animCtrl.forward();
      } else {
        setState(() => _error = 'Erreur ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Erreur réseau');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _chargerStats() async {
    setState(() => _loadingStats = true);
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$_hBaseUrl/historique/stats/'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        setState(() => _stats = Map<String, dynamic>.from(jsonDecode(res.body)));
      }
    } catch (_) {}
    finally {
      setState(() => _loadingStats = false);
    }
  }

  // ── Grouper les activités par date ───────────────────────────────
  Map<String, List<Map<String, dynamic>>> _grouperParDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final a in _activites) {
      final ts = a['timestamp'];
      if (ts == null) continue;
      try {
        final dt = DateTime.parse(ts.toString()).toLocal();
        final key = _labelDate(dt);
        grouped.putIfAbsent(key, () => []).add(a);
      } catch (_) {}
    }
    return grouped;
  }

  String _labelDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(dtDay).inDays;

    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    if (diff < 7) return 'Cette semaine';
    if (dt.month == now.month && dt.year == now.year) return 'Ce mois';
    return DateFormat('MMMM yyyy', 'fr_FR').format(dt);
  }

  // ── Formater le timestamp ────────────────────────────────────────
  String _formatTime(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return DateFormat('dd/MM à HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _hBg,
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(),
        ],
        body: Column(
          children: [
            _buildFilterRow(),
            _buildPeriodeRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: _hPrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _chargerTout,
          tooltip: 'Actualiser',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A5276), _hPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_outlined, color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'HISTORIQUE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mes activités',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Bandeaux stats ────────────────────────────
                  _loadingStats
                      ? const SizedBox(
                          height: 28,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white54,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            _statBadge(
                              '${_stats['total'] ?? 0}',
                              'au total',
                              Icons.timeline,
                            ),
                            const SizedBox(width: 10),
                            _statBadge(
                              '${_stats['cette_semaine'] ?? 0}',
                              'cette semaine',
                              Icons.date_range,
                            ),
                            const SizedBox(width: 10),
                            _statBadge(
                              '${_stats['ce_mois'] ?? 0}',
                              'ce mois',
                              Icons.calendar_month,
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
        title: const Text(
          'Historique',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
      ),
    );
  }

  Widget _statBadge(String count, String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              '$count $label',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  // ── Filtre catégories ────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: _filters.map((f) {
            final isSelected = _selectedCategory == f.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = f.key);
                    _chargerActivites();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _hPrimary
                          : _hPrimary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _hPrimary
                            : _hPrimary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          f.icon,
                          size: 14,
                          color: isSelected ? Colors.white : _hPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : _hPrimary,
                          ),
                        ),
                        // Badge comptage
                        if (!_loadingStats &&
                            f.key.isNotEmpty &&
                            (_stats['categories'] as Map<String, dynamic>?)?[f.key] != null &&
                            ((_stats['categories'] as Map<String, dynamic>)[f.key] as int) > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.3)
                                  : _hPrimary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(_stats['categories'] as Map<String, dynamic>)[f.key]}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Filtre période ───────────────────────────────────────────────
  Widget _buildPeriodeRow() {
    final periodes = [
      ('', 'Tout'),
      ('semaine', '7 jours'),
      ('mois', 'Ce mois'),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
      child: Row(
        children: [
          const Text(
            'Période :',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          ...periodes.map((p) {
            final isSelected = _selectedPeriode == p.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedPeriode = p.$1);
                  _chargerActivites();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _hDark
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    p.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          // Compteur résultats
          if (!_loading)
            Text(
              '${_activites.length} résultat${_activites.length > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  // ── Corps principal ──────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _hPrimary),
      );
    }

    if (_error.isNotEmpty) {
      return _buildErrorState();
    }

    if (_activites.isEmpty) {
      return _buildEmptyState();
    }

    final grouped = _grouperParDate();

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: _chargerTout,
        color: _hPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          children: [
            // ── Graphique résumé par catégorie ─────────────────
            if (_stats.isNotEmpty && _selectedCategory.isEmpty)
              _buildCategoryGrid(),
            if (_stats.isNotEmpty && _selectedCategory.isEmpty)
              const SizedBox(height: 16),

            // ── Activités groupées par date ────────────────────
            for (final entry in grouped.entries) ...[
              _buildDateHeader(entry.key),
              ...entry.value.map((a) => _buildActiviteCard(a)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Grille résumé catégories ─────────────────────────────────────
  Widget _buildCategoryGrid() {
    final cats = _stats['categories'] as Map<String, dynamic>? ?? {};
    final nonZero = cats.entries.where((e) => (e.value as int) > 0).toList();
    if (nonZero.isEmpty) return const SizedBox();

    final catMeta = {
      'cours':        {'icon': Icons.book_outlined,         'color': Color(0xFF1565C0), 'label': 'Cours'},
      'modules':      {'icon': Icons.folder_outlined,       'color': Color(0xFF6A1B9A), 'label': 'Modules'},
      'lecons':       {'icon': Icons.article_outlined,      'color': Color(0xFF00695C), 'label': 'Leçons'},
      'devoirs':      {'icon': Icons.assignment_outlined,   'color': Color(0xFF558B2F), 'label': 'Devoirs'},
      'exercices':    {'icon': Icons.quiz_outlined,         'color': Color(0xFF283593), 'label': 'Exercices'},
      'olympiades':   {'icon': Icons.emoji_events_outlined, 'color': Color(0xFFBF360C), 'label': 'Olympiades'},
      'enseignants':  {'icon': Icons.people_outlined,       'color': Color(0xFFE65100), 'label': 'Enseignants'},
      'departements': {'icon': Icons.domain_outlined,       'color': Color(0xFF006064), 'label': 'Dépts'},
      'corrections':  {'icon': Icons.grading_outlined,      'color': Color(0xFF2E7D32), 'label': 'Corrections'},
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition de vos activités',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _hDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nonZero.map((entry) {
              final meta = catMeta[entry.key] ?? {'icon': Icons.circle, 'color': Colors.grey, 'label': entry.key};
              final color = meta['color'] as Color;
              final icon = meta['icon'] as IconData;
              final label = meta['label'] as String;
              final count = entry.value as int;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = entry.key);
                  _chargerActivites();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Séparateur de date ───────────────────────────────────────────
  Widget _buildDateHeader(String label) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _hPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _hPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),
          ],
        ),
      );

  // ── Carte activité ───────────────────────────────────────────────
  Widget _buildActiviteCard(Map<String, dynamic> activite) {
    final action = activite['action']?.toString() ?? '';
    final label = activite['action_label']?.toString() ?? action;
    final description = activite['description']?.toString() ?? '';
    final ts = activite['timestamp']?.toString();
    final data = (activite['data'] as Map<String, dynamic>?) ?? {};
    final meta = _getMeta(action);
    final color = meta['color'] as Color;
    final icon = meta['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _hDark,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description.isNotEmpty)
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Text(
                _formatTime(ts),
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Expansion → données détaillées
          children: data.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description.isEmpty
                          ? 'Aucun détail disponible.'
                          : description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ]
              : [
                  const Divider(height: 16),
                  ...data.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              _formatKey(e.key),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value?.toString() ?? '—',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _hDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  // ── Formater les clés de données ─────────────────────────────────
  String _formatKey(String key) {
    final map = {
      'titre': 'Titre',
      'nom': 'Nom',
      'cours': 'Cours',
      'niveau': 'Niveau',
      'departement': 'Département',
      'parcours': 'Parcours',
      'enseignant': 'Enseignant',
      'apprenant': 'Apprenant',
      'devoir': 'Devoir',
      'lecon': 'Leçon',
      'module': 'Module',
      'exercice': 'Exercice',
      'olympiade': 'Olympiade',
      'matiere': 'Matière',
      'edition': 'Édition',
      'note': 'Note',
      'note_sur': 'Note sur',
      'etoiles': 'Étoiles',
      'ordre': 'Ordre',
      'participants': 'Participants',
      'date_limite': 'Date limite',
      'debut': 'Début',
      'nb_questions': 'Questions',
      'color_code': 'Couleur',
    };
    return map[key] ?? key.replaceAll('_', ' ');
  }

  // ── État vide ────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final filter = _filters.firstWhere(
      (f) => f.key == _selectedCategory,
      orElse: () => const _HFilter(key: '', label: 'Tout', icon: Icons.apps),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _hPrimary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                filter.icon,
                size: 48,
                color: _hPrimary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedCategory.isEmpty
                  ? 'Aucune activité enregistrée'
                  : 'Aucune activité "${filter.label}"',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _hDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory.isEmpty
                  ? 'Vos actions apparaîtront ici\nau fur et à mesure.'
                  : 'Essayez un autre filtre.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (_selectedCategory.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedCategory = '');
                  _chargerActivites();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Voir tout l\'historique'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── État erreur ──────────────────────────────────────────────────
  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _error,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _hPrimary),
              onPressed: _chargerTout,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
}


// ═══════════════════════════════════════════════════════════════════
//  MODÈLE
// ═══════════════════════════════════════════════════════════════════
class HistoriqueAction {
  final int id;
  final String action;
  final String actionLabel;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final int? objetId;
  final String objetType;
  final String userNom;

  HistoriqueAction({
    required this.id,
    required this.action,
    required this.actionLabel,
    required this.description,
    required this.timestamp,
    required this.data,
    this.objetId,
    this.objetType = '',
    this.userNom = '',
  });

  factory HistoriqueAction.fromJson(Map<String, dynamic> json) {
    return HistoriqueAction(
      id:          json['id'] ?? 0,
      action:      json['action'] ?? '',
      actionLabel: json['action_label'] ?? json['action'] ?? '',
      description: json['description'] ?? '',
      timestamp:   DateTime.parse(json['timestamp'].toString()),
      data:        Map<String, dynamic>.from(json['data'] ?? {}),
      objetId:     json['objet_id'] as int?,
      objetType:   json['objet_type'] ?? '',
      userNom:     json['user_nom'] ?? '',
    );
  }
}
