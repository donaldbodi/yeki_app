import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/models/repetiteur_models.dart';
import 'package:yeki/repositories/formation_repository.dart';

import '../service_client_controller.dart';

/// Onglet « Répétiteurs » (P9.5) — basculer `is_repetiteur`, ajouter/
/// retirer d'un cours, éditer ville et tarif.
///
/// « Ajouter à un cours » demandait jusqu'ici l'ID du cours en clair
/// (aucun endpoint de liste de cours n'existait côté `FormationRepository`
/// à l'époque). Remplacé par une cascade de menus déroulants (Parcours →
/// Département → Niveau → Cours), `liste_cours` (backend) désormais
/// accessible au Service Client et filtrable par département/niveau.
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
/// (interdit sous `lib/features/`, règle 7). Porte aussi la cascade de
/// sélection de cours (Parcours → Département → Niveau → Cours).
class _FormulaireState extends ChangeNotifier {
  _FormulaireState({required this.disponible});

  final _repo = FormationRepository();

  bool disponible;
  bool enCours = false;

  bool chargementParcours = true;
  List<ParcoursOption> parcoursListe = const [];
  int? parcoursId;

  List<DepartementOption> departementsListe = const [];
  int? departementId;
  bool chargementDepartements = false;

  List<String> niveauxListe = const [];
  String? niveau;
  bool chargementNiveaux = false;

  List<CoursOption> coursListe = const [];
  int? coursId;
  bool chargementCours = false;

  Future<void> chargerParcours() async {
    chargementParcours = true;
    notifyListeners();
    try {
      parcoursListe = await _repo.parcours();
    } catch (_) {
      parcoursListe = const [];
    }
    chargementParcours = false;
    notifyListeners();
  }

  Future<void> choisirParcours(int? id) async {
    parcoursId = id;
    departementId = null;
    niveau = null;
    coursId = null;
    departementsListe = const [];
    niveauxListe = const [];
    coursListe = const [];
    notifyListeners();
    if (id == null) return;
    chargementDepartements = true;
    notifyListeners();
    try {
      departementsListe = await _repo.departementsForParcours(id);
    } catch (_) {
      departementsListe = const [];
    }
    chargementDepartements = false;
    notifyListeners();
  }

  Future<void> choisirDepartement(int? id) async {
    departementId = id;
    niveau = null;
    coursId = null;
    niveauxListe = const [];
    coursListe = const [];
    notifyListeners();
    if (id == null) return;
    chargementNiveaux = true;
    notifyListeners();
    try {
      niveauxListe = await _repo.niveauxForDepartement(id);
    } catch (_) {
      niveauxListe = const [];
    }
    chargementNiveaux = false;
    notifyListeners();
    await _chargerCours();
  }

  Future<void> choisirNiveau(String? v) async {
    niveau = v;
    coursId = null;
    notifyListeners();
    await _chargerCours();
  }

  Future<void> _chargerCours() async {
    if (departementId == null) return;
    chargementCours = true;
    coursListe = const [];
    notifyListeners();
    try {
      coursListe = await _repo.coursFiltres(departementId: departementId, niveau: niveau);
    } catch (_) {
      coursListe = const [];
    }
    chargementCours = false;
    notifyListeners();
  }

  void choisirCours(int? id) {
    coursId = id;
    notifyListeners();
  }

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
  late final TextEditingController _villeCtrl = TextEditingController(text: widget.ville ?? '');
  late final TextEditingController _telephoneCtrl = TextEditingController(text: widget.telephone ?? '');
  late final TextEditingController _tarifCtrl = TextEditingController(
    text: widget.tarifMensuel?.toString() ?? '',
  );
  late final _state = _FormulaireState(disponible: widget.disponible ?? true);

  bool get _estEdition => widget.onValiderAvecDisponibilite != null;

  @override
  void initState() {
    super.initState();
    if (!_estEdition) _state.chargerParcours();
  }

  @override
  void dispose() {
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
        final coursId = _state.coursId;
        if (coursId == null) {
          _state.setEnCours(false);
          YkSnack.warning(context, 'Sélectionnez un cours.');
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
              YkDropdown<int>(
                label: 'Parcours',
                isLoading: _state.chargementParcours,
                value: _state.parcoursId,
                items: [for (final p in _state.parcoursListe) YkDropdownItem(value: p.id, label: p.nom)],
                onChanged: _state.choisirParcours,
              ),
              SizedBox(height: YkSpacing.sm),
              YkDropdown<int>(
                label: 'Département',
                isLoading: _state.chargementDepartements,
                value: _state.departementId,
                items: [for (final d in _state.departementsListe) YkDropdownItem(value: d.id, label: d.nom)],
                onChanged: _state.parcoursId == null ? (_) {} : _state.choisirDepartement,
              ),
              SizedBox(height: YkSpacing.sm),
              YkDropdown<String>(
                label: 'Niveau',
                isLoading: _state.chargementNiveaux,
                value: _state.niveau,
                items: [for (final n in _state.niveauxListe) YkDropdownItem(value: n, label: n)],
                onChanged: _state.departementId == null ? (_) {} : _state.choisirNiveau,
              ),
              SizedBox(height: YkSpacing.sm),
              YkDropdown<int>(
                label: 'Cours',
                isLoading: _state.chargementCours,
                value: _state.coursId,
                items: [
                  for (final c in _state.coursListe)
                    YkDropdownItem(value: c.id, label: '${c.titre} (${c.matiere})'),
                ],
                onChanged: _state.departementId == null ? (_) {} : _state.choisirCours,
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
