// lib/views/pages/apprenants/concours_pages.dart
//
// Refondu en P11.2 (rituel P5.0, migration mécanique) : bascule vers
// `FormationRepository.prepaConcours()` (plus de `http`/
// `SharedPreferences` bruts) et les tokens/composants `Yk*` (plus de
// `YekiColors`/`YekiButton`/glassmorphism codée en dur).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/formation_repository.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';

class ConcoursPage extends StatefulWidget {
  const ConcoursPage({super.key});

  @override
  State<ConcoursPage> createState() => _ConcoursPageState();
}

class _ConcoursPageState extends State<ConcoursPage> {
  final _repo = FormationRepository();

  bool _loading = true;
  bool _enErreur = false;
  List<DepartementItem> _tous = const [];
  String _filtre = 'Tous';
  String _recherche = '';
  String _niveauApprenant = '';

  static const _filtres = ['Tous', 'Gratuit', 'Payant', 'En cours'];

  @override
  void initState() {
    super.initState();
    _chargerNiveau();
    _charger();
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
      final concours = await _repo.prepaConcours();
      if (!mounted) return;
      setState(() {
        _tous = concours;
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
    return _tous.where((d) {
      final matchRecherche =
          q.isEmpty ||
          d.nom.toLowerCase().contains(q) ||
          d.nomConcours.toLowerCase().contains(q) ||
          d.niveauxCibles.toLowerCase().contains(q);
      final matchFiltre = switch (_filtre) {
        'Gratuit' => d.prix == 0,
        'Payant' => d.prix > 0,
        'En cours' => d.progressionMoyenne > 0 && d.progressionMoyenne < 100,
        _ => true,
      };
      final matchNiveau = _niveauApprenant.isEmpty || d.niveauxAccessibles.isEmpty
          ? true
          : NiveauService.estAccessibleParListe(_niveauApprenant, d.niveauxAccessibles);
      return matchRecherche && matchFiltre && matchNiveau;
    }).toList();
  }

  IconData _iconePourConcours(String texte) {
    final t = texte.toLowerCase();
    if (t.contains('polytech') || t.contains('ingé') || t.contains('mines')) return Icons.engineering_rounded;
    if (t.contains('ens') || t.contains('normale') || t.contains('pédagogie')) return Icons.school_rounded;
    if (t.contains('enam') || t.contains('admin') || t.contains('magistrature')) return Icons.gavel_rounded;
    if (t.contains('santé') || t.contains('médecine') || t.contains('fmsb')) return Icons.health_and_safety_rounded;
    if (t.contains('numérique') || t.contains('informatique')) return Icons.terminal_rounded;
    return Icons.workspace_premium_rounded;
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      return YkColors.accent(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: SafeArea(
        child: _loading
            ? Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 4, itemHeight: 200))
            : _enErreur
            ? YkEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Impossible de charger les concours',
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
                    YkTextField(
                      type: YkTextFieldType.search,
                      hint: 'Rechercher une école, un concours…',
                      onChanged: (v) => setState(() => _recherche = v),
                    ),
                    SizedBox(height: YkSpacing.sm),
                    _buildFiltres(context),
                    SizedBox(height: YkSpacing.md),
                    Row(
                      children: [
                        Text(
                          'Vos concours',
                          style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                        ),
                        const Spacer(),
                        YkBadge(
                          variant: YkBadgeVariant.label,
                          label: '${_affiches.length} ouverts',
                          color: YkColors.accent(context),
                        ),
                      ],
                    ),
                    SizedBox(height: YkSpacing.sm),
                    if (_affiches.isEmpty)
                      YkEmptyState(
                        icon: Icons.assignment_turned_in_rounded,
                        title: 'Aucun concours trouvé',
                        message: "Ajustez vos filtres ou votre recherche pour explorer d'autres opportunités.",
                      )
                    else
                      for (final dept in _affiches) _buildCarteConcours(context, dept),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEnTete(BuildContext context) {
    return YkCard(
      variant: YkCardVariant.filled,
      accentColor: YkColors.accent(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YkBadge(variant: YkBadgeVariant.label, label: 'YÉKI PRÉPA CONCOURS', color: YkColors.accent(context)),
          SizedBox(height: YkSpacing.xs),
          Text(
            "Atteignez l'excellence",
            style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          SizedBox(height: YkSpacing.xxs),
          Text(
            _niveauApprenant.isNotEmpty
                ? 'Concours accessibles pour le niveau : $_niveauApprenant'
                : "Propulsez votre avenir au sein des grandes écoles d'ingénierie.",
            style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltres(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filtres.length,
        separatorBuilder: (_, _) => SizedBox(width: YkSpacing.xs),
        itemBuilder: (context, index) {
          final filtre = _filtres[index];
          return YkChip(
            label: filtre,
            variant: YkChipVariant.filter,
            selected: _filtre == filtre,
            onSelected: (_) => setState(() => _filtre = filtre),
          );
        },
      ),
    );
  }

  Widget _buildCarteConcours(BuildContext context, DepartementItem dept) {
    final couleur = _parseColor(dept.couleur);
    final titre = dept.nomConcours.isNotEmpty ? dept.nomConcours : dept.nom;
    final aProgression = dept.progressionMoyenne > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        accentColor: couleur,
        onTap: () => context
            .pushNamed(AppRoute.concoursDetail, pathParameters: {'concoursId': dept.id.toString()}, extra: dept)
            .then((_) => _charger()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: couleur.withValues(alpha: 0.12),
                  child: Icon(_iconePourConcours(titre), color: couleur, size: 20),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dept.nom != dept.nomConcours && dept.nom.isNotEmpty)
                        Text(
                          dept.nom,
                          style: YkTypography.bodySm(context).copyWith(color: couleur),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (dept.niveauxAccessibles.isNotEmpty) ...[
                        SizedBox(height: YkSpacing.xxs),
                        Wrap(
                          spacing: YkSpacing.xxs,
                          runSpacing: YkSpacing.xxs,
                          children: [
                            for (final niveau in dept.niveauxAccessibles)
                              YkBadge(variant: YkBadgeVariant.label, label: niveau, color: YkColors.warning),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm, vertical: YkSpacing.xs),
              decoration: BoxDecoration(
                color: YkColors.surfaceVariant(context),
                borderRadius: BorderRadius.circular(YkRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoIcone(
                    context,
                    Icons.calendar_month_rounded,
                    dept.dateExamen?.toString().substring(0, 10) ?? 'À définir',
                  ),
                  if (dept.placesDisponibles != null)
                    _infoIcone(context, Icons.event_seat_rounded, '${dept.placesDisponibles} pl.'),
                  _infoIcone(context, Icons.layers_rounded, '${dept.nbCours} mod.'),
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
                            aProgression
                                ? 'Préparation en cours'
                                : (dept.prix == 0 ? 'Accès libre' : '${dept.prix} FCFA'),
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
                  onPressed: () => context
                      .pushNamed(
                        AppRoute.concoursDetail,
                        pathParameters: {'concoursId': dept.id.toString()},
                        extra: dept,
                      )
                      .then((_) => _charger()),
                ),
              ],
            ),
          ],
        ),
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
