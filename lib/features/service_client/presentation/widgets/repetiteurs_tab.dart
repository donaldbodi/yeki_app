import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/repetiteur_models.dart';

import '../service_client_controller.dart';

/// Onglet « Répétiteurs » (P9.5) — basculer `is_repetiteur`, ajouter/
/// retirer d'un cours, éditer ville et tarif.
///
/// Simplification actée (pas de question bloquante — décision
/// d'implémentation, règle 4) : « ajouter à un cours » demande l'ID du
/// cours directement (champ numérique), plutôt qu'un sélecteur de
/// cours/matière recherché — aucun endpoint de liste de cours n'existe
/// aujourd'hui côté `FormationRepository` (seulement parcours/départements),
/// et construire un sélecteur de recherche complet sort du périmètre de ce
/// ticket. Le Service Client doit connaître l'ID du cours (visible depuis
/// l'écran Administration générale).
class RepetiteursTab extends StatelessWidget {
  const RepetiteursTab({super.key, required this.controller});

  final ServiceClientController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.chargementRepetiteurs) {
      return Padding(padding: EdgeInsets.all(YkSpacing.md), child: const YkSkeleton.list(itemCount: 4));
    }
    if (controller.enErreurRepetiteurs) {
      return YkErrorState(
        message: 'Impossible de charger les répétiteurs.',
        cause: 'Vérifiez votre connexion internet.',
        onRetry: controller.chargerRepetiteurs,
      );
    }
    if (controller.candidats.isEmpty) {
      return const YkEmptyState(
        title: 'Aucun enseignant trouvé',
        message: 'Aucun enseignant principal ou secondaire à gérer pour le moment.',
        icon: Icons.support_agent_outlined,
      );
    }

    return ListView(
      padding: EdgeInsets.all(YkSpacing.md),
      children: [
        for (final candidat in controller.candidats) ...[
          _CandidatCard(controller: controller, candidat: candidat),
          SizedBox(height: YkSpacing.sm),
        ],
      ],
    );
  }
}

class _CandidatCard extends StatelessWidget {
  const _CandidatCard({required this.controller, required this.candidat});

  final ServiceClientController controller;
  final RepetiteurCandidat candidat;

  Future<void> _ouvrirAjoutFiche(BuildContext context) {
    return YkSheet.show<void>(
      context: context,
      title: 'Ajouter à un cours',
      bodyBuilder: (ctx) => _FormulaireFiche(
        onValider: (coursId, ville, telephone, tarif) => controller.creerFiche(
          enseignantId: candidat.id,
          coursId: coursId,
          ville: ville,
          telephone: telephone,
          tarifMensuel: tarif,
        ),
      ),
    );
  }

  Future<void> _ouvrirEditionFiche(BuildContext context, RepetiteurFiche fiche) {
    return YkSheet.show<void>(
      context: context,
      title: 'Éditer la fiche',
      bodyBuilder: (ctx) => _FormulaireFiche(
        ville: fiche.ville,
        telephone: fiche.telephone,
        tarifMensuel: fiche.tarifMensuel,
        disponible: fiche.disponible,
        onValider: (_, ville, telephone, tarif) =>
            controller.editerFiche(fiche.id, ville: ville, telephone: telephone, tarifMensuel: tarif),
        onValiderAvecDisponibilite: (ville, telephone, tarif, disponible) => controller.editerFiche(
          fiche.id,
          ville: ville,
          telephone: telephone,
          tarifMensuel: tarif,
          disponible: disponible,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return YkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidat.nom,
                      style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
                    ),
                    Text(
                      '@${candidat.username}',
                      style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: candidat.isRepetiteur,
                onChanged: (v) => controller.toggleRepetiteur(candidat.id, v),
                activeColor: YkColors.accent(context),
              ),
            ],
          ),
          if (candidat.isRepetiteur) ...[
            SizedBox(height: YkSpacing.sm),
            for (final fiche in candidat.fiches) ...[
              InkWell(
                onTap: () => _ouvrirEditionFiche(context, fiche),
                borderRadius: BorderRadius.circular(YkRadius.sm),
                child: Container(
                  padding: EdgeInsets.all(YkSpacing.sm),
                  margin: EdgeInsets.only(bottom: YkSpacing.xs),
                  decoration: BoxDecoration(
                    color: YkColors.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(YkRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${fiche.coursTitre} (${fiche.matiere})',
                              style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context)),
                            ),
                            Text(
                              '${fiche.ville} — ${fiche.tarifMensuel} FCFA/mois'
                              '${fiche.disponible ? '' : ' — indisponible'}',
                              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                            ),
                          ],
                        ),
                      ),
                      YkIconButton(
                        icon: Icons.delete_outline,
                        label: 'Retirer du cours',
                        variant: YkIconButtonVariant.ghost,
                        onPressed: () => controller.retirerFiche(fiche.id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            YkButton(
              label: 'Ajouter à un cours',
              variant: YkButtonVariant.secondary,
              icon: Icons.add,
              onPressed: () => _ouvrirAjoutFiche(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormulaireFiche extends StatefulWidget {
  const _FormulaireFiche({
    this.ville,
    this.telephone,
    this.tarifMensuel,
    this.disponible,
    required this.onValider,
    this.onValiderAvecDisponibilite,
  });

  final String? ville;
  final String? telephone;
  final int? tarifMensuel;
  final bool? disponible;
  final Future<void> Function(int coursId, String ville, String telephone, int? tarif) onValider;
  final Future<void> Function(String ville, String telephone, int? tarif, bool disponible)?
  onValiderAvecDisponibilite;

  @override
  State<_FormulaireFiche> createState() => _FormulaireFicheState();
}

/// État local du formulaire — `ChangeNotifier` plutôt que `setState`
/// (interdit sous `lib/features/`, règle 7).
class _FormulaireState extends ChangeNotifier {
  _FormulaireState({required this.disponible});

  bool disponible;
  bool enCours = false;

  void setDisponible(bool v) {
    disponible = v;
    notifyListeners();
  }

  void setEnCours(bool v) {
    enCours = v;
    notifyListeners();
  }
}

class _FormulaireFicheState extends State<_FormulaireFiche> {
  late final TextEditingController _coursIdCtrl = TextEditingController();
  late final TextEditingController _villeCtrl = TextEditingController(text: widget.ville ?? '');
  late final TextEditingController _telephoneCtrl = TextEditingController(text: widget.telephone ?? '');
  late final TextEditingController _tarifCtrl = TextEditingController(
    text: widget.tarifMensuel?.toString() ?? '',
  );
  late final _state = _FormulaireState(disponible: widget.disponible ?? true);

  bool get _estEdition => widget.onValiderAvecDisponibilite != null;

  @override
  void dispose() {
    _coursIdCtrl.dispose();
    _villeCtrl.dispose();
    _telephoneCtrl.dispose();
    _tarifCtrl.dispose();
    _state.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final ville = _villeCtrl.text.trim();
    final telephone = _telephoneCtrl.text.trim();
    if (ville.isEmpty || telephone.isEmpty) {
      YkSnack.warning(context, 'Ville et téléphone sont obligatoires.');
      return;
    }
    final tarif = int.tryParse(_tarifCtrl.text.trim());

    _state.setEnCours(true);
    try {
      if (_estEdition) {
        await widget.onValiderAvecDisponibilite!(ville, telephone, tarif, _state.disponible);
      } else {
        final coursId = int.tryParse(_coursIdCtrl.text.trim());
        if (coursId == null) {
          _state.setEnCours(false);
          YkSnack.warning(context, 'ID du cours invalide.');
          return;
        }
        await widget.onValider(coursId, ville, telephone, tarif);
      }
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
            if (!_estEdition) ...[
              YkTextField(
                controller: _coursIdCtrl,
                label: 'ID du cours',
                type: YkTextFieldType.number,
                required: true,
              ),
              SizedBox(height: YkSpacing.sm),
            ],
            YkTextField(controller: _villeCtrl, label: 'Ville', required: true),
            SizedBox(height: YkSpacing.sm),
            YkTextField(
              controller: _telephoneCtrl,
              label: 'Téléphone (contact WhatsApp)',
              type: YkTextFieldType.number,
              required: true,
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(
              controller: _tarifCtrl,
              label: 'Tarif mensuel (FCFA, optionnel)',
              type: YkTextFieldType.number,
            ),
            if (_estEdition) ...[
              SizedBox(height: YkSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Disponible', style: YkTypography.bodyMd(context).copyWith(color: YkColors.textPrimary(context))),
                  Switch(
                    value: _state.disponible,
                    onChanged: (v) => _state.setDisponible(v),
                    activeColor: YkColors.accent(context),
                  ),
                ],
              ),
            ],
            SizedBox(height: YkSpacing.lg),
            YkButton(label: 'Enregistrer', isLoading: _state.enCours, onPressed: _state.enCours ? null : _valider),
          ],
        ),
      ),
    );
  }
}
