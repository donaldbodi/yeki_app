import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/devoir_models.dart';

const _imageConstraint = YkFileConstraint(allowedExtensions: ['jpg', 'jpeg', 'png'], maxSizeBytes: 5 * 1024 * 1024);

/// État du formulaire — `ChangeNotifier` plutôt que `setState` (interdit
/// sous `lib/features/`, règle 7 de `check_design_system.sh`).
class _QuestionDevoirController extends ChangeNotifier {
  _QuestionDevoirController(QuestionDevoirItem? existant, bool autoriseQcm)
    : enonce = existant?.enonce ?? '',
      type = autoriseQcm ? (existant?.typeQuestion ?? 'qcm') : 'texte',
      points = existant?.points ?? 1.0,
      choixCtrl = existant != null && existant.estQcm
          ? existant.choix.map((c) => TextEditingController(text: c.texte)).toList()
          : [TextEditingController(), TextEditingController()],
      correctIndex = existant != null && existant.estQcm
          ? existant.choix.indexWhere((c) => c.estCorrect).clamp(0, 1 << 30)
          : 0,
      reponseAttendueCtrl = TextEditingController(text: existant?.reponseAttendue ?? ''),
      reponseExempleCtrl = TextEditingController(text: existant?.reponseExemple ?? '');

  String enonce;
  String type;
  double points;
  List<TextEditingController> choixCtrl;
  int correctIndex;
  final TextEditingController reponseAttendueCtrl;
  final TextEditingController reponseExempleCtrl;
  bool envoi = false;

  bool get estQcm => type == 'qcm';

  void setEnonce(String v) => enonce = v;

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
    for (final c in choixCtrl) {
      c.dispose();
    }
    reponseAttendueCtrl.dispose();
    reponseExempleCtrl.dispose();
    super.dispose();
  }
}

/// Formulaire ADAPTATIF de question (création ET modification, P7.4 —
/// l'ancien écran ne permettait que l'ajout et la suppression). Si le
/// devoir est en correction MANUELLE, le type QCM disparaît carrément
/// du sélecteur (pas juste désactivé) — le backend l'interdit déjà
/// (P7.3), ce formulaire évite à l'enseignant de buter sur un 400.
class QuestionDevoirForm extends StatefulWidget {
  const QuestionDevoirForm({super.key, this.existant, required this.typeCorrection, required this.onSubmit});

  final QuestionDevoirItem? existant;
  final String typeCorrection; // 'auto' | 'manuel'

  final Future<bool> Function({
    required String enonce,
    required String typeQuestion,
    required double points,
    String? reponseAttendue,
    String? reponseExemple,
    List<ChoixReponseItem>? choix,
  })
  onSubmit;

  bool get estEdition => existant != null;
  bool get autoriseQcm => typeCorrection != 'manuel';

  @override
  State<QuestionDevoirForm> createState() => _QuestionDevoirFormState();
}

class _QuestionDevoirFormState extends State<QuestionDevoirForm> {
  late final _QuestionDevoirController _controller = _QuestionDevoirController(
    widget.existant,
    widget.autoriseQcm,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> _uploadImage(YkPickedFile file) async {
    throw UnsupportedError('Téléversement d\'image indisponible pour le moment.');
  }

  Future<void> _submit() async {
    final c = _controller;
    if (c.enonce.trim().isEmpty) {
      YkSnack.error(context, "L'énoncé de la question est requis.");
      return;
    }

    List<ChoixReponseItem>? choix;
    String? reponseAttendue;
    if (c.estQcm) {
      if (c.choixCtrl.any((ctrl) => ctrl.text.trim().isEmpty)) {
        YkSnack.error(context, 'Remplissez tous les choix.');
        return;
      }
      choix = [
        for (var i = 0; i < c.choixCtrl.length; i++)
          ChoixReponseItem(id: 0, texte: c.choixCtrl[i].text.trim(), estCorrect: i == c.correctIndex),
      ];
    } else {
      reponseAttendue = c.reponseAttendueCtrl.text.trim();
      if (reponseAttendue.isEmpty) {
        YkSnack.error(context, 'La réponse attendue est requise.');
        return;
      }
    }

    c.setEnvoi(true);
    final ok = await widget.onSubmit(
      enonce: c.enonce,
      typeQuestion: c.type,
      points: c.points,
      reponseAttendue: reponseAttendue,
      reponseExemple: c.reponseExempleCtrl.text.trim(),
      choix: choix,
    );
    if (!mounted) return;
    c.setEnvoi(false);
    if (ok) {
      Navigator.of(context).pop();
      YkSnack.success(context, widget.estEdition ? 'Question modifiée.' : 'Question ajoutée.');
    } else {
      YkSnack.error(context, "Échec de l'enregistrement.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, _) => _buildForm(context));
  }

  Widget _buildForm(BuildContext context) {
    final c = _controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.autoriseQcm) ...[
          YkSegmented<String>(
            segments: const [
              YkSegment(value: 'qcm', label: 'QCM'),
              YkSegment(value: 'texte', label: 'Texte libre'),
            ],
            selected: c.type,
            onChanged: c.setType,
          ),
          SizedBox(height: YkSpacing.sm),
        ],
        YkRichEditor(
          key: const ValueKey('enonce-question'),
          initialHtml: c.enonce,
          onChanged: c.setEnonce,
          onUploadImage: _uploadImage,
          imageConstraint: _imageConstraint,
          label: 'Énoncé de la question',
          showEmoji: !widget.autoriseQcm,
        ),
        SizedBox(height: YkSpacing.sm),
        YkStepper(label: 'Points', value: c.points, min: 0.25, max: 10, step: 0.25, onChanged: c.setPoints),
        SizedBox(height: YkSpacing.md),
        if (c.estQcm) ...[
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
        ] else ...[
          YkTextField(controller: c.reponseAttendueCtrl, label: 'Réponse attendue', required: true),
          SizedBox(height: YkSpacing.sm),
          YkTextField(controller: c.reponseExempleCtrl, label: 'Réponse exemple (optionnelle)'),
        ],
        SizedBox(height: YkSpacing.lg),
        YkButton(
          label: widget.estEdition ? 'Enregistrer' : 'Ajouter la question',
          isLoading: c.envoi,
          onPressed: c.envoi ? null : _submit,
        ),
      ],
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
}
