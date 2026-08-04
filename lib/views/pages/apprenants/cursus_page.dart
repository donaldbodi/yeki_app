// lib/views/pages/apprenants/cursus_page.dart
//
// Refondu en P11.2 (rituel P5.0) — fiche d'écart : `docs/ecarts/accueil.md`
// §1 documente déjà le partage de responsabilité avec `accueil_page.dart`
// (P11.1) : la salutation/notifications/"Continuer la lecture" migrent
// vers l'onglet Accueil, CET écran redevient un catalogue PUR (recherche +
// grille de cours), sans duplication entre les deux onglets.
//
// Bascule vers `FormationRepository.cursus()` (plus de `http`/
// `SharedPreferences` bruts) et les tokens/composants `Yk*` (plus de
// `YekiColors`/`YekiTextStyles`/`YekiButton`/glassmorphism codée en dur).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/repositories/formation_repository.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart' show CoursItem;

class CursusPage extends StatefulWidget {
  const CursusPage({super.key});

  @override
  State<CursusPage> createState() => _CursusPageState();
}

class _CursusPageState extends State<CursusPage> {
  final _repo = FormationRepository();

  bool _loading = true;
  bool _enErreur = false;
  List<CoursItem> _cours = const [];
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _enErreur = false;
    });
    try {
      final cours = await _repo.cursus();
      if (!mounted) return;
      setState(() {
        _cours = cours;
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

  List<CoursItem> get _coursFiltres {
    if (_recherche.trim().isEmpty) return _cours;
    final q = _recherche.toLowerCase();
    return _cours
        .where(
          (c) => c.title.toLowerCase().contains(q) || c.enseignantPrincipal.toLowerCase().contains(q),
        )
        .toList();
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      return YkColors.accent(context);
    }
  }

  IconData _iconePourMatiere(String titre) {
    final t = titre.toLowerCase();
    if (t.contains('physique') || t.contains('chimie')) return Icons.science_rounded;
    if (t.contains('code') || t.contains('flutter') || t.contains('dev')) return Icons.terminal_rounded;
    if (t.contains('math') || t.contains('algebre') || t.contains('calcul')) return Icons.functions_rounded;
    if (t.contains('droit') || t.contains('juridique')) return Icons.gavel_rounded;
    return Icons.menu_book_rounded;
  }

  /// 2 initiales de repli pour l'avatar de l'enseignant principal (même
  /// motif que l'avatar de l'app bar Accueil — dégradé + initiales).
  String _initialesEnseignant(String nom) {
    final mots = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return (mots.first.substring(0, 1) + mots.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: SafeArea(
        child: _loading
            ? Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 4, itemHeight: 140))
            : _enErreur
            ? YkEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'Impossible de charger vos programmes',
                message: 'Vérifiez votre connexion puis réessayez.',
                actionLabel: 'Réessayer',
                onAction: _charger,
              )
            : RefreshIndicator(
                onRefresh: _charger,
                child: ListView(
                  padding: EdgeInsets.all(YkSpacing.md),
                  children: [
                    YkTextField(
                      type: YkTextFieldType.search,
                      hint: 'Rechercher un cours, un enseignant…',
                      onChanged: (v) => setState(() => _recherche = v),
                    ),
                    SizedBox(height: YkSpacing.md),
                    Row(
                      children: [
                        Text(
                          'Vos programmes',
                          style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
                        ),
                        const Spacer(),
                        if (_cours.isNotEmpty)
                          Text(
                            '${_coursFiltres.length} cours',
                            style: YkTypography.caption(
                              context,
                            ).copyWith(color: YkColors.textSecondary(context)),
                          ),
                      ],
                    ),
                    SizedBox(height: YkSpacing.sm),
                    if (_coursFiltres.isEmpty)
                      YkEmptyState(
                        icon: Icons.school_outlined,
                        title: 'Aucun cours',
                        message: _recherche.isEmpty
                            ? "Vous n'avez pas encore accès à un cours de ce cursus."
                            : 'Aucun cours ne correspond à « $_recherche ».',
                      )
                    else
                      for (final cours in _coursFiltres) _buildCarteCours(context, cours),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCarteCours(BuildContext context, CoursItem cours) {
    final couleur = _parseColor(cours.color);
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        accentColor: couleur,
        onTap: () => context.pushNamed(
          AppRoute.coursDetail,
          pathParameters: {'coursId': cours.id.toString()},
          queryParameters: {
            'titre': cours.title,
            'coursColor': couleur.toARGB32().toString(),
            // `true` volontaire (pas un oubli, P11.4) : le Cursus n'a pas
            // de système d'accès restreint par département contrairement
            // à Formations/Prépa Concours (`FormationRepository.cursus()`
            // ne renvoie que des `CoursItem`, sans `DepartementItem.
            // estAccessible`) — c'est le socle toujours accessible.
            'isPremium': 'true',
          },
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(YkRadius.md),
              child: Container(
                width: 50,
                height: 50,
                color: couleur.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: Icon(_iconePourMatiere(cours.title), color: couleur, size: 24),
              ),
            ),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cours.title,
                          style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: YkSpacing.xs),
                      _buildBadgeProgression(context, cours.progression),
                    ],
                  ),
                  if (cours.description.isNotEmpty) ...[
                    SizedBox(height: YkSpacing.xxs),
                    Text(
                      cours.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                  ],
                  SizedBox(height: YkSpacing.xs),
                  Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: YkGradientBackground(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [couleur, couleur.withValues(alpha: 0.7)],
                            ),
                            child: Center(
                              child: Text(
                                _initialesEnseignant(cours.enseignantPrincipal),
                                style: YkTypography.caption(
                                  context,
                                ).copyWith(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: YkSpacing.xs),
                      Expanded(
                        child: Text(
                          '${cours.enseignantPrincipal} · ${cours.lessons} leçons · '
                          '${cours.progression.toStringAsFixed(0)}%',
                          style: YkTypography.caption(context).copyWith(color: YkColors.textTertiary(context)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: YkSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(YkRadius.full),
                    child: LinearProgressIndicator(
                      value: cours.progression / 100,
                      minHeight: 6,
                      backgroundColor: YkColors.border(context),
                      valueColor: AlwaysStoppedAnimation(couleur),
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

  Widget _buildBadgeProgression(BuildContext context, double progression) {
    String texte = 'NOUVEAU';
    Color couleur = YkColors.accent(context);
    if (progression >= 100) {
      texte = 'TERMINÉ';
      couleur = YkColors.success;
    } else if (progression > 0) {
      texte = 'EN COURS';
      couleur = YkColors.warning;
    }
    return YkBadge(variant: YkBadgeVariant.label, label: texte, color: couleur);
  }
}
