// lib/widgets/modifier_cours_sheet.dart
//
// Refondu en P11.6 (rituel P5.0) : bascule vers `CoursRepository` (plus
// de `http`/`SharedPreferences` bruts) et les tokens/composants `Yk*`.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/cours_repository.dart';
import 'package:yeki/utils/color_utils.dart';
import 'package:yeki/utils/cours_icons.dart';

class ModifierCoursSheet extends StatefulWidget {
  final Map cours;
  final VoidCallback onSuccess;

  const ModifierCoursSheet({super.key, required this.cours, required this.onSuccess});

  @override
  State<ModifierCoursSheet> createState() => _ModifierCoursSheetState();
}

class _ModifierCoursSheetState extends State<ModifierCoursSheet> {
  final _repo = CoursRepository();
  final _formKey = GlobalKey<FormState>();
  bool _envoi = false;

  late final _titreCtrl = TextEditingController(text: widget.cours['titre'] ?? '');
  late final _niveauCtrl = TextEditingController(text: widget.cours['niveau'] ?? '');
  late final _descCtrl = TextEditingController(text: widget.cours['description_brief'] ?? '');

  late String _iconeSelectionnee = widget.cours['icon_name'] ?? 'school';
  // Repli sur la 1ère couleur de `YkCourseColors.palette` (Azur), pas
  // '#008080' (hors palette backend — voir creer_cours_sheet.dart).
  late Color _couleurSelectionnee = couleurDepuisHex(widget.cours['color_code'] as String?, const Color(0xFF2E7CAD));

  @override
  void dispose() {
    _titreCtrl.dispose();
    _niveauCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await _repo.modifierCours(
        widget.cours['id'] as int,
        titre: _titreCtrl.text.trim(),
        niveau: _niveauCtrl.text.trim(),
        colorCode: YkColorPicker.hexOf(_couleurSelectionnee),
        iconName: _iconeSelectionnee,
        descriptionBrief: _descCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        YkSnack.success(context, 'Cours modifié avec succès !');
      }
    } on ApiException catch (e) {
      // Même filet que creer_cours_sheet.dart : le message générique du
      // backend masque le champ réellement en cause.
      final details = e.fields.isNotEmpty ? ' (${e.fields.keys.join(", ")})' : '';
      if (mounted) YkSnack.error(context, '${e.message}$details');
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: YkColors.border(context), borderRadius: BorderRadius.circular(YkRadius.full)))),
              SizedBox(height: YkSpacing.md),
              Text('Modifier le cours', style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context))),
              SizedBox(height: YkSpacing.lg),

              _apercu(context),
              SizedBox(height: YkSpacing.lg),

              YkTextField(controller: _titreCtrl, label: 'Titre du cours *', hint: 'Ex : Mathématiques Terminale', validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null),
              SizedBox(height: YkSpacing.sm),
              YkTextField(controller: _niveauCtrl, label: 'Niveau *', hint: 'Ex : Terminale, Licence 1…', validator: (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null),
              SizedBox(height: YkSpacing.sm),
              YkTextField(controller: _descCtrl, label: 'Description courte', hint: 'Description brève du cours', type: YkTextFieldType.multiline, maxLines: 2),

              SizedBox(height: YkSpacing.lg),
              Text('Couleur du cours', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
              SizedBox(height: YkSpacing.sm),
              YkColorPicker(selectedHex: YkColorPicker.hexOf(_couleurSelectionnee), onChanged: (hex) => setState(() => _couleurSelectionnee = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)))),

              SizedBox(height: YkSpacing.lg),
              Text('Icône du cours', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
              SizedBox(height: YkSpacing.sm),
              _iconePicker(context),

              SizedBox(height: YkSpacing.lg),
              YkButton(label: 'Enregistrer les modifications', isLoading: _envoi, onPressed: _envoi ? null : _sauvegarder),
            ],
          ),
        ),
      ),
    );
  }

  Widget _apercu(BuildContext context) {
    final icone = iconePourNom(_iconeSelectionnee);
    return YkCard(
      accentColor: _couleurSelectionnee,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(YkSpacing.sm),
            decoration: BoxDecoration(color: _couleurSelectionnee.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(YkRadius.md)),
            child: Icon(icone, color: _couleurSelectionnee, size: 26),
          ),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titreCtrl.text.isEmpty ? 'Titre du cours' : _titreCtrl.text, style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                if (_niveauCtrl.text.isNotEmpty) Text(_niveauCtrl.text, style: YkTypography.bodySm(context).copyWith(color: _couleurSelectionnee)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconePicker(BuildContext context) {
    return Wrap(
      spacing: YkSpacing.xs,
      runSpacing: YkSpacing.xs,
      children: [
        for (final item in coursIcons)
          GestureDetector(
            onTap: () => setState(() => _iconeSelectionnee = item.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _iconeSelectionnee == item.name ? _couleurSelectionnee : _couleurSelectionnee.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(YkRadius.md),
                border: _iconeSelectionnee == item.name ? null : Border.all(color: _couleurSelectionnee.withValues(alpha: 0.2)),
              ),
              child: Icon(item.icon, color: _iconeSelectionnee == item.name ? Colors.white : _couleurSelectionnee, size: 22),
            ),
          ),
      ],
    );
  }
}
