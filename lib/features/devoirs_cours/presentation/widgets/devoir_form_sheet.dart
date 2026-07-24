import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/devoir_models.dart';

const _imageConstraint = YkFileConstraint(allowedExtensions: ['jpg', 'jpeg', 'png'], maxSizeBytes: 5 * 1024 * 1024);
const _pdfConstraint = YkFileConstraint(allowedExtensions: ['pdf'], maxSizeBytes: 10 * 1024 * 1024);

/// État du formulaire — `ChangeNotifier` plutôt que `setState` (interdit
/// sous `lib/features/`, règle 7 de `check_design_system.sh`).
class _DevoirFormController extends ChangeNotifier {
  _DevoirFormController(this.existant)
    : titreCtrl = TextEditingController(text: existant?.titre ?? ''),
      descriptionCtrl = TextEditingController(text: existant?.description ?? ''),
      dateDebut = existant?.dateDebut ?? DateTime.now(),
      dateLimite = existant?.dateLimite ?? DateTime.now().add(const Duration(days: 7)),
      dureeMinutes = (existant?.dureeMinutes ?? 60).toDouble(),
      noteSur = existant?.noteSur ?? 20,
      coefficient = existant?.coefficient ?? 1.0,
      tentativesMax = (existant?.tentativesMax ?? 1).toDouble(),
      typeCorrection = existant?.typeCorrection ?? 'auto';

  final DevoirListItem? existant;
  final TextEditingController titreCtrl;
  final TextEditingController descriptionCtrl;
  String enonce = '';
  DateTime dateDebut;
  DateTime dateLimite;
  double dureeMinutes;
  double noteSur;
  double coefficient;
  double tentativesMax;
  String typeCorrection;
  YkPickedFile? fichierCorrection;
  bool envoi = false;

  bool get estManuel => typeCorrection == 'manuel';

  void setEnonce(String v) => enonce = v;

  void setDateDebut(DateTime v) {
    dateDebut = v;
    notifyListeners();
  }

  void setDateLimite(DateTime v) {
    dateLimite = v;
    notifyListeners();
  }

  void setDureeMinutes(double v) {
    dureeMinutes = v;
    notifyListeners();
  }

  void setNoteSur(double v) {
    noteSur = v;
    notifyListeners();
  }

  void setCoefficient(double v) {
    coefficient = v;
    notifyListeners();
  }

  void setTentativesMax(double v) {
    tentativesMax = v;
    notifyListeners();
  }

  void setTypeCorrection(String v) {
    typeCorrection = v;
    notifyListeners();
  }

  void setFichierCorrection(YkPickedFile? f) {
    fichierCorrection = f;
    notifyListeners();
  }

  void setEnvoi(bool v) {
    envoi = v;
    notifyListeners();
  }

  @override
  void dispose() {
    titreCtrl.dispose();
    descriptionCtrl.dispose();
    super.dispose();
  }
}

/// Formulaire UNIQUE de création/édition d'un devoir.
///
/// En ÉDITION, le champ « énoncé » n'apparaît PAS : `Devoir.enonce`
/// (legacy) et `EnonceDevoir(ordre=1).contenu` sont deux emplacements
/// distincts en base — `ModifierDevoirView` ne met à jour QUE le
/// premier, jamais le second. Exposer ce champ ici créerait un
/// désaccord silencieux avec l'énoncé n°1 réellement affiché sur
/// l'écran de composition. Modifier l'énoncé n°1, comme tout autre
/// énoncé, passe exclusivement par `EnonceSection` (P7.1).
class DevoirFormSheet extends StatefulWidget {
  const DevoirFormSheet({super.key, this.existant, required this.onSubmit});

  final DevoirListItem? existant;

  final Future<bool> Function({
    required String titre,
    required String description,
    String? enonce,
    required DateTime dateDebut,
    required DateTime dateLimite,
    required int dureeMinutes,
    required double noteSur,
    required double coefficient,
    required int tentativesMax,
    required String typeCorrection,
    YkPickedFile? fichierCorrection,
  })
  onSubmit;

  bool get estEdition => existant != null;

  @override
  State<DevoirFormSheet> createState() => _DevoirFormSheetState();
}

class _DevoirFormSheetState extends State<DevoirFormSheet> {
  late final _DevoirFormController _controller = _DevoirFormController(widget.existant);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final c = _controller;
    if (c.titreCtrl.text.trim().isEmpty) {
      YkSnack.error(context, 'Le titre est requis.');
      return;
    }
    if (!widget.estEdition && c.enonce.trim().isEmpty) {
      YkSnack.error(context, "L'énoncé est requis.");
      return;
    }
    if (c.estManuel && !widget.estEdition && c.fichierCorrection == null) {
      YkSnack.error(context, 'Un fichier PDF de correction est requis pour la correction manuelle.');
      return;
    }
    if (c.dateLimite.isBefore(c.dateDebut)) {
      YkSnack.error(context, 'La date limite doit être postérieure à la date de début.');
      return;
    }

    c.setEnvoi(true);
    final ok = await widget.onSubmit(
      titre: c.titreCtrl.text.trim(),
      description: c.descriptionCtrl.text.trim(),
      enonce: widget.estEdition ? null : c.enonce,
      dateDebut: c.dateDebut,
      dateLimite: c.dateLimite,
      dureeMinutes: c.dureeMinutes.round(),
      noteSur: c.noteSur,
      coefficient: c.coefficient,
      tentativesMax: c.tentativesMax.round(),
      typeCorrection: c.typeCorrection,
      fichierCorrection: c.fichierCorrection,
    );
    if (!mounted) return;
    c.setEnvoi(false);
    if (ok) {
      Navigator.of(context).pop();
      YkSnack.success(context, widget.estEdition ? 'Devoir modifié.' : 'Devoir créé.');
    } else {
      YkSnack.error(context, "Échec de l'enregistrement.");
    }
  }

  Future<String> _uploadImageEnonce(YkPickedFile file) async {
    // Aucun endpoint de téléversement générique côté backend (P4.5,
    // constat déjà documenté dans YkRichEditor) — l'insertion d'image
    // échoue proprement (message déjà géré par le composant).
    throw UnsupportedError('Téléversement d\'image indisponible pour le moment.');
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
        YkTextField(controller: c.titreCtrl, label: 'Titre', required: true),
        SizedBox(height: YkSpacing.sm),
        YkTextField(
          controller: c.descriptionCtrl,
          type: YkTextFieldType.multiline,
          maxLines: 2,
          label: 'Description (optionnelle)',
        ),
        if (!widget.estEdition) ...[
          SizedBox(height: YkSpacing.sm),
          YkRichEditor(
            key: const ValueKey('enonce-principal'),
            initialHtml: c.enonce,
            onChanged: c.setEnonce,
            onUploadImage: _uploadImageEnonce,
            imageConstraint: _imageConstraint,
            label: 'Énoncé',
            showEmoji: c.estManuel,
          ),
        ],
        SizedBox(height: YkSpacing.md),
        YkDateTimePicker(
          mode: YkDateTimePickerMode.dateTime,
          label: 'Date de début',
          value: c.dateDebut,
          onChanged: c.setDateDebut,
        ),
        SizedBox(height: YkSpacing.sm),
        YkDateTimePicker(
          mode: YkDateTimePickerMode.dateTime,
          label: 'Date limite',
          value: c.dateLimite,
          onChanged: c.setDateLimite,
        ),
        SizedBox(height: YkSpacing.md),
        YkStepper(
          label: 'Durée (min)',
          value: c.dureeMinutes,
          min: 5,
          max: 240,
          step: 5,
          onChanged: c.setDureeMinutes,
        ),
        SizedBox(height: YkSpacing.sm),
        YkStepper(label: 'Note sur', value: c.noteSur, min: 5, max: 40, step: 0.5, onChanged: c.setNoteSur),
        SizedBox(height: YkSpacing.sm),
        YkStepper(
          label: 'Coefficient',
          value: c.coefficient,
          min: 0.5,
          max: 5,
          step: 0.5,
          onChanged: c.setCoefficient,
        ),
        SizedBox(height: YkSpacing.sm),
        YkStepper(
          label: 'Sorties autorisées avant soumission auto',
          value: c.tentativesMax,
          min: 1,
          max: 10,
          step: 1,
          onChanged: c.setTentativesMax,
        ),
        SizedBox(height: YkSpacing.md),
        Text(
          'Type de correction',
          style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
        ),
        SizedBox(height: YkSpacing.xs),
        YkSegmented<String>(
          segments: const [
            YkSegment(value: 'auto', label: 'Automatique'),
            YkSegment(value: 'manuel', label: 'Manuelle'),
          ],
          selected: c.typeCorrection,
          onChanged: c.setTypeCorrection,
        ),
        if (c.estManuel) ...[
          SizedBox(height: YkSpacing.sm),
          YkFileUpload(
            label: 'Fichier PDF de correction${widget.estEdition ? '' : ' (obligatoire)'}',
            constraint: _pdfConstraint,
            picked: c.fichierCorrection,
            onChanged: c.setFichierCorrection,
          ),
          if (widget.estEdition && widget.existant?.fichierCorrectionUrl != null && c.fichierCorrection == null)
            Padding(
              padding: EdgeInsets.only(top: YkSpacing.xxs),
              child: Text(
                'Un fichier est déjà en place — sélectionnez-en un pour le remplacer.',
                style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
              ),
            ),
        ],
        SizedBox(height: YkSpacing.lg),
        YkButton(
          label: widget.estEdition ? 'Enregistrer' : 'Créer le devoir',
          isLoading: c.envoi,
          onPressed: c.envoi ? null : _submit,
        ),
      ],
    );
  }
}
