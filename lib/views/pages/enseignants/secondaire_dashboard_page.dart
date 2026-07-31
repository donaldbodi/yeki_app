// lib/views/pages/enseignants/secondaire_dashboard_page.dart
//
// Refondu en P11.5 (rituel P5.0) : bascule vers `DashboardRepository`
// (plus de `http`/`SharedPreferences` bruts) et le squelette partagé
// `EnseignantDashboardSkeleton` (voir `dashboard_skeleton.dart`) — le
// dashboard le plus simple des 4 (lecture seule, sans FAB ni action).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/dashboard_repository.dart';
import 'package:yeki/views/pages/enseignants/dashboard_skeleton.dart';

class SecondaireCours {
  final int id;
  final String titre;
  final String niveau;
  final String? description;
  final String colorCode;
  final String iconName;
  final int nbLecons;
  final int nbDevoirs;
  final int nbApprenants;
  final double tauxCompletion;
  final String? departementNom;

  SecondaireCours({
    required this.id,
    required this.titre,
    required this.niveau,
    this.description,
    this.colorCode = '#2884A0',
    this.iconName = 'school',
    this.nbLecons = 0,
    this.nbDevoirs = 0,
    this.nbApprenants = 0,
    this.tauxCompletion = 0.0,
    this.departementNom,
  });

  factory SecondaireCours.fromJson(Map<String, dynamic> json) {
    return SecondaireCours(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      niveau: json['niveau'] as String? ?? '',
      description: json['description_brief'] as String?,
      colorCode: json['color_code'] as String? ?? '#2884A0',
      iconName: json['icon_name'] as String? ?? 'school',
      nbLecons: json['nb_lecons'] as int? ?? 0,
      nbDevoirs: json['nb_devoirs'] as int? ?? 0,
      nbApprenants: json['nb_apprenants'] as int? ?? 0,
      tauxCompletion: (json['taux_completion'] as num? ?? 0).toDouble(),
      departementNom: json['departement'] is Map
          ? json['departement']['nom'] as String?
          : json['departement_nom'] as String?,
    );
  }
}

class SecondaireDashboardPage extends StatefulWidget {
  const SecondaireDashboardPage({super.key});

  @override
  State<SecondaireDashboardPage> createState() => _SecondaireDashboardPageState();
}

class _SecondaireDashboardPageState extends State<SecondaireDashboardPage> with SingleTickerProviderStateMixin {
  final _repo = DashboardRepository();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<SecondaireCours> _cours = [];
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
      final data = await _repo.secondaire();
      final coursData = data['cours'] as List? ?? [];
      if (mounted) {
        setState(() {
          _stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
          _cours = coursData.map((c) => SecondaireCours.fromJson(Map<String, dynamic>.from(c as Map))).toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger votre tableau de bord.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _ouvrirDetailCours(SecondaireCours cours) {
    final couleur = couleurDepuisHex(cours.colorCode, YkColors.accent(context));
    context.pushNamed(
      AppRoute.coursDetailEnseignant,
      pathParameters: {'coursId': cours.id.toString()},
      queryParameters: {
        'titre': cours.titre,
        'estEnseignantPrincipal': 'false',
        'courseColor': couleur.toARGB32().toString(),
      },
    );
  }

  IconData _iconePourCours(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'school':
        return Icons.school_rounded;
      case 'book':
        return Icons.book_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'history':
        return Icons.history_rounded;
      case 'math':
        return Icons.calculate_rounded;
      case 'language':
        return Icons.translate_rounded;
      case 'computer':
        return Icons.computer_rounded;
      case 'art':
        return Icons.art_track_rounded;
      case 'music':
        return Icons.music_note_rounded;
      default:
        return Icons.book_rounded;
    }
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
        YkDashboardTab(label: 'Statistiques', body: _tabStats(context)),
      ],
    );
  }

  Widget _tabCours(BuildContext context) {
    if (_cours.isEmpty) {
      return YkEmptyState(
        icon: Icons.school_outlined,
        title: 'Aucun cours assigné',
        message: 'Les cours vous seront attribués par votre cadre.',
      );
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

  Widget _coursCard(BuildContext context, SecondaireCours cours) {
    final couleur = couleurDepuisHex(cours.colorCode, YkColors.accent(context));
    return YkCard(
      accentColor: couleur,
      onTap: () => _ouvrirDetailCours(cours),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(YkSpacing.xs),
                decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(YkRadius.md)),
                child: Icon(_iconePourCours(cours.iconName), color: couleur, size: 22),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cours.titre, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(cours.niveau, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                  ],
                ),
              ),
              YkBadge(variant: YkBadgeVariant.label, label: 'Assistant', color: YkColors.success),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Icon(Icons.article_rounded, size: 12, color: YkColors.info),
              SizedBox(width: 4),
              Text('${cours.nbLecons} leçons', style: YkTypography.caption(context)),
              SizedBox(width: YkSpacing.sm),
              Icon(Icons.assignment_rounded, size: 12, color: YkColors.warning),
              SizedBox(width: 4),
              Text('${cours.nbDevoirs} devoirs', style: YkTypography.caption(context)),
              SizedBox(width: YkSpacing.sm),
              Icon(Icons.people_rounded, size: 12, color: YkColors.success),
              SizedBox(width: 4),
              Text('${cours.nbApprenants} apprenants', style: YkTypography.caption(context)),
            ],
          ),
          if (cours.tauxCompletion > 0) ...[
            SizedBox(height: YkSpacing.sm),
            YkProgress(shape: YkProgressShape.linear, value: cours.tauxCompletion / 100, color: couleur),
          ],
          if (cours.departementNom != null) ...[
            SizedBox(height: YkSpacing.xs),
            Text(
              'Département : ${cours.departementNom}',
              style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabStats(BuildContext context) {
    final nbCours = _stats['nb_cours'] ?? _cours.length;
    final nbApprenants = _stats['nb_apprenants'] ?? 0;
    final nbLecons = _stats['nb_lecons'] ?? 0;
    final nbDevoirs = _stats['nb_devoirs'] ?? 0;

    return RefreshIndicator(
      onRefresh: _charger,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(YkSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YkDashboardStatGrid(
              cards: [
                YkStatCard(value: '$nbCours', label: 'Cours assignés', icon: Icons.book_outlined),
                YkStatCard(value: '$nbApprenants', label: 'Apprenants', icon: Icons.people_outline),
                YkStatCard(value: '$nbLecons', label: 'Leçons', icon: Icons.article_outlined),
                YkStatCard(value: '$nbDevoirs', label: 'Devoirs', icon: Icons.assignment_outlined),
              ],
            ),
            SizedBox(height: YkSpacing.lg),
            if (_cours.isEmpty)
              YkEmptyState(icon: Icons.book_outlined, title: 'Aucun cours assigné', message: '')
            else
              YkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Détail des cours', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    SizedBox(height: YkSpacing.sm),
                    for (final c in _cours)
                      Padding(
                        padding: EdgeInsets.only(bottom: YkSpacing.xs),
                        child: Row(
                          children: [
                            Container(width: 4, height: 30, decoration: BoxDecoration(color: couleurDepuisHex(c.colorCode, YkColors.accent(context)), borderRadius: BorderRadius.circular(2))),
                            SizedBox(width: YkSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.titre, style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context))),
                                  Text('${c.nbLecons} leçons · ${c.nbDevoirs} devoirs · ${c.nbApprenants} apprenants', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                                ],
                              ),
                            ),
                            YkButton(label: 'Voir', size: YkButtonSize.sm, variant: YkButtonVariant.tertiary, onPressed: () => _ouvrirDetailCours(c)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
