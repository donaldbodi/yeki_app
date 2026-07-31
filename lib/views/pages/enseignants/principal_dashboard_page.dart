// lib/views/pages/enseignants/principal_dashboard_page.dart
//
// Refondu en P11.5 (rituel P5.0) : bascule vers `DashboardRepository`
// (plus de `http`/`SharedPreferences` bruts) et le squelette partagé
// `EnseignantDashboardSkeleton`. Le "Suivi" (rendu/moyenne/retards,
// tendance 7 jours, élèves à risque) est unique à ce rôle — conservé tel
// quel, migré vers `Yk*`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/dashboard_repository.dart';
import 'package:yeki/views/pages/enseignants/dashboard_skeleton.dart';

class DashboardStats {
  final int nbCours;
  final int nbLecons;
  final int nbDevoirs;
  final int nbApprenants;
  final double tauxRenduGlobal;
  final double moyenneGlobale;
  final int nbRetards;

  DashboardStats({
    required this.nbCours,
    required this.nbLecons,
    required this.nbDevoirs,
    required this.nbApprenants,
    required this.tauxRenduGlobal,
    required this.moyenneGlobale,
    required this.nbRetards,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return DashboardStats(
      nbCours: stats['nb_cours'] as int? ?? 0,
      nbLecons: stats['nb_lecons'] as int? ?? 0,
      nbDevoirs: stats['nb_devoirs'] as int? ?? 0,
      nbApprenants: stats['nb_apprenants'] as int? ?? 0,
      tauxRenduGlobal: (stats['taux_rendu_global'] as num? ?? 0).toDouble(),
      moyenneGlobale: (stats['moyenne_globale'] as num? ?? 0).toDouble(),
      nbRetards: stats['nb_retards'] as int? ?? 0,
    );
  }
}

class DetailDevoir {
  final String titre;
  final DateTime dateLimite;
  final int nbRendus;
  final int nbRetards;
  final double tauxRendu;
  final double noteMoyenne;

  DetailDevoir({
    required this.titre,
    required this.dateLimite,
    required this.nbRendus,
    required this.nbRetards,
    required this.tauxRendu,
    required this.noteMoyenne,
  });

  factory DetailDevoir.fromJson(Map<String, dynamic> json) {
    DateTime dateLimite;
    try {
      dateLimite = DateTime.parse(json['date_limite'] as String);
    } catch (_) {
      dateLimite = DateTime.now();
    }
    return DetailDevoir(
      titre: json['titre'] as String? ?? '',
      dateLimite: dateLimite,
      nbRendus: json['nb_rendus'] as int? ?? 0,
      nbRetards: json['nb_retards'] as int? ?? 0,
      tauxRendu: (json['taux_rendu'] as num? ?? 0).toDouble(),
      noteMoyenne: (json['note_moyenne'] as num? ?? 0).toDouble(),
    );
  }
}

class DevoirParCours {
  final String coursTitre;
  final int nbDevoirs;
  final double tauxRendu;
  final List<DetailDevoir> detailsDevoirs;

  DevoirParCours({required this.coursTitre, required this.nbDevoirs, required this.tauxRendu, required this.detailsDevoirs});

  factory DevoirParCours.fromJson(Map<String, dynamic> json) {
    final detailsRaw = json['details_devoirs'] as List? ?? [];
    return DevoirParCours(
      coursTitre: json['cours_titre'] as String? ?? '',
      nbDevoirs: json['nb_devoirs'] as int? ?? 0,
      tauxRendu: (json['taux_rendu'] as num? ?? 0).toDouble(),
      detailsDevoirs: detailsRaw.whereType<Map>().map((d) => DetailDevoir.fromJson(Map<String, dynamic>.from(d))).toList(),
    );
  }
}

class TendanceRendu {
  final DateTime date;
  final int nbRendus;

  TendanceRendu({required this.date, required this.nbRendus});

  factory TendanceRendu.fromJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = DateTime.parse(json['date'] as String);
    } catch (_) {
      date = DateTime.now();
    }
    return TendanceRendu(date: date, nbRendus: json['nb_rendus'] as int? ?? 0);
  }
}

class DashboardPrincipalPage extends StatefulWidget {
  const DashboardPrincipalPage({super.key});

  @override
  State<DashboardPrincipalPage> createState() => _DashboardPrincipalPageState();
}

class _DashboardPrincipalPageState extends State<DashboardPrincipalPage> with SingleTickerProviderStateMixin {
  final _repo = DashboardRepository();
  late final TabController _tabCtrl;

  List<Map<String, dynamic>> _cours = [];
  DashboardStats? _stats;
  List<DevoirParCours> _devoirsParCours = [];
  List<Map<String, dynamic>> _apprenantsRisque = [];
  List<TendanceRendu> _tendanceRendus = [];

  bool _loading = true;
  String? _error;

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

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.principal();
      final cours = await _repo.principalCours();
      if (mounted) {
        setState(() {
          _stats = DashboardStats.fromJson(data);
          _devoirsParCours = (data['devoirs_par_cours'] as List? ?? [])
              .whereType<Map>()
              .map((d) => DevoirParCours.fromJson(Map<String, dynamic>.from(d)))
              .toList();
          _apprenantsRisque = (data['apprenants_risque'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _tendanceRendus = (data['tendance_rendus'] as List? ?? []).whereType<Map>().map((t) => TendanceRendu.fromJson(Map<String, dynamic>.from(t))).toList();
          _cours = cours;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger votre tableau de bord.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retirerEnseignant(int coursId, int enseignantId, String nom) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Retirer l'assistant"),
        content: Text('Voulez-vous retirer "$nom" de ce cours ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          YkButton(label: 'Retirer', variant: YkButtonVariant.destructive, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await _repo.retirerEnseignant(coursId, enseignantId);
      setState(() {
        for (final c in _cours) {
          if (c['id'] == coursId) {
            final sec = List.from(c['enseignants'] as List? ?? []);
            sec.removeWhere((e) => (e is Map ? e['id'] : e) == enseignantId);
            c['enseignants'] = sec;
          }
        }
      });
      if (mounted) YkSnack.success(context, 'Enseignant retiré avec succès.');
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    }
  }

  Future<void> _ajouterEnseignantSecondaire(int coursId) async {
    List<Map<String, dynamic>> disponibles;
    try {
      disponibles = await _repo.enseignantsListe('enseignant');
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur de chargement des enseignants.');
      return;
    }
    if (!mounted) return;

    final cours = _cours.firstWhere((c) => c['id'] == coursId, orElse: () => {});
    final existants = (cours['enseignants'] as List? ?? []).map((e) => e is Map ? e['id'] : e).toSet();
    final candidats = disponibles.where((e) => !existants.contains(e['id'])).toList();
    final selectionIds = <int>[];

    await YkSheet.show<void>(
      context: context,
      title: 'Assigner des assistants',
      bodyBuilder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${candidats.length} enseignant(s) disponible(s)', style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
            SizedBox(height: YkSpacing.sm),
            if (candidats.isEmpty)
              Text('Tous les enseignants sont déjà assignés.', style: YkTypography.bodyMd(context))
            else
              for (final ens in candidats)
                CheckboxListTile(
                  title: Text(ens['nom'] ?? ens['username'] ?? ''),
                  subtitle: (ens['email'] as String?)?.isNotEmpty == true ? Text(ens['email']) : null,
                  value: selectionIds.contains(ens['id']),
                  onChanged: (v) => setS(() => v == true ? selectionIds.add(ens['id'] as int) : selectionIds.remove(ens['id'])),
                ),
          ],
        ),
      ),
      actionsBuilder: (ctx) => [
        YkButton(
          label: 'Ajouter la sélection',
          onPressed: selectionIds.isEmpty
              ? null
              : () async {
                  Navigator.pop(ctx);
                  var succes = true;
                  for (final id in selectionIds) {
                    try {
                      await _repo.ajouterEnseignant(coursId, id);
                    } catch (_) {
                      succes = false;
                    }
                  }
                  if (succes) {
                    setState(() {
                      for (final c in _cours) {
                        if (c['id'] == coursId) {
                          final sec = List.from(c['enseignants'] as List? ?? []);
                          for (final id in selectionIds) {
                            final ajoute = candidats.firstWhere((e) => e['id'] == id, orElse: () => {});
                            if (ajoute.isNotEmpty) sec.add(ajoute);
                          }
                          c['enseignants'] = sec;
                        }
                      }
                    });
                    if (mounted) YkSnack.success(context, 'Enseignant(s) ajouté(s) avec succès !');
                  } else if (mounted) {
                    YkSnack.error(context, 'Certains ajouts ont échoué.');
                  }
                },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return EnseignantDashboardSkeleton(
      loading: _loading,
      errorMessage: _error,
      onRetry: _charger,
      tabController: _tabCtrl,
      tabs: [
        YkDashboardTab(label: 'Mes cours', body: _tabCours(context)),
        YkDashboardTab(label: 'Suivi', body: _tabSuivi(context)),
        YkDashboardTab(label: 'Statistiques', body: _tabStats(context)),
      ],
    );
  }

  Widget _tabCours(BuildContext context) {
    if (_cours.isEmpty) {
      return YkEmptyState(icon: Icons.book_outlined, title: 'Aucun cours assigné', message: 'Les cours vous seront attribués par votre cadre.');
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: _cours.length,
        separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
        itemBuilder: (_, i) => _coursCard(context, _cours[i]),
      ),
    );
  }

  Widget _coursCard(BuildContext context, Map<String, dynamic> c) {
    final assistants = (c['enseignants'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final couleur = couleurDepuisHex(c['color_code'] as String?, YkColors.accent(context));
    final coursId = c['id'] as int? ?? 0;

    return YkCard(
      accentColor: couleur,
      onTap: coursId == 0
          ? null
          : () => context.pushNamed(
                AppRoute.coursDetailEnseignant,
                pathParameters: {'coursId': coursId.toString()},
                queryParameters: {'titre': (c['titre'] ?? '') as String, 'estEnseignantPrincipal': 'true', 'courseColor': couleur.toARGB32().toString()},
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(YkSpacing.xs),
                decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(YkRadius.md)),
                child: Icon(Icons.book_rounded, color: couleur, size: 22),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['titre'] ?? '', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    Text(c['niveau'] ?? '', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Icon(Icons.article_rounded, size: 12, color: YkColors.info),
              const SizedBox(width: 4),
              Text('${c['nb_lecons'] ?? 0} leçons', style: YkTypography.caption(context)),
              SizedBox(width: YkSpacing.sm),
              Icon(Icons.assignment_rounded, size: 12, color: YkColors.warning),
              const SizedBox(width: 4),
              Text('${c['nb_devoirs'] ?? 0} devoirs', style: YkTypography.caption(context)),
              SizedBox(width: YkSpacing.sm),
              Icon(Icons.people_rounded, size: 12, color: YkColors.success),
              const SizedBox(width: 4),
              Text('${c['nb_apprenants'] ?? 0} élèves', style: YkTypography.caption(context)),
            ],
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Équipe (${assistants.length} assistant${assistants.length > 1 ? 's' : ''})', style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
              children: [
                if (assistants.isEmpty)
                  Text('Aucun assistant assigné.', style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
                for (final e in assistants) _assistantTile(context, coursId, e),
                SizedBox(height: YkSpacing.xs),
                YkButton(label: 'Ajouter un assistant', icon: Icons.add, variant: YkButtonVariant.tertiary, onPressed: () => _ajouterEnseignantSecondaire(coursId)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assistantTile(BuildContext context, int coursId, Map<String, dynamic> e) {
    final username = e['user']?['username'] ?? e['username'] ?? 'Assistant';
    final email = e['user']?['email'] ?? e['email'] ?? '';
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: YkColors.accent(context).withValues(alpha: 0.12), child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'A')),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
                if (email.isNotEmpty) Text(email, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
              ],
            ),
          ),
          YkIconButton(icon: Icons.remove_circle_outline, label: 'Retirer', variant: YkIconButtonVariant.ghost, onPressed: () => _retirerEnseignant(coursId, e['id'] as int, username)),
        ],
      ),
    );
  }

  Widget _tabSuivi(BuildContext context) {
    final stats = _stats;
    return RefreshIndicator(
      onRefresh: _charger,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(YkSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stats != null)
              Row(
                children: [
                  Expanded(child: YkStatCard(value: '${stats.tauxRenduGlobal.toStringAsFixed(0)}%', label: 'Rendu', icon: Icons.assignment_turned_in)),
                  SizedBox(width: YkSpacing.sm),
                  Expanded(child: YkStatCard(value: stats.moyenneGlobale.toStringAsFixed(1), label: 'Moyenne', icon: Icons.analytics)),
                  SizedBox(width: YkSpacing.sm),
                  Expanded(child: YkStatCard(value: '${stats.nbRetards}', label: 'Retards', icon: Icons.timer_outlined)),
                ],
              ),
            SizedBox(height: YkSpacing.lg),
            Text('Tendance des rendus (7 jours)', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            _tendanceChart(context),
            SizedBox(height: YkSpacing.lg),
            Text('Devoirs par cours', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            if (_devoirsParCours.isEmpty)
              YkEmptyState(icon: Icons.assignment_outlined, title: 'Aucun devoir créé', message: '')
            else
              for (final dpc in _devoirsParCours) _devoirParCoursCard(context, dpc),
            SizedBox(height: YkSpacing.lg),
            Text('Élèves à risque', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            if (_apprenantsRisque.isEmpty)
              YkEmptyState(icon: Icons.check_circle_outline, title: 'Aucun élève à risque', message: '')
            else
              YkCard(child: Column(children: [for (final ar in _apprenantsRisque) _apprenantRisqueTile(context, ar)])),
          ],
        ),
      ),
    );
  }

  Widget _tendanceChart(BuildContext context) {
    if (_tendanceRendus.isEmpty) {
      return YkCard(child: Text('Aucune donnée de tendance disponible.', style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))));
    }
    final tries = List<TendanceRendu>.from(_tendanceRendus)..sort((a, b) => a.date.compareTo(b.date));
    final maxValeur = tries.fold<int>(0, (max, t) => t.nbRendus > max ? t.nbRendus : max);
    final maxAffiche = maxValeur > 0 ? maxValeur.toDouble() : 1.0;

    return YkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total : ${tries.fold<int>(0, (s, t) => s + t.nbRendus)} rendus', style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
          SizedBox(height: YkSpacing.sm),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final t in tries)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (t.nbRendus > 0) Text('${t.nbRendus}', style: YkTypography.caption(context)),
                        SizedBox(height: YkSpacing.xxs),
                        Container(
                          height: (t.nbRendus / maxAffiche) * 80.0,
                          decoration: BoxDecoration(color: YkColors.accent(context), borderRadius: BorderRadius.vertical(top: Radius.circular(YkRadius.xs))),
                        ),
                        SizedBox(height: YkSpacing.xxs),
                        Text(DateFormat('dd/MM').format(t.date), style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _devoirParCoursCard(BuildContext context, DevoirParCours dpc) {
    final couleurTaux = dpc.tauxRendu >= 70 ? YkColors.success : (dpc.tauxRendu >= 40 ? YkColors.warning : YkColors.error);
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dpc.coursTitre, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                      Text('${dpc.nbDevoirs} devoir(s)', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                    ],
                  ),
                ),
                YkBadge(variant: YkBadgeVariant.label, label: '${dpc.tauxRendu.toStringAsFixed(0)}%', color: couleurTaux),
              ],
            ),
            children: [
              if (dpc.detailsDevoirs.isEmpty)
                Text('Aucun devoir pour ce cours.', style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)))
              else
                for (final dd in dpc.detailsDevoirs) _detailDevoirCard(context, dd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailDevoirCard(BuildContext context, DetailDevoir dd) {
    final enRetard = dd.dateLimite.isBefore(DateTime.now());
    final couleur = dd.tauxRendu >= 70 ? YkColors.success : (dd.tauxRendu >= 40 ? YkColors.warning : YkColors.error);
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.xs),
      child: Container(
        padding: EdgeInsets.all(YkSpacing.sm),
        decoration: BoxDecoration(color: YkColors.surfaceVariant(context), borderRadius: BorderRadius.circular(YkRadius.sm)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dd.titre, style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
                      Text(
                        'Limite : ${DateFormat('dd/MM/yyyy').format(dd.dateLimite)}${enRetard ? ' (en retard)' : ''}',
                        style: YkTypography.caption(context).copyWith(color: enRetard ? YkColors.error : YkColors.textTertiary(context)),
                      ),
                    ],
                  ),
                ),
                YkBadge(variant: YkBadgeVariant.label, label: '${dd.tauxRendu.toStringAsFixed(0)}%', color: couleur),
              ],
            ),
            SizedBox(height: YkSpacing.xs),
            Row(
              children: [
                Text('${dd.nbRendus} rendus', style: YkTypography.caption(context).copyWith(color: YkColors.info)),
                SizedBox(width: YkSpacing.sm),
                Text('${dd.nbRetards} retards', style: YkTypography.caption(context).copyWith(color: YkColors.warning)),
                SizedBox(width: YkSpacing.sm),
                Text('Moy : ${dd.noteMoyenne.toStringAsFixed(1)}/20', style: YkTypography.caption(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _apprenantRisqueTile(BuildContext context, Map<String, dynamic> ar) {
    final taux = (ar['taux_rendu'] as num? ?? 0).toDouble();
    final couleur = taux < 50 ? YkColors.error : YkColors.warning;
    final prenom = ar['prenom'] as String? ?? '?';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: YkSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: couleur.withValues(alpha: 0.12), child: Text(prenom.isNotEmpty ? prenom[0].toUpperCase() : '?', style: TextStyle(color: couleur))),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$prenom ${ar['nom'] ?? ''}'.trim(), style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context))),
                Text(ar['raison'] ?? 'Taux de rendu faible', style: YkTypography.caption(context).copyWith(color: couleur)),
                Text('Rendu : ${taux.toStringAsFixed(0)}% · Moy : ${(ar['moyenne'] as num? ?? 0).toStringAsFixed(1)}/20', style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabStats(BuildContext context) {
    final stats = _stats;
    if (stats == null) {
      return YkEmptyState(icon: Icons.bar_chart_outlined, title: 'Aucune statistique disponible', message: '');
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YkDashboardStatGrid(
            cards: [
              YkStatCard(value: '${stats.nbCours}', label: 'Cours', icon: Icons.book),
              YkStatCard(value: '${stats.nbApprenants}', label: 'Apprenants', icon: Icons.people),
              YkStatCard(value: '${stats.nbLecons}', label: 'Leçons', icon: Icons.article),
              YkStatCard(value: '${stats.nbDevoirs}', label: 'Devoirs', icon: Icons.assignment_outlined),
            ],
          ),
          SizedBox(height: YkSpacing.lg),
          Text('Performance globale', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
          SizedBox(height: YkSpacing.sm),
          YkCard(
            variant: YkCardVariant.filled,
            accentColor: YkColors.accent(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résumé de vos cours', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                SizedBox(height: YkSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _perfItem(context, '${stats.nbCours}', 'Cours actifs')),
                    Expanded(child: _perfItem(context, '${stats.nbLecons}', 'Leçons publiées')),
                    Expanded(child: _perfItem(context, '${stats.nbDevoirs}', 'Devoirs créés')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfItem(BuildContext context, String value, String label) => Column(
    children: [
      Text(value, style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context))),
      Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)), textAlign: TextAlign.center),
    ],
  );
}
