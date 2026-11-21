import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/features/admin_general/data/admin_general_models.dart';

import '../admin_general_controller.dart';

const _typesEnseignant = [
  YkDropdownItem(value: 'enseignant', label: 'Enseignant'),
  YkDropdownItem(value: 'enseignant_principal', label: 'Enseignant Principal'),
  YkDropdownItem(value: 'enseignant_cadre', label: 'Enseignant Cadre'),
  YkDropdownItem(value: 'enseignant_admin', label: 'Enseignant Administrateur'),
  // Bug corrigé : absent d'ici alors que la recherche de cet onglet
  // (AdminGeneralSearchEnseignantsView) rend ces comptes trouvables —
  // `_state.type` valait 'service_client' sans item correspondant dans
  // ce dropdown pour un tel compte (valeur orpheline).
  YkDropdownItem(value: 'service_client', label: 'Service Client'),
];

Future<void> showModifierEnseignantSheet(BuildContext context, AdminGeneralController controller, EnseignantAdmin enseignant) {
  return YkSheet.show<void>(
    context: context,
    title: 'Modifier ${enseignant.nom}',
    // `outerContext` distinct du `context` du sheet lui-même — même motif
    // que `departement_form_sheet.dart` (`context` capturé vs `ctx` local) :
    // afficher le snackbar de succès APRÈS avoir fermé le sheet exige un
    // contexte qui reste monté, pas celui du widget qu'on vient de retirer
    // de l'arbre.
    bodyBuilder: (ctx) => _FormulaireEnseignant(outerContext: context, controller: controller, enseignant: enseignant),
  );
}

class _FormulaireEnseignant extends StatefulWidget {
  const _FormulaireEnseignant({required this.outerContext, required this.controller, required this.enseignant});

  final BuildContext outerContext;
  final AdminGeneralController controller;
  final EnseignantAdmin enseignant;

  @override
  State<_FormulaireEnseignant> createState() => _FormulaireEnseignantState();
}

/// État local — `ChangeNotifier` plutôt que `setState` (interdit sous
/// `lib/features/`, règle 7).
class _FormulaireState extends ChangeNotifier {
  _FormulaireState({required this.type, required this.actif});

  String type;
  bool actif;
  bool enCours = false;

  void setType(String v) {
    type = v;
    notifyListeners();
  }

  void setActif(bool v) {
    actif = v;
    notifyListeners();
  }

  void setEnCours(bool v) {
    enCours = v;
    notifyListeners();
  }
}

class _FormulaireEnseignantState extends State<_FormulaireEnseignant> {
  late final _state = _FormulaireState(type: widget.enseignant.userType, actif: widget.enseignant.isActive);

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (_state.type == widget.enseignant.userType && _state.actif == widget.enseignant.isActive) {
      Navigator.of(context).pop();
      return;
    }
    _state.setEnCours(true);
    try {
      await widget.controller.modifierEnseignant(widget.enseignant.id, userType: _state.type, isActive: _state.actif);
      if (mounted) {
        Navigator.of(context).pop();
        // Bug corrigé : aucune confirmation n'était affichée — la liste se
        // recharge avec le MÊME filtre "État" encore actif, donc un compte
        // qu'on vient d'activer (filtré sur "Non autorisé") disparaît
        // simplement de la liste au lieu d'apparaître coché "Autorisé",
        // donnant l'impression que la modification n'a pas fonctionné.
        // `widget.outerContext` (pas `context`, sur le point d'être retiré
        // de l'arbre par le pop ci-dessus).
        if (widget.outerContext.mounted) {
          YkSnack.success(widget.outerContext, 'Enseignant modifié avec succès.');
        }
      }
    } catch (e) {
      if (mounted) {
        _state.setEnCours(false);
        // Bug corrigé : le vrai motif backend (ex. "Aucune modification
        // spécifiée.") était systématiquement jeté au profit d'un message
        // générique — donnant l'impression d'un échec alors que le backend
        // avait déjà validé (ou refusé pour une raison précise). `ApiException
        // .fromEnvelope` sait déjà dériver ce message, y compris depuis le
        // format legacy `{"detail": "..."}` renvoyé par cette vue.
        final message = e is ApiException ? e.message : 'Une erreur est survenue. Réessayez.';
        YkSnack.error(context, message);
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
            Text(widget.enseignant.email, style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context))),
            SizedBox(height: YkSpacing.md),
            YkDropdown<String>(
              items: _typesEnseignant,
              value: _state.type,
              label: "Type d'enseignant",
              onChanged: (v) => _state.setType(v ?? _state.type),
            ),
            SizedBox(height: YkSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Compte actif', style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context))),
                      Text(
                        _state.actif ? "L'enseignant peut se connecter" : "L'enseignant ne peut pas se connecter",
                        style: YkTypography.caption(context).copyWith(color: YkColors.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
                Switch(value: _state.actif, onChanged: (v) => _state.setActif(v), activeColor: YkColors.accent(context)),
              ],
            ),
            SizedBox(height: YkSpacing.lg),
            YkButton(label: 'Enregistrer', isLoading: _state.enCours, onPressed: _state.enCours ? null : _valider),
          ],
        ),
      ),
    );
  }
}
