// lib/views/pages/enseignants/departement_detail_page.dart
//
// Refondu en P11.5 (rituel P5.0) : bascule vers `DashboardRepository`
// (plus de `http`/`SharedPreferences` bruts) et les tokens `Yk*`.
// Consolide un doublon confirmé — `AdminDepartementDetailPage`
// (`enseignant_admin_dashboard_page.dart`), code quasi identique servant
// la route `coordinationDepartementDetail` — supprimé, cette page sert
// désormais les deux routes (`adminDepartementDetail` et
// `coordinationDepartementDetail`).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/dashboard_repository.dart';
import 'package:yeki/views/pages/enseignants/dashboard_skeleton.dart';

class DepartementDetailPage extends StatefulWidget {
  final int departementId;
  final String departementNom;
  final String parcoursNom;

  const DepartementDetailPage({
    super.key,
    required this.departementId,
    required this.departementNom,
    required this.parcoursNom,
  });

  @override
  State<DepartementDetailPage> createState() => _DepartementDetailPageState();
}

class _DepartementDetailPageState extends State<DepartementDetailPage> {
  final _repo = DashboardRepository();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _cours = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cours = await _repo.departementCours(widget.departementId);
      if (mounted) setState(() => _cours = cours);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erreur de chargement.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _nbApprenants => _cours.fold<int>(0, (s, c) => s + ((c['nb_apprenants'] as num?) ?? 0).toInt());
  double get _tauxMoyen => _cours.isEmpty ? 0.0 : _cours.fold<double>(0, (s, c) => s + ((c['taux_completion'] as num?) ?? 0.0).toDouble()) / _cours.length;

  void _ouvrirDetailCours(Map<String, dynamic> cours) {
    final couleur = couleurDepuisHex(cours['color_code'] as String?, YkColors.accent(context));
    context.pushNamed(
      AppRoute.coursDetailEnseignant,
      pathParameters: {'coursId': cours['id'].toString()},
      queryParameters: {'titre': (cours['titre'] ?? 'Sans titre') as String, 'estEnseignantPrincipal': 'false', 'courseColor': couleur.toARGB32().toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.departementNom, style: YkTypography.label(context)),
            Text('${widget.parcoursNom} · ${_cours.length} cours', style: YkTypography.caption(context)),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _charger)],
      ),
      body: _loading
          ? Center(child: YkProgress(shape: YkProgressShape.circular))
          : _error != null
              ? YkEmptyState(icon: Icons.error_outline_rounded, title: 'Erreur', message: _error!, actionLabel: 'Réessayer', onAction: _charger)
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView(
                    padding: EdgeInsets.all(YkSpacing.md),
                    children: [
                      Row(
                        children: [
                          Expanded(child: YkStatCard(value: '${_cours.length}', label: 'Cours', icon: Icons.book_rounded)),
                          SizedBox(width: YkSpacing.sm),
                          Expanded(child: YkStatCard(value: '$_nbApprenants', label: 'Apprenants', icon: Icons.people_rounded)),
                          SizedBox(width: YkSpacing.sm),
                          Expanded(child: YkStatCard(value: '${_tauxMoyen.toStringAsFixed(0)}%', label: 'Taux', icon: Icons.bar_chart_rounded)),
                        ],
                      ),
                      SizedBox(height: YkSpacing.lg),
                      if (_cours.isEmpty)
                        YkEmptyState(icon: Icons.book_outlined, title: 'Aucun cours dans ce département', message: '')
                      else
                        for (final c in _cours) Padding(padding: EdgeInsets.only(bottom: YkSpacing.sm), child: _coursCard(context, c)),
                    ],
                  ),
                ),
    );
  }

  Widget _coursCard(BuildContext context, Map<String, dynamic> cours) {
    final couleur = couleurDepuisHex(cours['color_code'] as String?, YkColors.accent(context));
    final taux = (cours['taux_completion'] as num? ?? 0).toDouble();
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
                child: Icon(Icons.book_rounded, color: couleur, size: 22),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cours['titre'] ?? 'Sans titre', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(cours['niveau'] ?? 'Niveau non spécifié', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Wrap(
            spacing: YkSpacing.xs,
            runSpacing: YkSpacing.xxs,
            children: [
              YkBadge(variant: YkBadgeVariant.label, label: '${cours['nb_apprenants'] ?? 0} apprenants', color: YkColors.success),
              YkBadge(variant: YkBadgeVariant.label, label: '${cours['nb_lecons'] ?? 0} leçons', color: YkColors.info),
              YkBadge(variant: YkBadgeVariant.label, label: '${cours['nb_devoirs'] ?? 0} devoirs', color: YkColors.warning),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          YkProgress(shape: YkProgressShape.linear, value: taux / 100, color: couleur),
        ],
      ),
    );
  }
}
