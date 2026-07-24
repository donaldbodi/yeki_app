// lib/features/olympiades/presentation/concours_detail_page.dart
//
// Écran « détail concours » (apprenant). Refondu en P8.3 (rituel P5.0)
// — remplace lib/views/pages/apprenants/concours_detail_page.dart.
//
// Corrige un bug réel : l'ancien fichier appelait à la main
// `${baseUrl}/departement/<id>/` (chemin inexistant côté backend, sans
// le préfixe `apprenant/`) — la page échouait silencieusement dès que
// `deptPrecharge` (passé via `state.extra`) n'était pas fourni. Corrigé
// via `FormationRepository.detailApprenant()`.
//
// Un concours est un `DepartementItem` (même modèle que
// `FormationDetailPage`), pas une `Olympiade` — cet écran n'est pas
// concerné par YkRichViewer/paiement 100 FCFA/YkCountdown/YkLeaderboard
// (concepts olympiade du ticket P8.3) : il reçoit le rituel P5.0
// standard.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart' show DepartementItem;

import 'concours_detail_controller.dart';

class ConcoursDetailPage extends StatefulWidget {
  const ConcoursDetailPage({super.key, required this.concoursId, this.deptPrecharge});

  final int concoursId;
  final DepartementItem? deptPrecharge;

  @override
  State<ConcoursDetailPage> createState() => _ConcoursDetailPageState();
}

class _ConcoursDetailPageState extends State<ConcoursDetailPage> with SingleTickerProviderStateMixin {
  late final ConcoursDetailController _controller;
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _controller = ConcoursDetailController(concoursId: widget.concoursId, precharge: widget.deptPrecharge);
    if (widget.deptPrecharge == null) _controller.charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Color _accentColor(BuildContext context, DepartementItem dept) {
    try {
      final hex = dept.couleur.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return YkColors.accent(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dept = _controller.departement;
        final accent = dept != null ? _accentColor(context, dept) : YkColors.accent(context);
        return Scaffold(
          backgroundColor: YkColors.background(context),
          body: _buildBody(context, accent),
          bottomNavigationBar:
              (_controller.etat == ConcoursDetailEtat.pret && dept != null && dept.nbCours > 0)
              ? _buildBottomBar(context, dept, accent)
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, Color accent) {
    switch (_controller.etat) {
      case ConcoursDetailEtat.chargement:
        return SingleChildScrollView(
          padding: EdgeInsets.all(YkSpacing.md),
          child: YkSkeleton.list(itemCount: 6, itemHeight: 72),
        );
      case ConcoursDetailEtat.erreur:
        return YkErrorState(
          message: _controller.erreurMessage ?? 'Concours introuvable.',
          onRetry: _controller.charger,
        );
      case ConcoursDetailEtat.pret:
        final dept = _controller.departement!;
        return NestedScrollView(
          headerSliverBuilder: (context, _) => [
            YkAppBar.sliver(
              context: context,
              title: dept.nomConcours.isNotEmpty ? dept.nomConcours : dept.nom,
              expandedHeight: 220,
              background: _buildHero(context, dept, accent),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(YkSpacing.sm),
                child: YkTabs(
                  controller: _tabCtrl,
                  tabs: const [
                    YkTabItem(label: 'Infos'),
                    YkTabItem(label: 'Cours'),
                    YkTabItem(label: 'Débouchés'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _TabInfos(dept: dept, accent: accent),
              _TabCours(dept: dept, accent: accent),
              _TabDebouches(dept: dept, accent: accent),
            ],
          ),
        );
    }
  }

  Widget _buildHero(BuildContext context, DepartementItem dept, Color accent) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (dept.imageUrl != null)
          Image.network(dept.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: accent))
        else
          Container(color: accent),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          left: YkSpacing.md,
          right: YkSpacing.md,
          bottom: YkSpacing.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dept.nom != dept.nomConcours && dept.nom.isNotEmpty)
                Text(dept.nom, style: YkTypography.bodySm(context).copyWith(color: Colors.white70)),
              Row(
                children: [
                  YkBadge(variant: YkBadgeVariant.label, label: '${dept.nbCours} cours', color: Colors.white),
                  SizedBox(width: YkSpacing.xs),
                  YkBadge(
                    variant: YkBadgeVariant.label,
                    label: dept.prix == 0 ? 'Gratuit' : '${dept.prix} FCFA',
                    color: dept.prix == 0 ? YkColors.success : YkColors.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, DepartementItem dept, Color accent) {
    final progression = dept.progressionMoyenne;
    return Container(
      padding: EdgeInsets.only(
        left: YkSpacing.md,
        right: YkSpacing.md,
        top: YkSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + YkSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: YkColors.surface(context),
        border: Border(top: BorderSide(color: YkColors.border(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progression > 0
                      ? '${progression.toStringAsFixed(0)}% complété'
                      : '${dept.nbCours} cours disponibles',
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                ),
                SizedBox(height: YkSpacing.xxs),
                YkProgress(value: progression / 100, color: accent),
              ],
            ),
          ),
          SizedBox(width: YkSpacing.md),
          YkButton(
            label: progression > 0 ? 'Continuer' : 'Commencer',
            onPressed: dept.cours.isNotEmpty
                ? () => context.pushNamed(
                    AppRoute.coursDetail,
                    pathParameters: {'coursId': dept.cours.first.id.toString()},
                    queryParameters: {'titre': dept.cours.first.title, 'coursColor': accent.value.toString()},
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _TabInfos extends StatelessWidget {
  const _TabInfos({required this.dept, required this.accent});

  final DepartementItem dept;
  final Color accent;

  static final _dateFmt = DateFormat('dd MMMM yyyy', 'fr_FR');

  String _fmtDate(DateTime? date) => date == null ? 'Non définie' : _dateFmt.format(date);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cloture = dept.dateLimiteInscription;
    final clotureBadge = cloture == null
        ? null
        : cloture.isBefore(now)
        ? ('Fermé', YkColors.error)
        : cloture.difference(now).inDays <= 30
        ? ('Bientôt', YkColors.warning)
        : ('Ouvert', YkColors.success);
    final examen = dept.dateExamen;
    final examenBadge = examen == null ? null : (examen.isBefore(now) ? 'Passé' : null);

    return ListView(
      padding: EdgeInsets.all(YkSpacing.md),
      children: [
        if (dept.description.isNotEmpty) ...[
          YkSection(
            title: 'À propos',
            child: YkCard(
              child: Text(
                dept.description,
                style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ),
          ),
          SizedBox(height: YkSpacing.lg),
        ],

        YkSection(
          title: 'Dates importantes',
          child: YkCard(
            child: Column(
              children: [
                if (cloture != null)
                  Row(
                    children: [
                      Expanded(
                        child: YkKeyValue(
                          label: 'Clôture des inscriptions',
                          value: _fmtDate(cloture),
                          icon: Icons.how_to_reg_outlined,
                        ),
                      ),
                      if (clotureBadge != null)
                        YkBadge(variant: YkBadgeVariant.label, label: clotureBadge.$1, color: clotureBadge.$2),
                    ],
                  ),
                if (examen != null)
                  Row(
                    children: [
                      Expanded(
                        child: YkKeyValue(
                          label: "Date de l'examen",
                          value: _fmtDate(examen),
                          icon: Icons.event_outlined,
                        ),
                      ),
                      if (examenBadge != null)
                        YkBadge(variant: YkBadgeVariant.label, label: examenBadge, color: YkColors.textSecondary(context)),
                    ],
                  ),
                if (cloture == null && examen == null)
                  Text(
                    'Dates non précisées',
                    style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: YkSpacing.lg),

        if (dept.arreteMinisteriel.isNotEmpty ||
            dept.niveauxCibles.isNotEmpty ||
            dept.placesDisponibles != null ||
            dept.fraisDossier > 0) ...[
          YkSection(
            title: 'Détails du concours',
            child: YkCard(
              child: Column(
                children: [
                  if (dept.arreteMinisteriel.isNotEmpty)
                    YkKeyValue(label: 'Arrêté ministériel', value: dept.arreteMinisteriel, icon: Icons.gavel_outlined),
                  if (dept.niveauxCibles.isNotEmpty)
                    YkKeyValue(label: 'Niveaux ciblés', value: dept.niveauxCibles, icon: Icons.school_outlined),
                  if (dept.placesDisponibles != null)
                    YkKeyValue(
                      label: 'Places disponibles',
                      value: '${dept.placesDisponibles}',
                      icon: Icons.people_outline,
                    ),
                  if (dept.fraisDossier > 0)
                    YkKeyValue(
                      label: 'Frais de dossier',
                      value: '${dept.fraisDossier} FCFA',
                      icon: Icons.receipt_long_outlined,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: YkSpacing.lg),
        ],

        if (dept.organismeConcours.isNotEmpty) ...[
          YkSection(
            title: 'Organisateur',
            child: YkCard(
              child: Row(
                children: [
                  Icon(Icons.apartment_outlined, color: accent, size: 28),
                  SizedBox(width: YkSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept.organismeConcours,
                          style: YkTypography.bodyMd(
                            context,
                          ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w600),
                        ),
                        if (dept.lienOfficiel.isNotEmpty)
                          Text(
                            dept.lienOfficiel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: YkTypography.bodySm(context).copyWith(color: accent),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: YkSpacing.lg),
        ],

        YkSection(
          title: 'Accès à la préparation',
          child: YkCard(
            variant: YkCardVariant.filled,
            accentColor: dept.prix == 0 ? YkColors.success : YkColors.warning,
            child: Row(
              children: [
                Icon(
                  dept.prix == 0 ? Icons.lock_open_outlined : Icons.lock_outline,
                  color: dept.prix == 0 ? YkColors.success : YkColors.warning,
                  size: 28,
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dept.prix == 0 ? 'Accès gratuit' : '${dept.prix} FCFA',
                        style: YkTypography.h4(
                          context,
                        ).copyWith(color: dept.prix == 0 ? YkColors.success : YkColors.warning),
                      ),
                      Text(
                        dept.prix == 0
                            ? 'Cette préparation est entièrement gratuite'
                            : 'Paiement unique pour accéder à tous les cours',
                        style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
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
}

class _TabCours extends StatelessWidget {
  const _TabCours({required this.dept, required this.accent});

  final DepartementItem dept;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (dept.cours.isEmpty) {
      return YkEmptyState(
        title: 'Aucun cours disponible',
        message: 'Les cours de ce concours seront bientôt disponibles.',
        icon: Icons.book_outlined,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(YkSpacing.md),
      itemCount: dept.cours.length,
      separatorBuilder: (_, _) => SizedBox(height: YkSpacing.sm),
      itemBuilder: (context, i) {
        final c = dept.cours[i];
        Color cardColor;
        try {
          cardColor = Color(int.parse('FF${c.color.replaceAll('#', '')}', radix: 16));
        } catch (_) {
          cardColor = accent;
        }

        return YkCard(
          accentColor: cardColor,
          onTap: () => context.pushNamed(
            AppRoute.coursDetail,
            pathParameters: {'coursId': c.id.toString()},
            queryParameters: {'titre': c.title, 'coursColor': cardColor.value.toString()},
          ),
          semanticLabel: 'Ouvrir le cours ${c.title}',
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(YkRadius.sm),
                ),
                child: Icon(Icons.book_outlined, color: cardColor, size: 22),
              ),
              SizedBox(width: YkSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: YkTypography.bodyMd(
                        context,
                      ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w600),
                    ),
                    if (c.description.isNotEmpty)
                      Text(
                        c.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                      ),
                    SizedBox(height: YkSpacing.xxs),
                    Row(
                      children: [
                        Icon(Icons.play_lesson_outlined, size: 13, color: YkColors.textSecondary(context)),
                        SizedBox(width: YkSpacing.xxs),
                        Text(
                          '${c.lessons} leçons',
                          style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                        SizedBox(width: YkSpacing.sm),
                        Icon(Icons.assignment_outlined, size: 13, color: YkColors.textSecondary(context)),
                        SizedBox(width: YkSpacing.xxs),
                        Text(
                          '${c.assignments} devoirs',
                          style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    Text(
                      '${c.progression.toStringAsFixed(0)}%',
                      style: YkTypography.bodySm(context).copyWith(color: cardColor, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: YkSpacing.xxs),
                    YkProgress(value: c.progression / 100, color: cardColor),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabDebouches extends StatelessWidget {
  const _TabDebouches({required this.dept, required this.accent});

  final DepartementItem dept;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (dept.debouches.isEmpty) {
      return YkEmptyState(
        title: 'Débouchés non précisés',
        message: 'Les débouchés de ce concours seront bientôt renseignés.',
        icon: Icons.trending_up_outlined,
      );
    }

    final lignes = dept.debouches
        .split(RegExp(r'\n|•|·'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return ListView(
      padding: EdgeInsets.all(YkSpacing.md),
      children: [
        YkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_outlined, color: accent, size: 22),
                  SizedBox(width: YkSpacing.xs),
                  Text(
                    'Après ce concours',
                    style: YkTypography.h4(context).copyWith(color: accent),
                  ),
                ],
              ),
              SizedBox(height: YkSpacing.sm),
              for (final l in lignes)
                Padding(
                  padding: EdgeInsets.only(bottom: YkSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: EdgeInsets.only(top: 6, right: YkSpacing.sm),
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: Text(
                          l,
                          style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
