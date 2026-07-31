import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/features/admin_general/data/admin_general_models.dart';

import '../admin_general_controller.dart';

const _typesParcours = [
  YkDropdownItem(value: 'cursus', label: 'Cursus scolaire / universitaire'),
  YkDropdownItem(value: 'prepa', label: 'Prépa Concours'),
  YkDropdownItem(value: 'formation', label: 'Formations professionnelles'),
  YkDropdownItem(value: 'autre', label: 'Autre'),
];

Future<void> showCreerParcoursSheet(BuildContext context, AdminGeneralController controller) {
  return YkSheet.show<void>(
    context: context,
    title: 'Créer un parcours',
    bodyBuilder: (ctx) => _FormulaireParcours(
      onValider: (nom, description, type) => controller.creerParcours(nom: nom, description: description, typeParcours: type),
    ),
  );
}

Future<void> showModifierParcoursSheet(BuildContext context, AdminGeneralController controller, ParcoursAdmin parcours) {
  return YkSheet.show<void>(
    context: context,
    title: 'Modifier le parcours',
    bodyBuilder: (ctx) => _FormulaireParcours(
      nom: parcours.nom,
      typeParcours: parcours.typeParcours,
      onValider: (nom, description, type) =>
          controller.modifierParcours(parcours.id, nom: nom, description: description, typeParcours: type),
    ),
  );
}

Future<void> showChangerAdminSheet(BuildContext context, AdminGeneralController controller, ParcoursAdmin parcours) {
  return YkSheet.show<void>(
    context: context,
    title: parcours.enseignantAdmin == null ? 'Nommer un administrateur' : "Changer l'administrateur",
    bodyBuilder: (ctx) => _ChangerAdminBody(controller: controller, parcours: parcours),
  );
}

class _FormulaireParcours extends StatefulWidget {
  const _FormulaireParcours({this.nom, this.typeParcours, required this.onValider});

  final String? nom;
  final String? typeParcours;
  final Future<void> Function(String nom, String description, String typeParcours) onValider;

  @override
  State<_FormulaireParcours> createState() => _FormulaireParcoursWidgetState();
}

/// État local des feuilles de ce fichier — `ChangeNotifier` plutôt que
/// `setState` (interdit sous `lib/features/`, règle 7).
class _FormulaireParcoursState extends ChangeNotifier {
  _FormulaireParcoursState({required this.type});

  String type;
  bool enCours = false;

  void setType(String v) {
    type = v;
    notifyListeners();
  }

  void setEnCours(bool v) {
    enCours = v;
    notifyListeners();
  }
}

class _FormulaireParcoursWidgetState extends State<_FormulaireParcours> {
  late final TextEditingController _nomCtrl = TextEditingController(text: widget.nom ?? '');
  final TextEditingController _descCtrl = TextEditingController();
  late final _state = _FormulaireParcoursState(type: widget.typeParcours ?? 'cursus');

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _state.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (_nomCtrl.text.trim().isEmpty) {
      YkSnack.warning(context, 'Le nom est obligatoire.');
      return;
    }
    _state.setEnCours(true);
    try {
      await widget.onValider(_nomCtrl.text.trim(), _descCtrl.text.trim(), _state.type);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        _state.setEnCours(false);
        YkSnack.error(context, 'Une erreur est survenue. Réessayez.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) => Padding(
        padding: EdgeInsets.all(YkSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            YkTextField(controller: _nomCtrl, label: 'Nom du parcours', required: true),
            SizedBox(height: YkSpacing.sm),
            YkTextField(controller: _descCtrl, label: 'Description', type: YkTextFieldType.multiline),
            SizedBox(height: YkSpacing.md),
            YkDropdown<String>(
              items: _typesParcours,
              value: _state.type,
              label: 'Type de parcours',
              onChanged: (v) => _state.setType(v ?? _state.type),
            ),
            SizedBox(height: YkSpacing.lg),
            YkButton(label: 'Enregistrer', isLoading: _state.enCours, onPressed: _state.enCours ? null : _valider),
          ],
        ),
      ),
    );
  }
}

class _ChangerAdminBody extends StatefulWidget {
  const _ChangerAdminBody({required this.controller, required this.parcours});

  final AdminGeneralController controller;
  final ParcoursAdmin parcours;

  @override
  State<_ChangerAdminBody> createState() => _ChangerAdminBodyState();
}

class _ChangerAdminState extends ChangeNotifier {
  int? selected;
  bool enCours = false;

  void setSelected(int? v) {
    selected = v;
    notifyListeners();
  }

  void setEnCours(bool v) {
    enCours = v;
    notifyListeners();
  }
}

class _ChangerAdminBodyState extends State<_ChangerAdminBody> {
  late final Future<List<AdminEnseignantRef>> _future = widget.controller.chargerEnseignantsAdmins();
  final _state = _ChangerAdminState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _confirmer() async {
    if (_state.selected == null) return;
    _state.setEnCours(true);
    try {
      await widget.controller.nommerAdminParcours(widget.parcours.id, _state.selected!);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        _state.setEnCours(false);
        YkSnack.error(context, 'Une erreur est survenue. Réessayez.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) => Padding(
        padding: EdgeInsets.all(YkSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Parcours : ${widget.parcours.nom}',
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            SizedBox(height: YkSpacing.md),
            FutureBuilder<List<AdminEnseignantRef>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const YkSkeleton.list(itemCount: 3);
                }
                final candidats = snapshot.data ?? const [];
                if (candidats.isEmpty) {
                  return const YkEmptyState(
                    title: 'Aucun enseignant administrateur',
                    message: "Aucun compte avec le rôle « enseignant_admin » n'est actif.",
                    icon: Icons.admin_panel_settings_outlined,
                  );
                }
                _state.selected ??= widget.parcours.enseignantAdmin?.id;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in candidats)
                        RadioListTile<int>(
                          value: c.id,
                          groupValue: _state.selected,
                          title: Text(c.nom, style: TextStyle(color: YkColors.textPrimary(context))),
                          subtitle: c.email != null
                              ? Text(c.email!, style: TextStyle(color: YkColors.textSecondary(context)))
                              : null,
                          onChanged: (v) => _state.setSelected(v),
                        ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: YkSpacing.md),
            YkButton(
              label: 'Confirmer',
              isLoading: _state.enCours,
              onPressed: _state.enCours || _state.selected == null ? null : _confirmer,
            ),
          ],
        ),
      ),
    );
  }
}
