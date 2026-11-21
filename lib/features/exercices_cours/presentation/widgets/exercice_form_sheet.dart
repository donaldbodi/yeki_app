import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/exercice_models.dart';

const _imageConstraint = YkFileConstraint(allowedExtensions: ['jpg', 'jpeg', 'png'], maxSizeBytes: 5 * 1024 * 1024);

const _typeItems = [
  YkDropdownItem(value: 'general', label: 'Général'),
  YkDropdownItem(value: 'module', label: 'Module'),
  YkDropdownItem(value: 'lecon', label: 'Leçon'),
  YkDropdownItem(value: 'epreuve', label: 'Épreuve (ensemble)'),
];

/// État du formulaire — `ChangeNotifier` plutôt que `setState` (interdit
/// sous `lib/features/`, règle 7 de `check_design_system.sh`).
class _ExerciceFormController extends ChangeNotifier {
  _ExerciceFormController(this.existant, this.modules)
    : titreCtrl = TextEditingController(text: existant?.titre ?? ''),
      enonce = existant?.enonce ?? '',
      typeExercice = existant?.typeExercice ?? 'general',
      moduleId = existant?.moduleId,
      leconId = existant?.leconId,
      etoiles = (existant?.etoiles ?? 1).toDouble(),
      duree = (existant?.dureeMinutes ?? 10).toDouble(),
      tentatives = (existant?.tentativesMax ?? 1).toDouble(),
      exercicesComposes = existant?.exercicesComposes.map((e) => e['id'] as int).toSet() ?? {};

  final ExerciceListItem? existant;
  final List<ModuleOption> modules;

  final TextEditingController titreCtrl;

  /// Rectification (demande explicite) : `enonce` + `enonce_image`
  /// (deux champs séparés) fusionnés en un unique champ riche (HTML),
  /// même mécanisme que `EnonceDevoir.contenu`/`YkRichEditor` — plus de
  /// champ image à part.
  String enonce;
  String typeExercice;
  int? moduleId;
  int? leconId;
  double etoiles;
  double duree;
  double tentatives;
  Set<int> exercicesComposes;
  bool envoi = false;

  void setEnonce(String v) => enonce = v;

  bool get estEpreuve => typeExercice == 'epreuve';

  List<LeconOption> get leconsDuModule {
    if (moduleId == null) return const [];
    for (final m in modules) {
      if (m.id == moduleId) return m.lecons;
    }
    return const [];
  }

  void setType(String? v) {
    typeExercice = v ?? 'general';
    if (typeExercice != 'module') moduleId = null;
    if (typeExercice != 'lecon') leconId = null;
    notifyListeners();
  }

  void setModule(int? v) {
    moduleId = v;
    notifyListeners();
  }

  void setModuleEtReinitialiserLecon(int? v) {
    moduleId = v;
    leconId = null;
    notifyListeners();
  }

  void setLecon(int? v) {
    leconId = v;
    notifyListeners();
  }

  void setExercicesComposes(Set<int> v) {
    exercicesComposes = v;
    notifyListeners();
  }

  void setEtoiles(int v) {
    etoiles = v.toDouble();
    notifyListeners();
  }

  void setDuree(double v) {
    duree = v;
    notifyListeners();
  }

  void setTentatives(double v) {
    tentatives = v;
    notifyListeners();
  }

  void setEnvoi(bool v) {
    envoi = v;
    notifyListeners();
  }

  @override
  void dispose() {
    titreCtrl.dispose();
    super.dispose();
  }
}

/// Formulaire UNIQUE de création/édition d'exercice — remplace les deux
/// sheets ~95 % identiques de l'ancien `exercices_cours.dart`
/// (`_showCreateExerciceSheet`/`_showEditExerciceSheet`), paramétré par
/// [existant] (`null` = création). La composition d'épreuve
/// (`est_epreuve`/`exercices_composes`) est conservée telle quelle
/// (déjà fonctionnelle, juste re-stylée — voir docs/ecarts/exercices_cours.md).
class ExerciceFormSheet extends StatefulWidget {
  const ExerciceFormSheet({
    super.key,
    this.existant,
    required this.modules,
    required this.exercicesDisponibles,
    required this.onSubmit,
  });

  final ExerciceListItem? existant;
  final List<ModuleOption> modules;

  /// Exercices du cours pouvant composer une épreuve (hors épreuves et
  /// hors l'exercice en cours d'édition).
  final List<ExerciceListItem> exercicesDisponibles;

  final Future<bool> Function({
    required String titre,
    required String enonce,
    required int etoiles,
    required int dureeMinutes,
    required int tentativesMax,
    required String typeExercice,
    int? moduleId,
    int? leconId,
    required bool estEpreuve,
    List<int>? exercicesComposes,
  })
  onSubmit;

  bool get estEdition => existant != null;

  @override
  State<ExerciceFormSheet> createState() => _ExerciceFormSheetState();
}

class _ExerciceFormSheetState extends State<ExerciceFormSheet> {
  late final _ExerciceFormController _controller = _ExerciceFormController(widget.existant, widget.modules);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> _uploadImage(YkPickedFile file) async {
    // Aucun endpoint de téléversement générique côté backend (même
    // limitation déjà documentée et acceptée pour `devoir_form_sheet.dart`/
    // `question_devoir_form.dart` — l'insertion d'image échoue proprement,
    // message déjà géré par le composant).
    throw UnsupportedError('Téléversement d\'image indisponible pour le moment.');
  }

  Future<void> _submit() async {
    if (_controller.titreCtrl.text.trim().isEmpty || _controller.enonce.trim().isEmpty) {
      YkSnack.error(context, 'Le titre et l\'énoncé sont requis.');
      return;
    }
    _controller.setEnvoi(true);
    final ok = await widget.onSubmit(
      titre: _controller.titreCtrl.text.trim(),
      enonce: _controller.enonce.trim(),
      etoiles: _controller.etoiles.round(),
      dureeMinutes: _controller.duree.round(),
      tentativesMax: _controller.tentatives.round(),
      typeExercice: _controller.typeExercice,
      moduleId: _controller.typeExercice == 'module' ? _controller.moduleId : null,
      leconId: _controller.typeExercice == 'lecon' ? _controller.leconId : null,
      estEpreuve: _controller.estEpreuve,
      exercicesComposes: _controller.estEpreuve ? _controller.exercicesComposes.toList() : null,
    );
    if (!mounted) return;
    _controller.setEnvoi(false);
    if (ok) {
      Navigator.of(context).pop();
      YkSnack.success(context, widget.estEdition ? 'Exercice modifié.' : 'Exercice créé.');
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
        YkDropdown<String>(
          label: "Type d'exercice",
          value: c.typeExercice,
          items: _typeItems,
          onChanged: c.setType,
        ),
        if (c.typeExercice == 'module' && widget.modules.isNotEmpty) ...[
          SizedBox(height: YkSpacing.sm),
          YkDropdown<int?>(
            label: 'Module',
            value: c.moduleId,
            items: [for (final m in widget.modules) YkDropdownItem(value: m.id, label: m.titre)],
            onChanged: c.setModule,
          ),
        ],
        if (c.typeExercice == 'lecon' && widget.modules.isNotEmpty) ...[
          SizedBox(height: YkSpacing.sm),
          YkDropdown<int?>(
            label: 'Module',
            value: c.moduleId,
            items: [for (final m in widget.modules) YkDropdownItem(value: m.id, label: m.titre)],
            onChanged: c.setModuleEtReinitialiserLecon,
          ),
          if (c.leconsDuModule.isNotEmpty) ...[
            SizedBox(height: YkSpacing.sm),
            YkDropdown<int?>(
              label: 'Leçon',
              value: c.leconId,
              items: [for (final l in c.leconsDuModule) YkDropdownItem(value: l.id, label: l.titre)],
              onChanged: c.setLecon,
            ),
          ],
        ],
        if (c.estEpreuve) ...[
          SizedBox(height: YkSpacing.sm),
          YkMultiSelect<int>(
            label: "Exercices composant l'épreuve",
            items: [
              for (final ex in widget.exercicesDisponibles)
                YkMultiSelectItem(value: ex.id, label: ex.titre),
            ],
            selectedValues: c.exercicesComposes,
            onChanged: c.setExercicesComposes,
          ),
        ],
        SizedBox(height: YkSpacing.sm),
        YkTextField(controller: c.titreCtrl, label: 'Titre', required: true),
        SizedBox(height: YkSpacing.sm),
        YkRichEditor(
          key: const ValueKey('enonce-exercice'),
          initialHtml: c.enonce,
          onChanged: c.setEnonce,
          onUploadImage: _uploadImage,
          imageConstraint: _imageConstraint,
          label: 'Énoncé',
        ),
        SizedBox(height: YkSpacing.md),
        YkRating(value: c.etoiles.round(), onChanged: c.setEtoiles),
        SizedBox(height: YkSpacing.md),
        YkStepper(label: 'Durée (min)', value: c.duree, min: 1, max: 180, step: 1, onChanged: c.setDuree),
        SizedBox(height: YkSpacing.sm),
        YkStepper(
          label: 'Tentatives max',
          value: c.tentatives,
          min: 1,
          max: 10,
          step: 1,
          onChanged: c.setTentatives,
        ),
        SizedBox(height: YkSpacing.lg),
        YkButton(
          label: widget.estEdition ? 'Enregistrer' : "Créer l'exercice",
          isLoading: c.envoi,
          onPressed: c.envoi ? null : _submit,
        ),
      ],
    );
  }
}
