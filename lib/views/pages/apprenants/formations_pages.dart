// lib/views/pages/apprenants/formations_pages.dart
//
// Refondu en P11.2 (rituel P5.0, migration mécanique) : bascule vers
// `FormationRepository` (plus de `http`/`SharedPreferences` bruts) et les
// tokens/composants `Yk*` (plus de `YekiColors`/`YekiButton`/glassmorphism
// codée en dur).
//
// Flux "demande d'accès" DÉJÀ implémenté ici (vérification → en attente/
// refusée/à demander → formulaire → envoi) — migré vers
// `FormationRepository.verifierAcces`/`demanderAcces`, comportement
// inchangé.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/formation_repository.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';

class FormationsPage extends StatefulWidget {
  const FormationsPage({super.key});

  @override
  State<FormationsPage> createState() => _FormationsPageState();
}

class _FormationsPageState extends State<FormationsPage> with SingleTickerProviderStateMixin {
  final _repo = FormationRepository();

  bool _loading = true;
  bool _enErreur = false;
  List<DepartementItem> _tous = const [];
  late final TabController _tabCtrl;
  String _niveauApprenant = '';
  String _recherche = '';
  String _filtreProgression = 'Toutes';

  static const _types = ['Tout', 'Métier', 'Classique'];
  static const _filtresProgression = ['Toutes', 'En cours', 'Nouvelles', 'Terminées'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _types.length, vsync: this)..addListener(() => setState(() {}));
    _chargerNiveau();
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerNiveau() async {
    final niveau = await NiveauService.getNiveau();
    if (mounted && niveau != null) setState(() => _niveauApprenant = niveau);
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _enErreur = false;
    });
    try {
      final formations = await _repo.formations();
      if (!mounted) return;
      setState(() {
        _tous = formations;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _enErreur = true;
          _loading = false;
        });
      }
    }
  }

  List<DepartementItem> get _affiches {
    final q = _recherche.toLowerCase();
    final tab = _tabCtrl.index;
    return _tous.where((d) {
      final matchType = switch (tab) {
        1 => d.estFormationMetier,
        2 => d.estFormationClassique,
        _ => true,
      };
      final matchNiveau = _niveauApprenant.isEmpty || d.niveauxAccessibles.isEmpty
          ? true
          : NiveauService.estAccessibleParListe(_niveauApprenant, d.niveauxAccessibles);
      final matchProgression = switch (_filtreProgression) {
        'En cours' => d.progression > 0 && d.progression < 100,
        'Nouvelles' => d.progression == 0,
        'Terminées' => d.progression >= 100,
        _ => true,
      };
      final matchRecherche =
          q.isEmpty ||
          d.nom.toLowerCase().contains(q) ||
          d.domaine.toLowerCase().contains(q) ||
          d.ville.toLowerCase().contains(q) ||
          d.dureeFormation.toLowerCase().contains(q);
      return matchType && matchProgression && matchRecherche && matchNiveau;
    }).toList();
  }

  IconData _iconePourFormation(DepartementItem dept) {
    final domaine = dept.domaine.toLowerCase();
    final nom = dept.nom.toLowerCase();
    if (domaine.contains('tech') || domaine.contains('informatique') || nom.contains('programmation')) {
      return Icons.terminal_rounded;
    }
    if (domaine.contains('business') || domaine.contains('gestion') || domaine.contains('finance')) {
      return Icons.trending_up_rounded;
    }
    if (domaine.contains('design') || domaine.contains('créativ')) return Icons.palette_rounded;
    if (domaine.contains('santé') || domaine.contains('médical')) return Icons.health_and_safety_rounded;
    if (domaine.contains('artisanat') || dept.estFormationMetier) return Icons.handyman_rounded;
    if (dept.modeFormation == 'distance') return Icons.laptop_rounded;
    return dept.estFormationMetier ? Icons.work_rounded : Icons.account_balance_rounded;
  }

  Color _parseColor(String hex, {bool metier = false}) {
    try {
      return Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      return metier ? YkColors.accent(context) : YkColors.info;
    }
  }

  Future<void> _ouvrirFormation(DepartementItem dept) async {
    if (dept.accesRestreint != true) {
      await context
          .pushNamed(AppRoute.formationDetail, pathParameters: {'formationId': dept.id.toString()}, extra: dept)
          .then((_) => _charger());
      return;
    }
    try {
      final acces = await _repo.verifierAcces(dept.id);
      if (!mounted) return;
      if (acces['acces'] == true) {
        await context
            .pushNamed(AppRoute.formationDetail, pathParameters: {'formationId': dept.id.toString()}, extra: dept)
            .then((_) => _charger());
      } else if (acces['statut'] == 'en_attente') {
        YkSnack.warning(context, "Votre demande d'accès est en attente de traitement.");
      } else if (acces['statut'] == 'refusee') {
        YkSnack.error(context, 'Accès refusé. Veuillez contacter le service client.');
      } else {
        _demanderAcces(dept);
      }
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    }
  }

  void _demanderAcces(DepartementItem dept) {
    final controleur = TextEditingController();
    YkSheet.show<void>(
      context: context,
      title: "Demander l'accès",
      bodyBuilder: (context) => Padding(
        padding: EdgeInsets.all(YkSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cette formation est à accès restreint. Expliquez brièvement votre demande.',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            SizedBox(height: YkSpacing.md),
            YkTextField(
              controller: controleur,
              type: YkTextFieldType.multiline,
              maxLines: 4,
              hint: 'Expliquez pourquoi vous souhaitez accéder à cette formation…',
            ),
          ],
        ),
      ),
      actionsBuilder: (context) => [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        YkButton(
          label: 'Envoyer la demande',
          onPressed: () {
            Navigator.of(context).pop();
            _envoyerDemandeAcces(dept.id, controleur.text.trim());
          },
        ),
      ],
    );
  }

  Future<void> _envoyerDemandeAcces(int departementId, String message) async {
    try {
      await _repo.demanderAcces(departementId, message);
      if (mounted) YkSnack.success(context, 'Votre demande a été envoyée au cadre.');
      _charger();
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: SafeArea(
        child: _loading
            ? Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 4, itemHeight: 220))
            : _enErreur
            ? YkEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Impossible de charger les formations',
                message: 'Vérifiez votre connexion puis réessayez.',
                actionLabel: 'Réessayer',
                onAction: _charger,
              )
            : RefreshIndicator(
                onRefresh: _charger,
                child: ListView(
                  padding: EdgeInsets.all(YkSpacing.md),
                  children: [
                    _buildEnTete(context),
                    SizedBox(height: YkSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: YkTextField(
                            type: YkTextFieldType.search,
                            hint: 'Rechercher une formation…',
                            onChanged: (v) => setState(() => _recherche = v),
                          ),
                        ),
                        SizedBox(width: YkSpacing.xs),
                        _buildFiltreProgressionMenu(context),
                      ],
                    ),
                    SizedBox(height: YkSpacing.sm),
                    YkTabs(
                      controller: _tabCtrl,
                      tabs: [
                        for (var i = 0; i < _types.length; i++)
                          YkTabItem(label: '${_types[i]} (${_compterParOnglet(i)})'),
                      ],
                    ),
                    SizedBox(height: YkSpacing.md),
                    Row(
                      children: [
                        Text(
                          'Vos formations',
                          style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                        ),
                        const Spacer(),
                        YkBadge(
                          variant: YkBadgeVariant.label,
                          label: '${_affiches.length} disponibles',
                          color: YkColors.accent(context),
                        ),
                      ],
                    ),
                    SizedBox(height: YkSpacing.sm),
                    if (_affiches.isEmpty)
                      YkEmptyState(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Aucune formation disponible',
                        message: "Ajustez vos filtres ou explorez d'autres catégories.",
                      )
                    else
                      for (final dept in _affiches) _buildCarteFormation(context, dept),
                  ],
                ),
              ),
      ),
    );
  }

  int _compterParOnglet(int index) {
    return switch (index) {
      1 => _tous.where((d) => d.estFormationMetier).length,
      2 => _tous.where((d) => d.estFormationClassique).length,
      _ => _tous.length,
    };
  }

  Widget _buildEnTete(BuildContext context) {
    return YkCard(
      variant: YkCardVariant.filled,
      accentColor: YkColors.accent(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YkBadge(
            variant: YkBadgeVariant.label,
            label: 'DÉVELOPPEMENT PROFESSIONNEL',
            color: YkColors.accent(context),
          ),
          SizedBox(height: YkSpacing.xs),
          Text('Formations', style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context))),
          SizedBox(height: YkSpacing.xxs),
          Text(
            'Développez vos compétences avec nos experts.',
            style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltreProgressionMenu(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: _filtreProgression,
      onSelected: (v) => setState(() => _filtreProgression = v),
      itemBuilder: (context) => [
        for (final f in _filtresProgression)
          PopupMenuItem(
            value: f,
            child: Row(
              children: [
                if (f == _filtreProgression) ...[
                  Icon(Icons.check_rounded, size: 15, color: YkColors.accent(context)),
                  SizedBox(width: YkSpacing.xs),
                ],
                Text(f),
              ],
            ),
          ),
      ],
      child: YkIconButton(
        icon: Icons.tune_rounded,
        label: 'Filtrer par progression',
        variant: YkIconButtonVariant.tonal,
        onPressed: null,
      ),
    );
  }

  Widget _buildCarteFormation(BuildContext context, DepartementItem dept) {
    final couleur = _parseColor(dept.couleur, metier: dept.estFormationMetier);
    final typeLabel = dept.estFormationMetier ? 'Formation métier' : 'Formation classique';
    final aProgression = dept.progression > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        accentColor: couleur,
        onTap: () => _ouvrirFormation(dept),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: couleur.withValues(alpha: 0.12),
                  child: Icon(_iconePourFormation(dept), color: couleur, size: 20),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept.nom,
                        style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: YkSpacing.xxs),
                      Wrap(
                        spacing: YkSpacing.xxs,
                        runSpacing: YkSpacing.xxs,
                        children: [
                          YkBadge(variant: YkBadgeVariant.label, label: typeLabel, color: couleur),
                          if (dept.accesRestreint == true)
                            YkBadge(
                              variant: YkBadgeVariant.label,
                              label: 'Sur demande',
                              color: YkColors.warning,
                            ),
                          for (final niveau in dept.niveauxAccessibles)
                            YkBadge(variant: YkBadgeVariant.label, label: niveau, color: YkColors.warning),
                        ],
                      ),
                    ],
                  ),
                ),
                if (dept.estCertifiante)
                  YkBadge(variant: YkBadgeVariant.label, label: 'Certifiante', color: YkColors.accent(context)),
              ],
            ),
            if (dept.description.isNotEmpty) ...[
              SizedBox(height: YkSpacing.xs),
              Text(
                dept.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ],
            SizedBox(height: YkSpacing.sm),
            Wrap(
              spacing: YkSpacing.xxs,
              runSpacing: YkSpacing.xxs,
              children: [
                if (dept.dureeFormation.isNotEmpty)
                  _infoChip(context, Icons.schedule_rounded, dept.dureeFormation, YkColors.info),
                if (dept.modeFormation.isNotEmpty)
                  _infoChip(
                    context,
                    dept.modeFormation == 'presentiel'
                        ? Icons.location_city_rounded
                        : dept.modeFormation == 'distance'
                        ? Icons.wifi_rounded
                        : Icons.devices_rounded,
                    dept.modeFormationLabel,
                    YkColors.accent(context),
                  ),
                if (dept.ville.isNotEmpty) _infoChip(context, Icons.location_on_rounded, dept.ville, couleur),
                if (dept.domaine.isNotEmpty)
                  _infoChip(context, Icons.category_rounded, dept.domaine, YkColors.accent(context)),
              ],
            ),
            SizedBox(height: YkSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xs),
              decoration: BoxDecoration(
                color: YkColors.surfaceVariant(context),
                borderRadius: BorderRadius.circular(YkRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoIcone(context, Icons.layers_rounded, '${dept.nbCours} modules'),
                  if (dept.dureeFormation.isNotEmpty) _infoIcone(context, Icons.timer_rounded, dept.dureeFormation),
                ],
              ),
            ),
            SizedBox(height: YkSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            aProgression ? 'Formation en cours' : (dept.prix == 0 ? 'Accès libre' : '${dept.prix} FCFA'),
                            style: YkTypography.bodySm(context).copyWith(
                              color: aProgression
                                  ? YkColors.accent(context)
                                  : (dept.prix == 0 ? YkColors.success : YkColors.textSecondary(context)),
                            ),
                          ),
                          if (aProgression)
                            Text(
                              '${dept.progressionMoyenne.toStringAsFixed(0)}%',
                              style: YkTypography.label(context).copyWith(color: YkColors.accent(context)),
                            ),
                        ],
                      ),
                      SizedBox(height: YkSpacing.xxs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(YkRadius.full),
                        child: LinearProgressIndicator(
                          value: aProgression ? dept.progressionMoyenne / 100 : 0.0,
                          backgroundColor: YkColors.border(context),
                          valueColor: AlwaysStoppedAnimation(aProgression ? couleur : YkColors.textTertiary(context)),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: YkSpacing.sm),
                YkButton(
                  label: aProgression ? 'Continuer' : 'Découvrir',
                  onPressed: () => _ouvrirFormation(dept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label, Color couleur) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: YkSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(YkRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: couleur),
          SizedBox(width: YkSpacing.xxs),
          Text(label, style: YkTypography.caption(context).copyWith(color: couleur, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoIcone(BuildContext context, IconData icon, String texte) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: YkColors.textSecondary(context)),
          SizedBox(width: YkSpacing.xxs),
          Flexible(
            child: Text(
              texte,
              style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
