// lib/views/pages/enseignants/historique_page.dart
//
// Refondu en P11.8 (rituel P5.0) : bascule vers `HistoriqueRepository`
// (plus de `http`/`SharedPreferences` bruts) et les tokens/composants
// `Yk*` — `YkTimeline` remplace la timeline à barre verticale faite main
// (voir le commentaire de tête d'`YkTimeline`, qui cite déjà cet écran
// comme cible).
//
// **Écart de design-système découvert** : les 24 couleurs distinctes de
// l'ancien `_actionMeta` (une par type d'action) n'ont aucun équivalent
// dans les tokens `Yk*` — la palette CDC ne définit que 4 couleurs
// sémantiques (success/warning/error/info) + la teinte primaire, pas de
// palette catégorielle pour différencier N catégories non ordonnées.
// Plutôt qu'inventer nos propres teintes (interdit par le commentaire de
// tête de `colors.dart` : « ne pas les améliorer à l'œil »), les 10
// catégories cyclent sur les 5 tokens sémantiques disponibles — l'icône
// (unique par catégorie) reste le différenciateur principal, la couleur
// n'étant plus qu'un renfort. Signalé dans la fiche d'écart, pas résolu
// silencieusement.
//
// `YkTimeline` n'a ni regroupement par date ni emplacement pour le détail
// clé/valeur par entrée (`data`) — les groupes de date restent des
// `YkTimeline` séparés sous un en-tête pilule, et le détail est replié
// dans `subtitle` (lignes "Clé : valeur").

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/repositories/historique_repository.dart';

class _CategorieMeta {
  const _CategorieMeta({required this.key, required this.label, required this.icon});
  final String key;
  final String label;
  final IconData icon;
}

const List<_CategorieMeta> _categories = [
  _CategorieMeta(key: '', label: 'Tout', icon: Icons.apps),
  _CategorieMeta(key: 'cours', label: 'Cours', icon: Icons.book_outlined),
  _CategorieMeta(key: 'modules', label: 'Modules', icon: Icons.folder_outlined),
  _CategorieMeta(key: 'lecons', label: 'Leçons', icon: Icons.article_outlined),
  _CategorieMeta(key: 'devoirs', label: 'Devoirs', icon: Icons.assignment_outlined),
  _CategorieMeta(key: 'exercices', label: 'Exercices', icon: Icons.quiz_outlined),
  _CategorieMeta(key: 'olympiades', label: 'Olympiades', icon: Icons.emoji_events_outlined),
  _CategorieMeta(key: 'enseignants', label: 'Enseignants', icon: Icons.people_outlined),
  _CategorieMeta(key: 'departements', label: 'Départements', icon: Icons.domain_outlined),
  _CategorieMeta(key: 'corrections', label: 'Corrections', icon: Icons.grading_outlined),
];

const Map<String, IconData> _iconesAction = {
  'course_created': Icons.add_circle_outlined,
  'course_modified': Icons.edit_outlined,
  'course_deleted': Icons.delete_outline,
  'teacher_assigned': Icons.person_add_outlined,
  'teacher_changed': Icons.swap_horiz,
  'secondary_added': Icons.group_add_outlined,
  'secondary_removed': Icons.group_remove_outlined,
  'module_created': Icons.folder_outlined,
  'module_modified': Icons.folder_open_outlined,
  'module_deleted': Icons.folder_delete_outlined,
  'lesson_created': Icons.article_outlined,
  'lesson_modified': Icons.edit_note_outlined,
  'lesson_deleted': Icons.delete_sweep_outlined,
  'homework_created': Icons.assignment_outlined,
  'homework_modified': Icons.assignment_late_outlined,
  'homework_graded': Icons.grading_outlined,
  'exercise_created': Icons.quiz_outlined,
  'question_added': Icons.help_outline,
  'olympiad_created': Icons.emoji_events_outlined,
  'olympiad_closed': Icons.event_busy_outlined,
  'ranking_computed': Icons.leaderboard_outlined,
  'department_created': Icons.domain_add_outlined,
  'cadre_assigned': Icons.supervisor_account_outlined,
  'submission_graded': Icons.done_all,
};

const Map<String, String> _libellesChamps = {
  'titre': 'Titre', 'nom': 'Nom', 'cours': 'Cours', 'niveau': 'Niveau',
  'departement': 'Département', 'parcours': 'Parcours', 'enseignant': 'Enseignant',
  'apprenant': 'Apprenant', 'devoir': 'Devoir', 'lecon': 'Leçon', 'module': 'Module',
  'exercice': 'Exercice', 'olympiade': 'Olympiade', 'matiere': 'Matière',
  'edition': 'Édition', 'note': 'Note', 'note_sur': 'Note sur', 'etoiles': 'Étoiles',
  'ordre': 'Ordre', 'participants': 'Participants', 'date_limite': 'Date limite',
  'debut': 'Début', 'nb_questions': 'Questions', 'color_code': 'Couleur',
};

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  final _repo = HistoriqueRepository();

  bool _loading = true;
  bool _chargementStats = true;
  String? _erreur;

  List<ActiviteHistorique> _activites = [];
  Map<String, dynamic> _stats = {};

  String _categorieSelectionnee = '';
  String _periodeSelectionnee = '';

  @override
  void initState() {
    super.initState();
    _chargerTout();
  }

  Future<void> _chargerTout() => Future.wait([_chargerActivites(), _chargerStats()]);

  Future<void> _chargerActivites() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    DateTime? depuis;
    if (_periodeSelectionnee == 'semaine') {
      depuis = DateTime.now().subtract(const Duration(days: 7));
    } else if (_periodeSelectionnee == 'mois') {
      depuis = DateTime(DateTime.now().year, DateTime.now().month, 1);
    }
    try {
      final activites = await _repo.activites(categorie: _categorieSelectionnee, depuis: depuis);
      if (mounted) setState(() => _activites = activites);
    } catch (_) {
      if (mounted) setState(() => _erreur = 'Erreur réseau.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chargerStats() async {
    setState(() => _chargementStats = true);
    try {
      final stats = await _repo.stats();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargementStats = false);
    }
  }

  Map<String, List<ActiviteHistorique>> _grouperParDate() {
    final groupes = <String, List<ActiviteHistorique>>{};
    for (final a in _activites) {
      if (a.timestamp == null) continue;
      final cle = _libelleDate(a.timestamp!.toLocal());
      groupes.putIfAbsent(cle, () => []).add(a);
    }
    return groupes;
  }

  String _libelleDate(DateTime dt) {
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

  String _formaterHeure(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return DateFormat('dd/MM à HH:mm').format(local);
  }

  Color _couleurCategorie(BuildContext context, String action) {
    final tokens = [YkColors.info, YkColors.success, YkColors.warning, YkColors.error, YkColors.accent(context)];
    return tokens[action.hashCode.abs() % tokens.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: _loading
          ? Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 6))
          : _erreur != null
              ? YkEmptyState(icon: Icons.cloud_off_rounded, title: 'Erreur', message: _erreur!, actionLabel: 'Réessayer', onAction: _chargerTout)
              : _activites.isEmpty
                  ? _etatVide(context)
                  : RefreshIndicator(
                      onRefresh: _chargerTout,
                      child: ListView(
                        padding: EdgeInsets.only(bottom: YkSpacing.xl),
                        children: [
                          _entete(context),
                          _filtres(context),
                          if (_stats.isNotEmpty && _categorieSelectionnee.isEmpty) _repartitionCategories(context),
                          ..._timelineGroupee(context),
                        ],
                      ),
                    ),
    );
  }

  Widget _entete(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(YkSpacing.lg, YkSpacing.md, YkSpacing.lg, YkSpacing.md),
      decoration: BoxDecoration(
        color: YkColors.accent(context),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(YkRadius.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_outlined, color: Colors.white70, size: 16),
              SizedBox(width: YkSpacing.xxs),
              Text('HISTORIQUE', style: YkTypography.caption(context).copyWith(color: Colors.white70, letterSpacing: 2)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _chargerTout),
            ],
          ),
          Text('Mes activités', style: YkTypography.h2(context).copyWith(color: Colors.white)),
          SizedBox(height: YkSpacing.sm),
          _chargementStats
              ? SizedBox(height: 28, child: Center(child: YkProgress(shape: YkProgressShape.circular, size: 18, color: Colors.white)))
              : Row(
                  children: [
                    _statBadge(context, '${_stats['total'] ?? 0}', 'au total', Icons.timeline),
                    SizedBox(width: YkSpacing.sm),
                    _statBadge(context, '${_stats['cette_semaine'] ?? 0}', 'cette semaine', Icons.date_range),
                    SizedBox(width: YkSpacing.sm),
                    _statBadge(context, '${_stats['ce_mois'] ?? 0}', 'ce mois', Icons.calendar_month),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _statBadge(BuildContext context, String count, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xxs),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(YkRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          SizedBox(width: YkSpacing.xxs),
          Text('$count $label', style: YkTypography.caption(context).copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _filtres(BuildContext context) {
    return Container(
      color: YkColors.surface(context),
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => SizedBox(width: YkSpacing.xxs),
              itemBuilder: (_, index) {
                final cat = _categories[index];
                final categories = Map<String, dynamic>.from(_stats['categories'] as Map? ?? {});
                final count = categories[cat.key] as int?;
                return YkChip(
                  label: count != null && count > 0 ? '${cat.label} ($count)' : cat.label,
                  avatar: Icon(cat.icon, size: 14),
                  variant: YkChipVariant.filter,
                  selected: _categorieSelectionnee == cat.key,
                  onPressed: () {
                    setState(() => _categorieSelectionnee = cat.key);
                    _chargerActivites();
                  },
                );
              },
            ),
          ),
          SizedBox(height: YkSpacing.xs),
          Row(
            children: [
              Text('Période :', style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
              SizedBox(width: YkSpacing.xs),
              _periodeChip(context, 'Tout', ''),
              SizedBox(width: YkSpacing.xxs),
              _periodeChip(context, '7 jours', 'semaine'),
              SizedBox(width: YkSpacing.xxs),
              _periodeChip(context, 'Ce mois', 'mois'),
              const Spacer(),
              if (!_loading)
                Text('${_activites.length} résultat${_activites.length > 1 ? 's' : ''}', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodeChip(BuildContext context, String label, String value) {
    return YkChip(
      label: label,
      variant: YkChipVariant.filter,
      selected: _periodeSelectionnee == value,
      onPressed: () {
        setState(() => _periodeSelectionnee = value);
        _chargerActivites();
      },
    );
  }

  Widget _repartitionCategories(BuildContext context) {
    final categories = Map<String, dynamic>.from(_stats['categories'] as Map? ?? {});
    final nonZero = categories.entries.where((e) => (e.value as int) > 0).toList();
    if (nonZero.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(YkSpacing.md),
      child: YkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Répartition de vos activités', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            Wrap(
              spacing: YkSpacing.xs,
              runSpacing: YkSpacing.xs,
              children: [
                for (final entry in nonZero)
                  YkChip(
                    label: '${_categories.firstWhere((c) => c.key == entry.key, orElse: () => _categories.first).label} (${entry.value})',
                    avatar: Icon(_categories.firstWhere((c) => c.key == entry.key, orElse: () => _categories.first).icon, size: 14),
                    onPressed: () {
                      setState(() => _categorieSelectionnee = entry.key);
                      _chargerActivites();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _timelineGroupee(BuildContext context) {
    final groupes = _grouperParDate();
    final widgets = <Widget>[];
    for (final entry in groupes.entries) {
      widgets.add(_enteteDate(context, entry.key));
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: YkSpacing.md),
          child: YkTimeline(
            entries: [
              for (final activite in entry.value)
                YkTimelineEntry(
                  title: activite.label,
                  subtitle: _sousTitre(activite),
                  time: _formaterHeure(activite.timestamp),
                  icon: _iconesAction[activite.action] ?? Icons.history,
                  color: _couleurCategorie(context, activite.action),
                ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  String? _sousTitre(ActiviteHistorique activite) {
    final lignes = <String>[];
    if (activite.description.isNotEmpty) lignes.add(activite.description);
    for (final e in activite.data.entries) {
      lignes.add('${_libellesChamps[e.key] ?? e.key.replaceAll('_', ' ')} : ${e.value ?? '—'}');
    }
    return lignes.isEmpty ? null : lignes.join('\n');
  }

  Widget _enteteDate(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md, YkSpacing.md, YkSpacing.xs),
      child: Row(
        children: [
          YkBadge(variant: YkBadgeVariant.label, label: label, color: YkColors.accent(context)),
          SizedBox(width: YkSpacing.xs),
          Expanded(child: Divider(color: YkColors.border(context))),
        ],
      ),
    );
  }

  Widget _etatVide(BuildContext context) {
    final filtre = _categories.firstWhere((c) => c.key == _categorieSelectionnee, orElse: () => _categories.first);
    return YkEmptyState(
      icon: filtre.icon,
      title: _categorieSelectionnee.isEmpty ? 'Aucune activité enregistrée' : 'Aucune activité "${filtre.label}"',
      message: _categorieSelectionnee.isEmpty ? 'Vos actions apparaîtront ici au fur et à mesure.' : 'Essayez un autre filtre.',
      actionLabel: _categorieSelectionnee.isNotEmpty ? "Voir tout l'historique" : null,
      onAction: _categorieSelectionnee.isNotEmpty
          ? () {
              setState(() => _categorieSelectionnee = '');
              _chargerActivites();
            }
          : null,
    );
  }
}
