import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/exercice_models.dart';

/// État de la feuille — `ChangeNotifier` plutôt que `setState` (interdit
/// sous `lib/features/`, règle 7 de `check_design_system.sh`).
class _QuestionsSheetController extends ChangeNotifier {
  _QuestionsSheetController({required this.exerciceId, required this.fetchQuestions});

  final int exerciceId;
  final Future<List<QuestionExercice>> Function(int exerciceId) fetchQuestions;

  List<QuestionExercice> questions = const [];
  bool chargement = true;
  bool afficherForme = false;

  final texteCtrl = TextEditingController();
  final bonneRepCtrl = TextEditingController();
  String type = 'qcm';
  double points = 1.0;
  List<TextEditingController> choixCtrl = [TextEditingController(), TextEditingController()];
  int correctIndex = 0;
  bool envoi = false;

  Future<void> charger() async {
    chargement = true;
    notifyListeners();
    questions = await fetchQuestions(exerciceId);
    chargement = false;
    notifyListeners();
  }

  void afficherFormulaire() {
    afficherForme = true;
    notifyListeners();
  }

  void resetForm() {
    texteCtrl.clear();
    bonneRepCtrl.clear();
    for (final c in choixCtrl) {
      c.dispose();
    }
    choixCtrl = [TextEditingController(), TextEditingController()];
    type = 'qcm';
    points = 1.0;
    correctIndex = 0;
    afficherForme = false;
    notifyListeners();
  }

  void setType(String v) {
    type = v;
    notifyListeners();
  }

  void setPoints(double v) {
    points = v;
    notifyListeners();
  }

  void ajouterChoix() {
    choixCtrl.add(TextEditingController());
    notifyListeners();
  }

  void supprimerDernierChoix() {
    choixCtrl.removeLast().dispose();
    if (correctIndex >= choixCtrl.length) correctIndex = choixCtrl.length - 1;
    notifyListeners();
  }

  void selectionnerCorrect(int index) {
    correctIndex = index;
    notifyListeners();
  }

  void setEnvoi(bool v) {
    envoi = v;
    notifyListeners();
  }

  @override
  void dispose() {
    texteCtrl.dispose();
    bonneRepCtrl.dispose();
    for (final c in choixCtrl) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Gestion des questions d'un exercice — liste + formulaire d'ajout.
///
/// Corrige le bug critique de l'ancien `_QuestionsSheetState._submit` :
/// chaque choix QCM porte désormais explicitement `est_correct` (au
/// lieu d'un unique `bonne_reponse` texte jamais reflété par aucun
/// `Choix.est_correct` côté serveur — voir docs/ecarts/exercices_cours.md).
/// Même UI visuelle qu'avant (une sélection radio par choix), payload
/// corrigé seulement.
class QuestionsSheet extends StatefulWidget {
  const QuestionsSheet({
    super.key,
    required this.exerciceId,
    required this.exerciceTitre,
    required this.canEdit,
    required this.fetchQuestions,
    required this.ajouterQuestion,
  });

  final int exerciceId;
  final String exerciceTitre;
  final bool canEdit;
  final Future<List<QuestionExercice>> Function(int exerciceId) fetchQuestions;
  final Future<bool> Function({
    required int exerciceId,
    required String text,
    required String typeQuestion,
    required double points,
    String? bonneReponse,
    List<ChoixQuestion>? choix,
  })
  ajouterQuestion;

  @override
  State<QuestionsSheet> createState() => _QuestionsSheetState();
}

class _QuestionsSheetState extends State<QuestionsSheet> {
  late final _QuestionsSheetController _controller = _QuestionsSheetController(
    exerciceId: widget.exerciceId,
    fetchQuestions: widget.fetchQuestions,
  );

  @override
  void initState() {
    super.initState();
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final c = _controller;
    final texte = c.texteCtrl.text.trim();
    if (texte.isEmpty) {
      YkSnack.error(context, "L'énoncé est requis.");
      return;
    }

    List<ChoixQuestion>? choix;
    String? bonneReponse;
    if (c.type == 'qcm') {
      if (c.choixCtrl.any((ctrl) => ctrl.text.trim().isEmpty)) {
        YkSnack.error(context, 'Remplissez tous les choix.');
        return;
      }
      choix = [
        for (var i = 0; i < c.choixCtrl.length; i++)
          ChoixQuestion(texte: c.choixCtrl[i].text.trim(), estCorrect: i == c.correctIndex),
      ];
    } else {
      bonneReponse = c.bonneRepCtrl.text.trim();
      if (bonneReponse.isEmpty) {
        YkSnack.error(context, 'Indiquez la bonne réponse.');
        return;
      }
    }

    c.setEnvoi(true);
    final ok = await widget.ajouterQuestion(
      exerciceId: widget.exerciceId,
      text: texte,
      typeQuestion: c.type,
      points: c.points,
      bonneReponse: bonneReponse,
      choix: choix,
    );
    if (!mounted) return;
    c.setEnvoi(false);
    if (ok) {
      YkSnack.success(context, 'Question ajoutée.');
      c.resetForm();
      c.charger();
    } else {
      YkSnack.error(context, "Échec de l'envoi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, _) => _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final c = _controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.canEdit && !c.afficherForme)
          Padding(
            padding: EdgeInsets.only(bottom: YkSpacing.md),
            child: YkButton(
              label: 'Ajouter une question',
              icon: Icons.add,
              variant: YkButtonVariant.secondary,
              onPressed: c.afficherFormulaire,
            ),
          ),
        if (c.afficherForme) _buildForm(context),
        if (c.chargement)
          Padding(padding: EdgeInsets.all(YkSpacing.lg), child: YkSkeleton.list(itemCount: 2, itemHeight: 80))
        else if (c.questions.isEmpty && !c.afficherForme)
          const YkEmptyState(title: 'Aucune question', message: "Cet exercice n'a pas encore de question.")
        else
          ...c.questions.asMap().entries.map((e) => _buildQuestionCard(context, e.key + 1, e.value)),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final c = _controller;
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.md),
      child: YkCard(
        variant: YkCardVariant.filled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YkSegmented<String>(
              segments: const [
                YkSegment(value: 'qcm', label: 'QCM'),
                YkSegment(value: 'texte', label: 'Texte libre'),
              ],
              selected: c.type,
              onChanged: c.setType,
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(
              controller: c.texteCtrl,
              type: YkTextFieldType.multiline,
              maxLines: 3,
              label: 'Énoncé de la question',
              required: true,
            ),
            SizedBox(height: YkSpacing.sm),
            YkStepper(label: 'Points', value: c.points, min: 0.25, max: 10, step: 0.25, onChanged: c.setPoints),
            SizedBox(height: YkSpacing.sm),
            if (c.type == 'qcm') ...[
              Text(
                'Choix de réponse — sélectionnez le choix correct',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
              SizedBox(height: YkSpacing.xs),
              ...List.generate(c.choixCtrl.length, (i) => _buildChoixRow(context, i)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (c.choixCtrl.length < 6)
                    TextButton.icon(
                      onPressed: c.ajouterChoix,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter un choix'),
                    ),
                  if (c.choixCtrl.length > 2)
                    TextButton.icon(
                      onPressed: c.supprimerDernierChoix,
                      icon: Icon(Icons.remove_circle_outline, size: 16, color: YkColors.error),
                      label: Text('Supprimer', style: TextStyle(color: YkColors.error)),
                    ),
                ],
              ),
            ] else
              YkTextField(controller: c.bonneRepCtrl, label: 'Réponse attendue', required: true),
            SizedBox(height: YkSpacing.md),
            Row(
              children: [
                Expanded(
                  child: YkButton(label: 'Annuler', variant: YkButtonVariant.ghost, onPressed: c.resetForm),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: YkButton(label: 'Publier', isLoading: c.envoi, onPressed: c.envoi ? null : _submit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoixRow(BuildContext context, int index) {
    final c = _controller;
    final selectionne = c.correctIndex == index;
    final accent = YkColors.accent(context);
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.xs),
      child: Row(
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => c.selectionnerCorrect(index),
            child: Padding(
              padding: EdgeInsets.all(YkSpacing.xxs),
              child: Icon(
                selectionne ? Icons.check_circle : Icons.circle_outlined,
                color: selectionne ? accent : YkColors.textTertiary(context),
                size: 22,
              ),
            ),
          ),
          SizedBox(width: YkSpacing.xs),
          Expanded(
            child: YkTextField(
              controller: c.choixCtrl[index],
              hint: 'Choix ${index + 1}',
              semanticLabel: 'Choix ${index + 1}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, int numero, QuestionExercice question) {
    return Padding(
      padding: EdgeInsets.only(bottom: YkSpacing.sm),
      child: YkCard(
        variant: YkCardVariant.outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                YkChip(label: 'Q$numero', variant: YkChipVariant.assist),
                SizedBox(width: YkSpacing.xs),
                YkChip(label: question.estQcm ? 'QCM' : 'Texte libre', variant: YkChipVariant.assist),
                const Spacer(),
                Text(
                  '${question.points.toStringAsFixed(question.points.truncateToDouble() == question.points ? 0 : 2)} pt',
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                ),
              ],
            ),
            SizedBox(height: YkSpacing.sm),
            Text(
              question.text,
              style: YkTypography.bodyMd(
                context,
              ).copyWith(color: YkColors.textPrimary(context), fontWeight: FontWeight.w600),
            ),
            SizedBox(height: YkSpacing.sm),
            if (question.estQcm)
              ...question.choix.map(
                (c) => Padding(
                  padding: EdgeInsets.only(bottom: YkSpacing.xxs),
                  child: Row(
                    children: [
                      Icon(
                        c.estCorrect ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: c.estCorrect ? YkColors.success : YkColors.textTertiary(context),
                      ),
                      SizedBox(width: YkSpacing.xs),
                      Text(
                        c.texte,
                        style: YkTypography.bodySm(context).copyWith(
                          color: c.estCorrect ? YkColors.success : YkColors.textPrimary(context),
                          fontWeight: c.estCorrect ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (question.bonneReponse.isNotEmpty)
              Text(
                'Réponse : ${question.bonneReponse}',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.success, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }
}
