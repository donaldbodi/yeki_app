// lib/features/devoirs_cours/presentation/resultat_devoir_page.dart
//
// Écran « résultat de devoir ». Refondu en P7.6 (rituel P5.0) — remplace
// lib/views/pages/apprenants/resultat_devoir_page.dart. Pas de maquette
// dédiée trouvée (comme pour son jumeau `resultat_exercice_page.dart`,
// P6.5) — le texte du ticket fait foi.
//
// Contrairement à l'exercice : pas de tentatives multiples ni de bouton
// « Refaire » (une seule soumission par devoir), pas de pipeline
// rang-gagné/`YkCelebration` (confirmé absent côté devoir, P7.5). En
// plus : état « en attente de correction » dédié, note nullable
// (correction manuelle), commentaire enseignant, PDF de correction.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/models/devoir_models.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';

import 'resultat_devoir_controller.dart';
import 'widgets/detail_reponse_devoir_tile.dart';

class ResultatDevoirPage extends StatefulWidget {
  const ResultatDevoirPage({
    super.key,
    required this.devoirId,
    required this.titre,
    this.coursId,
    this.coursTitre,
  });

  final int devoirId;
  final String titre;
  final int? coursId;
  final String? coursTitre;

  @override
  State<ResultatDevoirPage> createState() => _ResultatDevoirPageState();
}

class _ResultatDevoirPageState extends State<ResultatDevoirPage> {
  late final ResultatDevoirController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ResultatDevoirController(devoirId: widget.devoirId);
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
      source: 'devoir',
      devoirId: widget.devoirId,
      devoirTitre: widget.titre,
      coursId: widget.coursId,
      coursTitre: widget.coursTitre ?? '',
    );
  }

  /// Corrige l'ancien fichier : `(coursId ?? 0)` interrogeait
  /// `/ia/cours/0/chat/` pour un devoir sans cours lié — désactivé
  /// proprement à la place (même patron que `resultat_exercice_page.dart`).
  void _ouvrirIA() {
    if (widget.coursId == null) return;
    context.pushNamed(
      AppRoute.iaChat,
      pathParameters: {'coursId': widget.coursId.toString()},
      queryParameters: {
        'coursTitre': widget.coursTitre ?? '',
        'sourceInitiale': 'devoir',
        'sourceId': widget.devoirId.toString(),
        'sourceTitreInit': widget.titre,
      },
    );
  }

  Future<void> _telechargerPdf(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, _) => _buildScaffold(context));
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        title: Text(widget.titre, style: YkTypography.h4(context)),
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
      body: switch (_controller.etat) {
        ResultatDevoirEtat.chargement => Padding(
          padding: EdgeInsets.all(YkSpacing.md),
          child: YkSkeleton.list(itemCount: 4, itemHeight: 96),
        ),
        ResultatDevoirEtat.enAttenteCorrection => YkEmptyState(
          icon: Icons.hourglass_top_rounded,
          title: 'Correction en attente',
          message: _controller.erreurMessage ??
              "Votre devoir sera corrigé prochainement par l'enseignant.",
          actionLabel: 'Actualiser',
          onAction: _controller.charger,
        ),
        ResultatDevoirEtat.erreur => YkErrorState(
          message: _controller.erreurMessage ?? 'Une erreur est survenue.',
          onRetry: _controller.charger,
        ),
        ResultatDevoirEtat.pret => _buildResultat(context),
      },
    );
  }

  Widget _buildResultat(BuildContext context) {
    final resultat = _controller.resultat;
    if (resultat == null) {
      return const YkEmptyState(
        title: 'Aucun résultat',
        message: 'Aucun résultat disponible pour ce devoir.',
      );
    }

    final pourcentage = resultat.noteSur > 0 ? (resultat.note! / resultat.noteSur * 100) : 0.0;
    final scoreOk = pourcentage >= 50;

    return ListView(
      padding: EdgeInsets.all(YkSpacing.md),
      children: [
        _buildEnTete(context, resultat, scoreOk, pourcentage),
        if (resultat.commentaire.isNotEmpty) ...[
          SizedBox(height: YkSpacing.md),
          _buildCommentaire(context, resultat.commentaire),
        ],
        if (resultat.fichierCorrectionUrl != null) ...[
          SizedBox(height: YkSpacing.md),
          _buildPdfCorrection(context, resultat.fichierCorrectionUrl!),
        ],
        if (resultat.questionsDetail.isNotEmpty) ...[
          SizedBox(height: YkSpacing.md),
          _buildToggleCorrection(context),
          if (_controller.correctionVisible)
            ...resultat.questionsDetail.asMap().entries.map(
              (e) => DetailReponseDevoirTile(detail: e.value, index: e.key + 1),
            ),
        ],
        SizedBox(height: YkSpacing.md),
      ],
    );
  }

  Widget _buildEnTete(BuildContext context, ResultatDevoir resultat, bool scoreOk, double pourcentage) {
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
            'Note : ${resultat.note!.toStringAsFixed(1)} / ${resultat.noteSur.toStringAsFixed(0)}',
            style: YkTypography.h1(context).copyWith(color: couleur),
          ),
          Text(
            '${pourcentage.toStringAsFixed(0)} %',
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
          ),
          if (resultat.estEnRetard) ...[
            SizedBox(height: YkSpacing.xs),
            YkChip(
              label: 'Soumis en retard',
              variant: YkChipVariant.assist,
              accentColor: YkColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentaire(BuildContext context, String commentaire) {
    return YkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment_rounded, size: 16, color: YkColors.accent(context)),
              SizedBox(width: YkSpacing.xs),
              Text(
                "Commentaire de l'enseignant",
                style: YkTypography.label(context).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: YkSpacing.xs),
          Text(commentaire, style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context))),
        ],
      ),
    );
  }

  Widget _buildPdfCorrection(BuildContext context, String url) {
    return YkCard(
      variant: YkCardVariant.filled,
      onTap: () => _telechargerPdf(url),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: YkColors.accent(context), size: 24),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fichier de correction',
                  style: YkTypography.label(context).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Téléchargez le PDF pour voir la correction détaillée',
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          Icon(Icons.download_rounded, color: YkColors.accent(context)),
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
