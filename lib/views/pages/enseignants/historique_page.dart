// lib/views/pages/enseignants/historique_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// PAGE HISTORIQUE ENSEIGNANT — VERSION ULTRA SIMPLE ET STABLE
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

// ─── CONFIGURATION ─────────────────────────────────────────────────────────

const Map<String, Map<String, dynamic>> _actionMeta = {
  'course_created':    {'icon': Icons.add_circle_outlined,    'color': Color(0xFF2E7D32), 'cat': 'cours', 'label': 'Cours créé'},
  'course_modified':   {'icon': Icons.edit_outlined,          'color': Color(0xFF1565C0), 'cat': 'cours', 'label': 'Cours modifié'},
  'course_deleted':    {'icon': Icons.delete_outline,         'color': Color(0xFFC62828), 'cat': 'cours', 'label': 'Cours supprimé'},
  'teacher_assigned':  {'icon': Icons.person_add_outlined,    'color': Color(0xFFE65100), 'cat': 'enseignants', 'label': 'Enseignant assigné'},
  'teacher_changed':   {'icon': Icons.swap_horiz,             'color': Color(0xFFE65100), 'cat': 'enseignants', 'label': 'Enseignant changé'},
  'secondary_added':   {'icon': Icons.group_add_outlined,     'color': Color(0xFF00838F), 'cat': 'enseignants', 'label': 'Assistant ajouté'},
  'secondary_removed': {'icon': Icons.group_remove_outlined,  'color': Color(0xFFAD1457), 'cat': 'enseignants', 'label': 'Assistant retiré'},
  'module_created':    {'icon': Icons.folder_outlined,        'color': Color(0xFF6A1B9A), 'cat': 'modules', 'label': 'Module créé'},
  'module_modified':   {'icon': Icons.folder_open_outlined,   'color': Color(0xFF4527A0), 'cat': 'modules', 'label': 'Module modifié'},
  'module_deleted':    {'icon': Icons.folder_delete_outlined, 'color': Color(0xFFC62828), 'cat': 'modules', 'label': 'Module supprimé'},
  'lesson_created':    {'icon': Icons.article_outlined,       'color': Color(0xFF00695C), 'cat': 'lecons', 'label': 'Leçon créée'},
  'lesson_modified':   {'icon': Icons.edit_note_outlined,     'color': Color(0xFF00695C), 'cat': 'lecons', 'label': 'Leçon modifiée'},
  'lesson_deleted':    {'icon': Icons.delete_sweep_outlined,  'color': Color(0xFFC62828), 'cat': 'lecons', 'label': 'Leçon supprimée'},
  'homework_created':  {'icon': Icons.assignment_outlined,    'color': Color(0xFF558B2F), 'cat': 'devoirs', 'label': 'Devoir créé'},
  'homework_modified': {'icon': Icons.assignment_late_outlined,'color': Color(0xFF558B2F), 'cat': 'devoirs', 'label': 'Devoir modifié'},
  'homework_graded':   {'icon': Icons.grading_outlined,       'color': Color(0xFF558B2F), 'cat': 'devoirs', 'label': 'Devoir corrigé'},
  'exercise_created':  {'icon': Icons.quiz_outlined,          'color': Color(0xFF283593), 'cat': 'exercices', 'label': 'Exercice créé'},
  'question_added':    {'icon': Icons.help_outline,           'color': Color(0xFF283593), 'cat': 'exercices', 'label': 'Question ajoutée'},
  'olympiad_created':  {'icon': Icons.emoji_events_outlined,  'color': Color(0xFFBF360C), 'cat': 'olympiades', 'label': 'Olympiade créée'},
  'olympiad_closed':   {'icon': Icons.event_busy_outlined,    'color': Color(0xFFBF360C), 'cat': 'olympiades', 'label': 'Olympiade fermée'},
  'ranking_computed':  {'icon': Icons.leaderboard_outlined,   'color': Color(0xFFBF360C), 'cat': 'olympiades', 'label': 'Classement calculé'},
  'department_created':{'icon': Icons.domain_add_outlined,    'color': Color(0xFF00695C), 'cat': 'departements', 'label': 'Département créé'},
  'cadre_assigned':    {'icon': Icons.supervisor_account_outlined, 'color': Color(0xFF006064), 'cat': 'departements', 'label': 'Cadre assigné'},
  'submission_graded': {'icon': Icons.done_all,               'color': Color(0xFF2E7D32), 'cat': 'corrections', 'label': 'Soumission corrigée'},
};

Map<String, dynamic> _getMeta(String action) =>
    _actionMeta[action] ??
    {'icon': Icons.history, 'color': YekiColors.textLight, 'cat': 'autre', 'label': action};

// ─── FILTRES ─────────────────────────────────────────────────────────────

class _HFilter {
  final String key;
  final String label;
  final IconData icon;
  const _HFilter({required this.key, required this.label, required this.icon});
}

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

// ─── PAGE PRINCIPALE ──────────────────────────────────────────────────────

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  bool _loading = true;
  bool _loadingStats = true;
  String _error = '';

  List<Map<String, dynamic>> _activites = [];
  Map<String, dynamic> _stats = {};

  String _selectedCategory = '';
  String _selectedPeriode = '';

  @override
  void initState() {
    super.initState();
    _chargerTout();
  }

  // ─── API ──────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

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

      params['limit'] = '200';

      final uri = Uri.parse(ApiConstants.historique).replace(queryParameters: params);
      final res = await http.get(uri, headers: headers);

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _activites = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
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
        Uri.parse(ApiConstants.historiqueStats),
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

  // ─── HELPERS ──────────────────────────────────────────────────────────

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

  // ─── BUILD ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      body: SafeArea(
        child: _loading
            ? const Center(child: YekiLoader())
            : _error.isNotEmpty
                ? _buildErrorState()
                : _activites.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _chargerTout,
                        color: YekiColors.primaryDark,
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            _buildHeader(),
                            _buildFilters(),
                            if (_stats.isNotEmpty && _selectedCategory.isEmpty)
                              _buildCategoryGrid(),
                            ..._buildTimeline(),
                          ],
                        ),
                      ),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A5276), YekiColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_outlined, color: YekiColors.white.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 6),
              Text(
                'HISTORIQUE',
                style: TextStyle(
                  color: YekiColors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: YekiColors.white, size: 20),
                onPressed: _chargerTout,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Mes activités',
            style: TextStyle(
              color: YekiColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _loadingStats
              ? SizedBox(
                  height: 28,
                  child: Center(
                    child: YekiLoader(size: 18, color: YekiColors.white.withValues(alpha: 0.54)),
                  ),
                )
              : Row(
                  children: [
                    _statBadge('${_stats['total'] ?? 0}', 'au total', Icons.timeline),
                    const SizedBox(width: 10),
                    _statBadge('${_stats['cette_semaine'] ?? 0}', 'cette semaine', Icons.date_range),
                    const SizedBox(width: 10),
                    _statBadge('${_stats['ce_mois'] ?? 0}', 'ce mois', Icons.calendar_month),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _statBadge(String count, String label, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: YekiColors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              '$count $label',
              style: const TextStyle(
                color: YekiColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  // ─── FILTRES ──────────────────────────────────────────────────────────

  Widget _buildFilters() {
    return Container(
      color: YekiColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtres de catégorie
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, index) {
                final f = _filters[index];
                final isSelected = _selectedCategory == f.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = f.key);
                    _chargerActivites();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? YekiColors.primaryDark : YekiColors.primaryDark.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? YekiColors.primaryDark : YekiColors.primaryDark.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          f.icon,
                          size: 14,
                          color: isSelected ? YekiColors.white : YekiColors.primaryDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? YekiColors.white : YekiColors.primaryDark,
                          ),
                        ),
                        if (!_loadingStats &&
                            f.key.isNotEmpty &&
                            (_stats['categories'] as Map<String, dynamic>?)?[f.key] != null &&
                            ((_stats['categories'] as Map<String, dynamic>)[f.key] as int) > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? YekiColors.white.withValues(alpha: 0.3) : YekiColors.primaryDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(_stats['categories'] as Map<String, dynamic>)[f.key]}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? YekiColors.white : YekiColors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Période
          Row(
            children: [
              const Text(
                'Période :',
                style: TextStyle(fontSize: 12, color: YekiColors.textDark),
              ),
              const SizedBox(width: 8),
              _periodeChip('Tout', ''),
              const SizedBox(width: 4),
              _periodeChip('7 jours', 'semaine'),
              const SizedBox(width: 4),
              _periodeChip('Ce mois', 'mois'),
              const Spacer(),
              if (!_loading)
                Text(
                  '${_activites.length} résultat${_activites.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11, color: YekiColors.textLight),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodeChip(String label, String value) {
    final isSelected = _selectedPeriode == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriode = value);
        _chargerActivites();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? YekiColors.textDark : YekiColors.borderLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? YekiColors.white : YekiColors.textLight,
          ),
        ),
      ),
    );
  }

  // ─── CATEGORY GRID ────────────────────────────────────────────────────

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition de vos activités',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: YekiColors.textDark),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: nonZero.map((entry) {
                final meta = catMeta[entry.key] ?? {'icon': Icons.circle, 'color': YekiColors.textLight, 'label': entry.key};
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
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 14),
                        const SizedBox(width: 5),
                        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: YekiColors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TIMELINE ──────────────────────────────────────────────────────────

  List<Widget> _buildTimeline() {
    final grouped = _grouperParDate();
    final List<Widget> widgets = [];

    for (final entry in grouped.entries) {
      widgets.add(_buildDateHeader(entry.key));
      for (int i = 0; i < entry.value.length; i++) {
        widgets.add(_buildTimelineItem(entry.value[i], i, entry.value.length));
      }
    }

    return widgets;
  }

  Widget _buildDateHeader(String label) => Padding(
        padding: const EdgeInsets.only(top: 16, left: 14, right: 14, bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: YekiColors.primaryDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: YekiColors.primaryDark),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: YekiColors.borderLight,
              ),
            ),
          ],
        ),
      );

  Widget _buildTimelineItem(Map<String, dynamic> activite, int index, int total) {
    final action = activite['action']?.toString() ?? '';
    final label = activite['action_label']?.toString() ?? _getMeta(action)['label'] ?? action;
    final description = activite['description']?.toString() ?? '';
    final ts = activite['timestamp']?.toString();
    final data = (activite['data'] as Map<String, dynamic>?) ?? {};
    final meta = _getMeta(action);
    final color = meta['color'] as Color;
    final icon = meta['icon'] as IconData;

    final bool isLast = index == total - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barre verticale ────────────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: YekiColors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: color.withValues(alpha: 0.2),
                  ),
              ],
            ),
          ),
          // ── Contenu ────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 8, bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: YekiColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: YekiColors.borderLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: YekiColors.textDark),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatTime(ts),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: color.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (data.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: YekiColors.borderLight,
                    ),
                    const SizedBox(height: 8),
                    ...data.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                _formatKey(e.key),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: YekiColors.textMedium),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value?.toString() ?? '—',
                                style: const TextStyle(fontSize: 11, color: YekiColors.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ETATS VIDES ──────────────────────────────────────────────────────

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
                color: YekiColors.primaryDark.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(filter.icon, size: 48, color: YekiColors.primaryDark.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedCategory.isEmpty
                  ? 'Aucune activité enregistrée'
                  : 'Aucune activité "${filter.label}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: YekiColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory.isEmpty
                  ? 'Vos actions apparaîtront ici\nau fur et à mesure.'
                  : 'Essayez un autre filtre.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: YekiColors.textMedium),
            ),
            if (_selectedCategory.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedCategory = '');
                  _chargerActivites();
                },
                icon: const Icon(Icons.clear_all, color: YekiColors.primaryDark),
                label: const Text('Voir tout l\'historique', style: TextStyle(color: YekiColors.primaryDark)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: YekiColors.borderLight),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: YekiColors.textDark)),
            const SizedBox(height: 16),
            YekiButton(
              label: 'Réessayer',
              icon: Icons.refresh,
              onPressed: _chargerTout,
              width: 160,
            ),
          ],
        ),
      );
}