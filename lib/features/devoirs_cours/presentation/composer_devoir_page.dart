// lib/features/devoirs_cours/presentation/composer_devoir_page.dart
//
// Écran « composer un devoir » (apprenant). Refondu en P7.5 (rituel
// P5.0) — remplace lib/views/pages/apprenants/composer_devoir_page.dart.
// `PopScope` existait DÉJÀ dans l'ancien fichier (seul du projet) mais
// est intégralement réécrit ici sur `YkConfirmSheet`/`YkExitPolicy.devoir*`
// — déjà entièrement codés (même sprint que la politique exercice, P6.4)
// mais jamais consommés par aucun écran réel avant ce ticket.
//
// `StatefulWidget` simple (pas de provider Riverpod — même précédent que
// Login/Register/Onboarding/`PasserExercicePage`, aucun état partagé
// entre écrans requis). État dans `ComposerDevoirController`
// (ChangeNotifier) : `lib/features/` interdit `setState` (règle 7 de
// `check_design_system.sh`) — y compris pour le `TabController` de
// navigation entre énoncés, construit paresseusement dans `build()`
// plutôt que via `setState` (même patron que `_QuestionDevoirController`,
// `widgets/question_devoir_form.dart`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiMode;
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/models/devoir_models.dart';

import 'composer_devoir_controller.dart';
import 'widgets/question_devoir_composer_card.dart';

class ComposerDevoirPage extends StatefulWidget {
  const ComposerDevoirPage({
    super.key,
    required this.devoirId,
    required this.titre,
    required this.dureeMin,
    required this.noteSur,
    this.typeCorrection,
  });

  final int devoirId;
  final String titre;
  final int dureeMin;
  final int noteSur;
  final String? typeCorrection;

  @override
  State<ComposerDevoirPage> createState() => _ComposerDevoirPageState();
}

class _ComposerDevoirPageState extends State<ComposerDevoirPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final ComposerDevoirController _controller;
  TabController? _tabController;
  int _tabControllerLength = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ComposerDevoirController(devoirId: widget.devoirId);
    _controller.charger().then((_) {
      if (!mounted || _controller.etat != ComposerDevoirEtat.pret) return;

      // Mode immersif réservé aux devoirs d'olympiade (compétition
      // chronométrée) — comportement RÉEL de l'ancien écran, atteignable
      // via `olympiades_page.dart` → `AppRoute.devoirComposer` en phase de
      // compétition, conservé tel quel (règle 5 : ne rien perdre). NE PAS
      // confondre avec le mode « question par question » de l'ancien
      // écran (`_qParQ`), lui réellement mort — voir
      // `DevoirAComposer.typeDevoir`.
      if (_controller.devoir!.estOlympiade) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }

      // Temps déjà écoulé pendant l'absence de l'apprenant (reprise d'une
      // composition en cours) — `YkCountdown` ne peut pas déclencher
      // `onExpired` s'il n'est jamais affiché (durée <= 0).
      if (widget.dureeMin > 0 && _controller.tempsRestantSecondes <= 0) {
        _soumettre(auto: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _tabController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Anti-triche généralisé à TOUS les devoirs (P7.5) — l'ancien écran ne
    // signalait la perte de focus QUE pour les devoirs d'olympiade
    // (`_estOlymp`, un indicateur réel et atteignable, contrairement au
    // mode question-par-question ci-dessus) : les devoirs de cours
    // ordinaires n'avaient aucune détection de perte de focus avant ce
    // ticket.
    if (_controller.etat == ComposerDevoirEtat.pret &&
        (state == AppLifecycleState.paused || state == AppLifecycleState.inactive)) {
      _controller.signalerFocusPerdu();
    }
  }

  TabController _tabControllerFor(int length) {
    if (_tabController == null || _tabControllerLength != length) {
      _tabController?.dispose();
      _tabControllerLength = length;
      _tabController = TabController(length: length, vsync: this);
    }
    return _tabController!;
  }

  /// Sortie anticipée (bouton retour / geste système / bouton croix) —
  /// message EXACT imposé par le ticket, déjà porté par `YkConfirmSheet`.
  /// NE PAS confondre avec la politique exercice (P4.4/P6.4) : ici,
  /// `sortir()` est TOUJOURS appelé après confirmation, quelle que soit la
  /// politique — c'est le serveur qui décide, via son propre compteur,
  /// s'il s'agit d'un simple comptage ou d'une soumission automatique.
  Future<bool> _confirmerSortie() async {
    final policy = _controller.sortieEpuiseraLesTentatives
        ? YkExitPolicy.devoirTentativesEpuisees
        : YkExitPolicy.devoirTentativesRestantes;
    final quitter = await YkConfirmSheet.confirmExit(context, policy: policy);
    if (!quitter) return false;
    await _controller.sortir();
    return true;
  }

  Future<void> _soumettre({bool auto = false}) async {
    if (!auto && !_controller.toutesRepondues) {
      final total = _controller.devoir!.toutesLesQuestions.length;
      final manquantes = total - _controller.reponses.length;
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
        YkSnack.warning(context, 'Pas de connexion — vos réponses sont sauvegardées, réessayez.');
      }
      return;
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    YkSnack.success(
      context,
      auto ? 'Temps écoulé ! Devoir soumis automatiquement.' : 'Devoir soumis avec succès.',
    );
    _voirResultat();
  }

  void _voirResultat() {
    context.pushReplacementNamed(
      AppRoute.devoirResultat,
      pathParameters: {'devoirId': widget.devoirId.toString()},
      queryParameters: {'titre': widget.titre},
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_controller.etat != ComposerDevoirEtat.pret) {
          Navigator.of(context).pop();
          return;
        }
        final quitter = await _confirmerSortie();
        if (!quitter || !mounted) return;
        Navigator.of(context).pop();
      },
      child: AnimatedBuilder(animation: _controller, builder: (context, _) => _buildScaffold(context)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    switch (_controller.etat) {
      case ComposerDevoirEtat.chargement:
        return _scaffoldChargement(context);
      case ComposerDevoirEtat.erreur:
        return Scaffold(
          backgroundColor: YkColors.background(context),
          appBar: AppBar(title: Text(widget.titre)),
          body: YkErrorState(
            message: _controller.erreurMessage ?? 'Une erreur est survenue.',
            onRetry: _controller.charger,
          ),
        );
      case ComposerDevoirEtat.dejaSoumis:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _voirResultat();
        });
        return _scaffoldChargement(context);
      case ComposerDevoirEtat.pret:
        return _buildDevoir(context);
    }
  }

  Widget _scaffoldChargement(BuildContext context) => Scaffold(
    backgroundColor: YkColors.background(context),
    appBar: AppBar(title: Text(widget.titre)),
    body: Padding(padding: EdgeInsets.all(YkSpacing.md), child: YkSkeleton.list(itemCount: 4, itemHeight: 96)),
  );

  Widget _buildDevoir(BuildContext context) {
    final devoir = _controller.devoir!;
    final questions = devoir.toutesLesQuestions;
    final progress = questions.isEmpty ? 0.0 : _controller.reponses.length / questions.length;
    final multiEnonces = devoir.enonces.length > 1;
    final tabController = multiEnonces ? _tabControllerFor(devoir.enonces.length) : null;

    // Devoir d'olympiade : pas de bouton de sortie manuel affiché (comme
    // l'ancien écran) — seul le geste système reste intercepté par
    // `PopScope`, avec la même confirmation que partout ailleurs.
    final boutonSortie = devoir.estOlympiade
        ? null
        : IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Quitter',
            onPressed: () async {
              final quitter = await _confirmerSortie();
              if (quitter && mounted) Navigator.of(context).pop();
            },
          );

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: YkColors.background(context),
        appBar: AppBar(leading: boutonSortie),
        body: const YkEmptyState(
          title: 'Aucune question',
          message: "Ce devoir ne contient aucune question pour l'instant.",
        ),
      );
    }

    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        leading: boutonSortie,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(devoir.titre, style: YkTypography.h4(context), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              '${_controller.reponses.length}/${questions.length} questions répondues',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
          ],
        ),
        actions: [
          if (widget.dureeMin > 0 && _controller.tempsRestantSecondes > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: YkSpacing.sm),
              child: Center(
                child: YkCountdown(
                  key: ValueKey('countdown-devoir-${devoir.id}'),
                  duration: Duration(seconds: _controller.tempsRestantSecondes),
                  onExpired: () => _soumettre(auto: true),
                ),
              ),
            ),
        ],
        bottom: multiEnonces
            ? YkTabs(
                controller: tabController!,
                tabs: [for (final e in devoir.enonces) YkTabItem(label: 'Énoncé ${e.ordre}')],
              )
            : null,
      ),
      body: Column(
        children: [
          YkProgress(value: progress),
          Expanded(
            child: multiEnonces
                ? TabBarView(
                    controller: tabController,
                    children: [for (final e in devoir.enonces) _buildEnonceListe(context, e)],
                  )
                : _buildEnonceListe(context, devoir.enonces.first),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildEnonceListe(BuildContext context, EnonceDevoirComposer enonce) {
    return ListView(
      padding: EdgeInsets.all(YkSpacing.md),
      children: [
        if (enonce.contenu.isNotEmpty) ...[
          YkCard(child: YkRichViewer(html: enonce.contenu)),
          SizedBox(height: YkSpacing.lg),
        ],
        ...enonce.questions.asMap().entries.map(
          (entry) => QuestionDevoirComposerCard(
            key: ValueKey(entry.value.id),
            question: entry.value,
            index: entry.key + 1,
            reponseActuelle: _controller.reponses[entry.value.id],
            onChanged: (valeur) => _controller.repondre(entry.value.id, valeur),
          ),
        ),
        SizedBox(height: YkSpacing.xl),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(YkSpacing.md),
      color: YkColors.surface(context),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_controller.toutesRepondues)
              Padding(
                padding: EdgeInsets.only(bottom: YkSpacing.sm),
                child: Text(
                  '${_controller.devoir!.toutesLesQuestions.length - _controller.reponses.length} question(s) restante(s)',
                  textAlign: TextAlign.center,
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.warning, fontWeight: FontWeight.w600),
                ),
              ),
            YkButton(
              label: 'Soumettre le devoir',
              isLoading: _controller.soumission,
              onPressed: _controller.soumission ? null : () => _soumettre(),
            ),
          ],
        ),
      ),
    );
  }
}
