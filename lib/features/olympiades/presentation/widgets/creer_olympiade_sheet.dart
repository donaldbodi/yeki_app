// lib/features/olympiades/presentation/widgets/creer_olympiade_sheet.dart
//
// Feuille de création/modification d'une olympiade par un enseignant
// cadre. Refondue en P8.2 (rituel P5.0) — remplace
// lib/widgets/creer_olympiade_sheet.dart. Aucune maquette dédiée pour ce
// formulaire précis (seulement des tuiles de dashboard) — le texte du
// ticket fait foi.
//
// Présentée via `YkSheet.show` (gère nativement conteneur arrondi,
// poignée, titre, bouton fermer — pas de `BoxDecoration` recopiée à la
// main, règle 2) plutôt qu'un widget instancié directement dans un
// `showModalBottomSheet` brut : d'où la fonction top-niveau
// `ouvrirCreerOlympiade`, même patron que `ouvrirPreoccupation`
// (`widgets/form_preoccupation_sheet.dart`).
//
// `YkFormController`/`YkForm` (P8.2 : premier usage dans une feuille
// modale, jusqu'ici réservés aux pages pleines login/register/mot de
// passe oublié — exigé nommément par le texte du ticket). Seuls les
// `YkTextField` nommés s'enregistrent automatiquement ; les 3 dates
// obligatoires (`YkDateTimePicker`, sans intégration `YkForm`) sont
// enregistrées manuellement comme champs virtuels, ainsi qu'un 4e champ
// virtuel `dates_coherentes` (clôture des inscriptions avant le début).

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/repositories/formation_repository.dart';
import 'package:yeki/repositories/olympiade_repository.dart';

const _imageConstraint = YkFileConstraint(allowedExtensions: ['jpg', 'jpeg', 'png'], maxSizeBytes: 5 * 1024 * 1024);

/// État du formulaire — `ChangeNotifier` plutôt que `setState` (interdit
/// sous `lib/features/`, règle 7), même patron que
/// `_QuestionDevoirController` (`widgets/question_devoir_form.dart`) :
/// possède aussi les `TextEditingController`, disposés avec lui.
class _CreerOlympiadeController extends ChangeNotifier {
  _CreerOlympiadeController({Map<String, dynamic>? olympiade})
    : titreCtrl = TextEditingController(text: olympiade?['titre'] as String? ?? ''),
      descCtrl = TextEditingController(text: olympiade?['description'] as String? ?? ''),
      editionCtrl = TextEditingController(text: olympiade?['edition'] as String? ?? ''),
      prixCtrl = TextEditingController(
        text: ((olympiade?['prix_participation'] as num?) ?? 100).toInt().toString(),
      ),
      dureeCtrl = TextEditingController(
        text: ((olympiade?['duree_minutes'] as num?) ?? 120).toInt().toString(),
      ),
      nbQuestionsCtrl = TextEditingController(
        text: ((olympiade?['nb_questions'] as num?) ?? 30).toInt().toString(),
      ),
      maxFocusCtrl = TextEditingController(
        text: ((olympiade?['max_focus_perdu'] as num?) ?? 3).toInt().toString(),
      ),
      recompenseHtml = olympiade?['recompense'] as String? ?? '',
      demandePaiementParticipants = olympiade?['demande_paiement_participants'] as bool? ?? true,
      melangerQuestions = olympiade?['melanger_questions'] as bool? ?? true,
      melangerChoix = olympiade?['melanger_choix'] as bool? ?? true,
      uneSeuleSession = olympiade?['une_seule_session'] as bool? ?? true,
      dateOuvertureInscription = _parseDate(olympiade?['date_ouverture_inscription']),
      dateClotureInscription = _parseDate(olympiade?['date_cloture_inscription']),
      dateDebutOlympiade = _parseDate(olympiade?['date_debut_olympiade']) {
    final niveaux = olympiade?['niveaux_accessibles'];
    if (niveaux is List) {
      niveauxSelectionnes = niveaux.map((n) => n.toString()).toSet();
    } else if (niveaux is String && niveaux.isNotEmpty) {
      niveauxSelectionnes = niveaux.split(',').map((n) => n.trim()).where((n) => n.isNotEmpty).toSet();
    }
    // Bug corrigé : la tuile "Fin de l'olympiade (calculée)" ne se
    // rafraîchissait pas à la frappe dans "Durée" — `dureeCtrl` n'avait
    // aucun listener, seul un rebuild déclenché par un AUTRE champ (date,
    // switch) la mettait à jour par ricochet. `dateFin` reste un getter
    // calculé, jamais modifiable ni envoyé au serveur (qui la recalcule
    // identiquement) — seule la réactivité de l'AFFICHAGE est corrigée.
    dureeCtrl.addListener(notifyListeners);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  final TextEditingController titreCtrl;
  final TextEditingController descCtrl;
  final TextEditingController editionCtrl;
  final TextEditingController prixCtrl;
  final TextEditingController dureeCtrl;
  final TextEditingController nbQuestionsCtrl;
  final TextEditingController maxFocusCtrl;

  String recompenseHtml;
  bool demandePaiementParticipants;
  bool melangerQuestions;
  bool melangerChoix;
  bool uneSeuleSession;

  Set<String> niveauxSelectionnes = {};
  List<String> niveauxDisponibles = [];
  bool niveauxCharges = false;

  DateTime? dateOuvertureInscription;
  DateTime? dateClotureInscription;
  DateTime? dateDebutOlympiade;

  /// Affichée, calculée, JAMAIS modifiable ni envoyée au serveur (qui la
  /// recalcule lui-même identiquement — P8.1) : pure prévisualisation.
  DateTime? get dateFin {
    if (dateDebutOlympiade == null) return null;
    final duree = int.tryParse(dureeCtrl.text.trim());
    if (duree == null) return null;
    return dateDebutOlympiade!.add(Duration(minutes: duree));
  }

  bool get datesCoherentes =>
      dateOuvertureInscription != null &&
      dateClotureInscription != null &&
      dateDebutOlympiade != null &&
      dateOuvertureInscription!.isBefore(dateClotureInscription!) &&
      dateClotureInscription!.isBefore(dateDebutOlympiade!);

  void setDateOuverture(DateTime v) {
    dateOuvertureInscription = v;
    notifyListeners();
  }

  void setDateCloture(DateTime v) {
    dateClotureInscription = v;
    notifyListeners();
  }

  void setDateDebut(DateTime v) {
    dateDebutOlympiade = v;
    notifyListeners();
  }

  void setRecompense(String v) {
    recompenseHtml = v;
  }

  void setNiveaux(Set<String> v) {
    niveauxSelectionnes = v;
    notifyListeners();
  }

  void toggleDemandePaiement(bool v) {
    demandePaiementParticipants = v;
    notifyListeners();
  }

  void toggleMelangerQuestions(bool v) {
    melangerQuestions = v;
    notifyListeners();
  }

  void toggleMelangerChoix(bool v) {
    melangerChoix = v;
    notifyListeners();
  }

  void toggleUneSeuleSession(bool v) {
    uneSeuleSession = v;
    notifyListeners();
  }

  /// « Fonction de livraison des niveaux » du ticket = fonction
  /// canonique unique (P5.4) — vrai `GET /niveaux/`, pas une valeur en
  /// dur (règle 3).
  Future<void> chargerNiveaux() async {
    if (niveauxCharges) return;
    try {
      niveauxDisponibles = await FormationRepository().niveaux();
    } catch (_) {
      niveauxDisponibles = [];
    }
    niveauxCharges = true;
    notifyListeners();
  }

  @override
  void dispose() {
    titreCtrl.dispose();
    descCtrl.dispose();
    editionCtrl.dispose();
    prixCtrl.dispose();
    dureeCtrl.dispose();
    nbQuestionsCtrl.dispose();
    maxFocusCtrl.dispose();
    super.dispose();
  }
}

/// Ouvre la feuille de création (ou modification si [olympiade] fourni)
/// — même contrat que l'ancien `CreerOlympiadeSheet` instancié
/// directement (`departementId`, `departementNom`, `onSuccess`,
/// `parcoursType`, `olympiade`).
Future<void> ouvrirCreerOlympiade(
  BuildContext context, {
  required int departementId,
  required String departementNom,
  required VoidCallback onSuccess,
  String parcoursType = 'cursus',
  Map<String, dynamic>? olympiade,
}) async {
  final formController = YkFormController();
  final controller = _CreerOlympiadeController(olympiade: olympiade);
  final isEditing = olympiade != null;
  final olympiadeId = olympiade?['id'] as int? ?? 0;

  // Les 3 dates obligatoires n'ont pas d'intégration `YkForm` native
  // (`YkDateTimePicker` ne porte pas de `name`/`required`) — enregistrées
  // manuellement comme champs virtuels (API publique du contrôleur,
  // prévue pour ça). `dates_coherentes` couvre la règle transversale
  // « clôture avant début » : une vraie désactivation du bouton, pas
  // juste un bandeau d'avertissement ignorable comme l'ancien fichier.
  const champsVirtuels = ['date_ouverture', 'date_cloture', 'date_debut', 'dates_coherentes'];
  for (final champ in champsVirtuels) {
    formController.registerField(champ, required: true);
  }
  void synchroniserDatesForm() {
    formController.updateFieldFilled('date_ouverture', controller.dateOuvertureInscription != null);
    formController.updateFieldFilled('date_cloture', controller.dateClotureInscription != null);
    formController.updateFieldFilled('date_debut', controller.dateDebutOlympiade != null);
    formController.updateFieldFilled('dates_coherentes', controller.datesCoherentes);
  }

  synchroniserDatesForm();
  controller.addListener(synchroniserDatesForm);
  unawaited(controller.chargerNiveaux());

  await YkSheet.show(
    context: context,
    title: isEditing ? "Modifier l'olympiade" : 'Nouvelle olympiade',
    bodyBuilder: (ctx) => YkForm(
      controller: formController,
      child: _CreerOlympiadeFields(controller: controller, departementNom: departementNom),
    ),
    actionsBuilder: (ctx) => [
      YkFormSubmitButton(
        controller: formController,
        label: isEditing ? 'Enregistrer' : "Créer l'olympiade",
        successMessage: isEditing
            ? 'Olympiade modifiée avec succès !'
            : "Olympiade créée et publiée ! Ajoutez maintenant ses questions.",
        onValidSubmit: () async {
          final repo = OlympiadeRepository();
          if (isEditing) {
            await repo.modifier(
              olympiadeId,
              titre: controller.titreCtrl.text.trim(),
              description: controller.descCtrl.text.trim(),
              edition: controller.editionCtrl.text.trim(),
              recompense: controller.recompenseHtml.trim(),
              prixParticipation: int.tryParse(controller.prixCtrl.text.trim()) ?? 100,
              demandePaiementParticipants: controller.demandePaiementParticipants,
              niveauxAccessibles: controller.niveauxSelectionnes.toList(),
              dateOuvertureInscription: controller.dateOuvertureInscription!,
              dateClotureInscription: controller.dateClotureInscription!,
              dateDebutOlympiade: controller.dateDebutOlympiade!,
              dureeMinutes: int.tryParse(controller.dureeCtrl.text.trim()) ?? 120,
              nbQuestions: int.tryParse(controller.nbQuestionsCtrl.text.trim()) ?? 30,
              maxFocusPerdu: int.tryParse(controller.maxFocusCtrl.text.trim()) ?? 3,
              melangerQuestions: controller.melangerQuestions,
              melangerChoix: controller.melangerChoix,
              uneSeuleSession: controller.uneSeuleSession,
            );
          } else {
            await repo.creer(
              departementId: departementId,
              titre: controller.titreCtrl.text.trim(),
              description: controller.descCtrl.text.trim(),
              edition: controller.editionCtrl.text.trim(),
              recompense: controller.recompenseHtml.trim(),
              prixParticipation: int.tryParse(controller.prixCtrl.text.trim()) ?? 100,
              demandePaiementParticipants: controller.demandePaiementParticipants,
              niveauxAccessibles: controller.niveauxSelectionnes.toList(),
              dateOuvertureInscription: controller.dateOuvertureInscription!,
              dateClotureInscription: controller.dateClotureInscription!,
              dateDebutOlympiade: controller.dateDebutOlympiade!,
              dureeMinutes: int.tryParse(controller.dureeCtrl.text.trim()) ?? 120,
              nbQuestions: int.tryParse(controller.nbQuestionsCtrl.text.trim()) ?? 30,
              maxFocusPerdu: int.tryParse(controller.maxFocusCtrl.text.trim()) ?? 3,
              melangerQuestions: controller.melangerQuestions,
              melangerChoix: controller.melangerChoix,
              uneSeuleSession: controller.uneSeuleSession,
            );
          }
          // Ferme la feuille avant que l'appelant n'affiche son propre
          // succès (les deux sites d'appel existants le font déjà,
          // `cadre_dashboard_page.dart`) — le message de
          // `YkFormController.submit()` ne s'affichera alors pas
          // (contexte démonté, protégé par `context.mounted`, jamais un
          // crash), redondance déjà présente dans l'ancien fichier
          // évitée plutôt qu'aggravée.
          if (ctx.mounted) Navigator.of(ctx).pop();
          onSuccess();
        },
      ),
    ],
  );

  controller.removeListener(synchroniserDatesForm);
  formController.dispose();
  controller.dispose();
}

class _CreerOlympiadeFields extends StatelessWidget {
  const _CreerOlympiadeFields({required this.controller, required this.departementNom});

  final _CreerOlympiadeController controller;
  final String departementNom;

  Future<String> _uploadImage(YkPickedFile file) async {
    throw UnsupportedError("Téléversement d'image indisponible pour le moment.");
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Padding(
        padding: EdgeInsets.symmetric(horizontal: YkSpacing.md, vertical: YkSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              departementNom,
              style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
            ),
            SizedBox(height: YkSpacing.md),
            YkTextField(
              name: 'titre',
              required: true,
              controller: controller.titreCtrl,
              label: "Titre de l'olympiade",
              hint: 'Ex : Grand Prix de Mathématiques 2026',
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(controller: controller.editionCtrl, label: 'Édition', hint: 'Ex : 2026-1'),
            SizedBox(height: YkSpacing.sm),
            YkTextField(
              controller: controller.descCtrl,
              type: YkTextFieldType.multiline,
              maxLines: 3,
              label: 'Description',
              hint: "Décrivez l'olympiade…",
            ),
            SizedBox(height: YkSpacing.md),
            Text(
              'Niveaux accessibles',
              style: YkTypography.label(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            SizedBox(height: YkSpacing.xs),
            if (!controller.niveauxCharges)
              const YkSkeleton.line(height: 36)
            else
              YkMultiSelect<String>(
                items: [for (final n in controller.niveauxDisponibles) YkMultiSelectItem(value: n, label: n)],
                selectedValues: controller.niveauxSelectionnes,
                onChanged: controller.setNiveaux,
              ),
            if (controller.niveauxCharges && controller.niveauxSelectionnes.isEmpty) ...[
              SizedBox(height: YkSpacing.xxs),
              Text(
                'Aucun niveau sélectionné → accessible à tous les niveaux.',
                style: YkTypography.bodySm(
                  context,
                ).copyWith(color: YkColors.textSecondary(context), fontStyle: FontStyle.italic),
              ),
            ],
            SizedBox(height: YkSpacing.md),
            YkCard(
              child: SwitchListTile(
                value: controller.demandePaiementParticipants,
                onChanged: controller.toggleDemandePaiement,
                activeColor: YkColors.accent(context),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Demander un paiement aux participants',
                  style: YkTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '100 FCFA par défaut — répartis entre Yéki et vous',
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                ),
              ),
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(
              name: 'prix_participation',
              required: true,
              controller: controller.prixCtrl,
              type: YkTextFieldType.number,
              label: 'Prix de participation (FCFA)',
              hint: '100',
            ),
            SizedBox(height: YkSpacing.md),
            YkRichEditor(
              key: const ValueKey('recompense-olympiade'),
              initialHtml: controller.recompenseHtml,
              onChanged: controller.setRecompense,
              onUploadImage: _uploadImage,
              imageConstraint: _imageConstraint,
              label: 'Récompenses',
            ),
            SizedBox(height: YkSpacing.lg),
            Text('Calendrier', style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context))),
            SizedBox(height: YkSpacing.sm),
            YkDateTimePicker(
              mode: YkDateTimePickerMode.dateTime,
              label: 'Ouverture des inscriptions',
              value: controller.dateOuvertureInscription,
              firstDate: DateTime.now(),
              onChanged: controller.setDateOuverture,
            ),
            SizedBox(height: YkSpacing.sm),
            YkDateTimePicker(
              mode: YkDateTimePickerMode.dateTime,
              label: 'Clôture des inscriptions',
              value: controller.dateClotureInscription,
              firstDate: DateTime.now(),
              onChanged: controller.setDateCloture,
            ),
            SizedBox(height: YkSpacing.sm),
            YkDateTimePicker(
              mode: YkDateTimePickerMode.dateTime,
              label: "Début de l'olympiade",
              value: controller.dateDebutOlympiade,
              firstDate: DateTime.now(),
              onChanged: controller.setDateDebut,
            ),
            SizedBox(height: YkSpacing.sm),
            _DateFinTile(dateFin: controller.dateFin),
            if (controller.dateOuvertureInscription != null &&
                controller.dateClotureInscription != null &&
                controller.dateDebutOlympiade != null &&
                !controller.datesCoherentes) ...[
              SizedBox(height: YkSpacing.sm),
              _MessageBanner(
                icon: Icons.error_outline,
                color: YkColors.error,
                message:
                    "L'ouverture puis la clôture des inscriptions doivent précéder le début de l'olympiade.",
              ),
            ],
            SizedBox(height: YkSpacing.lg),
            Text(
              'Composition',
              style: YkTypography.h4(context).copyWith(color: YkColors.textPrimary(context)),
            ),
            SizedBox(height: YkSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: YkTextField(
                    name: 'duree_minutes',
                    required: true,
                    controller: controller.dureeCtrl,
                    type: YkTextFieldType.number,
                    label: 'Durée (minutes)',
                    hint: '120',
                  ),
                ),
                SizedBox(width: YkSpacing.sm),
                Expanded(
                  child: YkTextField(
                    name: 'nb_questions',
                    required: true,
                    controller: controller.nbQuestionsCtrl,
                    type: YkTextFieldType.number,
                    label: 'Nb de questions',
                    hint: '30',
                  ),
                ),
              ],
            ),
            SizedBox(height: YkSpacing.sm),
            YkTextField(
              name: 'max_focus_perdu',
              required: true,
              controller: controller.maxFocusCtrl,
              type: YkTextFieldType.number,
              label: 'Pertes de focus max (avant soumission auto)',
              hint: '3',
            ),
            SizedBox(height: YkSpacing.md),
            YkCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: controller.melangerQuestions,
                    onChanged: controller.toggleMelangerQuestions,
                    activeColor: YkColors.accent(context),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mélanger les questions'),
                    subtitle: const Text('Ordre différent pour chaque participant'),
                  ),
                  SwitchListTile(
                    value: controller.melangerChoix,
                    onChanged: controller.toggleMelangerChoix,
                    activeColor: YkColors.accent(context),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mélanger les choix QCM'),
                    subtitle: const Text('Ordre des réponses différent par participant'),
                  ),
                  SwitchListTile(
                    value: controller.uneSeuleSession,
                    onChanged: controller.toggleUneSeuleSession,
                    activeColor: YkColors.accent(context),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Session unique'),
                    subtitle: const Text('Impossible de reprendre après interruption'),
                  ),
                ],
              ),
            ),
            SizedBox(height: YkSpacing.md),
            _MessageBanner(
              icon: Icons.info_outline,
              color: YkColors.info,
              message:
                  'La note est automatiquement sur 20. Vous pourrez ajouter les questions après la création.',
            ),
            SizedBox(height: YkSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Date de fin — affichée, calculée, JAMAIS modifiable (le serveur la
/// recalcule identiquement, P8.1). Une simple tuile en lecture seule,
/// pas un `YkDateTimePicker` qui suggérerait à tort une interaction.
class _DateFinTile extends StatelessWidget {
  const _DateFinTile({required this.dateFin});

  final DateTime? dateFin;

  @override
  Widget build(BuildContext context) {
    return YkCard(
      variant: YkCardVariant.filled,
      child: Row(
        children: [
          Icon(Icons.event_available_outlined, color: YkColors.accent(context), size: 20),
          SizedBox(width: YkSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fin de l'olympiade (calculée)",
                  style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                ),
                Text(
                  dateFin != null
                      ? '${dateFin!.day.toString().padLeft(2, '0')}/'
                            '${dateFin!.month.toString().padLeft(2, '0')}/'
                            '${dateFin!.year} à '
                            '${dateFin!.hour.toString().padLeft(2, '0')}h'
                            '${dateFin!.minute.toString().padLeft(2, '0')}'
                      : 'Renseignez le début et la durée',
                  style: YkTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.icon, required this.color, required this.message});

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(YkSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(YkRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: YkSpacing.xs),
          Expanded(
            child: Text(message, style: YkTypography.bodySm(context).copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
