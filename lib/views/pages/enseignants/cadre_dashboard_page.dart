// lib/views/pages/enseignants/cadre_dashboard_page.dart
//
// Refondu en P11.5 (rituel P5.0) : bascule vers `DashboardRepository`
// (plus de `http`/`SharedPreferences` bruts) et le squelette partagé
// `EnseignantDashboardSkeleton`. `_buildCoursCard`/`_buildCoursActions`/
// `_ouvrirCoursDetail` (code mort, jamais appelés dans `build()`, déjà
// flagués `TODO(arbitrage)` en P4.2) supprimés — ce ticket, dont l'objet
// même est de réduire ce fichier, est celui que ce TODO attendait pour
// trancher : aucune section de ce dashboard n'affiche de liste de cours,
// fonctionnalité non câblée nulle part ailleurs non plus. Premier onglet
// renommé "Départements" (affichait déjà des départements sous le nom
// trompeur "Mes cours" — correction de libellé, pas un changement de
// contenu). Classement des départements migré vers `YkLeaderboard`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/features/olympiades/presentation/widgets/creer_olympiade_sheet.dart';
import 'package:yeki/repositories/dashboard_repository.dart';
import 'package:yeki/views/pages/enseignants/dashboard_skeleton.dart';
import 'package:yeki/widgets/creer_cours_sheet.dart';

class CadreDashboardPage extends StatefulWidget {
  const CadreDashboardPage({super.key});

  @override
  State<CadreDashboardPage> createState() => _CadreDashboardPageState();
}

class _CadreDashboardPageState extends State<CadreDashboardPage> with SingleTickerProviderStateMixin {
  final _repo = DashboardRepository();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _departements = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _olympiades = [];
  List<Map<String, dynamic>> _enseignantsPrincipaux = [];
  late final TabController _tabCtrl;
  int? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
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
      final data = await _repo.cadre();
      final olympiades = await _repo.mesOlympiadesCadre();
      if (mounted) {
        setState(() {
          _stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
          _departements = (data['departements'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _enseignantsPrincipaux = (data['enseignants_principaux'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _olympiades = olympiades;
          if (_departements.isNotEmpty && !_departements.any((d) => d['id'] == _selectedDeptId)) {
            _selectedDeptId = _departements.first['id'] as int?;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger votre tableau de bord.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _departementCourant {
    if (_selectedDeptId == null) return null;
    try {
      return _departements.firstWhere((d) => d['id'] == _selectedDeptId);
    } catch (_) {
      return _departements.isNotEmpty ? _departements.first : null;
    }
  }

  int get _nbOlympiadesEnAttente => _olympiades.where((o) => o['est_validee'] == false && o['est_refusee'] == false).length;

  void _ouvrirGestionDemandes(Map<String, dynamic> dept) {
    context.pushNamed(
      AppRoute.cadreGestionDemandes,
      pathParameters: {'departementId': (dept['id'] as int).toString()},
      queryParameters: {'departementNom': dept['nom'] as String? ?? ''},
    ).then((_) => _charger());
  }

  void _ouvrirDetailDepartement(Map<String, dynamic> dept) {
    context.pushNamed(
      AppRoute.cadreDepartementDetail,
      pathParameters: {'departementId': dept['id'].toString()},
      queryParameters: {'departementNom': dept['nom']?.toString() ?? ''},
    ).then((_) => _charger());
  }

  void _ouvrirCreerCours() {
    final dept = _departementCourant;
    if (dept == null) {
      YkSnack.error(context, 'Aucun département assigné.');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreerCoursSheet(departementId: dept['id'] as int, departementNom: dept['nom'] as String? ?? '', onSuccess: _charger),
    );
  }

  void _ouvrirCreerOlympiade() {
    final dept = _departementCourant;
    if (dept == null) {
      YkSnack.error(context, 'Aucun département assigné.');
      return;
    }
    ouvrirCreerOlympiade(
      context,
      departementId: dept['id'] as int,
      departementNom: dept['nom'] as String? ?? '',
      parcoursType: dept['parcours_type']?.toString() ?? 'cursus',
      onSuccess: () {
        YkSnack.success(context, 'Olympiade créée !');
        _charger();
      },
    );
  }

  Future<void> _modifierOlympiade(Map<String, dynamic> olympiade) async {
    if (olympiade['est_validee'] == true || olympiade['est_refusee'] == true) {
      YkSnack.error(context, 'Cette olympiade ne peut plus être modifiée.');
      return;
    }
    ouvrirCreerOlympiade(
      context,
      departementId: _departementCourant?['id'] as int? ?? 0,
      departementNom: _departementCourant?['nom'] as String? ?? '',
      parcoursType: _departementCourant?['parcours_type']?.toString() ?? 'cursus',
      olympiade: olympiade,
      onSuccess: () {
        YkSnack.success(context, 'Olympiade modifiée !');
        _charger();
      },
    );
  }

  Future<void> _lierDevoirOlympiade(Map<String, dynamic> olympiade) async {
    List<Map<String, dynamic>> devoirs;
    try {
      devoirs = await _repo.cadreDevoirs();
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Impossible de charger les devoirs.');
      return;
    }
    if (!mounted) return;
    final candidats = devoirs.where((d) => d['est_lie_olympiade'] != true).toList();
    int? selection;

    await YkSheet.show<void>(
      context: context,
      title: "Lier un devoir à l'olympiade",
      bodyBuilder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olympiade : ${olympiade['titre'] ?? ''}', style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
            SizedBox(height: YkSpacing.sm),
            if (candidats.isEmpty)
              Text('Aucun devoir disponible à lier.', style: YkTypography.bodyMd(context))
            else
              for (final d in candidats)
                RadioListTile<int>(
                  value: d['id'] as int,
                  groupValue: selection,
                  title: Text(d['titre'] ?? ''),
                  subtitle: Text('${d['matiere'] ?? ''} · ${d['niveau'] ?? ''}'),
                  onChanged: (v) => setS(() => selection = v),
                ),
          ],
        ),
      ),
      actionsBuilder: (ctx) => [
        YkButton(
          label: 'Lier',
          onPressed: selection == null
              ? null
              : () async {
                  Navigator.pop(ctx);
                  try {
                    await _repo.lierDevoirOlympiade(olympiade['id'] as int, selection!);
                    if (mounted) YkSnack.success(context, 'Devoir lié avec succès !');
                    _charger();
                  } on ApiException catch (e) {
                    if (mounted) YkSnack.error(context, e.message);
                  } catch (_) {
                    if (mounted) YkSnack.error(context, 'Erreur réseau.');
                  }
                },
        ),
      ],
    );
  }

  void _afficherMenuActions() {
    if (_departements.isEmpty) {
      YkSnack.error(context, 'Aucun département assigné.');
      return;
    }
    YkSheet.show<void>(
      context: context,
      title: 'Actions rapides',
      bodyBuilder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_departements.length > 1)
              YkDropdown<int>(
                label: 'Département',
                value: _selectedDeptId,
                items: [for (final d in _departements) YkDropdownItem(value: d['id'] as int, label: d['nom'] ?? 'Département')],
                onChanged: (v) => setS(() => _selectedDeptId = v),
              ),
            SizedBox(height: YkSpacing.sm),
            YkButton(
              label: 'Créer un cours',
              icon: Icons.book_outlined,
              onPressed: () {
                Navigator.pop(ctx);
                _ouvrirCreerCours();
              },
            ),
            SizedBox(height: YkSpacing.sm),
            YkButton(
              label: 'Créer une olympiade',
              icon: Icons.emoji_events_outlined,
              variant: YkButtonVariant.secondary,
              onPressed: () {
                Navigator.pop(ctx);
                _ouvrirCreerOlympiade();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EnseignantDashboardSkeleton(
      loading: _loading,
      errorMessage: _error,
      onRetry: _charger,
      tabController: _tabCtrl,
      fab: _departements.isEmpty ? null : YkFab(icon: Icons.add_rounded, label: 'Actions', onPressed: _afficherMenuActions),
      tabs: [
        YkDashboardTab(label: 'Départements', body: _tabDepartements(context)),
        YkDashboardTab(label: 'Enseignants', body: _tabEnseignants(context)),
        YkDashboardTab(label: 'Olympiades', badge: _nbOlympiadesEnAttente > 0 ? _nbOlympiadesEnAttente : null, body: _tabOlympiades(context)),
        YkDashboardTab(label: 'Statistiques', body: _tabStats(context)),
      ],
    );
  }

  Widget _tabDepartements(BuildContext context) {
    if (_departements.isEmpty) {
      return YkEmptyState(
        icon: Icons.domain_disabled_rounded,
        title: 'Aucun département assigné',
        message: "Vous n'êtes encore affecté à aucun département. Contactez votre administrateur.",
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: _departements.length,
        separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
        itemBuilder: (_, i) => _departementCard(context, _departements[i]),
      ),
    );
  }

  Widget _departementCard(BuildContext context, Map<String, dynamic> dept) {
    final taux = (dept['taux_moyen'] as num? ?? 0).toDouble();
    final typeDept = dept['type_departement'] as String? ?? 'cursus';
    final accesRestreint = dept['acces_restreint'] as bool? ?? false;
    final demandesAttente = (dept['demandes_acces'] as List?)?.length ?? 0;
    final couleur = couleurDepuisHex(dept['couleur'] as String?, YkColors.accent(context));

    return YkCard(
      accentColor: couleur,
      onTap: () => _ouvrirDetailDepartement(dept),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(YkSpacing.xs),
                decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(YkRadius.md)),
                child: Icon(_iconeTypeDept(typeDept), color: couleur, size: 22),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dept['nom'] ?? 'Département', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    Text(_libelleTypeDept(typeDept), style: YkTypography.caption(context).copyWith(color: couleur)),
                  ],
                ),
              ),
              YkBadge(variant: YkBadgeVariant.label, label: '${dept['nb_cours'] ?? 0} cours', color: couleur),
            ],
          ),
          if ((dept['description'] as String?)?.isNotEmpty == true) ...[
            SizedBox(height: YkSpacing.sm),
            Text(dept['description'], maxLines: 2, overflow: TextOverflow.ellipsis, style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
          ],
          SizedBox(height: YkSpacing.sm),
          Wrap(
            spacing: YkSpacing.xs,
            runSpacing: YkSpacing.xs,
            children: [
              YkBadge(variant: YkBadgeVariant.label, label: '${dept['nb_apprenants'] ?? 0} apprenants', color: YkColors.accent(context)),
              if ((dept['ville'] as String?)?.isNotEmpty == true) YkBadge(variant: YkBadgeVariant.label, label: dept['ville'], color: YkColors.info),
              if ((dept['prix'] as num? ?? 0) > 0)
                YkBadge(variant: YkBadgeVariant.label, label: '${dept['prix']} FCFA', color: YkColors.warning)
              else
                YkBadge(variant: YkBadgeVariant.label, label: 'Gratuit', color: YkColors.success),
              if (accesRestreint) YkBadge(variant: YkBadgeVariant.label, label: 'Sur demande', color: YkColors.accent(context)),
            ],
          ),
          if (accesRestreint) ...[
            SizedBox(height: YkSpacing.sm),
            YkButton(
              label: demandesAttente > 0 ? "Demandes d'accès ($demandesAttente)" : "Demandes d'accès",
              icon: Icons.person_add_alt_1_rounded,
              variant: YkButtonVariant.tertiary,
              size: YkButtonSize.sm,
              onPressed: () => _ouvrirGestionDemandes(dept),
            ),
          ],
          SizedBox(height: YkSpacing.sm),
          YkProgress(shape: YkProgressShape.linear, value: taux / 100, color: couleur),
        ],
      ),
    );
  }

  IconData _iconeTypeDept(String type) {
    switch (type) {
      case 'prepa_concours':
        return Icons.emoji_events_rounded;
      case 'formation_metier':
        return Icons.work_rounded;
      case 'formation_classique':
        return Icons.account_balance_rounded;
      default:
        return Icons.domain_rounded;
    }
  }

  String _libelleTypeDept(String type) {
    switch (type) {
      case 'prepa_concours':
        return 'Prépa Concours';
      case 'formation_metier':
        return 'Formation Métier';
      case 'formation_classique':
        return 'Formation Classique';
      default:
        return 'Département';
    }
  }

  Widget _tabEnseignants(BuildContext context) {
    if (_enseignantsPrincipaux.isEmpty) {
      return YkEmptyState(icon: Icons.person_outline_rounded, title: 'Aucun enseignant principal assigné', message: '');
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: _enseignantsPrincipaux.length,
        separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
        itemBuilder: (_, i) => _enseignantCard(context, _enseignantsPrincipaux[i]),
      ),
    );
  }

  Widget _enseignantCard(BuildContext context, Map<String, dynamic> ep) {
    final score = (ep['score_moyen'] as num? ?? 0).toDouble();
    final nom = ep['nom'] ?? ep['username'] ?? '';
    return YkCard(
      child: Row(
        children: [
          YkAvatar(imageUrl: ep['photo'] as String?, fallbackText: nom, size: YkAvatarSize.lg),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: YkSpacing.xxs),
                Wrap(
                  spacing: YkSpacing.xs,
                  children: [
                    YkBadge(variant: YkBadgeVariant.label, label: '${ep['nb_cours'] ?? 0} cours', color: YkColors.accent(context)),
                    YkBadge(variant: YkBadgeVariant.label, label: '${ep['nb_apprenants'] ?? 0} apprenants', color: YkColors.accent(context)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(score.toStringAsFixed(1), style: YkTypography.h3(context).copyWith(color: YkColors.accent(context))),
              Text('/20 moy.', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabOlympiades(BuildContext context) {
    if (_olympiades.isEmpty) {
      return YkEmptyState(
        icon: Icons.military_tech_rounded,
        title: 'Aucune olympiade créée',
        message: 'Créez votre première olympiade depuis le menu Actions.',
        actionLabel: 'Créer une olympiade',
        onAction: _ouvrirCreerOlympiade,
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: _olympiades.length,
        separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
        itemBuilder: (_, i) => _olympiadeCard(context, _olympiades[i]),
      ),
    );
  }

  Widget _olympiadeCard(BuildContext context, Map<String, dynamic> olympiade) {
    final estValidee = olympiade['est_validee'] as bool? ?? false;
    final estRefusee = olympiade['est_refusee'] as bool? ?? false;
    final estPubliee = olympiade['est_publiee'] as bool? ?? false;
    final prixGlobal = (olympiade['prix_global'] as num? ?? 0);

    Color couleurStatut;
    String libelleStatut;
    if (estRefusee) {
      couleurStatut = YkColors.error;
      libelleStatut = 'Refusée';
    } else if (estValidee && estPubliee) {
      couleurStatut = YkColors.success;
      libelleStatut = 'Validée';
    } else if (prixGlobal > 0 && !estPubliee) {
      couleurStatut = YkColors.warning;
      libelleStatut = 'En attente de paiement';
    } else {
      couleurStatut = YkColors.warning;
      libelleStatut = 'En attente de validation';
    }
    final estModifiable = !estValidee && !estRefusee && !estPubliee;

    return YkCard(
      accentColor: couleurStatut,
      onTap: () => _detailOlympiade(context, olympiade),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(YkSpacing.xs),
                decoration: BoxDecoration(color: YkColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(YkRadius.md)),
                child: Icon(Icons.military_tech_rounded, color: YkColors.warning, size: 20),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(olympiade['titre'] ?? 'Olympiade', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    if ((olympiade['edition'] as String?)?.isNotEmpty == true)
                      Text(olympiade['edition'], style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                  ],
                ),
              ),
              YkBadge(variant: YkBadgeVariant.label, label: libelleStatut, color: couleurStatut),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Wrap(
            spacing: YkSpacing.xs,
            runSpacing: YkSpacing.xs,
            children: [
              YkBadge(variant: YkBadgeVariant.label, label: 'Début : ${_formaterDate(olympiade['date_debut_olympiade'])}', color: YkColors.accent(context)),
              YkBadge(variant: YkBadgeVariant.label, label: 'Fin : ${_formaterDate(olympiade['date_fin_olympiade'])}', color: YkColors.accent(context)),
              if ((olympiade['nb_inscrits'] as num? ?? 0) > 0)
                YkBadge(variant: YkBadgeVariant.label, label: '${olympiade['nb_inscrits']} inscrits', color: YkColors.info),
              if (prixGlobal > 0) YkBadge(variant: YkBadgeVariant.label, label: '$prixGlobal FCFA', color: YkColors.warning),
              if (estRefusee && olympiade['motif_refus'] != null)
                YkBadge(variant: YkBadgeVariant.label, label: 'Motif : ${olympiade['motif_refus']}', color: YkColors.error),
            ],
          ),
          if (estModifiable) ...[
            SizedBox(height: YkSpacing.sm),
            Row(
              children: [
                if (!estPubliee && olympiade['devoir_id'] == null) ...[
                  Expanded(child: YkButton(label: 'Lier un devoir', icon: Icons.link_rounded, variant: YkButtonVariant.secondary, size: YkButtonSize.sm, onPressed: () => _lierDevoirOlympiade(olympiade))),
                  SizedBox(width: YkSpacing.xs),
                ],
                Expanded(child: YkButton(label: 'Modifier', icon: Icons.edit_outlined, variant: YkButtonVariant.secondary, size: YkButtonSize.sm, onPressed: () => _modifierOlympiade(olympiade))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formaterDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return date.toString().substring(0, 10);
    }
  }

  void _detailOlympiade(BuildContext context, Map<String, dynamic> olympiade) {
    YkSheet.show<void>(
      context: context,
      title: olympiade['titre'] ?? 'Olympiade',
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ligneInfo(context, 'Édition', olympiade['edition'] ?? ''),
          _ligneInfo(context, 'Date début', olympiade['date_debut_olympiade']?.toString().substring(0, 10) ?? ''),
          _ligneInfo(context, 'Date fin', olympiade['date_fin_olympiade']?.toString().substring(0, 10) ?? ''),
          _ligneInfo(context, 'Durée', '${olympiade['duree_minutes'] ?? 0} min'),
          _ligneInfo(context, 'Questions', '${olympiade['nb_questions'] ?? 0}'),
          _ligneInfo(context, 'Inscrits', '${olympiade['nb_inscrits'] ?? 0}'),
          if ((olympiade['prix_global'] as num? ?? 0) > 0) _ligneInfo(context, 'Prix global', '${olympiade['prix_global']} FCFA'),
          if ((olympiade['description'] as String?)?.isNotEmpty == true) ...[
            SizedBox(height: YkSpacing.sm),
            Text('Description', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.xxs),
            Text(olympiade['description'], style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
          ],
        ],
      ),
    );
  }

  Widget _ligneInfo(BuildContext context, String label, String valeur) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: YkSpacing.xxs),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)))),
          SizedBox(width: YkSpacing.sm),
          Expanded(child: Text(valeur.isNotEmpty ? valeur : '—', style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context)))),
        ],
      ),
    );
  }

  Widget _tabStats(BuildContext context) {
    final nbDepts = _stats['nb_departements'] ?? _departements.length;
    final tauxMoyen = (_stats['taux_moyen'] as num? ?? 0).toDouble();

    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YkDashboardStatGrid(
            cards: [
              YkStatCard(value: '$nbDepts', label: 'Départements', icon: Icons.domain_rounded),
              YkStatCard(value: '${_stats['nb_cours'] ?? 0}', label: 'Cours', icon: Icons.book_rounded),
              YkStatCard(value: '${_stats['nb_apprenants'] ?? 0}', label: 'Apprenants', icon: Icons.people_rounded),
              YkStatCard(value: '${_stats['nb_enseignants'] ?? 0}', label: 'Enseignants', icon: Icons.person_outline_rounded),
            ],
          ),
          SizedBox(height: YkSpacing.lg),
          YkCard(
            variant: YkCardVariant.filled,
            accentColor: YkColors.accent(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Taux de complétion moyen', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                SizedBox(height: YkSpacing.sm),
                YkProgress(shape: YkProgressShape.linear, value: tauxMoyen / 100, color: YkColors.accent(context)),
                SizedBox(height: YkSpacing.xxs),
                Text('${tauxMoyen.toStringAsFixed(0)}%', style: YkTypography.h4(context).copyWith(color: YkColors.accent(context))),
              ],
            ),
          ),
          if (_departements.isNotEmpty) ...[
            SizedBox(height: YkSpacing.lg),
            Text('Classement des départements', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            YkLeaderboard(entries: _classementDepartements(), showPodium: false),
          ],
          SizedBox(height: YkSpacing.lg),
          Text('Actions rapides', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Expanded(child: YkButton(label: 'Nouveau cours', icon: Icons.add_circle_outline, variant: YkButtonVariant.secondary, onPressed: _ouvrirCreerCours)),
              SizedBox(width: YkSpacing.sm),
              Expanded(child: YkButton(label: 'Olympiade', icon: Icons.emoji_events_outlined, variant: YkButtonVariant.secondary, onPressed: _ouvrirCreerOlympiade)),
            ],
          ),
        ],
      ),
    );
  }

  List<YkLeaderboardEntry> _classementDepartements() {
    final tries = List<Map<String, dynamic>>.from(_departements)
      ..sort((a, b) => ((b['taux_moyen'] as num?) ?? 0).compareTo((a['taux_moyen'] as num?) ?? 0));
    return [
      for (var i = 0; i < tries.length; i++)
        YkLeaderboardEntry(rank: i + 1, name: tries[i]['nom'] ?? 'Département', points: ((tries[i]['taux_moyen'] as num?) ?? 0).round()),
    ];
  }
}
