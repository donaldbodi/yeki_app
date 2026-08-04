// lib/views/pages/apprenants/accueil_page.dart
//
// Nouveau en P11.1 (rituel P5.0) — l'onglet "Accueil" apprenant. Refondu en
// Phase 2 (rituel P5.0, fiche d'écart `docs/ecarts/p2_accueil.md`) d'après
// une nouvelle comparaison avec `docs/maquette/YEKI App Apprenant.dc.html`
// (écran "01 · Accueil — dashboard vivant") et 3 arbitrages explicites
// avec l'utilisateur :
// - Salutation + avatar (désormais 2 initiales sur dégradé, comme la
//   maquette) + notifications (badge réel, `notificationsProvider`)
// - `YkSearchBar` — raccourci qui bascule vers l'onglet Cursus (la
//   recherche réelle dans le catalogue vit sur cet onglet, elle n'est pas
//   dupliquée ici)
// - "Continuer la lecture" — BASCULE vers une carte héro unique (la
//   reprise la plus récente, dégradé + bouton lecture, comme la maquette)
//   + lien "Tout voir" vers Cursus — arbitrage tranché : les autres
//   reprises restent accessibles depuis Cursus, pas perdues
// - "Prochaines échéances" — CONSERVÉE telle quelle (règle 4 : absente de
//   l'écran Accueil de la maquette, mais une absence dans la maquette
//   n'est jamais une instruction de suppression) — devoirs non soumis
//   triés par date limite (`DevoirRepository.listMine`)
// - PAS de section "Vos programmes" (catalogue enrichi mentor/badge) —
//   arbitrage tranché : Cursus reste l'unique catalogue (décision P11.2
//   déjà actée, « catalogue PUR, sans duplication »)
// - PAS de cartes XP/niveau/série d'étude — arbitrage tranché : aucun
//   modèle backend de gamification n'existe, pas de chiffres inventés
//   (règle 3) ; construire un vrai système est un chantier séparé

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
  String _nom = '';
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
        _nom = utilisateur.lastName as String;
        _reprises = reprises;
        _echeances = echeances.take(3).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 2 initiales (prénom + nom, comme la maquette) — repli sur `'?'` si
  /// aucun des deux n'est encore chargé.
  String get _initiales {
    final p = _prenom.isNotEmpty ? _prenom[0].toUpperCase() : '';
    final n = _nom.isNotEmpty ? _nom[0].toUpperCase() : '';
    final combinees = '$p$n';
    return combinees.isEmpty ? '?' : combinees;
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
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 44,
            height: 44,
            child: YkGradientBackground(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [YkColors.primary700, YkColors.primary500],
              ),
              child: Center(
                child: Text(
                  _initiales,
                  style: YkTypography.label(context).copyWith(color: YkColors.textOnPrimary),
                ),
              ),
            ),
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
        Row(
          children: [
            Expanded(
              child: Text(
                'Continuer la lecture',
                style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
              ),
            ),
            if (_reprises.isNotEmpty)
              YkButton(
                label: 'Tout voir',
                variant: YkButtonVariant.ghost,
                size: YkButtonSize.sm,
                onPressed: () => context.goNamed(AppRoute.dashboardCursus),
              ),
          ],
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
          _buildHeroReprise(context, _reprises.first),
      ],
    );
  }

  /// Carte héro — la reprise de lecture la plus récente, mise en avant
  /// (maquette, écran Accueil) : dégradé de marque, bouton lecture, barre
  /// de progression réelle. Les autres reprises restent accessibles
  /// depuis Cursus (lien « Tout voir » ci-dessus) — arbitrage tranché
  /// avec l'utilisateur, pas une perte de fonctionnalité.
  Widget _buildHeroReprise(BuildContext context, LectureRecente item) {
    return YkCard(
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [YkColors.primary700, YkColors.primary500],
      ),
      onTap: item.coursId == null
          ? null
          : () => context.pushNamed(
              AppRoute.coursDetail,
              pathParameters: {'coursId': item.coursId!.toString()},
              queryParameters: {
                'titre': item.coursTitre,
                'coursColor': _parseColor(item.coursColorHex).toARGB32().toString(),
                // `true` volontaire (P11.4) : une reprise de lecture
                // suppose un accès déjà obtenu ; `LectureRecente` ne
                // porte pas `estAccessible` (pas la même API que
                // `DepartementItem`).
                'isPremium': 'true',
              },
            ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Halo décoratif hors-cadre (maquette) — réutilise le composant
          // déjà construit pour ce motif plutôt qu'un `BoxDecoration` fait
          // main.
          Positioned(
            top: -50,
            right: -50,
            child: YkRadialGlow(color: Colors.white, alpha: 0.1, size: 150),
          ),
          Padding(
            padding: EdgeInsets.all(YkSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.coursTitre.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: YkTypography.overline(context).copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      SizedBox(height: YkSpacing.xxs),
                      Text(
                        item.leconTitre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: YkTypography.h4(context).copyWith(color: Colors.white),
                      ),
                      SizedBox(height: YkSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(YkRadius.full),
                              child: LinearProgressIndicator(
                                value: item.pourcentage / 100,
                                backgroundColor: Colors.white.withValues(alpha: 0.22),
                                valueColor: AlwaysStoppedAnimation(YkColors.gold(context)),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          SizedBox(width: YkSpacing.xs),
                          Text(
                            '${item.pourcentage}%',
                            style: YkTypography.caption(context).copyWith(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: YkSpacing.sm),
                // Bouton lecture — même motif Material+CircleBorder que
                // `YkIconButton` (pas de `BoxDecoration`), en blanc fixe :
                // aucune de ses 4 variantes existantes ne convient (elles
                // sont toutes relatives au thème ambiant, alors que cette
                // carte a une identité de couleur fixe, comme l'écran
                // Splash).
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.play_arrow_rounded, color: YkColors.primary700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
