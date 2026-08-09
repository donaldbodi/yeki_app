// lib/widgets/creer_cours_sheet.dart
//
// Refondu en P11.6 (rituel P5.0) : bascule vers `CoursRepository`/
// `DashboardRepository` (plus de `http`/`SharedPreferences` bruts) et les
// tokens/composants `Yk*`.
//
// Simplifié (demande explicite) : « Matière » (le titre du cours joue déjà
// ce rôle — confirmé non lu nulle part ailleurs), « Concours lié » (jamais
// lu nulle part) et « Image de couverture » (confirmé NO-OP côté serveur —
// `Cours` n'a aucun champ image, `CoursCreateSerializer` ignorait déjà ce
// champ silencieusement) retirés. Sélecteur d'icône corrigé (bug réel :
// `YkChip(variant: filter)` écoute `onSelected`, pas `onPressed` — le tap
// ne faisait donc rien) et migré vers `coursIcons` (`cours_icons.dart`),
// source unique désormais partagée avec `modifier_cours_sheet.dart` et
// `secondaire_dashboard_page.dart`.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/cours_repository.dart';
import 'package:yeki/repositories/dashboard_repository.dart';
import 'package:yeki/utils/color_utils.dart';
import 'package:yeki/utils/cours_icons.dart';

const List<String> _niveaux = [
  'Terminale', '1ère', '2nde', '3ème',
  'Licence 1', 'Licence 2', 'Licence 3',
  'Master 1', 'Master 2', 'Autre',
];

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

  String? _niveau;
  String _colorCode = '#008080';
  String _iconName = 'school';
  int? _enseignantPrincipalId;

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
        descriptionBrief: _descCtrl.text.trim(),
        enseignantPrincipalId: _enseignantPrincipalId,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      if (mounted) YkSnack.error(context, e.message);
    } catch (e) {
      // Root cause non certaine à 100% (règle 7) — filet de diagnostic.
      debugPrint('CreerCoursSheet._soumettre() — exception inattendue : ${e.runtimeType} : $e');
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
            YkTextField(controller: _descCtrl, label: 'Description brève', hint: 'Objectifs et contenu du cours', type: YkTextFieldType.multiline, maxLines: 3),

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
        for (final item in coursIcons)
          YkChip(
            label: item.label,
            avatar: Icon(item.icon, size: 16, color: _iconName == item.name ? Colors.white : couleur),
            variant: YkChipVariant.filter,
            selected: _iconName == item.name,
            // Bug corrigé : `YkChip(variant: filter)` route vers un
            // `FilterChip`, qui écoute `onSelected` — `onPressed` (utilisé
            // avant) n'est lu par aucune variante `filter`, le tap ne
            // faisait donc jamais rien.
            onSelected: (_) => setState(() => _iconName = item.name),
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
