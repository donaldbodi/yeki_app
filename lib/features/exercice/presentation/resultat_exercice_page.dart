// lib/features/exercice/presentation/resultat_exercice_page.dart
//
// Écran « résultat d'exercice ». Refondu en P6.5 (rituel P5.0) — fiche
// d'écarts : docs/ecarts/resultat_exercice.md. `ChangeNotifier` (pas de
// `setState`, règle 7) — même patron que `PasserExerciceController`.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/models/exercice_models.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';

import 'resultat_exercice_controller.dart';
import 'widgets/detail_reponse_tile.dart';
import 'widgets/resultat_actions_row.dart';
import 'widgets/tentative_card.dart';

class ResultatExercicePage extends StatefulWidget {
  const ResultatExercicePage({
    super.key,
    required this.exerciceId,
    required this.exerciceTitre,
    this.coursId,
    this.coursTitre = '',
    this.rangGagne,
    this.ancienRang,
    this.nouveauRang,
  });

  final int exerciceId;
  final String exerciceTitre;
  final int? coursId;
  final String coursTitre;

  /// Transmis par `PasserExercicePage` après une soumission qui fait
  /// gagner un rang (`evaluer`/`sortir`, P6.3) — `GET resultat` ne
  /// renvoie jamais ces valeurs, seule la soumission le fait.
  final bool? rangGagne;
  final int? ancienRang;
  final int? nouveauRang;

  @override
  State<ResultatExercicePage> createState() => _ResultatExercicePageState();
}

class _ResultatExercicePageState extends State<ResultatExercicePage> {
  late final ResultatExerciceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ResultatExerciceController(
      exerciceId: widget.exerciceId,
      celebrationVisible: widget.rangGagne == true,
    );
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ouvrirPreoccupation() {
    ouvrirPreoccupation(
      context: context,
      source: 'exercice',
      exerciceId: widget.exerciceId,
      exerciceTitre: widget.exerciceTitre,
      coursId: widget.coursId,
      coursTitre: widget.coursTitre,
    );
  }

  void _ouvrirIA() {
    if (widget.coursId == null) return;
    context.pushNamed(
      AppRoute.iaChat,
      pathParameters: {'coursId': widget.coursId.toString()},
      queryParameters: {
        'coursTitre': widget.coursTitre,
        'sourceInitiale': 'exercice',
        'sourceId': widget.exerciceId.toString(),
        'sourceTitreInit': widget.exerciceTitre,
      },
    );
  }

  /// Remplace l'ancien `pushNamed` (empilait indéfiniment la pile de
  /// navigation à chaque cycle Refaire→Résultat) par un remplacement.
  void _refaireExercice() {
    context.pushReplacementNamed(
      AppRoute.exercicePasser,
      pathParameters: {'exerciceId': widget.exerciceId.toString()},
      queryParameters: {
        if (widget.coursId != null) 'coursId': widget.coursId.toString(),
        'coursTitre': widget.coursTitre,
      },
    );
  }

  Future<void> _voirToutesLesTentatives() async {
    await _controller.chargerHistoriqueComplet();
    if (!mounted) return;
    await YkSheet.show(
      context: context,
      title: 'Toutes les tentatives',
      bodyBuilder: (ctx) => AnimatedBuilder(
        animation: _controller,
        builder: (ctx, _) {
          final tentatives = _controller.historiqueComplet;
          if (_controller.chargementHistorique) {
            return Padding(
              padding: EdgeInsets.all(YkSpacing.md),
              child: YkSkeleton.list(itemCount: 3, itemHeight: 72),
            );
          }
          if (tentatives == null || tentatives.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: YkEmptyState(title: 'Aucune tentative', message: 'Aucune tentative enregistrée.'),
            );
          }
          return Padding(
            padding: EdgeInsets.all(YkSpacing.md),
            child: Column(
              children: [for (final t in tentatives.reversed) TentativeCard(tentative: t)],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, _) => _buildScaffold(context));
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        title: Text(widget.exerciceTitre, style: YkTypography.h4(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_rounded),
            tooltip: 'Yéki IA',
            onPressed: widget.coursId != null ? _ouvrirIA : null,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Poser une question',
            onPressed: _ouvrirPreoccupation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Affichée immédiatement à l'arrivée, indépendamment du
          // chargement du résultat — ne dépend que des query params
          // transmis par `PasserExercicePage`, pas de `GET resultat`.
          if (_controller.celebrationVisible)
            Padding(
              padding: EdgeInsets.all(YkSpacing.md),
              child: YkCelebration(
                title: 'Vous progressez !',
                statLabel: 'Nouveau rang du département',
                statValue: '#${widget.nouveauRang}',
                onDismiss: _controller.masquerCelebration,
              ),
            ),
          Expanded(
            child: switch (_controller.etat) {
              ResultatExerciceEtat.chargement => SingleChildScrollView(
                padding: EdgeInsets.all(YkSpacing.md),
                child: YkSkeleton.list(itemCount: 4, itemHeight: 96),
              ),
              ResultatExerciceEtat.erreur => YkErrorState(
                message: _controller.erreurMessage ?? 'Une erreur est survenue.',
                onRetry: _controller.charger,
              ),
              ResultatExerciceEtat.pret => _buildResultat(context),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultat(BuildContext context) {
    final resultat = _controller.resultat;
    if (resultat == null) {
      return const YkEmptyState(
        title: 'Aucun résultat',
        message: "Faites l'exercice pour voir votre résultat.",
      );
    }

    final scoreOk = resultat.total <= 0 || (resultat.score / resultat.total) >= 0.5;
    final derniereTentative = resultat.historique.isNotEmpty ? resultat.historique.last : null;

    return ListView(
      padding: EdgeInsets.all(YkSpacing.md),
      children: [
        _buildEnTete(context, resultat, scoreOk),
        SizedBox(height: YkSpacing.md),
        if (resultat.detail.isNotEmpty) ...[
          _buildToggleCorrection(context),
          if (_controller.correctionVisible)
            ...resultat.detail.asMap().entries.map(
              (e) => DetailReponseTile(detail: e.value, index: e.key + 1),
            ),
          SizedBox(height: YkSpacing.md),
        ] else if (derniereTentative != null) ...[
          TentativeCard(tentative: derniereTentative, initiallyExpanded: true),
          SizedBox(height: YkSpacing.md),
        ],
        ResultatActionsRow(
          tentativesEpuisees: resultat.tentativesEpuisees,
          onVoirTentatives: _voirToutesLesTentatives,
          onRefaire: _refaireExercice,
        ),
      ],
    );
  }

  Widget _buildEnTete(BuildContext context, ResultatExercice resultat, bool scoreOk) {
    final couleur = scoreOk ? YkColors.success : YkColors.error;
    return YkCard(
      variant: YkCardVariant.filled,
      accentColor: couleur,
      child: Column(
        children: [
          Icon(scoreOk ? Icons.emoji_events_rounded : Icons.refresh_rounded, color: couleur, size: 40),
          SizedBox(height: YkSpacing.xs),
          Text(
            scoreOk ? 'Bravo !' : 'Continuez vos efforts !',
            style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.xxs),
          Text(
            '${resultat.score.toStringAsFixed(resultat.score.truncateToDouble() == resultat.score ? 0 : 1)}'
            ' / ${resultat.total.toStringAsFixed(resultat.total.truncateToDouble() == resultat.total ? 0 : 1)}',
            style: YkTypography.h1(context).copyWith(color: couleur),
          ),
          Text(
            'Note : ${resultat.note.toStringAsFixed(1)} / ${resultat.noteSur.toStringAsFixed(0)}',
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          if (!resultat.tentativesEpuisees) ...[
            SizedBox(height: YkSpacing.xxs),
            Text(
              'Tentatives restantes : ${resultat.tentativesRestantes} / ${resultat.tentativesMax}',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleCorrection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        onTap: _controller.basculerCorrectionVisible,
        semanticLabel: 'Afficher ou masquer la correction détaillée',
        child: Row(
          children: [
            Icon(Icons.list_alt_rounded, color: YkColors.accent(context), size: 20),
            SizedBox(width: YkSpacing.sm),
            Expanded(
              child: Text(
                'Correction détaillée',
                style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
              ),
            ),
            Icon(
              _controller.correctionVisible ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: YkColors.accent(context),
            ),
          ],
        ),
      ),
    );
  }
}
