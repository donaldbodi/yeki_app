// lib/features/exercice/presentation/passer_exercice_page.dart
//
// Écran « passer un exercice ». Refondu en P6.4 (rituel P5.0) — fiche
// d'écarts : docs/ecarts/passer_exercice.md. Priorité absolue du ticket :
// `PopScope` était totalement absent (régression signalée depuis deux
// cahiers des charges) — câblé ici sur `YkConfirmSheet`/`YkExitPolicy`,
// déjà entièrement codés mais jamais consommés par aucun écran réel.
//
// `StatefulWidget` simple (pas de provider Riverpod — même précédent que
// Login/Register/Onboarding, aucun état partagé entre écrans requis).
// État dans `PasserExerciceController` (ChangeNotifier) : `lib/features/`
// interdit `setState` (règle 7 de `check_design_system.sh`).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/models/exercice_models.dart';
import 'package:yeki/widgets/form_preoccupation_sheet.dart';

import 'passer_exercice_controller.dart';
import 'widgets/question_card.dart';

class PasserExercicePage extends StatefulWidget {
  const PasserExercicePage({
    super.key,
    required this.exerciceId,
    required this.coursId,
    required this.coursTitre,
  });

  final int exerciceId;
  final int? coursId;
  final String coursTitre;

  @override
  State<PasserExercicePage> createState() => _PasserExercicePageState();
}

class _PasserExercicePageState extends State<PasserExercicePage> {
  late final PasserExerciceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PasserExerciceController(exerciceId: widget.exerciceId);
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Priorité absolue du ticket : sortie système (bouton retour Android,
  /// swipe) ET bouton de sortie manuel passent tous les deux par ici —
  /// message EXACT imposé par le ticket, déjà porté par `YkConfirmSheet`
  /// (mis à jour pour P6.4).
  Future<bool> _confirmerSortie() async {
    final policy = _controller.tentativesEpuisees
        ? YkExitPolicy.exerciceTentativesEpuisees
        : YkExitPolicy.exerciceTentativesRestantes;
    final quitter = await YkConfirmSheet.confirmExit(context, policy: policy);
    if (!quitter) return false;
    if (!_controller.tentativesEpuisees) {
      await _controller.sortir();
    }
    return true;
  }

  void _ouvrirPreoccupation() {
    ouvrirPreoccupation(
      context: context,
      source: 'exercice',
      exerciceId: widget.exerciceId,
      exerciceTitre: _controller.exercice?.titre ?? 'Exercice',
      coursId: widget.coursId,
      coursTitre: widget.coursTitre,
    );
  }

  void _ouvrirIA() {
    context.pushNamed(
      AppRoute.iaChat,
      pathParameters: {'coursId': (widget.coursId ?? 0).toString()},
      queryParameters: {
        'coursTitre': widget.coursTitre,
        'sourceInitiale': 'exercice',
        'sourceId': widget.exerciceId.toString(),
        'sourceTitreInit': _controller.exercice?.titre ?? 'Exercice',
      },
    );
  }

  /// Bouton « Voir la correction » — PERMANENT si tentatives épuisées
  /// (exigence explicite), pas seulement juste après une soumission
  /// fraîche. Réutilise la route déjà existante (une seule UI de
  /// résultat, règle 1) au lieu de dupliquer une vue inline.
  ///
  /// [soumission] transmet un gain de rang éventuel (P6.3 : renvoyé
  /// uniquement par `evaluer`/`sortir`, jamais par `GET resultat`) —
  /// c'est `ResultatExercicePage` qui affiche désormais `YkCelebration`
  /// (P6.5, remplace l'ancien `YkDialog.alert` ci-dessous).
  void _voirCorrection([SoumissionExercice? soumission]) {
    context.pushNamed(
      AppRoute.exerciceResultat,
      pathParameters: {'exerciceId': widget.exerciceId.toString()},
      queryParameters: {
        'exerciceTitre': _controller.exercice?.titre ?? 'Exercice',
        if (widget.coursId != null) 'coursId': widget.coursId.toString(),
        'coursTitre': widget.coursTitre,
        if (soumission?.rangGagne == true) ...{
          'rangGagne': 'true',
          'ancienRang': soumission!.ancienRang.toString(),
          'nouveauRang': soumission.nouveauRang.toString(),
        },
      },
    );
  }

  Future<void> _soumettre({bool auto = false}) async {
    if (!auto && !_controller.toutesRepondues) {
      final manquantes = _controller.exercice!.questions.length - _controller.reponses.length;
      final confirme = await YkDialog.confirm(
        context: context,
        title: 'Soumettre malgré tout ?',
        message: "Vous n'avez pas répondu à $manquantes question(s). "
            'Voulez-vous vraiment soumettre ?',
        confirmLabel: 'Soumettre',
      );
      if (confirme != true) return;
    }

    final resultat = await _controller.soumettre(auto: auto);
    if (!mounted) return;

    if (resultat == null) {
      if (_controller.horsLigne) {
        YkSnack.warning(
          context,
          'Pas de connexion — vos réponses sont sauvegardées, réessayez.',
        );
      }
      return;
    }

    YkSnack.success(
      context,
      auto ? 'Temps écoulé ! Exercice soumis automatiquement.' : 'Exercice soumis avec succès.',
    );
    _voirCorrection(resultat);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final quitter = await _confirmerSortie();
        if (!quitter || !mounted) return;
        Navigator.of(context).pop();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    switch (_controller.etat) {
      case PasserExerciceEtat.chargement:
        return Scaffold(
          backgroundColor: YkColors.background(context),
          appBar: AppBar(title: const Text('Exercice')),
          body: Padding(
            padding: EdgeInsets.all(YkSpacing.md),
            child: YkSkeleton.list(itemCount: 4, itemHeight: 96),
          ),
        );
      case PasserExerciceEtat.erreur:
        return Scaffold(
          backgroundColor: YkColors.background(context),
          appBar: AppBar(title: const Text('Exercice')),
          body: YkErrorState(
            message: _controller.erreurMessage ?? 'Une erreur est survenue.',
            onRetry: _controller.charger,
          ),
        );
      case PasserExerciceEtat.pret:
        return _buildExercice(context);
    }
  }

  Widget _buildExercice(BuildContext context) {
    final exercice = _controller.exercice!;
    final questions = exercice.questions;
    final progress = questions.isEmpty ? 0.0 : _controller.reponses.length / questions.length;

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: YkColors.background(context),
        appBar: AppBar(leading: BackButton(onPressed: () => Navigator.of(context).maybePop())),
        body: const YkEmptyState(
          title: 'Aucune question',
          message: "Cet exercice ne contient aucune question pour l'instant.",
        ),
      );
    }

    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Quitter',
          onPressed: () async {
            final quitter = await _confirmerSortie();
            if (quitter && mounted) Navigator.of(context).pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercice.titre, style: YkTypography.h4(context)),
            Text(
              '${_controller.reponses.length}/${questions.length} questions répondues',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
          ],
        ),
        actions: [
          if (!_controller.tentativesEpuisees && exercice.tempsRestantSecondes > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm),
              child: Center(
                child: YkCountdown(
                  key: ValueKey('countdown-${exercice.id}'),
                  duration: Duration(seconds: exercice.tempsRestantSecondes),
                  onExpired: () => _soumettre(auto: true),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.psychology_rounded),
            tooltip: 'Yéki IA',
            onPressed: _ouvrirIA,
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
          YkProgress(value: progress),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(YkSpacing.md),
              children: [
                _buildEnonce(context, exercice),
                SizedBox(height: YkSpacing.lg),
                ...questions.asMap().entries.map(
                      (entry) => QuestionCard(
                        key: ValueKey(entry.value.id),
                        question: entry.value,
                        index: entry.key + 1,
                        reponseActuelle: _controller.reponses[entry.value.id],
                        tentativesEpuisees: _controller.tentativesEpuisees,
                        onChanged: (valeur) => _controller.repondre(entry.value.id, valeur),
                      ),
                    ),
                SizedBox(height: YkSpacing.lg),
                _buildBoutonBas(context),
                SizedBox(height: YkSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnonce(BuildContext context, exercice) {
    return YkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: YkColors.accent(context), size: 20),
              SizedBox(width: YkSpacing.xs),
              Text('Consigne', style: YkTypography.label(context).copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: YkSpacing.sm),
          YkRichViewer(
            html: exercice.enonce.isNotEmpty
                ? exercice.enonce
                : 'Lisez attentivement les questions suivantes.',
          ),
          if (!_controller.tentativesEpuisees) ...[
            SizedBox(height: YkSpacing.sm),
            Text(
              'Tentatives restantes : ${exercice.tentativesRestantes} / ${exercice.tentativesMax}',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
          ] else ...[
            SizedBox(height: YkSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: YkColors.warning, size: 16),
                SizedBox(width: YkSpacing.xxs),
                Text(
                  'Vous avez utilisé toutes vos tentatives',
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.warning, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoutonBas(BuildContext context) {
    if (_controller.tentativesEpuisees) {
      // Correction PERMANENTE — exigence explicite du ticket, accessible
      // à tout moment, pas seulement après une soumission de cette session.
      return YkButton(label: 'Voir la correction', onPressed: _voirCorrection);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_controller.toutesRepondues)
          Padding(
            padding: EdgeInsets.only(bottom: YkSpacing.sm),
            child: Text(
              '${_controller.exercice!.questions.length - _controller.reponses.length} question(s) restante(s)',
              textAlign: TextAlign.center,
              style: YkTypography.bodySm(context).copyWith(color: YkColors.warning, fontWeight: FontWeight.w600),
            ),
          ),
        YkButton(
          label: "Terminer l'examen",
          isLoading: _controller.soumission,
          onPressed: _controller.soumission ? null : () => _soumettre(),
        ),
      ],
    );
  }
}
