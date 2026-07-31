// lib/widgets/creer_cours_sheet.dart
//
// Refondu en P11.6 (rituel P5.0) : bascule vers `CoursRepository`/
// `DashboardRepository` (plus de `http`/`SharedPreferences` bruts) et les
// tokens/composants `Yk*` (`YkFileUpload` remplace le sélecteur d'image
// fait main).

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/cours_repository.dart';
import 'package:yeki/repositories/dashboard_repository.dart';
import 'package:yeki/utils/color_utils.dart';

const List<String> _niveaux = [
  'Terminale', '1ère', '2nde', '3ème',
  'Licence 1', 'Licence 2', 'Licence 3',
  'Master 1', 'Master 2', 'Autre',
];

const List<String> _matieres = [
  'Mathématiques', 'Physique', 'Chimie', 'SVT',
  'Informatique', 'Français', 'Anglais',
  'Histoire-Géo', 'Philosophie', 'Économie', 'Autre',
];

const List<Map<String, dynamic>> _icones = [
  {'name': 'school', 'icon': Icons.school, 'label': 'École'},
  {'name': 'book', 'icon': Icons.book, 'label': 'Livre'},
  {'name': 'calculate', 'icon': Icons.calculate, 'label': 'Maths'},
  {'name': 'science', 'icon': Icons.science, 'label': 'Sciences'},
  {'name': 'language', 'icon': Icons.language, 'label': 'Langue'},
  {'name': 'computer', 'icon': Icons.computer, 'label': 'Info'},
  {'name': 'history_edu', 'icon': Icons.history_edu, 'label': 'Histoire'},
  {'name': 'psychology', 'icon': Icons.psychology, 'label': 'Philo'},
  {'name': 'bar_chart', 'icon': Icons.bar_chart, 'label': 'Stats'},
  {'name': 'biotech', 'icon': Icons.biotech, 'label': 'Bio'},
  {'name': 'music_note', 'icon': Icons.music_note, 'label': 'Musique'},
  {'name': 'sports_soccer', 'icon': Icons.sports_soccer, 'label': 'Sport'},
  {'name': 'palette', 'icon': Icons.palette, 'label': 'Art'},
  {'name': 'engineering', 'icon': Icons.engineering, 'label': 'Ingé'},
  {'name': 'medical_services', 'icon': Icons.medical_services, 'label': 'Médecine'},
];

const _imageConstraint = YkFileConstraint(allowedExtensions: ['jpg', 'jpeg', 'png'], maxSizeBytes: 5 * 1024 * 1024);

class CreerCoursSheet extends StatefulWidget {
  final int departementId;
  final String departementNom;
  final VoidCallback onSuccess;

  const CreerCoursSheet({super.key, required this.departementId, required this.departementNom, required this.onSuccess});

  @override
  State<CreerCoursSheet> createState() => _CreerCoursSheetState();
}

class _CreerCoursSheetState extends State<CreerCoursSheet> {
  final _coursRepo = CoursRepository();
  final _dashboardRepo = DashboardRepository();

  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _concoursCtrl = TextEditingController();

  String? _niveau;
  String? _matiere;
  String _colorCode = '#008080';
  String _iconName = 'school';
  int? _enseignantPrincipalId;
  YkPickedFile? _image;

  bool _envoi = false;
  List<Map<String, dynamic>> _enseignants = [];
  bool _chargementEP = true;

  @override
  void initState() {
    super.initState();
    _chargerEnseignants();
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _concoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerEnseignants() async {
    try {
      final enseignants = await _dashboardRepo.enseignantsListe('principal');
      if (mounted) setState(() => _enseignants = enseignants);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargementEP = false);
    }
  }

  Future<void> _soumettre() async {
    if (_titreCtrl.text.trim().isEmpty) {
      YkSnack.error(context, 'Le titre est obligatoire.');
      return;
    }
    if (_niveau == null) {
      YkSnack.error(context, 'Le niveau est obligatoire.');
      return;
    }
    setState(() => _envoi = true);
    try {
      await _coursRepo.creerCours(
        departementId: widget.departementId,
        titre: _titreCtrl.text.trim(),
        niveau: _niveau!,
        colorCode: _colorCode,
        iconName: _iconName,
        matiere: _matiere,
        concours: _concoursCtrl.text.trim(),
        descriptionBrief: _descCtrl.text.trim(),
        enseignantPrincipalId: _enseignantPrincipalId,
        image: _image,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (_) {
      if (mounted) YkSnack.error(context, 'Erreur réseau.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: YkColors.surface(context), borderRadius: BorderRadius.vertical(top: Radius.circular(YkRadius.xl))),
      padding: EdgeInsets.only(left: YkSpacing.lg, right: YkSpacing.lg, top: YkSpacing.md, bottom: MediaQuery.of(context).viewInsets.bottom + YkSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: YkColors.border(context), borderRadius: BorderRadius.circular(YkRadius.full)))),
            SizedBox(height: YkSpacing.md),
            Text('Créer un cours', style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.xs),
            YkBadge(variant: YkBadgeVariant.label, label: 'Département : ${widget.departementNom}', color: YkColors.accent(context)),
            SizedBox(height: YkSpacing.lg),

            YkTextField(controller: _titreCtrl, label: 'Titre du cours *', hint: 'Ex : Algèbre Linéaire S1'),
            SizedBox(height: YkSpacing.sm),
            YkDropdown<String>(
              label: 'Niveau *',
              value: _niveau,
              items: [for (final n in _niveaux) YkDropdownItem(value: n, label: n)],
              onChanged: (v) => setState(() => _niveau = v),
            ),
            SizedBox(height: YkSpacing.sm),
            YkDropdown<String>(
              label: 'Matière',
              value: _matiere,
              items: [for (final m in _matieres) YkDropdownItem(value: m, label: m)],
              onChanged: (v) => setState(() => _matiere = v),
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(controller: _descCtrl, label: 'Description brève', hint: 'Objectifs et contenu du cours', type: YkTextFieldType.multiline, maxLines: 3),
            SizedBox(height: YkSpacing.sm),
            YkTextField(controller: _concoursCtrl, label: 'Concours lié (optionnel)', hint: 'Ex : BEPC, BAC, ENS…'),

            SizedBox(height: YkSpacing.lg),
            Text('Apparence', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            YkColorPicker(selectedHex: _colorCode, onChanged: (hex) => setState(() => _colorCode = hex)),
            SizedBox(height: YkSpacing.sm),
            _iconePicker(context),

            SizedBox(height: YkSpacing.lg),
            Text('Enseignant principal', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            _selecteurEP(context),

            SizedBox(height: YkSpacing.lg),
            Text('Image de couverture', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            YkFileUpload(constraint: _imageConstraint, picked: _image, onChanged: (f) => setState(() => _image = f)),

            SizedBox(height: YkSpacing.lg),
            YkButton(label: 'Créer le cours', isLoading: _envoi, onPressed: _envoi ? null : _soumettre),
          ],
        ),
      ),
    );
  }

  Widget _iconePicker(BuildContext context) {
    final couleur = couleurDepuisHex(_colorCode, YkColors.accent(context));
    return Wrap(
      spacing: YkSpacing.xs,
      runSpacing: YkSpacing.xs,
      children: [
        for (final item in _icones)
          YkChip(
            label: item['label'] as String,
            avatar: Icon(item['icon'] as IconData, size: 16, color: _iconName == item['name'] ? Colors.white : couleur),
            variant: YkChipVariant.filter,
            selected: _iconName == item['name'],
            onPressed: () => setState(() => _iconName = item['name'] as String),
          ),
      ],
    );
  }

  Widget _selecteurEP(BuildContext context) {
    if (_chargementEP) {
      return Center(child: YkProgress(shape: YkProgressShape.circular));
    }
    if (_enseignants.isEmpty) {
      return YkEmptyState(icon: Icons.info_outline_rounded, title: 'Aucun enseignant principal disponible', message: '');
    }
    return YkDropdown<int?>(
      label: 'Enseignant principal (optionnel)',
      value: _enseignantPrincipalId,
      items: [
        const YkDropdownItem(value: null, label: 'Aucun pour l\'instant'),
        for (final e in _enseignants) YkDropdownItem(value: e['id'] as int, label: e['nom'] ?? e['username'] ?? ''),
      ],
      onChanged: (v) => setState(() => _enseignantPrincipalId = v),
    );
  }
}
