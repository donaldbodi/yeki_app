// lib/views/pages/apprenants/accueil_page.dart
//
// Nouveau en P11.1 (rituel P5.0) — l'onglet "Accueil" apprenant. Existait
// dans `yk_nav_config_apprenant.dart` comme destination déjà décrite (CDC
// DESIGN §4.2.1) mais sans route ni écran ("TODO(nav) : aucun tableau de
// bord Accueil apprenant n'existe encore comme route globale") : ce
// fichier comble ce trou. Fiche d'écart : `docs/ecarts/accueil.md`.
//
// Contenu retenu après comparaison avec `docs/maquette/YEKI App
// Apprenant.dc.html` (écran "01 · Accueil — dashboard vivant") et
// arbitrage explicite avec l'utilisateur :
// - Salutation + avatar + notifications (badge réel, `notificationsProvider`)
// - `YkSearchBar` — raccourci qui bascule vers l'onglet Cursus (la
//   recherche réelle dans le catalogue vit sur cet onglet, elle n'est pas
//   dupliquée ici)
// - "Continuer la lecture" — liste défilante des reprises récentes
//   (`FormationRepository.lecturesRecentes`), format CONSERVÉ (liste, pas
//   une carte héro unique comme la maquette) : décision actée, plus utile
//   quand l'apprenant a plusieurs cours en cours, ne perd rien de l'écran
//   existant
// - "Prochaines échéances" — devoirs non soumis triés par date limite
//   (`DevoirRepository.listMine`), aucune donnée nouvelle à créer
// - PAS de cartes XP/niveau/série d'étude (aucune donnée réelle,
//   décision actée) ni de section "recommandations" (aucun moteur de
//   recommandation, décision actée)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/providers/notifications_provider.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/auth_repository.dart';
import 'package:yeki/repositories/devoir_repository.dart';
import 'package:yeki/repositories/formation_repository.dart';
import 'package:yeki/views/pages/apprenants/devoir_models.dart' show DevoirItem;

class AccueilPage extends ConsumerStatefulWidget {
  const AccueilPage({super.key});

  @override
  ConsumerState<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends ConsumerState<AccueilPage> {
  final _authRepo = AuthRepository();
  final _formationRepo = FormationRepository();
  final _devoirRepo = DevoirRepository();

  bool _loading = true;
  String _prenom = '';
  List<LectureRecente> _reprises = const [];
  List<DevoirItem> _echeances = const [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final resultats = await Future.wait([
        _authRepo.getCurrentUser(),
        _formationRepo.lecturesRecentes(),
        _devoirRepo.listMine(),
      ]);
      if (!mounted) return;
      final utilisateur = resultats[0] as dynamic;
      final reprises = resultats[1] as List<LectureRecente>;
      final devoirs = resultats[2] as List<DevoirItem>;
      final echeances =
          devoirs
              .where((d) => d.statutApprenant == 'non_commence' || d.statutApprenant == 'en_cours')
              .toList()
            ..sort((a, b) => a.dateLimite.compareTo(b.dateLimite));
      setState(() {
        _prenom = utilisateur.firstName.isNotEmpty ? utilisateur.firstName : utilisateur.username;
        _reprises = reprises;
        _echeances = echeances.take(3).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _salutation {
    final heure = DateTime.now().hour;
    if (heure < 12) return 'Bonjour';
    if (heure < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return YkColors.accent(context);
    try {
      return Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      return YkColors.accent(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nonLues = ref.watch(notificationsProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: SafeArea(
        child: _loading
            ? Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 4, itemHeight: 96))
            : RefreshIndicator(
                onRefresh: _charger,
                child: ListView(
                  padding: EdgeInsets.all(YkSpacing.md),
                  children: [
                    _buildAppBar(context, nonLues),
                    SizedBox(height: YkSpacing.md),
                    YkSearchBar(
                      hint: 'Rechercher un cours, un enseignant…',
                      onQueryChanged: (q) {
                        if (q.trim().isNotEmpty) context.goNamed(AppRoute.dashboardCursus);
                      },
                    ),
                    SizedBox(height: YkSpacing.lg),
                    _buildContinuerLecture(context),
                    SizedBox(height: YkSpacing.lg),
                    _buildProchainesEcheances(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int nonLues) {
    final initiale = _prenom.isNotEmpty ? _prenom[0].toUpperCase() : '?';
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: YkColors.accent(context),
          child: Text(
            initiale,
            style: YkTypography.label(context).copyWith(color: YkColors.onAccent(context)),
          ),
        ),
        SizedBox(width: YkSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_salutation 👋',
                style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
              ),
              Text(
                _prenom.isEmpty ? 'Apprenant' : _prenom,
                style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            YkIconButton(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              variant: YkIconButtonVariant.tonal,
              onPressed: () => context.pushNamed(AppRoute.notifications),
            ),
            if (nonLues > 0)
              Positioned(
                top: -2,
                right: -2,
                child: YkBadge(count: nonLues),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContinuerLecture(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continuer la lecture',
          style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
        ),
        SizedBox(height: YkSpacing.sm),
        if (_reprises.isEmpty)
          YkCard(
            variant: YkCardVariant.filled,
            child: Row(
              children: [
                const Text('🎓', style: TextStyle(fontSize: 22)),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Text(
                    'Prêt à entamer un chapitre ? Choisissez un cours dans l\'onglet Cursus.',
                    style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _reprises.length,
              separatorBuilder: (_, _) => SizedBox(width: YkSpacing.sm),
              itemBuilder: (context, index) {
                final item = _reprises[index];
                final couleur = _parseColor(item.coursColorHex);
                return SizedBox(
                  width: 260,
                  child: YkCard(
                    accentColor: couleur,
                    onTap: item.coursId == null
                        ? null
                        : () => context.pushNamed(
                            AppRoute.coursDetail,
                            pathParameters: {'coursId': item.coursId!.toString()},
                            queryParameters: {
                              'titre': item.coursTitre,
                              'coursColor': couleur.toARGB32().toString(),
                              // `true` volontaire (P11.4) : une reprise de
                              // lecture suppose un accès déjà obtenu ;
                              // `LectureRecente` ne porte pas
                              // `estAccessible` (pas la même API que
                              // `DepartementItem`).
                              'isPremium': 'true',
                            },
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.coursTitre.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: YkTypography.caption(context).copyWith(color: couleur, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: YkSpacing.xxs),
                        Text(
                          item.leconTitre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                        ),
                        SizedBox(height: YkSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(YkRadius.full),
                                child: LinearProgressIndicator(
                                  value: item.pourcentage / 100,
                                  backgroundColor: YkColors.border(context),
                                  valueColor: AlwaysStoppedAnimation(couleur),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            SizedBox(width: YkSpacing.xs),
                            Text('${item.pourcentage}%', style: YkTypography.caption(context)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProchainesEcheances(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prochaines échéances',
          style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
        ),
        SizedBox(height: YkSpacing.sm),
        if (_echeances.isEmpty)
          YkEmptyState(
            icon: Icons.event_available_outlined,
            title: 'Aucune échéance',
            message: "Vous n'avez aucun devoir à rendre pour l'instant.",
          )
        else
          for (final devoir in _echeances)
            Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.sm),
              child: YkCard(
                onTap: () => context.pushNamed(
                  AppRoute.devoirComposer,
                  pathParameters: {'devoirId': devoir.id.toString()},
                  queryParameters: {
                    'titre': devoir.titre,
                    'dureeMin': devoir.dureeMinutes.toString(),
                    'noteSur': devoir.noteSur.toInt().toString(),
                  },
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_outlined, color: YkColors.warning),
                    SizedBox(width: YkSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            devoir.titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                          ),
                          Text(
                            _formatDateLimite(devoir.dateLimite),
                            style: YkTypography.caption(
                              context,
                            ).copyWith(color: YkColors.textSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  String _formatDateLimite(DateTime date) {
    final restant = date.difference(DateTime.now());
    if (restant.inHours < 1) return 'Dans moins d\'une heure';
    if (restant.inHours < 24) return 'Dans ${restant.inHours} h';
    return 'Dans ${restant.inDays} j — ${date.day}/${date.month}/${date.year}';
  }
}
