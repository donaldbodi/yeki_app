// lib/features/exercices_cours/presentation/exercices_cours_page.dart
//
// Onglet « Exercices » d'un cours. Refondu en P6.5 (rituel P5.0) —
// fiche d'écarts : docs/ecarts/exercices_cours.md. Embarqué comme
// contenu d'onglet par `CoursDetailTabs` (apprenant) et
// `DetailCoursEnseignantPage` (enseignant) — DEUX routes distinctes
// (P3.3), aucune Scaffold ici (le parent porte l'AppBar/les tabs).
//
// `didUpdateWidget` corrige le bug de filtre : la bascule d'onglet
// interne du parent (`_naviguerVersExercicesAvecFiltre`) change
// `moduleId`/`leconId` sur ce widget SANS lui donner de nouvelle `Key`
// — sans ce hook, l'ancien `_fetch()` (appelé uniquement depuis
// `initState`) ne se relançait jamais et les dropdowns visibles
// restaient désynchronisés (voir docs/ecarts/exercices_cours.md §3.2).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/models/exercice_models.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart' show RoleEnseignant;

import 'exercices_cours_controller.dart';
import 'widgets/exercice_card.dart';
import 'widgets/exercice_form_sheet.dart';
import 'widgets/filtres_row.dart';
import 'widgets/questions_sheet.dart';

class ExercicesCoursPage extends StatefulWidget {
  final String coursId;
  final String coursTitre;
  final RoleEnseignant? role;
  final void Function(int questionId)? onNaviguerForum;
  final Color courseColor;
  final int? moduleId;
  final int? leconId;

  /// Espace réservé en haut du contenu défilable — voir
  /// `LeconsCoursPage.topPadding` (même besoin, en-tête « verre dépoli »
  /// de `CoursDetailTabs`). `0` par défaut (autres contextes d'usage,
  /// ex. `DetailCoursEnseignantPage`, sans cet en-tête).
  final double topPadding;

  const ExercicesCoursPage({
    super.key,
    required this.coursId,
    required this.coursTitre,
    this.role,
    this.onNaviguerForum,
    required this.courseColor,
    this.moduleId,
    this.leconId,
    this.topPadding = 0,
  });

  @override
  State<ExercicesCoursPage> createState() => _ExercicesCoursPageState();
}

class _ExercicesCoursPageState extends State<ExercicesCoursPage> {
  late final ExercicesCoursController _controller;

  /// Réservé au seul enseignant principal (décision explicite, non
  /// négociable) : un cadre ne peut plus créer d'exercices.
  bool get _canEdit => widget.role == RoleEnseignant.enseignantPrincipal;

  @override
  void initState() {
    super.initState();
    _controller = ExercicesCoursController(coursId: int.parse(widget.coursId), canEdit: _canEdit)
      ..moduleFiltre = widget.moduleId
      ..leconFiltre = widget.leconId;
    _controller.charger(moduleId: widget.moduleId, leconId: widget.leconId);
  }

  @override
  void didUpdateWidget(covariant ExercicesCoursPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleId != widget.moduleId || oldWidget.leconId != widget.leconId) {
      _controller.appliquerFiltresExternes(moduleId: widget.moduleId, leconId: widget.leconId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Prend directement l'id (pas un `ExerciceListItem` complet) : appelé
  /// à la fois pour un exercice normal et pour un composant d'épreuve
  /// choisi depuis `_voirEpreuve` (qui n'a qu'un `id`/`titre`/`nb_questions`
  /// bruts, pas un `ExerciceListItem` complet).
  void _ouvrirExercice(int exerciceId) {
    context
        .pushNamed(
          AppRoute.exercicePasser,
          pathParameters: {'exerciceId': exerciceId.toString()},
          queryParameters: {
            if (int.tryParse(widget.coursId) != null) 'coursId': widget.coursId,
            'coursTitre': widget.coursTitre,
          },
        )
        .then((_) => _controller.charger(moduleId: _controller.moduleFiltre, leconId: _controller.leconFiltre));
  }

  Future<void> _ouvrirFormulaire({ExerciceListItem? existant}) async {
    final exercicesDisponibles = _controller.exercices
        .where((e) => !e.estEpreuve && e.id != existant?.id)
        .toList();
    await YkSheet.show(
      context: context,
      title: existant == null ? 'Nouvel exercice' : "Modifier l'exercice",
      bodyBuilder: (ctx) => ExerciceFormSheet(
        existant: existant,
        modules: _controller.modules,
        exercicesDisponibles: exercicesDisponibles,
        onSubmit: existant == null
            ? ({
                required titre,
                required enonce,
                required etoiles,
                required dureeMinutes,
                required tentativesMax,
                required typeExercice,
                moduleId,
                leconId,
                required estEpreuve,
                exercicesComposes,
              }) => _controller.creerExercice(
                titre: titre,
                enonce: enonce,
                etoiles: etoiles,
                dureeMinutes: dureeMinutes,
                tentativesMax: tentativesMax,
                typeExercice: typeExercice,
                moduleId: moduleId,
                leconId: leconId,
                estEpreuve: estEpreuve,
                exercicesComposes: exercicesComposes,
              )
            : ({
                required titre,
                required enonce,
                required etoiles,
                required dureeMinutes,
                required tentativesMax,
                required typeExercice,
                moduleId,
                leconId,
                required estEpreuve,
                exercicesComposes,
              }) => _controller.modifierExercice(
                exerciceId: existant.id,
                titre: titre,
                enonce: enonce,
                etoiles: etoiles,
                dureeMinutes: dureeMinutes,
                tentativesMax: tentativesMax,
                typeExercice: typeExercice,
                moduleId: moduleId,
                leconId: leconId,
                estEpreuve: estEpreuve,
                exercicesComposes: exercicesComposes,
              ),
      ),
    );
  }

  Future<void> _ouvrirQuestions(ExerciceListItem exercice) async {
    await YkSheet.show(
      context: context,
      title: exercice.titre,
      bodyBuilder: (ctx) => QuestionsSheet(
        exerciceId: exercice.id,
        exerciceTitre: exercice.titre,
        canEdit: _canEdit,
        fetchQuestions: _controller.listerQuestions,
        ajouterQuestion: _controller.ajouterQuestion,
      ),
    );
  }

  /// Bug corrigé : « Traiter » sur une épreuve envoyait tout droit vers
  /// `PasserExercicePage` avec l'id de l'ÉPREUVE elle-même — une épreuve
  /// n'a structurellement AUCUNE question propre (décision déjà actée en
  /// P6.3 : la note d'une épreuve est la SOMME de ses exercices composés,
  /// corrigés séparément, voir `_corriger_epreuve_composee` côté backend)
  /// — l'écran s'ouvrait donc toujours avec 0 question. Cette feuille
  /// sert maintenant de sélecteur réel : chaque exercice composé est
  /// cliquable (côté apprenant) et ouvre CE composant précis dans
  /// `PasserExercicePage`, qui a lui de vraies questions.
  Future<void> _voirEpreuve(ExerciceListItem epreuve) async {
    await YkSheet.show(
      context: context,
      title: epreuve.titre,
      bodyBuilder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in epreuve.exercicesComposes.asMap().entries)
            Padding(
              padding: EdgeInsets.only(bottom: YkSpacing.xs),
              child: YkCard(
                variant: YkCardVariant.outlined,
                onTap: _canEdit
                    ? null
                    : () {
                        Navigator.of(ctx).pop();
                        final composantId = entry.value['id'] as int?;
                        if (composantId != null) _ouvrirExercice(composantId);
                      },
                child: Row(
                  children: [
                    Text('${entry.key + 1}. ', style: YkTypography.label(context)),
                    Expanded(
                      child: Text(
                        entry.value['titre']?.toString() ?? '',
                        style: YkTypography.bodyMd(context),
                      ),
                    ),
                    Text(
                      '${entry.value['nb_questions'] ?? 0} questions',
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                    if (!_canEdit) ...[
                      SizedBox(width: YkSpacing.xs),
                      Icon(Icons.chevron_right_rounded, color: YkColors.textTertiary(context)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _supprimerExercice(ExerciceListItem exercice) async {
    final confirme = await YkDialog.confirm(
      context: context,
      title: "Supprimer l'exercice",
      message: 'Voulez-vous supprimer « ${exercice.titre} » ? Cette action est irréversible.',
      confirmLabel: 'Supprimer',
      variant: YkDialogVariant.destructive,
    );
    if (confirme != true) return;
    final ok = await _controller.supprimerExercice(exercice.id);
    if (!mounted) return;
    ok ? YkSnack.success(context, 'Exercice supprimé.') : YkSnack.error(context, 'Échec de la suppression.');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, _) => _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.etat) {
      case ExercicesCoursEtat.chargement:
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md + widget.topPadding, YkSpacing.md, YkSpacing.md),
          child: YkSkeleton.list(itemCount: 4, itemHeight: 140),
        );
      case ExercicesCoursEtat.erreur:
        return Padding(
          padding: EdgeInsets.only(top: widget.topPadding),
          child: YkErrorState(
            message: _controller.erreurMessage ?? 'Une erreur est survenue.',
            onRetry: () => _controller.charger(moduleId: _controller.moduleFiltre, leconId: _controller.leconFiltre),
          ),
        );
      case ExercicesCoursEtat.pret:
        return _buildListe(context);
    }
  }

  Widget _buildListe(BuildContext context) {
    final exercices = _controller.exercices;
    return RefreshIndicator(
      onRefresh: () => _controller.charger(moduleId: _controller.moduleFiltre, leconId: _controller.leconFiltre),
      child: ListView(
        padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md + widget.topPadding, YkSpacing.md, YkSpacing.md),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              Text(
                'Exercices',
                style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
              ),
              const Spacer(),
              if (_canEdit)
                YkButton(
                  label: 'Créer',
                  icon: Icons.add,
                  size: YkButtonSize.sm,
                  onPressed: () => _ouvrirFormulaire(),
                ),
            ],
          ),
          SizedBox(height: YkSpacing.md),
          FiltresRow(
            typeFiltre: _controller.typeFiltre,
            onTypeChanged: (v) => _controller.setTypeFiltre(v ?? 'all'),
            modules: _controller.modules,
            moduleFiltre: _controller.moduleFiltre,
            onModuleChanged: _controller.setModuleFiltre,
            leconFiltre: _controller.leconFiltre,
            onLeconChanged: _controller.setLeconFiltre,
            etoileFiltre: _controller.etoileFiltre,
            onEtoileChanged: _controller.setEtoileFiltre,
            onRechercheChanged: _controller.setRecherche,
          ),
          SizedBox(height: YkSpacing.md),
          if (exercices.isEmpty)
            YkEmptyState(
              title: 'Aucun exercice',
              message: _canEdit
                  ? 'Créez un exercice avec le bouton « Créer » ci-dessus.'
                  : 'Aucun exercice disponible pour ce cours.',
            )
          else
            for (final exercice in exercices)
              ExerciceCard(
                exercice: exercice,
                courseColor: widget.courseColor,
                canEdit: _canEdit,
                onTraiter: exercice.estEpreuve ? () => _voirEpreuve(exercice) : () => _ouvrirExercice(exercice.id),
                onEdit: _canEdit ? () => _ouvrirFormulaire(existant: exercice) : null,
                onQuestions: _canEdit ? () => _ouvrirQuestions(exercice) : null,
                onViewEpreuve: exercice.estEpreuve ? () => _voirEpreuve(exercice) : null,
                onDelete: _canEdit ? () => _supprimerExercice(exercice) : null,
              ),
        ],
      ),
    );
  }
}
