import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

/// Feuille de détail + actions Valider/Refuser — partagée par les onglets
/// Paiements et Retraits (P9.5) : même mécanique (détail en lecture,
/// valider en un geste, refuser exige un motif), seules les données
/// affichées diffèrent. Aucun appel réseau ici — délégué à [onValider]/
/// [onRefuser], fournis par l'écran appelant (convention déjà établie
/// pour tous les composants `overlays/`).
Future<void> showDemandeActionsSheet(
  BuildContext context, {
  required String titre,
  required List<MapEntry<String, String>> details,
  required Future<void> Function() onValider,
  required Future<void> Function(String motif) onRefuser,
}) {
  return YkSheet.show<void>(
    context: context,
    title: titre,
    bodyBuilder: (ctx) => _DemandeActionsBody(details: details, onValider: onValider, onRefuser: onRefuser),
  );
}

/// État local de la feuille — `ChangeNotifier` plutôt que `setState`
/// (interdit sous `lib/features/`, règle 7).
class _ActionsState extends ChangeNotifier {
  bool saisieMotif = false;
  bool enCours = false;
  String? erreurMotif;

  void setSaisieMotif(bool v) {
    saisieMotif = v;
    notifyListeners();
  }

  void setEnCours(bool v) {
    enCours = v;
    notifyListeners();
  }

  void demarrerConfirmationRefus() {
    enCours = true;
    erreurMotif = null;
    notifyListeners();
  }

  void setErreurMotif(String? v) {
    erreurMotif = v;
    notifyListeners();
  }
}

class _DemandeActionsBody extends StatefulWidget {
  const _DemandeActionsBody({required this.details, required this.onValider, required this.onRefuser});

  final List<MapEntry<String, String>> details;
  final Future<void> Function() onValider;
  final Future<void> Function(String motif) onRefuser;

  @override
  State<_DemandeActionsBody> createState() => _DemandeActionsBodyState();
}

class _DemandeActionsBodyState extends State<_DemandeActionsBody> {
  final TextEditingController _motifCtrl = TextEditingController();
  final _state = _ActionsState();

  @override
  void dispose() {
    _motifCtrl.dispose();
    _state.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    _state.setEnCours(true);
    try {
      await widget.onValider();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _state.setEnCours(false);
        YkSnack.error(context, 'Une erreur est survenue. Réessayez.');
      }
    }
  }

  Future<void> _confirmerRefus() async {
    final motif = _motifCtrl.text.trim();
    if (motif.isEmpty) {
      _state.setErreurMotif('Le motif est obligatoire.');
      return;
    }
    _state.demarrerConfirmationRefus();
    try {
      await widget.onRefuser(motif);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
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
            YkCard(
              variant: YkCardVariant.filled,
              child: Column(
                children: [
                  for (var i = 0; i < widget.details.length; i++) ...[
                    if (i > 0) SizedBox(height: YkSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.details[i].key,
                          style: YkTypography.label(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                        Flexible(
                          child: Text(
                            widget.details[i].value,
                            textAlign: TextAlign.end,
                            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: YkSpacing.md),
            if (!_state.saisieMotif) ...[
              YkButton(label: 'Valider', isLoading: _state.enCours, onPressed: _state.enCours ? null : _valider),
              SizedBox(height: YkSpacing.sm),
              YkButton(
                label: 'Refuser',
                variant: YkButtonVariant.destructive,
                onPressed: _state.enCours ? null : () => _state.setSaisieMotif(true),
              ),
            ] else ...[
              YkTextField(
                controller: _motifCtrl,
                label: 'Motif du refus',
                required: true,
                type: YkTextFieldType.multiline,
                errorText: _state.erreurMotif,
              ),
              SizedBox(height: YkSpacing.md),
              YkButton(
                label: 'Confirmer le refus',
                variant: YkButtonVariant.destructive,
                isLoading: _state.enCours,
                onPressed: _state.enCours ? null : _confirmerRefus,
              ),
              SizedBox(height: YkSpacing.sm),
              YkButton(
                label: 'Annuler',
                variant: YkButtonVariant.ghost,
                onPressed: _state.enCours ? null : () => _state.setSaisieMotif(false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
