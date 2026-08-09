// lib/views/pages/enseignants/enseignant_admin_dashboard_page.dart
//
// Refondu en P11.5 (rituel P5.0) : bascule vers `DashboardRepository`
// (plus de `http`/`SharedPreferences` bruts) et le squelette partagé
// `EnseignantDashboardSkeleton`. `AdminDepartementDetailPage` (embarquée
// ici) supprimée — doublon confirmé de `departement_detail_page.dart`
// (`DepartementDetailPage`, même code quasi identique) ; les deux routes
// (`adminDepartementDetail`, `coordinationDepartementDetail`) pointent
// désormais vers ce fichier unique. Formulaire création/modification de
// département extrait dans `departement_form_sheet.dart` (~700 lignes
// dupliquées entre les 2 anciennes méthodes, unifiées en un seul
// formulaire piloté par un paramètre `existant`).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/dashboard_repository.dart';
import 'package:yeki/repositories/olympiade_repository.dart';
import 'package:yeki/views/pages/enseignants/dashboard_skeleton.dart';
import 'package:yeki/views/pages/enseignants/departement_form_sheet.dart';
import 'package:yeki/views/pages/enseignants/olympiades_a_valider_tab.dart';

Color _couleurTypeDept(BuildContext context, String type) {
  switch (type) {
    case 'classique':
      return YkColors.info;
    case 'metier':
      return YkColors.warning;
    case 'concours':
      return YkColors.success;
    default:
      return YkColors.accent(context);
  }
}

const _typeDeptIcons = {
  'normal': Icons.domain_rounded,
  'classique': Icons.account_balance_rounded,
  'metier': Icons.work_rounded,
  'concours': Icons.emoji_events_rounded,
};

const _typeDeptLabels = {
  'normal': 'Département',
  'classique': 'Formation Classique',
  'metier': 'Formation Métier',
  'concours': 'Prépa Concours',
};

class EnseignantAdminDashboardPage extends StatefulWidget {
  const EnseignantAdminDashboardPage({super.key});

  @override
  State<EnseignantAdminDashboardPage> createState() => _EnseignantAdminDashboardPageState();
}

class _EnseignantAdminDashboardPageState extends State<EnseignantAdminDashboardPage> with SingleTickerProviderStateMixin {
  final _repo = DashboardRepository();
  final _olympiadeRepo = OlympiadeRepository();
  late final TabController _tabCtrl;

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _departements = [];
  List<Map<String, dynamic>> _cadres = [];
  String _nomParcours = '';
  int _idParcours = 0;
  String _typeParcours = 'cursus';
  int _nbOlympiadesEnAttente = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
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
      final data = await _repo.admin();
      if (mounted) {
        setState(() {
          _stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
          _departements = (data['departements'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _cadres = (data['cadres'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _idParcours = data['id_parcours'] as int? ?? 0;
          _nomParcours = data['nom_parcours'] as String? ?? '';
          _typeParcours = data['type_parcours'] as String? ?? 'cursus';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger votre tableau de bord.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _chargerNbOlympiadesEnAttente();
  }

  /// Compteur pour le badge de l'onglet — même motif que
  /// `cadre_dashboard_page.dart._nbOlympiadesEnAttente`. Non bloquant :
  /// un échec laisse simplement le badge à 0 plutôt que de gêner le
  /// chargement du reste du dashboard.
  Future<void> _chargerNbOlympiadesEnAttente() async {
    try {
      final liste = await _olympiadeRepo.aValiderAdmin();
      if (mounted) setState(() => _nbOlympiadesEnAttente = liste.where((o) => o['statut_validation'] == 'attente').length);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _chargerTousLesCours() async {
    try {
      final cours = await _repo.tousLesCours();
      return cours.where((c) => c['parcours_id'] == _idParcours).toList();
    } catch (_) {
      return [];
    }
  }

  void _voirDetailDepartement(Map<String, dynamic> dept) {
    context.pushNamed(
      AppRoute.coordinationDepartementDetail,
      pathParameters: {'departementId': dept['id'].toString()},
      queryParameters: {'departementNom': dept['nom']?.toString() ?? '', 'parcoursNom': _nomParcours},
    ).then((_) => _charger());
  }

  void _creerDepartement() {
    ouvrirDepartementForm(context: context, typeParcours: _typeParcours, idParcours: _idParcours, nomParcours: _nomParcours, onSuccess: _charger);
  }

  void _modifierDepartement(Map<String, dynamic> dept) {
    ouvrirDepartementForm(context: context, typeParcours: _typeParcours, idParcours: _idParcours, nomParcours: _nomParcours, existant: dept, onSuccess: _charger);
  }

  Future<void> _changerCadre(Map<String, dynamic> dept) async {
    List<Map<String, dynamic>> cadresDisp;
    try {
      cadresDisp = await _repo.enseignantsListe('cadre');
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Impossible de charger les cadres.');
      return;
    }
    if (!mounted) return;

    int? selection = dept['cadre']?['id'] as int?;
    await YkSheet.show<void>(
      context: context,
      title: dept['cadre'] == null ? 'Nommer un cadre' : 'Changer le cadre',
      bodyBuilder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Département : ${dept['nom'] ?? ''}', style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
            SizedBox(height: YkSpacing.sm),
            if (cadresDisp.isEmpty)
              Text('Aucun enseignant cadre disponible.', style: YkTypography.bodyMd(context))
            else
              for (final c in cadresDisp)
                RadioListTile<int>(
                  value: c['id'] as int,
                  groupValue: selection,
                  title: Text(c['nom'] ?? c['username'] ?? ''),
                  subtitle: Text(c['email'] ?? ''),
                  onChanged: (v) => setS(() => selection = v),
                ),
          ],
        ),
      ),
      actionsBuilder: (ctx) => [
        YkButton(
          label: 'Confirmer',
          onPressed: selection == null
              ? null
              : () async {
                  Navigator.pop(ctx);
                  try {
                    await _repo.changerCadre(dept['id'] as int, selection!);
                    if (mounted) YkSnack.success(context, 'Cadre modifié !');
                    _charger();
                  } catch (_) {
                    if (mounted) YkSnack.error(context, 'Erreur réseau.');
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
      heroCard: YkDashboardHeroBanner(
        title: _nomParcours.isEmpty ? 'Mon parcours' : _nomParcours,
        stats: [
          ('${_stats['nb_departements'] ?? _departements.length}', 'Départements'),
          ('${_stats['nb_cours'] ?? 0}', 'Cours'),
          ('${_stats['nb_apprenants'] ?? 0}', 'Inscrits'),
        ],
      ),
      tabController: _tabCtrl,
      fab: _nomParcours.isEmpty ? null : YkFab(icon: Icons.add_rounded, label: 'Département', onPressed: _creerDepartement),
      tabs: [
        YkDashboardTab(label: 'Départements', body: _tabDepartements(context)),
        YkDashboardTab(label: 'Cadres', body: _tabCadres(context)),
        YkDashboardTab(label: 'Statistiques', body: _tabStats(context)),
        YkDashboardTab(label: 'Tous les cours', body: _tabTousCours(context)),
        // Validation admin des olympiades — rétablie (demande explicite).
        YkDashboardTab(
          label: 'Olympiades',
          badge: _nbOlympiadesEnAttente > 0 ? _nbOlympiadesEnAttente : null,
          body: OlympiadesAValiderTab(onChanged: _chargerNbOlympiadesEnAttente),
        ),
      ],
    );
  }

  Widget _tabDepartements(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: EdgeInsets.all(YkSpacing.md),
        children: [
          _parcoursCard(context),
          SizedBox(height: YkSpacing.md),
          if (_departements.isEmpty)
            YkEmptyState(
              icon: Icons.domain_rounded,
              title: _typeParcours == 'prepa' ? 'Aucun concours créé' : (_typeParcours == 'formation' ? 'Aucune formation créée' : 'Aucun département créé'),
              message: 'Commencez par créer votre premier élément.',
            )
          else
            for (final d in _departements) Padding(padding: EdgeInsets.only(bottom: YkSpacing.sm), child: _deptCard(context, d)),
        ],
      ),
    );
  }

  Widget _parcoursCard(BuildContext context) {
    if (_nomParcours.isEmpty) {
      return YkCard(
        variant: YkCardVariant.outlined,
        accentColor: YkColors.warning,
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: YkColors.warning),
            SizedBox(width: YkSpacing.sm),
            Expanded(child: Text("Aucun parcours ne vous est encore assigné.\nContactez l'administrateur général.", style: YkTypography.bodySm(context).copyWith(color: YkColors.warning))),
          ],
        ),
      );
    }
    final typeIcon = const {'cursus': Icons.school_rounded, 'prepa': Icons.emoji_events_rounded, 'formation': Icons.work_rounded, 'olympiade': Icons.military_tech_rounded}[_typeParcours] ?? Icons.domain_rounded;

    return YkCard(
      variant: YkCardVariant.filled,
      accentColor: YkColors.accent(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, color: YkColors.accent(context), size: 22),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mon parcours', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                    Text('Coordonnateur', style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
                  ],
                ),
              ),
              YkBadge(variant: YkBadgeVariant.label, label: '${_departements.length} dép.', color: YkColors.accent(context)),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          Divider(color: YkColors.border(context)),
          SizedBox(height: YkSpacing.sm),
          Text(_nomParcours, style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context))),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              _quickStat(context, '${_stats['nb_cours'] ?? 0}', 'cours'),
              SizedBox(width: YkSpacing.md),
              _quickStat(context, '${_stats['nb_apprenants'] ?? 0}', 'inscrits'),
              SizedBox(width: YkSpacing.md),
              _quickStat(context, '${_stats['nb_enseignants'] ?? 0}', 'cadres'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickStat(BuildContext context, String valeur, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(valeur, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
      Text(label, style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
    ],
  );

  Widget _deptCard(BuildContext context, Map<String, dynamic> dept) {
    final typeDept = dept['type_dept'] as String? ?? 'normal';
    final prix = dept['prix'] as int? ?? 0;
    final cadre = dept['cadre'] as Map?;
    final couleur = _couleurTypeDept(context, typeDept);
    final niveauFormation = dept['niveau_formation'] as String?;

    return YkCard(
      accentColor: couleur,
      onTap: () => _voirDetailDepartement(dept),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(YkSpacing.xs),
                decoration: BoxDecoration(color: couleur.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(YkRadius.md)),
                child: Icon(_typeDeptIcons[typeDept] ?? Icons.domain_rounded, color: couleur, size: 22),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dept['nom'] ?? '', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                    SizedBox(height: YkSpacing.xxs),
                    Wrap(
                      spacing: YkSpacing.xs,
                      children: [
                        YkBadge(variant: YkBadgeVariant.label, label: _typeDeptLabels[typeDept] ?? 'Département', color: couleur),
                        if (prix > 0)
                          YkBadge(variant: YkBadgeVariant.label, label: '$prix FCFA', color: YkColors.accent(context))
                        else
                          YkBadge(variant: YkBadgeVariant.label, label: 'Gratuit', color: YkColors.success),
                        if (typeDept == 'metier' && niveauFormation != null) YkBadge(variant: YkBadgeVariant.label, label: 'Niv. $niveauFormation', color: YkColors.warning),
                      ],
                    ),
                  ],
                ),
              ),
              YkIconButton(
                icon: cadre == null ? Icons.person_add_outlined : Icons.swap_horiz,
                label: cadre == null ? 'Nommer un cadre' : 'Changer cadre',
                variant: YkIconButtonVariant.ghost,
                onPressed: () => _changerCadre(dept),
              ),
              YkIconButton(icon: Icons.edit_outlined, label: 'Modifier le département', variant: YkIconButtonVariant.ghost, onPressed: () => _modifierDepartement(dept)),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          if (cadre != null)
            Row(
              children: [
                Icon(Icons.person_rounded, size: 14, color: YkColors.accent(context)),
                SizedBox(width: YkSpacing.xxs),
                Text('Cadre : ${cadre['nom'] ?? cadre['username'] ?? ''}', style: YkTypography.bodySm(context).copyWith(color: YkColors.textPrimary(context))),
              ],
            )
          else
            YkBadge(variant: YkBadgeVariant.label, label: 'Aucun cadre nommé', color: YkColors.warning),
          SizedBox(height: YkSpacing.sm),
          Row(
            children: [
              Icon(Icons.book_outlined, size: 13, color: YkColors.textSecondary(context)),
              SizedBox(width: YkSpacing.xxs),
              Text('${dept['nb_cours'] ?? 0} cours', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
              SizedBox(width: YkSpacing.sm),
              Icon(Icons.people_outline, size: 13, color: YkColors.textSecondary(context)),
              SizedBox(width: YkSpacing.xxs),
              Text('${dept['nb_inscrits'] ?? 0} inscrits', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabCadres(BuildContext context) {
    if (_cadres.isEmpty) {
      return YkEmptyState(icon: Icons.person_outline_rounded, title: 'Aucun enseignant cadre', message: '');
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: EdgeInsets.all(YkSpacing.md),
        itemCount: _cadres.length,
        separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
        itemBuilder: (_, i) => _cadreCard(context, _cadres[i]),
      ),
    );
  }

  Widget _cadreCard(BuildContext context, Map<String, dynamic> cadre) {
    final dept = cadre['departement'] as Map?;
    final nom = cadre['nom'] ?? cadre['username'] ?? '';
    return YkCard(
      child: Row(
        children: [
          YkAvatar(fallbackText: nom, size: YkAvatarSize.lg),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                if (dept != null) Text(dept['nom'] ?? '', style: YkTypography.caption(context).copyWith(color: YkColors.accent(context))),
                Text('${cadre['nb_cours'] ?? 0} cours · ${cadre['nb_apprenants'] ?? 0} apprenants', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabStats(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YkDashboardStatGrid(
            cards: [
              YkStatCard(value: '${_stats['nb_departements'] ?? _departements.length}', label: 'Départements', icon: Icons.domain),
              YkStatCard(value: '${_stats['nb_cours'] ?? 0}', label: 'Cours', icon: Icons.book),
              YkStatCard(value: '${_stats['nb_apprenants'] ?? 0}', label: 'Inscrits', icon: Icons.people),
              YkStatCard(value: '${_stats['nb_enseignants'] ?? 0}', label: 'Cadres', icon: Icons.person_outline),
            ],
          ),
          if (_departements.isNotEmpty) ...[
            SizedBox(height: YkSpacing.lg),
            Text('Classement des départements', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            YkLeaderboard(entries: _classement(), showPodium: false),
          ],
        ],
      ),
    );
  }

  List<YkLeaderboardEntry> _classement() {
    final tries = List<Map<String, dynamic>>.from(_departements)
      ..sort((a, b) => ((b['taux_moyen'] as num?) ?? 0).compareTo((a['taux_moyen'] as num?) ?? 0));
    return [for (var i = 0; i < tries.length; i++) YkLeaderboardEntry(rank: i + 1, name: tries[i]['nom'] ?? '', points: ((tries[i]['taux_moyen'] as num?) ?? 0).round())];
  }

  Widget _tabTousCours(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _chargerTousLesCours(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: YkProgress(shape: YkProgressShape.circular));
        }
        final cours = snapshot.data ?? [];
        if (cours.isEmpty) {
          return YkEmptyState(icon: Icons.book_outlined, title: 'Aucun cours créé dans ce parcours', message: '');
        }
        return RefreshIndicator(
          onRefresh: _charger,
          child: ListView.separated(
            padding: EdgeInsets.all(YkSpacing.md),
            itemCount: cours.length,
            separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
            itemBuilder: (_, i) => _coursCard(context, cours[i]),
          ),
        );
      },
    );
  }

  Widget _coursCard(BuildContext context, Map<String, dynamic> cours) {
    final couleur = couleurDepuisHex(cours['color_code'] as String?, YkColors.accent(context));
    return YkCard(
      accentColor: couleur,
      onTap: () => context.pushNamed(
        AppRoute.coursDetailEnseignant,
        pathParameters: {'coursId': cours['id'].toString()},
        queryParameters: {'titre': (cours['titre'] ?? 'Sans titre') as String, 'estEnseignantPrincipal': 'true', 'courseColor': couleur.toARGB32().toString()},
      ),
      child: Row(
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
                Text(cours['titre'] ?? 'Sans titre', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                Text('${cours['niveau'] ?? 'Niveau non spécifié'} · ${cours['nb_apprenants'] ?? 0} apprenants', style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context))),
                if (cours['departement'] != null)
                  Text('Département : ${cours['departement']}', style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
